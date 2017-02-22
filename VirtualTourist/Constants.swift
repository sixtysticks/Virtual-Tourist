//
//  Constants.swift
//  VirtualTourist
//
//  Created by David Gibbs on 21/02/2017.
//  Copyright © 2017 SixtySticks. All rights reserved.
//

import Foundation

struct Constants {
    
    // MARK: FLICKR
    
    struct FlickrAPI {
        static let Scheme = "https"
        static let Host = "api.flickr.com"
        static let Path = "/services/rest"
    }
    
    struct FlickrParameterKeys {
        static let Method = "method"
        static let APIKey = "api_key"
        static let Latitude = "lat"
        static let Longitude = "lon"
        static let Extras = "extras"
        static let Format = "format"
        static let NoJSONCallback = "nojsoncallback"
    }
    
    struct FlickrParameterValues {
        static let SearchMethod = "flickr.photos.search"
        static let APIKey = "32dedc40b9bf05c76ae2386445340108"
        static let MediumURL = "url_m"
        static let ResponseFormat = "json"
        static let DisableJSONCallback = "1"
    }
    
    // https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=8c14785ef917106b03f2f26449e0511e&lat=48.856614&lon=2.352222&extras=url_m&format=json&nojsoncallback=1
    

    
}
