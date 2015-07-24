//
//  PostLocationViewController.swift
//  OnTheMap
//
//  Created by Andrea Bigagli on 12/7/15.
//  Copyright (c) 2015 Andrea Bigagli. All rights reserved.
//

import UIKit
import MapKit

class PostLocationViewController: UIViewController {
    
    
    //MARK: Outlets
    @IBOutlet weak var questionView: UIView!
    @IBOutlet weak var findOnMapButton: UIButton!
    @IBOutlet weak var locationTextView: UITextView!
    @IBOutlet weak var semiTransparentView: UIView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var linkTextField: UITextField!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var browseURLButton: UIButton!
    
    @IBAction func browseToURL() {
        var mediaURL = self.linkTextField.text.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
        
        //No need to check for validity, as the UI guarantees we can only activate this button if the link is somewhat valid...
        UIApplication.sharedApplication().openURL(NSURL(string: mediaURL)!)
    }

    @IBAction func stopTextInput(sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    
    //MARK: Actions
    @IBAction func cancelButtonTapped(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    @IBAction func findOnTheMapTapped(sender: AnyObject) {
        
        var geoCoder = CLGeocoder()
        
        self.busyStatusManager.setBusyStatus(true, disableUserInteraction: true)
        
        geoCoder.geocodeAddressString(locationTextView.text, completionHandler: { (placemarks, error) -> Void in
            dispatch_async(dispatch_get_main_queue(), {
                self.busyStatusManager.setBusyStatus(false)
                if error == nil {
                    
                    //Switch on UI Related to link input
                    self.submitButton.hidden = false
                    self.browseURLButton.hidden = false
                    self.mapView.hidden = false
                    self.linkTextField.hidden = false
                    self.cancelButton.tintColor = UIColor.whiteColor()
                    self.semiTransparentView.hidden = false
                    
                    //Switch off UI Related to location input
                    self.questionView.hidden = true
                    self.locationTextView.hidden = true
                    self.findOnMapButton.hidden = true
                    
                    
                    self.mapString = self.locationTextView.text
                    
                    //Process placemarks
                    for placemark in placemarks
                    {
                        self.userLocation = (placemark as! CLPlacemark).location
                        
                        var userLocationAnnotation = MKPointAnnotation()
                        userLocationAnnotation.coordinate = self.userLocation!.coordinate
                        
                        self.mapView.addAnnotation(userLocationAnnotation)
                        
                        //Update Map Region
                        self.mapView.centerCoordinate = self.userLocation!.coordinate
                        
                        let miles = 5.0;
                        var scalingFactor = abs((cos(2 * M_PI * self.userLocation!.coordinate.latitude / 360.0) ))
                        
                        var span = MKCoordinateSpan(latitudeDelta: miles / 50.0, longitudeDelta: miles / (scalingFactor * 50.0))
                        
                        
                        var region = MKCoordinateRegion(center: self.userLocation!.coordinate, span: span)
                        
                        self.mapView.setRegion(region, animated: true)
                    }
                }
                else {
                    Utils.alert(fromVC: self, withTitle: "Error", message: "Location is invalid. Please enter a valid Location.", completionHandler: nil)
                }

            })
        })
    }
    
    
    @IBAction func submitInformation() {
        
        self.view.endEditing(true)
        
        self.busyStatusManager.setBusyStatus(true, disableUserInteraction: true)
        
        var theURL = self.linkTextField.text.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
        
        if self.doUpdateInsteadOfCreate == true { // We just update last student's known location
            ParseAPIClient.sharedInstance.updateStudentLocation(self.mapString, location: self.userLocation, mediaURL: theURL, completionHandler: { (success, errorString) -> Void in
                dispatch_async(dispatch_get_main_queue(), {
                    
                    //self.setButtonStatus (self.submitButton, enabled: true)
                    self.busyStatusManager.setBusyStatus(false)
                    
                    if success {
                        self.dismissViewControllerAnimated(true, completion: nil)
                    }
                    else {
                        self.showRetryAlert("Error Updating Location", message: errorString!)
                    }
                })
            })
        }
        else { //This is a real creation of a new Student location
            ParseAPIClient.sharedInstance.postStudentLocation(self.mapString, location: self.userLocation, mediaURL: theURL, completionHandler: { (success, errorString) -> Void in
                dispatch_async(dispatch_get_main_queue(), {
                    
                    //self.setButtonStatus (self.submitButton, enabled: true)
                    self.busyStatusManager.setBusyStatus(false)
                    
                    if success {
                        self.dismissViewControllerAnimated(true, completion: nil)
                    }
                    else {
                        self.showRetryAlert("Error Posting Location", message: errorString!)
                    }
                })
            })
        }
    }
    

    
    //MARK: State
    var doUpdateInsteadOfCreate = false
    private var busyStatusManager: BusyStatusManager!
    
    //Using implicitly unwrapped optionals here because the flow of the UI
    //guarantees that they must have been filled by the time we get to use them
    private var userLocation: CLLocation!
    private var mapString: String!
    
    
    private static let locationPlaceholder = "Enter Your Location Here"
    private static let linkPlacheholder = "Enter a Link to share here"

    //MARK Lifetime
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.findOnMapButton.layer.cornerRadius = 10.0
        self.setButtonStatus (self.findOnMapButton, enabled: false)
        
        self.submitButton.layer.cornerRadius = 10.0
        self.setButtonStatus (self.submitButton, enabled: false)
        self.setButtonStatus (self.browseURLButton, enabled: false)

        self.locationTextView.text = PostLocationViewController.locationPlaceholder
        self.linkTextField.text = PostLocationViewController.linkPlacheholder
        
        //Setting this in Storyboard doesn't seem to work,
        //i.e. the color of the prompt seems to remain as the default (blu-ish)
        self.linkTextField.tintColor = UIColor.whiteColor()
        
        self.semiTransparentView.backgroundColor = UIColor.clearColor().colorWithAlphaComponent(0.3)
        
        self.busyStatusManager = BusyStatusManager(forView: self.view)
    }
    
    //MARK Business Logic
    private func setButtonStatus (button: UIButton, enabled: Bool) {
        button.enabled = enabled
        button.alpha = enabled ? 1.0 : 0.4
    }
    
    private func showRetryAlert(title: String, message: String) {
        
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        
        alertVC.addAction(UIAlertAction(title: "Retry", style: UIAlertActionStyle.Default, handler: alertActionHandler(forController: alertVC)))
        alertVC.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: alertActionHandler(forController: alertVC)))
        
