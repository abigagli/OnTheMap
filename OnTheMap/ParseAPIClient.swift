//
//  ParseAPIClient.swift
//  OnTheMap
//
//  Created by Andrea Bigagli on 10/7/15.
//  Copyright (c) 2015 Andrea Bigagli. All rights reserved.
//

import Foundation
import CoreLocation

class ParseAPIClient {
    
    //Singleton, leveraging swift 1.2 static let
    static let sharedInstance = ParseAPIClient()
    
    //MARK: State
    var objectID: String! //Implicitly unwrapped optional, as we get to the place where we need it only afer having successfully retrieved it
    
    var students = [StudentInformation]()
    var lastStudentsUpdate: NSTimeInterval = 0
    
    func reloadStudentsInformation(limit: Int = 100, completionHandler: (success: Bool, errorString: String?) -> Void) {
        
        if !Utils.isConnectedToNetwork() {
            
            completionHandler (success: false, errorString: "Network is not available")
            return
        }
        
        var tempStudents = [StudentInformation]()

        let methodParams = [
            "limit" : limit
        ]
        
        let task = taskForGETMethod (Methods.StudentLocation, parameters: methodParams) { data, response, error in
            
            if error != nil { //API INVOCATION FAILURE
                completionHandler(success: false, errorString: ParseAPIClient.apiFailedMessage(Methods.StudentLocation, error!.description))
            }
            else {
                Utils.jsonizeData(data!, andPassTo: { (result, error) -> Void in
                    if let results = result["results"] as? [AnyObject] {
                        for result in results {
                            let info = StudentInformation(dictionary: result as! NSDictionary)
                            tempStudents.append(info)
                        }
                        
                        //CodeReview: order by "updateAt" field so that list view will have most recents on top
                        self.students = tempStudents.sort{$0.updatedAt!.compare($1.updatedAt!) == NSComparisonResult.OrderedDescending}
                        
                        self.lastStudentsUpdate = NSDate().timeIntervalSince1970
                        completionHandler(success: true, errorString: nil)
                    }
                    else {
                        //We can get here both because jsonize failed itself, or because we can't get the results array out of the parsed json. In either case it means we couldn't obtain the data we were looking for...
                        completionHandler(success: false, errorString: "Failed retrieving last 100 students' locations")
                    }
                })
            }
        }
        task.resume()
    }
    
    
    func checkCurrentUserLocation(completionHandler: (success: Bool, locationAlreadySubmitted: Bool, errorString: String?) -> Void) {
        
        if !Utils.isConnectedToNetwork() {
            
            completionHandler (success: false, locationAlreadySubmitted: false, errorString: "Network is not available")
            return
        }

        let methodParams = [
            "where" : "{\"uniqueKey\":\"\(UdacityAPIClient.sharedInstance.user.uniqueKey)\"}"
        ]

        let task = taskForGETMethod (Methods.StudentLocation, parameters: methodParams) { data, response, error in

            if error != nil { //API INVOCATION FAILURE
                completionHandler(success: false, locationAlreadySubmitted: false, errorString: ParseAPIClient.apiFailedMessage(Methods.StudentLocation, error!.description))
            }
            else {
                Utils.jsonizeData(data!, andPassTo: { (result, error) -> Void in
                    if error == nil { //JSON Parsing OK
                        if let
                            results = result["results"] as? [[String : AnyObject]],
                            objectID = results[0]["objectId"] as? String { //Current user has already posted a location
                                
                                self.objectID = objectID
                                completionHandler(success: true, locationAlreadySubmitted: true, errorString: nil)
                        }
                        else { //No previous location for current user
                            completionHandler(success: true, locationAlreadySubmitted: false, errorString: nil)
                        }
                    }
                    else { //JSON parsing FAILED
                        completionHandler(success: false, locationAlreadySubmitted: false, errorString: "Failed querying student location: " + error!.description)
                    }
                })
            }
        }
        task.resume()
    }

