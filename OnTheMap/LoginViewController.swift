//
//  ViewController.swift
//  OnTheMap
//
//  Created by Andrea Bigagli on 6/7/15.
//  Copyright (c) 2015 Andrea Bigagli. All rights reserved.
//

import UIKit

//class LoginViewController: UIViewControllerWithBusyState {
class LoginViewController: UIViewController {

    //MARK: Outlets
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var emailLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var emailTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var pwdLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var pwdTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var loginTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var loginBottomConstraint: NSLayoutConstraint!
    
    //MARK: Actions
    @IBAction func backgroundTapped(sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    @IBAction func loginToUdacity(sender: UIButton) {
        if self.usernameTextField.text.isEmpty {
            Utils.alert(fromVC: self, withTitle:"Error", message: "Missing Username", completionHandler: { (alertAction) -> Void in
                self.usernameTextField.becomeFirstResponder()
            })
            return
        }
        
        if self.passwordTextField.text.isEmpty {
            Utils.alert(fromVC: self, withTitle:"Error", message: "Missing Password", completionHandler: { (alertAction) -> Void in
                self.passwordTextField.becomeFirstResponder()
            })
            return
        }
        
        self.usernameTextField.resignFirstResponder()
        self.passwordTextField.resignFirstResponder()
        
        self.busyStatusManager.setBusyStatus(true, disableUserInteraction: true)

        UdacityAPIClient.sharedInstance.authenticate(usernameTextField.text, password: passwordTextField.text) { (success, errorString) in
            dispatch_async(dispatch_get_main_queue(), {
                
                self.busyStatusManager.setBusyStatus(false)

                if success {
                    
                    let controller = self.storyboard!.instantiateViewControllerWithIdentifier("RootNavigation") as! UINavigationController
                    self.presentViewController(controller, animated: true, completion: nil)
                    
                } else {
                    Utils.alert(fromVC: self, withTitle:"Login error", message: errorString!, completionHandler: nil)
                }
            })
        }
    }

    @IBAction func openCreateUdacityAccount(sender: UIButton) {
        UIApplication.sharedApplication().openURL(NSURL(string: UdacityAPIClient.Constants.SignInURL)!)
    }

    
    //MARK: State
    private var busyStatusManager: BusyStatusManager!
    
    
    //MARK: Lifetime
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        //Ensure email and password fields are clear, just in case we return here via "Logout"
        self.usernameTextField.text = ""
        self.passwordTextField.text = ""
        
        self.emailLeadingConstraint.constant -= self.view.bounds.size.width
        self.emailTrailingConstraint.constant += self.view.bounds.size.width
        
        self.pwdLeadingConstraint.constant += self.view.bounds.size.width
        self.pwdTrailingConstraint.constant -= self.view.bounds.size.width
        
        self.imageTopConstraint.constant -= 150.0
        self.imageBottomConstraint.constant += 150.0
        
        self.loginTopConstraint.constant += self.view.bounds.size.height
        self.loginBottomConstraint.constant -= self.view.bounds.size.height
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.emailLeadingConstraint.constant += self.view.bounds.size.width
        self.emailTrailingConstraint.constant -= self.view.bounds.size.width
        
        self.pwdLeadingConstraint.constant -= self.view.bounds.size.width
        self.pwdTrailingConstraint.constant += self.view.bounds.size.width
        
        self.imageTopConstraint.constant += 150.0
        self.imageBottomConstraint.constant -= 150.0
        
        self.loginTopConstraint.constant -= self.view.bounds.size.height
        self.loginBottomConstraint.constant += self.view.bounds.size.height
        
        
        UIView.animateWithDuration(1.0, animations: {
            self.view.layoutIfNeeded()
            }
            //CodeReview: Help the user setting username as first responder
            , completion: { _ in
                self.usernameTextField.becomeFirstResponder()
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.busyStatusManager = BusyStatusManager(forView: self.view)
    }
}

