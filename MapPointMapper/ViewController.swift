//
//  ViewController.swift
//  MapPointMapper
//
//  Created by Daniel on 11/18/14.
//  Copyright (c) 2014 dmiedema. All rights reserved.
//

import Cocoa
import MapKit

class ViewController: NSViewController, MKMapViewDelegate, NSTextFieldDelegate {
    // MARK: - Properties
    // MARK: Buttons
    @IBOutlet weak var loadFileButton: NSButton!
    @IBOutlet weak var removeLastLineButton: NSButton!
    @IBOutlet weak var removeAllLinesButton: NSButton!
    @IBOutlet weak var addLineFromTextButton: NSButton!
    @IBOutlet weak var switchLatLngButton: NSButton!
    @IBOutlet weak var colorWell: NSColorWell!
    // MARK: Views
    @IBOutlet weak var mapview: MKMapView!
    @IBOutlet weak var textfield: NSTextField!
    @IBOutlet weak var latlngLabel: NSTextField!
    
    var parseLatitudeFirst = true
    // MARK: - Methods
    // MARK: View life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        mapview.delegate = self
        textfield.delegate = self
    }

    // MARK: Actions
    @IBAction func loadFileButtonPressed(sender: NSButton!) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = false
        
        openPanel.beginSheetModalForWindow(NSApplication.sharedApplication().keyWindow!, completionHandler: { (result) -> Void in
            self.readFileAtURL(openPanel.URL)
        })
    }
    
    @IBAction func addLineFromTextPressed(sender: NSButton) {
        if textfield.stringValue.isEmpty {
            return
        }
        parseInput(textfield.stringValue)
    }
    
    @IBAction func removeLastLinePressed(sender: NSButton) {
        if let overlay: AnyObject = mapview.overlays.last {
            mapview.removeOverlay(overlay as MKOverlay)
        }
    }
    @IBAction func removeAllLinesPressed(sender: NSButton) {
        mapview.removeOverlays(mapview.overlays)
    }
    @IBAction func switchLatLngPressed(sender: NSButton) {
        parseLatitudeFirst = !parseLatitudeFirst
        if self.parseLatitudeFirst {
            self.latlngLabel.stringValue = "Lat/Lng"
        } else {
            self.latlngLabel.stringValue = "Lng/Lat"
        }
    }
    
    // MARK: MKMapDelegate
    func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.alpha = 1.0
        renderer.lineWidth = 4.0
        renderer.strokeColor = colorWell.color
        return renderer
    }
    // MARK: NSTextFieldDelegate
    override func keyUp(theEvent: NSEvent) {
        if theEvent.keyCode == 36 { // 36 is the return key apparently
            addLineFromTextPressed(self.addLineFromTextButton)
        }
    }
    
    // MARK: - Private
    private func drawPointsOnMap(mapPoints: [CLLocationCoordinate2D]) {
        let coordinates = UnsafeMutablePointer<CLLocationCoordinate2D>.alloc(mapPoints.count)
        
        var count: Int = 0
        for coordinate in mapPoints {
            coordinates[count] = coordinate
            ++count
        }
        
        let polyline = MKPolyline(coordinates: coordinates, count: count)
        
        mapview.addOverlay(polyline, level: .AboveRoads)
        mapview.setVisibleMapRect(polyline.boundingMapRect, animated: true)
        
        free(coordinates)
    }
    
    private func readFileAtURL(passedURL: NSURL?) {
        if let url = passedURL {
            if !NSFileManager.defaultManager().isReadableFileAtPath(url.absoluteString!) {
                NSAlert(error: NSError(domain: "com.dmiedema.MapPointMapper", code: -42, userInfo: [NSLocalizedDescriptionKey: "File is unreadable at \(url.absoluteString)"]))
            }
            
            var error: NSError?
            let contents = NSString(contentsOfURL: url, encoding: NSUTF8StringEncoding, error: &error)
            
            if let err = error {
                NSAlert(error: err)
                return
            }
            
            parseInput(contents!)
        }
    } // end readFileAtURL
    
    private func parseInput(input: String) {
        
        let mapPoints = Parser.parseString(input)
        drawPointsOnMap(mapPoints)
    }
}

