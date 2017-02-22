//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by David Gibbs on 21/02/2017.
//  Copyright © 2017 SixtySticks. All rights reserved.
//

import Foundation

class FlickrClient {
    
    // MARK: SHARED INSTANCE
    
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }
    
    // MARK: GET PHOTOS FROM FLICKR
    
    func getPhotosFromFlickr(params: [String: AnyObject], completionHandlerForGetPhotos: @escaping (_ result: [String: AnyObject]?, _ success: Bool, _ error: String?) -> Void) {
        
        let session = URLSession.shared
        let request = URLRequest(url: buildFlickrURLFromParams(params))
        
        let task = session.dataTask(with: request) { (data, response, error) in
            
            // GUARD: Was there an error?
            guard (error == nil) else {
                self.displayError("There was an error with your request!")
                completionHandlerForGetPhotos(nil, false, error as! String?)
                return
            }
            
            // GUARD: Did we get a successful 2XX response?
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                self.displayError("We did not get a successful 2XX response!")
                completionHandlerForGetPhotos(nil, false, error as! String?)
                return
            }
            
            // GUARD: Was there a successful request?
            guard (data != nil) else {
                self.displayError("There was no data returned!")
                completionHandlerForGetPhotos(nil, false, error as! String?)
                return
            }
            
            self.parseJSON(data!, completionHandlerForJSON: completionHandlerForGetPhotos)
        
        }
        
        task.resume()
        
        
    }
    
    // MARK: PARSE JSON DATA
    
    private func parseJSON(_ data: Data, completionHandlerForJSON: (_ result: [String: AnyObject]?, _ success: Bool, _ error: String?) -> Void) {
        
        let parsedResult: AnyObject!
        
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject!
        } catch {
            completionHandlerForJSON(nil, false, error as? String)
            return
        }
        completionHandlerForJSON(parsedResult as? [String:AnyObject], true, nil)
    }
    
    // MARK: BUILD FLICKR URL
    
    private func buildFlickrURLFromParams(_ params: [String: AnyObject]) -> URL {
        
        var components = URLComponents()
        components.scheme = Constants.FlickrAPI.Scheme
        components.host = Constants.FlickrAPI.Host
        components.path = Constants.FlickrAPI.Path
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in params {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
    
    // MARK: ERROR MESSAGE FUNCTION
    
    func displayError(_ error: String) {
        print("ERROR: \(error)")
    }
    
}
