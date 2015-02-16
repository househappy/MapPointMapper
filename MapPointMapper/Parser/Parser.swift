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
    var isEmpty: Bool {
        get { return self.length == 0 || self.isEqualToString("") }
    }
}

class Parser {
    // MARK: - Public
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
    Convert [(String, String)] array of tuples into a [CLLocationCoordinate2D]
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
    */
    internal func stripExtraneousCharacters(input: NSString) -> NSString {
        let regex = NSRegularExpression(pattern: "\\w+\\s+\\((.*)\\)", options: .CaseInsensitive, error: nil)
        let match: AnyObject? = regex?.matchesInString(input, options: .ReportCompletion, range: NSMakeRange(0, input.length)).first
        let range = match?.rangeAtIndex(1)
        
        let loc = range?.location as Int!
        let len = range?.length as Int!
        
        return (input as NSString).substringWithRange(NSRange(location: loc, length: len)) as NSString
    }
    
    internal func isProbablyGeoString(input: String) -> Bool {
        if let geoString = input.rangeOfString("^\\w+", options: .RegularExpressionSearch) {
            return true
        }
        return false
    }
    
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
