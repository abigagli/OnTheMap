//
//  Utils.swift
//  OnTheMap
//
//  Created by Andrea Bigagli on 10/7/15.
//  Copyright (c) 2015 Andrea Bigagli. All rights reserved.
//

import UIKit
import SystemConfiguration

class Utils {
    class func jsonizeData(data: NSData, andPassTo completionHandler: (result: AnyObject!, error: NSError?) -> Void) {
        
        var parsingError: NSError? = nil
        
        let parsedResult: AnyObject?
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
        } catch let error as NSError {
            parsingError = error
            parsedResult = nil
        }
        
        if parsingError != nil {
            completionHandler(result: nil, error: parsingError)
        } else {
            completionHandler(result: parsedResult, error: nil)
        }
    }
    
    
    class func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            let stringOfValue = "\(value)"
            let escapedValue = stringOfValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            urlVars += [key + "=" + "\(escapedValue!)"]
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
    
    class func alert(fromVC fromVC: UIViewController, withTitle title: String, message: String, completionHandler: ((UIAlertAction!) -> Void)?) -> UIAlertController {
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        
        alertVC.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: completionHandler))
        
        fromVC.presentViewController(alertVC, animated: true, completion: nil)
        
        return alertVC
    }
 
    //CodeReview: add check for network connectivity.
    //Found this approach, which seems to work fine, on on SO: http://stackoverflow.com/questions/25623272/how-to-use-scnetworkreachability-in-swift/25623647#25623647
    class func isConnectedToNetwork() -> Bool {
        
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(&zeroAddress, {
            SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0))
        }) else {
            return false
        }
        
        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return false
        }
        
        let isReachable = flags.contains(.Reachable)
        let needsConnection = flags.contains(.ConnectionRequired)
        
        return isReachable && !needsConnection
    }
}
