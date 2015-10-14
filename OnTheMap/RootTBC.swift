//
//  RootTBC.swift
//  OnTheMap
//
//  Created by Andrea Bigagli on 10/7/15.
//  Copyright (c) 2015 Andrea Bigagli. All rights reserved.
//

import UIKit

/*
NOTE TO REVIEWER: I decided for the following approach:
-)  Instead of replicating the "logout, addlocation, refresh" logic and UI on
    both the MAP and TABLE VCs, I chose to "centralize" it here in a UITabBarController
    derived class that acts as a "dispatcher" of such user actions to the currently selected VC
*/

class RootTBC: UITabBarController {
    
    //MARK: Actions
    @IBAction func logoutUser(sender: UIBarButtonItem) {
        self.busyStatusManager.setBusyStatus(true, disableUserInteraction: true)
        
        //CodeReview: Added invocation of http.delete on the udacity session API to invalidate current “XSRF_TOKEN”
        UdacityAPIClient.sharedInstance.logoutUser{ (success, errorString) in
            dispatch_async(dispatch_get_main_queue(), {
                
                self.busyStatusManager.setBusyStatus(false)
                
                //DOUBT: I'm not sure if denying logout in case of any error does really make sense here:
                //Do I really have to remain stuck in the session if it cannot call home and tell the server
                //I'm going away?
        
                if success {
                    self.dismissViewControllerAnimated(true, completion: nil)

                } else {
                    Utils.alert(fromVC: self, withTitle:"Logout error", message: errorString!, completionHandler: nil)
                }
            })
        }
    }
    
    @IBAction func refreshData() { //This is the one and only "source of truth", in the sense that it is the only point that downloads the latest positions and updates the model
        self.navigationItem.rightBarButtonItem!.enabled = false
        
        self.busyStatusManager.setBusyStatus(true)
        
        ParseAPIClient.sharedInstance.reloadStudentsInformation { (success, errorString) -> Void in
            dispatch_async(dispatch_get_main_queue(), {
                if success {
                    self.lastUpdate = ParseAPIClient.sharedInstance.lastStudentsUpdate
                    self.syncSelectedVCWithLatestData()
                }
                else {
                    Utils.alert(fromVC: self, withTitle: "Data Refresh Error", message: errorString!, completionHandler: nil)
                }
                
                self.busyStatusManager.setBusyStatus(false)
                self.navigationItem.rightBarButtonItem!.enabled = true
            })
        }
    }
    
    //MARK: State
    private var lastUpdate: NSTimeInterval = 0
    private var busyStatusManager: BusyStatusManager!


    //MARK: Lifetime
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let addLocationButton = UIBarButtonItem(image: UIImage(named: "pin"), style: UIBarButtonItemStyle.Plain, target: self, action: "checkForStudentLocation")
        let refreshButton = UIBarButtonItem(barButtonSystemItem: .Refresh, target: self, action: "refreshData")
        
        self.navigationItem.rightBarButtonItems = [refreshButton, addLocationButton]
        
        self.delegate = self //Yes, I'm the delegate of myself
        
        self.busyStatusManager = BusyStatusManager(forView: self.view)
    }
    
    override func viewDidAppear(animated: Bool)
    {
        super.viewDidAppear(animated)
        
        if (self.lastUpdate == 0 || self.lastUpdate < ParseAPIClient.sharedInstance.lastStudentsUpdate) {
            self.refreshData()
        }
    }
    
    
    //MARK: Business Logic
    func checkForStudentLocation() {
        let pinButton = (self.navigationItem.rightBarButtonItems?[1] as? UIBarButtonItem)
        pinButton?.enabled = false
        
        self.busyStatusManager.setBusyStatus(true)

        
        ParseAPIClient.sharedInstance.checkCurrentUserLocation { (success, locationAlreadySubmitted, errorString) -> Void in
            dispatch_async(dispatch_get_main_queue(), {
                self.busyStatusManager.setBusyStatus(false)
                pinButton?.enabled = true
                
                if success {
                    if locationAlreadySubmitted {
                        self.showOverwriteAlert()
                    }
                    else {
                        self.showPostLocationViewController(overwritingLocation: false)
                    }
                }
                else {
                    Utils.alert(fromVC: self, withTitle: "Location Query Error", message: errorString!, completionHandler: nil)
                }
            })
        }
    }
    
    private func syncSelectedVCWithLatestData() {
        switch (self.selectedViewController)
        {
        case let mapVC as MapViewController:
            if (mapVC.lastUpdate == 0 || mapVC.lastUpdate < ParseAPIClient.sharedInstance.lastStudentsUpdate) {
                mapVC.refreshData()
            }
        case let listVC as ListViewController:
            if (listVC.lastUpdate == 0 || (listVC.lastUpdate < ParseAPIClient.sharedInstance.lastStudentsUpdate)) {
                listVC.refreshData()
            }
        default: () //No meaningful default case
        }

    }
    
    //If the student already posted a location, a alertview will ask if him wants to overwrite the location with a new one.
    private func showOverwriteAlert() {
        let alert = UIAlertController(title: nil, message: "User \(UdacityAPIClient.sharedInstance.user.fullName) has already posted a location!", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Overwrite", style: .Default, handler: {action in
            self.showPostLocationViewController(overwritingLocation: true)
        }))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
 
    private func showPostLocationViewController(overwritingLocation overwritingLocation: Bool) {
        let controller = self.storyboard!.instantiateViewControllerWithIdentifier("PostLocationVC") as! PostLocationViewController
        controller.doUpdateInsteadOfCreate = overwritingLocation
        self.navigationController!.presentViewController(controller, animated: true, completion: nil)
    }
}

//MARK: Protocol conformance

extension RootTBC: UITabBarControllerDelegate {
    
    func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool {
        //Prevent switching tab while refreshing to avoid getting too complicated 
        //of a handling of consistency between view and model.
        return self.navigationItem.rightBarButtonItem!.enabled
    }
    
    func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {
        self.syncSelectedVCWithLatestData()
    }
}
    
