//
//  ViewController.swift
//  VirtualTourist
//
//  Created by David Gibbs on 16/02/2017.
//  Copyright © 2017 SixtySticks. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsViewController: UIViewController, MKMapViewDelegate {
    
    // MARK: Variables/Constants
    
    let delegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    var longPressGestureRecognizer: UILongPressGestureRecognizer?
    
    // MARK: Outlets
    
    @IBOutlet weak var mapView: MKMapView!
    
    // MARK: Lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadPins()
        
        // Add gesture recognizer to map
        
        longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(TravelLocationsViewController.handleLongPressGesture(gesture:)))
        longPressGestureRecognizer?.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPressGestureRecognizer!)
    }
    
    // MARK: Private methods
    
    func handleLongPressGesture(gesture: UIGestureRecognizer) {
        if gesture.state == UIGestureRecognizerState.began {
            
            let annotation = MKPointAnnotation()
            let point: CGPoint = gesture.location(in: mapView)
            let coord: CLLocationCoordinate2D = mapView.convert(point, toCoordinateFrom: mapView)
            annotation.coordinate = coord
            mapView.addAnnotation(annotation)
            
            let pin = Pin(context: delegate.persistentContainer.viewContext)
            pin.latitude = coord.latitude
            pin.longitude = coord.longitude
            
            delegate.saveContext()
            
        }
    }
    
    func loadPins() {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")

        do {
            let savedPins = try delegate.persistentContainer.viewContext.fetch(request)
            
            for pin in savedPins as [AnyObject] {
                let annotation = MKPointAnnotation()
                let coord = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
                annotation.coordinate = coord
                mapView.addAnnotation(annotation)
            }
            
        } catch  {
           fatalError("Error in loadPins method")
        }
    }
    
    // MARK: Delegate methods
    
    // Animate the dropping of the pin
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
        annotationView.animatesDrop = true
        return annotationView
    }
    
    // MARK: Extensions
    
}

