//
//  Parser.swift
//  MapPointMapper
//
//  Created by Daniel on 11/20/14.
//  Copyright (c) 2014 dmiedema. All rights reserved.
//

import Foundation
import MapKit

class Parser {
    // MARK: - Public
    class func parseString(input: String) -> [CLLocationCoordinate2D] {
        return self.init().parseInput(input)
    }
    
    class func parseArray(input: [String]) -> [CLLocationCoordinate2D] {
        return self.init().parseInput(input)
    }
    
    class func parseDictionary(input: [String: String]) -> [CLLocationCoordinate2D] {
        return self.init().parseInput(input)
    }
    
    // MARK: - Private
    private var longitudeFirst = false
    
    // MARK: Parsing
    private func parseInput(input: AnyObject) ->  [CLLocationCoordinate2D] {
        var results = [(String, String)]()
        
        if let arr = input as? Array<Dictionary<String, String>> {
            
        } else {
            var delimiter = ","
            var first = ""
            var array = Array<String>()
            
            if let line = input as? String {
                var str = line
                if isPolygon(line) || isMultipolygon(line) {
                    longitudeFirst = true
                    str = stripExtraneousCharacters(line)
                }
                str = str.stringByReplacingOccurrencesOfString("\n", withString: ",", options: .CaseInsensitiveSearch, range: nil)
                
                // Figure out what kind of thing we're dealing with. Check polygon and type, etc
                // and strip unnecessary items by this point.
                
                array = str.componentsSeparatedByString(",")
                first = array.first!
            } else if let arr = input as? Array<String> {
                array = arr
                first = arr.first!
            }
            
            // Handle the case of only getting a single point.
            // We add the point twice so that we can still draw a 'line' between the points
            if array.count == 1 {
                array.append(array.first!)
            }
            
            if isSpaceDelimited(first) {
                delimiter = " "
                results = array.map { self.splitLine($0, delimiter: delimiter) }
            } else {
                for var i = 0; i < array.count; i += 2 {
                    results.append((array[i], array[i + 1]))
                }
            }
        }
        
        return convertToCoordinates(results)
    }
    
    private func splitLine(input: String, delimiter: String) -> (String, String) {
        let array = input.componentsSeparatedByString(delimiter)
        return (array.first!, array.last!)
    }
    
    private func convertToCoordinates(pairs: [(String, String)]) -> [CLLocationCoordinate2D] {
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
