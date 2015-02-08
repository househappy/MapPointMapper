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
    
    // MARK: - Private
    
    // MARK: Parsing
    private func parseInput(input: NSString) ->  [[CLLocationCoordinate2D]] {
        var results = [[(String, String)]()]
        
        var array = [[NSString]]()
        
        let line = input
    
        if isPolygon(line) {
            longitudeFirst = true
            var polygons = [NSString]()
            
            if isMultipolygon(line) {
                polygons = stripExtraneousCharacters(line).componentsSeparatedByString("), ")
            } else {
                polygons = [stripExtraneousCharacters(line)]
            }
            
            array = polygons.map({ self.formatPolygonString($0) })
            
        } else { // not a polygon

        }
        
        var tmpResults = [(String, String)]()
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
        
        return results.filter({ !$0.isEmpty }).map{ self.convertToCoordinates($0, longitudeFirst: self.longitudeFirst) }
    }
    
    private func formatPolygonString(input: NSString) -> [NSString] {
        // Remove Extra ()
        let stripped = input
            .stringByReplacingOccurrencesOfString("(", withString: "")
            .stringByReplacingOccurrencesOfString(")", withString: "")
        
        // Break on ','
        let pairs = stripped.componentsSeparatedByString(",")
        
        // break on " " and remove empties
        var filtered = [NSString]()
        
        for pair in pairs {
            pair.componentsSeparatedByString(" ").filter({!$0.isEmpty}).map({filtered.append($0)})
        }
        
        return filtered
    }
    
    private func formatCustomLatLongString(input: NSString) -> [NSString] {
        return input.stringByReplacingOccurrencesOfString("\n", withString: ",").componentsSeparatedByString(",") as [NSString]
    }
    
    private func splitLine(input: String, delimiter: String) -> (String, String) {
        let array = input.componentsSeparatedByString(delimiter)
        return (array.first!, array.last!)
    }
    
    /**
    Convert [(String, String)] array of tuples into a [CLLocationCoordinate2D]
    */
    private func convertToCoordinates(pairs: [(String, String)], longitudeFirst: Bool) -> [CLLocationCoordinate2D] {
        var coordinates = [CLLocationCoordinate2D]()
        for pair in pairs {
            var lat: Double = 0.0
            var lng: Double = 0.0
            if longitudeFirst {
                lat = (pair.1 as NSString).doubleValue
                lng = (pair.0 as NSString).doubleValue
            } else {
                lat = (pair.0 as NSString).doubleValue
                lng = (pair.1 as NSString).doubleValue
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
    private func stripExtraneousCharacters(input: String) -> String {
        let regex = NSRegularExpression(pattern: "\\w+ \\(\\((.*)\\)\\)", options: .CaseInsensitive, error: nil)
        let match: AnyObject? = regex?.matchesInString(input, options: .ReportCompletion, range: NSMakeRange(0, input.utf16Count)).first
        let range = match?.rangeAtIndex(1)
        
        let loc = range?.location as Int!
        let len = range?.length as Int!
        
        return (input as NSString).substringWithRange(NSRange(location: loc, length: len))
    }
    
    private func isPolygon(input: String) -> Bool {
        if let isPolygon = input.rangeOfString("POLYGON ", options: .RegularExpressionSearch) {
            return true
        }
        return false
    }
    
    private func isMultipolygon(input: String) -> Bool {
        if let isPolygon = input.rangeOfString("MULTIPOLYGON ", options: .RegularExpressionSearch) {
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
