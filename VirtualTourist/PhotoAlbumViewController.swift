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

class PhotoAlbumViewController: UIViewController {
    
    // MARK: CONSTANTS/VARIABLES
    
    let stack = CoreDataStack.sharedInstance()
    
    var annotationView = MKAnnotationView()
    var annotationLatitude: Double = 0.0
    var annotationLongitude: Double = 0.0
    var pin = Pin(context: CoreDataStack.sharedInstance().context)
    
    
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStack.sharedInstance().context
    }()
    
    lazy var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>? = {
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        fr.sortDescriptors = [NSSortDescriptor(key: "url", ascending: true)]
        fr.predicate = NSPredicate(format: "pin == %@", self.pin)
        
        return NSFetchedResultsController(fetchRequest: fr, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil,cacheName: nil)
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
        
        newCollectionButton.isEnabled = false
        
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            fatalError("Error in 'viewDidLoad' method")
        }
        
        // TODO: Check this photos object...
        if pin.photos?.count == 0 {
            downloadPhotosFromFlickr()
        }
    }
    
    // MARK: CUSTOM METHODS
    
    @IBAction func newCollectionButtonPressed(_ sender: UIBarButtonItem) {
        // TODO: Add new collection functionality
    }
    
    func downloadPhotosFromFlickr() {
        
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
                
                DispatchQueue.main.async {
                    for photo in photoArray as! [AnyObject] {
                        if let url = photo["url_m"] as? String {
                            let photoEntity = Photo(context: self.sharedContext, pin: self.pin)
                            photoEntity.hasDownloaded = false
                            photoEntity.url = url
                        }
                    }
                    
                    do {
                        try self.stack.saveContext()
                    } catch {
                        fatalError("Error in 'getPhotosFromFlickr' method")
                    }
                    
                    try? self.fetchedResultsController?.performFetch()
                    self.collectionView?.reloadData()
                    
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
            print("NUMBER OF SECTIONS: \((frc.sections?.count)!)")
            return (frc.sections?.count)!
        } else {
            return 0
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let frc = fetchedResultsController {
            print("NUMBER OF ITEMS: \(frc.sections![section].numberOfObjects)")
            return frc.sections![section].numberOfObjects
        } else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let photo = fetchedResultsController?.object(at: indexPath) as! Photo
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath)
        
//        if !photo.hasDownloaded {
            let photoUrl = URL(string: photo.url!)
            let photoImage = try? UIImage(data: Data(contentsOf: photoUrl!))
            let photoImageView = UIImageView(image: photoImage!)
            cell.backgroundColor = UIColor.red
            cell.contentView.addSubview(photoImageView)
            
            photo.hasDownloaded = true
//        }
//        
        return cell
    }
    
}

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    
}


