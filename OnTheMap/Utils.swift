//
//  Utils.swift
//  OnTheMap
//
//  Created by Andrea Bigagli on 10/7/15.
//  Copyright (c) 2015 Andrea Bigagli. All rights reserved.
//

import UIKit

class Utils {
    class func jsonizeData(data: NSData, andPassTo completionHandler: (result: AnyObject!, error: NSError?) -> Void) {
        
        var parsingError: NSError? = nil
        
        let parsedResult: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError)
        
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
        
        return (!urlVars.isEmpty ? "?" : "") + join("&", urlVars)
    }
    
    class func alert(#fromVC: UIViewController, withTitle title: String, message: String, completionHandler: ((UIAlertAction!) -> Void)?) -> UIAlertController {
        var alertVC = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        
        alertVC.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: completionHandler))
        
        fromVC.presentViewController(alertVC, animated: true, completion: nil)
        
        return alertVC
    }
 
}
