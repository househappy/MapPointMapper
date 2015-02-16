//
//  Parser.swift
//  MapPointMapper
//
//  Created by Daniel on 11/20/14.
//  Copyright (c) 2014 dmiedema. All rights reserved.
//

import Foundation
import MapKit

extension NSString {
    /**
    Convienence so `isEmpty` can be performed on an `NSString` instance just as if it were a `String`
    */
    var isEmpty: Bool {
        get { return self.length == 0 || self.isEqualToString("") }
    }
}
extension String {
    /**
    Strip all leading and trailing whitespace from a given `String` instance.
    
    :returns: a newly stripped string instance.
    */
    func stringByStrippingLeadingAndTrailingWhiteSpace() -> String {
        let mutable = self.mutableCopy() as NSMutableString
        CFStringTrimWhitespace(mutable)
        return mutable.copy() as String
    }
}

class Parser {
    // MARK: - Public
    /**
    Parse a given string of Lat/Lng values to return a collection of `CLLocationCoordinate2D` arrays.

    :note: The preferred way/format of the input string is `Well-Known Text` as the parser supports that for multipolygons and such

    :param: input          String to parse
    :param: longitudeFirst Only used if it is determined to not be `Well-Known Text` format.

    :returns: An array of `CLLocationCoordinate2D` arrays representing the parsed areas/lines
    */
    class func parseString(input: NSString, longitudeFirst: Bool) -> [[CLLocationCoordinate2D]] {
        return Parser(longitudeFirst: longitudeFirst).parseInput(input)
    }
    
    var longitudeFirst = false
    convenience init(longitudeFirst: Bool) {
        self.init()
        self.longitudeFirst = longitudeFirst
    }
    init() {}
    
    // MARK: - Private
    
    // MARK: Parsing

    /**
    Parse input string into a collection of `CLLocationCoordinate2D` arrays that can be drawn on a map

    :note: This method supports (and really works best with/prefers) `Well-Known Text` format

    :param: input `NSString` to parse

    :returns: Collection of `CLLocationCoordinate2D` arrays
    */
    internal func parseInput(input: NSString) ->  [[CLLocationCoordinate2D]] {
        var array = [[NSString]]()
        
        let line = input
    
        if isProbablyGeoString(line) {
            self.longitudeFirst = true
            var items = [NSString]()
            
            if isMultiItem(line) {
                items = stripExtraneousCharacters(line).componentsSeparatedByString("),") as [NSString]
            } else {
                items = [stripExtraneousCharacters(line)]
            }
            
            array = items.map({ self.formatStandardGeoDataString($0) })
            
        }
        
        let results = convertStringArraysToTuples(array)
        
        return results.filter({ !$0.isEmpty }).map{ self.convertToCoordinates($0, longitudeFirst: self.longitudeFirst) }
    }

    /**
    Convert an array of strings into tuple pairs.
    
    :note: the number of values passed in should probaly be even, since it creates pairs.

    :param: array of `[NSString]` array to create tuples from

    :returns: array of collections of tuple pairs where the tuples are lat/lng values as `NSString`s
    */
    internal func convertStringArraysToTuples(array: [[NSString]]) -> [[(NSString, NSString)]] {
        var tmpResults = [(NSString, NSString)]()
        var results = [[(NSString, NSString)]]()
        for arr in array {
            for var i = 0; i < arr.count - 1; i += 2 {
                tmpResults.append((arr[i], arr[i + 1]))
            }
            
            if tmpResults.count == 1 {
                tmpResults.append(tmpResults.first!)
            }
            
            results.append(tmpResults)
            tmpResults.removeAll(keepCapacity: false)
        } // end for arr in array
        return results
    }

    /**
    :abstract: Naively format a `Well-Known Text` string into array of string values, where each string is a single value
    
    :disucssion: This removes any lingering parens from the given string, breaks on `,` then breaks on ` ` while filtering out any empty strings.

    :param: input String to format, assumed `Well-Known Text` format

    :returns: array of strings where each string is one value from the string with all empty strings filtered out.
    */
    internal func formatStandardGeoDataString(input: NSString) -> [NSString] {
        // Remove Extra ()
        let stripped = input
            .stringByReplacingOccurrencesOfString("(", withString: "")
            .stringByReplacingOccurrencesOfString(")", withString: "")
        
        // Break on ',' to get pairs separated by ' '
        let pairs = stripped.componentsSeparatedByString(",")
        
        // break on " " and remove empties
        var filtered = [NSString]()
        
        for pair in pairs {
            pair.componentsSeparatedByString(" ").filter({!$0.isEmpty}).map({filtered.append($0)})
        }
        
        return filtered.filter({!$0.isEmpty})
    }
    
