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

class PhotoAlbumViewController: UIViewController, NSFetchedResultsControllerDelegate {
    
    // MARK: CONSTANTS/VARIABLES
    
    let stack = CoreDataStack.sharedInstance()
    
    let cellIdentifier = "PhotoCell"
    
    var annotationView = MKAnnotationView()
    var annotationLatitude: Double = 0.0
    var annotationLongitude: Double = 0.0
    var pin: Pin!
    
    lazy var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>? = {
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        fr.sortDescriptors = [NSSortDescriptor(key: "url", ascending: true)]
        fr.predicate = NSPredicate(format: "pin == %@", self.pin)
        
        return NSFetchedResultsController(fetchRequest: fr, managedObjectContext: self.stack.context, sectionNameKeyPath: nil,cacheName: nil)
    }()
    
    // MARK: OUTLETS
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    
    // MARK: LIFECYCLE METHODS
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchedResultsController?.delegate = self
        
        displayPinOnMap()
        
        collectionView!.register(UINib(nibName: "PhotoCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: cellIdentifier)
        
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            fatalError("Error in 'viewDidLoad' method")
        }
        
        if pin.photos?.count == 0 {
            downloadPhotosFromFlickr()
        } else {
            try? self.fetchedResultsController?.performFetch()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        
        do {
            try stack.saveContext()
        } catch {
            fatalError("Context cannot be saved")
        }
    }
    
    // MARK: CUSTOM METHODS
    
    @IBAction func newCollectionButtonPressed(_ sender: UIBarButtonItem) {
        
        // Get the results form the next page of images for pin
        self.pin.page = self.pin.page + 1
        
        for photo in (self.fetchedResultsController?.fetchedObjects)! {
            self.stack.context.delete(photo as! NSManagedObject)
        }
        
        do {
            try self.stack.saveContext()
        } catch {
            fatalError("Context cannot be saved")
        }
        
        downloadPhotosFromFlickr()
        
        try? self.fetchedResultsController?.performFetch()
        
        DispatchQueue.main.async {
            self.collectionView?.reloadData()
        }
        
    }
    
    func downloadPhotosFromFlickr() {
        
        newCollectionButton.isEnabled = false
        
        // Set parameters for requested Flickr API
        
        let params: [String: AnyObject] = [
            Constants.FlickrParameterKeys.Method            :   Constants.FlickrParameterValues.SearchMethod as AnyObject,
            Constants.FlickrParameterKeys.APIKey            :   Constants.FlickrParameterValues.APIKey as AnyObject,
            Constants.FlickrParameterKeys.Latitude          :   annotationLatitude as AnyObject,
            Constants.FlickrParameterKeys.Longitude         :   annotationLongitude as AnyObject,
            Constants.FlickrParameterKeys.Page              :   self.pin.page as AnyObject,
            Constants.FlickrParameterKeys.PerPage           :   Constants.FlickrParameterValues.ResultsReturned as AnyObject,
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
                    
                    guard let _ = photo["url_m"] as? String, let _ = photo["id"] as? String else {
                        FlickrClient.sharedInstance().displayError("Error trying to find the photo url and/or id")
                        return
                    }
                    
                    let _ = Photo(context: self.stack.context, pin: self.pin, dict: photo as! [String:AnyObject])
                }
                
                try? self.fetchedResultsController?.performFetch()
                
                
                DispatchQueue.main.async {
                    self.collectionView?.reloadData()
                    self.newCollectionButton.isEnabled =  true
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
    
}

// MARK: EXTENSIONS DELEGATE METHODS

extension PhotoAlbumViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let space: CGFloat = 3.0
        let dimension: CGFloat = (self.view.frame.size.width - (2 * space)) / space
        
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        
        return CGSize(width: dimension, height: dimension)
    }
    
}

extension PhotoAlbumViewController: UICollectionViewDelegate , UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if let frc = fetchedResultsController {
            return (frc.sections?.count)!
        } else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let frc = fetchedResultsController {
            return frc.sections![section].numberOfObjects
        } else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let photo = self.fetchedResultsController?.object(at: indexPath) as! Photo
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.cellIdentifier, for: indexPath) as! PhotoCollectionViewCell
        
        if photo.image != nil {
            cell.imageView.image = photo.image
        } else {
            let photoUrl = URL(string: photo.url!)
            let photoImage = try? UIImage(data: Data(contentsOf: photoUrl!))
            FlickrClient.Cache.imageCache.storeImage(photoImage!, withIdentifier: photo.id!)
            cell.imageView.image = FlickrClient.Cache.imageCache.imageWithIdentifier(photo.id)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let photo = fetchedResultsController?.object(at: indexPath) as! Photo
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! PhotoCollectionViewCell
        
        stack.context.delete(photo as NSManagedObject)
        
        do {
            try stack.saveContext()
        } catch {
            fatalError("Context cannot be saved")
        }
        
        cell.imageView.image = nil
        
        try? self.fetchedResultsController?.performFetch()
        
        DispatchQueue.main.async {
            self.collectionView?.reloadData()
        }
        
    }
    
}


