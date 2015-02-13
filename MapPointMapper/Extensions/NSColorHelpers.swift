//
//  NSColorHelpers.swift
//  MapPointMapper
//
//  Created by Lucas Charles on 2/13/15.
//  Copyright (c) 2015 dmiedema. All rights reserved.
//

import Foundation
import AppKit

extension NSColor {
    class func randomColor() -> NSColor {
        let red = CGFloat(arc4random() % 255) / 255
        let green = CGFloat(arc4random() % 255) / 255
        let blue = CGFloat(arc4random() % 255) / 255

        return NSColor(red: red, green: green, blue: blue, alpha: 1.0)
    }
}