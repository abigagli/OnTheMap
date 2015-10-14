//
//  UdacityAPIClient.swift
//  OnTheMap
//
//  Created by Andrea Bigagli on 10/7/15.
//  Copyright (c) 2015 Andrea Bigagli. All rights reserved.
//

import Foundation


class UdacityAPIClient {
    
    struct UdacityUser {
        //Implicitly unwrapped optionals, as we wouldn't progress to the point where
        //they'll be used if we can't get them...
        var uniqueKey: String! = ""
        var firstName: String! = ""
        var lastName: String! = ""
        
        var fullName: String {
            return (!firstName.isEmpty ? firstName : "") + " " + (!lastName.isEmpty ? lastName! : "")
        }
    }
    
    //Singleton, leveraging swift 1.2 static let
    static let sharedInstance = UdacityAPIClient()
    
    //MARK: State
    var user = UdacityUser()
    
    
    func authenticate(username: String, password: String, completionHandler: (success: Bool, errorString: String?) -> Void) {
        
        if !Utils.isConnectedToNetwork() {
            
            completionHandler (success: false, errorString: "Network is not available")
            return
        }

        let request = NSMutableURLRequest(URL: NSURL(string: Constants.BaseURL + Methods.Session)!)
        request.HTTPMethod = "POST"
        request.addValue(Constants.JSONType, forHTTPHeaderField: "Accept")
        request.addValue(Constants.JSONType, forHTTPHeaderField: "Content-Type")
        
        
        let jsonBody : [String : [String : AnyObject]] = [
            "udacity" : [
                "username" : "\(username)",
                "password" : "\(password)"
            ]
        ]
        
        var jsonifyError: NSError? = nil
        do {
            request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(jsonBody, options: [])
        } catch var error as NSError {
            jsonifyError = error
            request.HTTPBody = nil
        }
        
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request) { data, response, error in
            if error != nil { //API INVOCATION FAILURE
                completionHandler(success: false, errorString: UdacityAPIClient.apiFailedMessage (Methods.Session, error.description))
            } else {
                let dataSubset = data.subdataWithRange(NSMakeRange(5, data.length - 5)) /* Skip first 5 chars of response */
            
                Utils.jsonizeData(dataSubset, andPassTo: { (result, error) -> Void in
                    
                    if error == nil { //JSON parsing OK
                        if let errorString = result["error"] as? String { //Error in login procedure
                            completionHandler(success: false, errorString: errorString)
                        }
                        else { //Login successful
                            
                            //Extract the uniqueKey
                            let accountDetails = result["account"] as! NSDictionary
                            self.user.uniqueKey = accountDetails["key"] as? String
                            
                            //Chain invocation of another API method with same completion handler
                            self.getPublicUserData(completionHandler)
                        }
                    } else { //JSON parsing FAILED
                        completionHandler(success: false, errorString: "Failed parsing " + Methods.Session + " response: " + error!.description)
                    }
                })
            }
        }
        task.resume()
    
    }
    
    //CodeReview: Implemented proper logout invocation
    func logoutUser(completionHandler: (success: Bool, errorString: String?) -> Void) {
        
        if !Utils.isConnectedToNetwork() {
            completionHandler (success: false, errorString: "Network is not available")
            return
        }
        
        let request = NSMutableURLRequest(URL: NSURL(string: Constants.BaseURL + Methods.Session)!)
        request.HTTPMethod = "DELETE"
        
        var xsrfCookie: NSHTTPCookie? = nil
        let sharedCookieStorage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
        for cookie in sharedCookieStorage.cookies as! [NSHTTPCookie] {
            if cookie.name == "XSRF-TOKEN" { xsrfCookie = cookie }
        }
        if let xsrfCookie = xsrfCookie {
            request.setValue(xsrfCookie.value, forHTTPHeaderField: "X-XSRF-TOKEN")
        }
        
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request) { data, response, error in
            if error != nil { //API INVOCATION FAILURE
                completionHandler(success: false, errorString: UdacityAPIClient.apiFailedMessage (Methods.Session, error.description))
            } else {
                let dataSubset = data.subdataWithRange(NSMakeRange(5, data.length - 5)) /* Skip first 5 chars of response */
                
                Utils.jsonizeData(dataSubset, andPassTo: { (result, error) -> Void in
                    if error == nil { //JSON parsing OK
                        //Callback into the completion handler for a successful logout
                        completionHandler(success: true, errorString: nil)
                    }
                    else { //JSON parsing FAILED
                        completionHandler(success: false, errorString: "Failed parsing " + Methods.Session + " response: " + error!.description)
                    }
                })
            }
        }
        task.resume()
        
    }
    
    func getPublicUserData(completionHandler: (success: Bool, errorString: String?) -> Void) {
        if !Utils.isConnectedToNetwork() {
            
            completionHandler (success: false, errorString: "Network is not available")
            return
        }
        
        let request = NSMutableURLRequest(URL: NSURL(string: Constants.BaseURL + Methods.Users + user.uniqueKey)!)
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request) { data, response, error in
            if error != nil { //API INVOCATION FAILURE
                completionHandler(success: false, errorString: UdacityAPIClient.apiFailedMessage (Methods.Users, error.description))
            }
            else {
                let dataSubset = data.subdataWithRange(NSMakeRange(5, data.length - 5)) /* Skip first 5 chars of response */
                
                Utils.jsonizeData(dataSubset, andPassTo: { (result, error) -> Void in
                    if error == nil { //JSON parsing OK
                        //Grab account details to extract first and last name
                        let userDetails = result["user"] as! NSDictionary
                        self.user.firstName = userDetails["first_name"] as? String
                        self.user.lastName = userDetails["last_name"] as? String
                        
                        //Finally callback into the completion handler for a successful login
                        completionHandler(success: true, errorString: nil)
                    }
                    else { //JSON parsing FAILED
                        completionHandler(success: false, errorString: "Failed parsing " + Methods.Users + " response: " + error!.description)
                    }
                })
            }
        }
        task.resume()
    }
    
}

extension UdacityAPIClient{

    //MARK: Constants
    struct Constants {
        static let BaseURL : String = "https://www.udacity.com/api/"
        static let SignInURL : String = "https://www.udacity.com/account/auth#!/signin"
        static let JSONType : String = "application/json"
    }
    
    //MARK: Methods
    struct Methods{
        static let Session: String = "session"
        static let Users: String = "users/"
    }

    class func apiFailedMessage (api: String, _ details: String?) -> String{
        return "Error connecting to Udacity \"\(api)\" API" + ((details != nil) ? (": " + details!) : "")
    }

}
