//
//  TravelLocationsViewController.swift
//  VirtualTourist
//
//  Created by David Gibbs on 16/02/2017.
//  Copyright © 2017 SixtySticks. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    // MARK: VARIABLES/CONSTANTS
    
    let defaults = UserDefaults.standard
    let stack = CoreDataStack.sharedInstance()
    
    var longPressGestureRecognizer: UILongPressGestureRecognizer?
    
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStack.sharedInstance().context
    }()
    
    lazy var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>? = {
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        fr.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        return NSFetchedResultsController(fetchRequest: fr, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil,cacheName: nil)
    }()
    
    // MARK: OUTLETS
    
    @IBOutlet weak var mapView: MKMapView!
    
    // MARK: LIFECYCLE METHODS
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchedResultsController?.delegate = self
        
        // Position the map's region how it was left in last session, or create User defaults to save for next time
        
        if let currentLatitude = defaults.value(forKey: "currentLatitude"), let currentLongitude = defaults.value(forKey: "currentLongitude"),
           let latitudeDelta = defaults.value(forKey: "latitudeDelta"), let longitudeDelta = defaults.value(forKey: "longitudeDelta") {

            let center = CLLocationCoordinate2DMake(currentLatitude as! CLLocationDegrees, currentLongitude as! CLLocationDegrees)
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta as! CLLocationDegrees, longitudeDelta: longitudeDelta as! CLLocationDegrees)
            let region = MKCoordinateRegionMake(center, span)
            
            mapView.region = region
            
        } else {
            defaults.set(mapView.region.center.latitude, forKey: "currentLatitude")
            defaults.set(mapView.region.center.longitude, forKey: "currentLongitude")
            defaults.set(mapView.region.span.latitudeDelta, forKey: "latitudeDelta")
            defaults.set(mapView.region.span.longitudeDelta, forKey: "longitudeDelta")
        }
        
        // Load all the saved pins
        
        loadPins()
        
        // Add gesture recognizer to map
        
        longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(TravelLocationsViewController.handleLongPressGesture(gesture:)))
        longPressGestureRecognizer?.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPressGestureRecognizer!)
    }
    
    
    // MARK: CUSTOM METHODS
    
    func handleLongPressGesture(gesture: UIGestureRecognizer) {
        if gesture.state == UIGestureRecognizerState.began {
            
            let annotation = MKPointAnnotation()
            let point: CGPoint = gesture.location(in: mapView)
            let coord: CLLocationCoordinate2D = mapView.convert(point, toCoordinateFrom: mapView)
            annotation.coordinate = coord
            mapView.addAnnotation(annotation)
            
            let pin = Pin(context: self.sharedContext)
            pin.latitude = coord.latitude
            pin.longitude = coord.longitude

            do {
                try stack.saveContext()
            } catch {
                fatalError("Error in 'handleLongPressGesture' method")
            }
        }
    }
    
    func loadPins() {
        do {
            try fetchedResultsController?.performFetch()
        } catch  {
           fatalError("Error in 'loadPins' method")
        }
        
        let savedPins = fetchedResultsController?.fetchedObjects
        
        for pin in (savedPins as? [Pin])! {
            let annotation = MKPointAnnotation()
            let coord = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
            annotation.coordinate = coord
            mapView.addAnnotation(annotation)
        }
        
    }
    
    // MARK: DELEGATE METHODS
    
    // Animate the dropping of the pin
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
        annotationView.animatesDrop = true
        return annotationView
    }
    
    // Save the users current view of the map in UserDefaults every time map is moved
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if let _ = defaults.value(forKey: "currentLatitude"), let _ = defaults.value(forKey: "currentLongitude"),
           let _ = defaults.value(forKey: "latitudeDelta"), let _ = defaults.value(forKey: "longitudeDelta"){
            
            defaults.set(mapView.region.center.latitude, forKey: "currentLatitude")
            defaults.set(mapView.region.center.longitude, forKey: "currentLongitude")
            defaults.set(mapView.region.span.latitudeDelta, forKey: "latitudeDelta")
            defaults.set(mapView.region.span.longitudeDelta, forKey: "longitudeDelta")
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        let photoAlbumVC = self.storyboard?.instantiateViewController(withIdentifier: "photoAlbumVC") as! PhotoAlbumViewController
        
        // Send tapped annotation data to Photo View Controller
        photoAlbumVC.annotationView = view
        
        // Change text for back link in Photo View Controller navigation
        let backButton = UIBarButtonItem()
        backButton.title = "Back"
        navigationItem.backBarButtonItem = backButton
        
        self.navigationController?.pushViewController(photoAlbumVC, animated: true)
    }
    
}