        self.presentViewController(alertVC, animated: true, completion: nil)
        
    }
    
    private func alertActionHandler (forController alertController: UIAlertController) -> (sender: UIAlertAction!) -> Void {
        return { sender in
            if(sender.title == "Retry"){
                self.submitInformation()
            }
            else if(sender.title == "Cancel" || sender.title == "Ok") {
                alertController.dismissViewControllerAnimated(true, completion: nil)
            }
        }
    }
}


    //MARK: Protocol Conformance
extension PostLocationViewController: UITextViewDelegate
{
    func textViewDidBeginEditing(textView: UITextView) {
        textView.text = ""
        textView.textAlignment = .Left
        
        self.setButtonStatus (self.findOnMapButton, enabled: false)
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        textView.textAlignment = .Center
        if textView.text.isEmpty {
            textView.text = PostLocationViewController.locationPlaceholder
            
            self.setButtonStatus (self.findOnMapButton, enabled: false)
        }
    }
    
    /* This kind of realtime UI updating of the submit button is not really useful in a normal
    scenario, where the virtual keyboard will keep it covered while editing, and then *didEndEditing 
    will do the right thing, but just in case someone is entering text through an external keyboard...
    */
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        
        let currentString =  (textView.text as NSString).stringByReplacingCharactersInRange(range, withString: text)
        
        self.setButtonStatus (self.findOnMapButton, enabled: !currentString.isEmpty)
        
        return true
    }
}

extension PostLocationViewController: UITextFieldDelegate
{
    func textFieldDidBeginEditing(textField: UITextField) {
        textField.text = ""
        textField.textAlignment = .Left
        
        self.setButtonStatus (self.submitButton, enabled: false)
        self.setButtonStatus (self.browseURLButton, enabled: false)
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        textField.textAlignment = .Center
        
        var enableSubmitButton = true
        
        if textField.text.isEmpty {
            textField.text = PostLocationViewController.linkPlacheholder
            enableSubmitButton = false
        }
        else {
            var mediaURL = textField.text.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
            if !UIApplication.sharedApplication().canOpenURL(NSURL(string: mediaURL)!) {
                Utils.alert(fromVC: self, withTitle: "Error", message: "Link is invalid. Please enter a valid URL", completionHandler: nil)
                enableSubmitButton = false
            }
        }
        
        self.setButtonStatus (self.submitButton, enabled: enableSubmitButton)
        self.setButtonStatus (self.browseURLButton, enabled: enableSubmitButton)
    }
    
    /* This kind of realtime UI updating of the submit button is not really useful in a normal
    scenario, where the virtual keyboard will keep it covered while editing, and then *didEndEditing 
    will do the right thing, but just in case someone is entering text through an external keyboard...
    */
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
        let currentString =  (textField.text as NSString).stringByReplacingCharactersInRange(range, withString: string)
        
        var mediaURL = textField.text.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
        
        self.setButtonStatus (self.submitButton, enabled: UIApplication.sharedApplication().canOpenURL(NSURL(string: mediaURL)!))
        self.setButtonStatus (self.browseURLButton, enabled: UIApplication.sharedApplication().canOpenURL(NSURL(string: mediaURL)!))
        
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }
}