    private func formatCustomLatLongString(input: NSString) -> [NSString] {
        return input.stringByReplacingOccurrencesOfString("\n", withString: ",").componentsSeparatedByString(",") as [NSString]
    }
    
    private func splitLine(input: NSString, delimiter: NSString) -> (NSString, NSString) {
        let array = input.componentsSeparatedByString(delimiter)
        return (array.first! as NSString, array.last! as NSString)
    }
    
    /**
    :abstract: Convert a given array of `(String, String)` tuples to array of `CLLocationCoordinate2D` values
    
    :discussion: This attempts to parse the strings double values but does no safety checks if they can be parsed as `double`s.

    :param: pairs          array of `String` tuples to parse as `Double`s
    :param: longitudeFirst boolean flag if the first item in the tuple should be the longitude value

    :returns: array of `CLLocationCoordinate2D` values
    */
    internal func convertToCoordinates(pairs: [(NSString, NSString)], longitudeFirst: Bool) -> [CLLocationCoordinate2D] {
        var coordinates = [CLLocationCoordinate2D]()
        for pair in pairs {
            var lat: Double = 0.0
            var lng: Double = 0.0
            if longitudeFirst {
                lat = pair.1.doubleValue
                lng = pair.0.doubleValue
            } else {
                lat = pair.0.doubleValue
                lng = pair.1.doubleValue
            }
            coordinates.append(CLLocationCoordinate2D(latitude: lat, longitude: lng))
        }
        return coordinates
    }

    /**
    Removes any text before lat long points as well as two outer sets of parens.
    
    Example:
    input  => "POLYGON(( 15 32 ))"
    output => "15 32"

    input  => "MULTIPOLYGON((( 15 32 )))"
    output => "( 15 32 )"

    :param: input NSString to strip extraneous characters from

    :returns: stripped string instance
    */
    internal func stripExtraneousCharacters(input: NSString) -> NSString {
        let regex = NSRegularExpression(pattern: "\\w+\\s+\\((.*)\\)", options: .CaseInsensitive, error: nil)
        let match: AnyObject? = regex?.matchesInString(input, options: .ReportCompletion, range: NSMakeRange(0, input.length)).first
        let range = match?.rangeAtIndex(1)
        
        let loc = range?.location as Int!
        let len = range?.length as Int!
        
        return input.substringWithRange(NSRange(location: loc, length: len)) as NSString
    }

    /**
    :abstract: Attempt to determine if a given string is in `Well-Known Text` format (GeoString as its referred to internally)

    :discussion: This strips any leading & trailing white space before checking for the existance of word characters at the start of the string.

    :param: input String to attempt determine if is in `Well-Known Text` format

    :returns: `true` if it thinks it is, `false` otherwise
    */
    internal func isProbablyGeoString(input: String) -> Bool {
        let stripped = input.stringByStrippingLeadingAndTrailingWhiteSpace()
        if let geoString = stripped.rangeOfString("^\\w+", options: .RegularExpressionSearch) {
            return true
        }
        return false
    }

    /**
    Determine if a given string is a `MULTI*` item.

    :param: input String to check

    :returns: `true` if the string starts with `MULTI`. `false` otherwise
    */
    internal func isMultiItem(input: String) -> Bool {
        if let isPolygon = input.rangeOfString("MULTI", options: .RegularExpressionSearch) {
            return true
        }
        return false
    }

    /**
    Determines if a the collection is space delimited or not
    
    :note: This function should only be passed a single entry or else it will probably have incorrect results
    
    :param: input a single entry from the collection as a string
    
    :returns: `true` if elements are space delimited, `false` otherwise
    */
    private func isSpaceDelimited(input: String) -> Bool {
        let array = input.componentsSeparatedByString(" ")
        return array.count > 1
    }
}
