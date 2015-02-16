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
        // Change bias based on http://martin.ankerl.com/2009/12/09/how-to-create-random-colors-programmatically/
        let golden_ratio_conjugate: Double = 0.618033988749895
        var hue = Double(arc4random() % 255) / 255
        hue += golden_ratio_conjugate
        hue %= 1

        return NSColor(hue: CGFloat(hue), saturation: 0.5, brightness: 0.95, alpha: 1.0)
    }
}