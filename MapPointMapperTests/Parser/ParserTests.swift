//
//  ParserTests.swift
//  MapPointMapper
//
//  Created by Daniel on 2/9/15.
//  Copyright (c) 2015 dmiedema. All rights reserved.
//

import Cocoa
import XCTest
import MapKit

let line            = "LINESTRING (30 10, 10 30, 40 40)"
let polygon         = "POLYGON ((30 10, 40 40, 20 40, 10 20, 30 10))"
let point           = "POINT (30 10)"
let point_alternate = "POINT(30 10)"
let unknown         = "-30 20, -45 40, -10 15"
let multiPolygon    = "MULTIPOLYGON (((30 20, 45 40, 10 40, 30 20)), ((15 5, 40 10, 10 20, 5 10, 15 5)))"
let multiPoint      = "MULTIPOINT ((10 40), (40 30), (20 20), (30 10))"
let multiLine       = "MULTILINESTRING ((10 10, 20 20, 10 40), (40 40, 30 30, 40 20, 30 10))"

class ParserSpec: XCTestCase {
  var parser: Parser!
  
  func testParserRecognizesGeoSpacialStrings() {
    XCTAssertTrue(parser.isProbablyGeoString(line), "'line' should be a geospacial string")
    XCTAssertTrue(parser.isProbablyGeoString(polygon), "'polygon' should be a geospacial string")
    XCTAssertTrue(parser.isProbablyGeoString(point), "'point' should be a geospacial string")
    XCTAssertTrue(parser.isProbablyGeoString(multiPolygon), "'multipolygon' should be a geospacial string")
    XCTAssertTrue(parser.isProbablyGeoString(multiPoint), "'multipoint' should be a geospacial string")
    XCTAssertTrue(parser.isProbablyGeoString(multiLine), "'multiline' should be a geospacial string")
  }
  
  func testParserKnowsWhenItsNotGeoSpacial() {
    XCTAssertFalse(parser.isProbablyGeoString(unknown), "'unknown' should not be a geospacial string")
  }
  
  func testParserKnowsItsNotGeoSpacialEvenIfItsClose() {
    XCTAssertFalse(parser.isProbablyGeoString("-122 45"), "'-122 45' should not be geospacial")
  }
  
  func testIsMultiItem() {
    XCTAssertTrue(parser.isMultiItem(multiPolygon), "'multipolygon' should be a multi item")
    XCTAssertTrue(parser.isMultiItem(multiLine), "'multiline' should be a multi item")
    XCTAssertTrue(parser.isMultiItem(multiPoint), "'multipoint' should be a multi item")
    XCTAssertFalse(parser.isMultiItem(unknown), "'unknown' should not be a multi item")
    XCTAssertFalse(parser.isMultiItem(polygon), "'polygon' should not be a multi item")
  }
  
  func testFormatsStandardGeoDataString() {
    let formatted = [parser.stripExtraneousCharacters(polygon)].map({
      self.parser.formatStandardGeoDataString($0)
    })
    
    let first = formatted.first!
    XCTAssertEqual(first.first!, "30", "First item should be '30', was \(first.first!)")
    XCTAssertEqual(first.last!, "10", "Last item should be '10', was \(first.last!)")
  }

  func testHandlesAlternativeWKTFormats() {
    let formatted_first = [parser.stripExtraneousCharacters(point)].map({
      self.parser.formatStandardGeoDataString($0)
    })
    let formatted_second = [parser.stripExtraneousCharacters(point_alternate)].map({
      self.parser.formatStandardGeoDataString($0)
    })

    let first = formatted_first.first!
    let second = formatted_second.first!
    XCTAssertEqual(first.first!, second.first!, "First item should equal second, first was \(first.first!), second was \(second.first!)")
    XCTAssertEqual(first.last!, second.last!, "First item should equal second, first was \(first.last!), second was \(second.last!)")
  }
  
  func testParsingInvalidInputString() {
    let inputString = "POLYGON (( herp derp dee derp"
    do {
      try Parser.parseString(inputString, longitudeFirst: false)
    } catch {
      XCTAssertTrue(error is ErrorType)
    }
  }

  func testParsingInput() {
    let parsedLine = parser.parseInput(line)
    
    XCTAssertTrue(parsedLine.count == 1, "parsedLine should have 1 item. had \(parsedLine.count)")
    
    let parsedPolygon = parser.parseInput(polygon)
    XCTAssertTrue(parsedPolygon.count == 1, "parsedLine should have 1 item. had \(parsedPolygon.count)")
    
    let parsedMultiPolygon = parser.parseInput(multiPolygon)
    XCTAssertTrue(parsedMultiPolygon.count == 2, "parsedMultiPolygon should have 2 items. had \(parsedLine.count)")
  }

  func testConvertStringArraysToTuples() {
    let formatted = [parser.stripExtraneousCharacters(polygon)].map({
      self.parser.formatStandardGeoDataString($0)
    })
    
    let converted = parser.convertStringArraysToTuples(formatted)
    
    let tuples = converted.first!
    
    XCTAssertEqual(tuples.first!.0, "30", "First item in the tuple should be 30, was \(tuples.first!.0)")
    XCTAssertEqual(tuples.first!.1, "10", "First item in the tuple should be 10, was \(tuples.first!.1)")
  }
  
  func testConvertToCoordinates() {
    let formatted = [parser.stripExtraneousCharacters(polygon)].map({
      self.parser.formatStandardGeoDataString($0)
    })
    
    let converted = parser.convertStringArraysToTuples(formatted)
    let coordinatesArray = converted.map({self.parser.convertToCoordinates($0, longitudeFirst: true)})
    
    if let coordinates = coordinatesArray.first {
      XCTAssertEqualWithAccuracy(coordinates.first!.latitude, 10.0, accuracy: 0.001, "latitude should be 10, was \(coordinates.first!.latitude)")
      XCTAssertEqualWithAccuracy(coordinates.first!.longitude, 30.0, accuracy: 0.001, "longitude should be 30, was \(coordinates.first!.longitude)")
    } else {
      XCTFail("Unable to take first from coordinatesArray")
    }
  }
  
  func testPerformanceOfParsing() {
    self.measureBlock() {
      let result = self.parser.parseInput(multiPolygon)
    }
  }
  
  // MARK: - Setup
  override func setUp() {
    super.setUp()
    self.parser = Parser()
  }
}
