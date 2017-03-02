//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by David Gibbs on 16/02/2017.
//  Copyright © 2017 SixtySticks. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    // MARK: VARIABLES/CONSTANTS
    
    var annotationView = MKAnnotationView()
    var annotationLatitude: Double = 0.0
    var annotationLongitude: Double = 0.0
    var flickrPhotosArray = [String]()
    var pin = Pin()
    
    var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>? {
        didSet {
            fetchedResultsController?.delegate = self.fetchedResultsController as! NSFetchedResultsControllerDelegate?
            collectionView?.reloadData()
        }
    }
    
    // MARK: OUTLETS
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    // MARK: LIFECYCLE METHODS
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        displayPinOnMap()
        
        downloadPhotosFromflickr()
        
    }
    
    // MARK: CUSTOM METHODS
    
    func downloadPhotosFromflickr() {
        
        // Set parameters for requested Flickr API
        
        let params: [String: AnyObject] = [
            Constants.FlickrParameterKeys.Method            :   Constants.FlickrParameterValues.SearchMethod as AnyObject,
            Constants.FlickrParameterKeys.APIKey            :   Constants.FlickrParameterValues.APIKey as AnyObject,
            Constants.FlickrParameterKeys.Latitude          :   annotationLatitude as AnyObject,
            Constants.FlickrParameterKeys.Longitude         :   annotationLongitude as AnyObject,
            Constants.FlickrParameterKeys.Extras            :   Constants.FlickrParameterValues.MediumURL as AnyObject,
            Constants.FlickrParameterKeys.Format            :   Constants.FlickrParameterValues.ResponseFormat as AnyObject,
            Constants.FlickrParameterKeys.NoJSONCallback    :   Constants.FlickrParameterValues.DisableJSONCallback as AnyObject
        ]
        
        // Call Flickr API
        
        FlickrClient.sharedInstance().getPhotosFromFlickr(params: params) { (result, success, error) in
            if success {
                
                // GUARD: Did Flickr return a status error?
                
                guard let stat = result?["stat"] as? String, stat == Constants.FlickrResponseValues.OKStatus else {
                    FlickrClient.sharedInstance().displayError("Flickr API returned an error. See error code and message in \(result)")
                    print("ERROR IN GUARD FOR STAT")
                    return
                }
                
                // GUARD: Check there are 'photos' and 'photo' keys
                
                guard let photos = result?["photos"] as? [String:Any], let photoArray = photos["photo"] else {
                    FlickrClient.sharedInstance().displayError("Could not find the \(Constants.FlickrResponseKeys.Photo) or \(Constants.FlickrResponseKeys.Photos) keys.")
                    print("ERROR IN GUARD FOR PHOTOS")
                    return
                }
                
                
                for photo in photoArray as! [AnyObject] {
                    if let url = photo["url_m"] {
                        self.flickrPhotosArray.append(url! as! String)
                    }
                }
            }
        }
    }
    
    func displayPinOnMap() {
        
        let annotation = annotationView.annotation
        let latitude = annotation?.coordinate.latitude
        let longitude = annotation?.coordinate.longitude
        
        let center = CLLocationCoordinate2DMake(latitude! as CLLocationDegrees, longitude! as CLLocationDegrees)
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        let region = MKCoordinateRegionMake(center, span)
        mapView.region = region
        
        mapView.addAnnotation(annotation!)
        mapView.setRegion(region, animated: false)
        mapView.regionThatFits(region)
        
        // Grab lat and long values for Flickr API call
        annotationLatitude = latitude!
        annotationLongitude = longitude!
        
    }
    
    
    // MARK: DELEGATE METHODS
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 24
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
//        let photo = fetchedResultsController?.object(at: indexPath) as! Photo
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let space: CGFloat = 3.0
        let dimension: CGFloat = (self.view.frame.size.width - (2 * space)) / space
        
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        return CGSize(width: dimension, height: dimension)
    }
    
}