    func postStudentLocation(mapString: String, location: CLLocation, mediaURL: String, completionHandler: (success: Bool, errorString: String?) -> Void) {
        
        if !Utils.isConnectedToNetwork() {
            
            completionHandler (success: false, errorString: "Network is not available")
            return
        }

        var request = NSMutableURLRequest(URL: NSURL(string: Constants.BaseURL + Methods.StudentLocation)!)
        
        request.HTTPMethod = "POST"
        
        prepareRequestForPutAndPost (&request, withMapString: mapString, location: location, mediaURL: mediaURL)

        let session = NSURLSession.sharedSession()
        
        let task = session.dataTaskWithRequest(request) { data, response, error in
            
            if error != nil { //API INVOCATION FAILURE
                completionHandler(success: false, errorString: ParseAPIClient.apiFailedMessage(Methods.StudentLocation, error!.description))
            }
            else {
                Utils.jsonizeData(data!, andPassTo: { (result, error) -> Void in
                    if let
                        postResult = result as? [String : AnyObject],
                        successfulPost = postResult["createdAt"] as? String,
                        objectID = postResult["objectId"] as? String {
                            
                            self.objectID = objectID

                            print ("Posted location for \(self.objectID) at: \(successfulPost)")
                            
                            self.lastStudentsUpdate = NSDate().timeIntervalSince1970
                            completionHandler(success: true, errorString: nil)
                    }
                    else {
                        completionHandler(success: false, errorString: "Failed posting student location")
                    }
                })
            }
        }
        task.resume()
    }
    
    
    func updateStudentLocation(mapString: String, location: CLLocation, mediaURL: String, completionHandler: (success: Bool, errorString: String?) -> Void) {
        
        if !Utils.isConnectedToNetwork() {
            
            completionHandler (success: false, errorString: "Network is not available")
            return
        }

        var request = NSMutableURLRequest(URL: NSURL(string: Constants.BaseURL + Methods.StudentLocation + "/\(self.objectID)")!)
        
        request.HTTPMethod = "PUT"
        
        prepareRequestForPutAndPost (&request, withMapString: mapString, location: location, mediaURL: mediaURL)
        
        let session = NSURLSession.sharedSession()
        
        let task = session.dataTaskWithRequest(request) { data, response, error in
            
            if error != nil { //API INVOCATION FAILURE
                completionHandler(success: false, errorString: ParseAPIClient.apiFailedMessage(Methods.StudentLocation, error!.description))
            }
            else {
                Utils.jsonizeData(data!, andPassTo: { (result, error) -> Void in
                    if let
                        putResult = result as? [String : AnyObject],
                        successfulUpdate = putResult["updatedAt"] as? String {
                            
                            print ("Updated location at: \(successfulUpdate)")
                            
                            self.lastStudentsUpdate = NSDate().timeIntervalSince1970
                            completionHandler(success: true, errorString: nil)
                    }
                    else {
                        completionHandler(success: false, errorString: "Failed updating student location")
                    }
                })
            }
        }
        task.resume()
    }

    private func taskForGETMethod(method: String, parameters: [String : AnyObject], completionHandler: ((NSData?, NSURLResponse?, NSError?) -> Void)) -> NSURLSessionDataTask {

        let urlString = Constants.BaseURL + method + "?" + Utils.escapedParameters(parameters)
        let url = NSURL(string: urlString)!
        let request = NSMutableURLRequest(URL: url)

        request.addValue(Constants.ApplicationID, forHTTPHeaderField: "X-Parse-Application-Id")
        request.addValue(Constants.APIKey, forHTTPHeaderField: "X-Parse-REST-API-Key")

        let session = NSURLSession.sharedSession()

        let task = session.dataTaskWithRequest(request, completionHandler: completionHandler)

        return task
    }

    private func prepareRequestForPutAndPost (inout request: NSMutableURLRequest, withMapString mapString: String, location: CLLocation, mediaURL: String) {
        request.addValue(Constants.ApplicationID, forHTTPHeaderField: "X-Parse-Application-Id")
        request.addValue(Constants.APIKey, forHTTPHeaderField: "X-Parse-REST-API-Key")
        request.addValue(Constants.JsonContentType, forHTTPHeaderField: "Content-Type")
        
        let jsonBody : [String : AnyObject] = [
            "uniqueKey" : "\(UdacityAPIClient.sharedInstance.user.uniqueKey)",
            "firstName" : "\(UdacityAPIClient.sharedInstance.user.firstName)",
            "lastName" : "\(UdacityAPIClient.sharedInstance.user.lastName)",
            "mapString" : "\(mapString)",
            "mediaURL" : "\(mediaURL)",
            "latitude" : location.coordinate.latitude,
            "longitude" : location.coordinate.longitude
        ]
        
        do {
            request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(jsonBody, options: [])
        } catch {
            request.HTTPBody = nil
        }
    }
}

extension ParseAPIClient {
    
    //MARK: Constants
    struct Constants {
        
        static let ApplicationID = "QrX47CA9cyuGewLdsL7o5Eb8iug6Em8ye0dnAbIr"
        static let APIKey = "QuWThTdiRmTux3YaDseUSEpUKo7aBYM737yKd4gY"
        static let JsonContentType = "application/json"
        
        static let BaseURL = "https://api.parse.com/1/classes/"
        
    }
    
    //MARK: Methods
    struct Methods{
        static let StudentLocation = "StudentLocation"
    }
    
    class func apiFailedMessage (api: String, _ details: String?) -> String {
        return "Error connecting to Parse \"\(api)\" API" + ((details != nil) ? (": " + details!) : "")
    }
}
