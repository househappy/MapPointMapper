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
    // MARK: Views
    @IBOutlet weak var mapview: MKMapView!
    @IBOutlet weak var textfield: NSTextField!
    
    // MARK: - Methods
    // MARK: View life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
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
    // MARK: MKMapDelegate
    func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.alpha = 1.0
        renderer.lineWidth = 4.0
        renderer.strokeColor = NSColor(red:59.0/255.0, green:173.0/255.0, blue:253.0/255.0, alpha:1)
        
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
        let stripped = input.stringByReplacingOccurrencesOfString(" ", withString: "", options: .CaseInsensitiveSearch, range: nil).stringByReplacingOccurrencesOfString("\n", withString: ",", options: .CaseInsensitiveSearch, range: nil)
        
        let components = stripped.componentsSeparatedByString(",")
        
        if components.count % 2 != 0 {
            let error = NSError(domain: "com.dmiedema.MapPointMapper", code: -101, userInfo: [NSLocalizedDescriptionKey: "Invalid number of map points given"])
            NSAlert(error: error)
            return
        }
        
        var mapPoints = [CLLocationCoordinate2D]()
        for var i = 0; i < components.count; i += 2 {
            let one = components[i] as NSString
            let two = components[i + 1] as NSString
            
            let lat = one.doubleValue
            let lng = two.doubleValue
            
            mapPoints.append(CLLocationCoordinate2D(latitude: lat, longitude: lng))
        }
        
        drawPointsOnMap(mapPoints)
    }
}

