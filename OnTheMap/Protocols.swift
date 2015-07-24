//
//  Protocols.swift
//  OnTheMap
//
//  Created by Andrea Bigagli on 7/7/15.
//  Copyright (c) 2015 Andrea Bigagli. All rights reserved.
//

import UIKit

//What is provided here, is something I suspect would be a very good fit for the new swift 2.0 protocol extension feature
//What I'd really need is infact to make some of my viewcontrollers adopt a protocol for which there is a common implementation
//I can't easily do the same with single inheritance as I need this behaviour in not hierarchically related VCs (i.e. plain VCs,
//and tabbarcontroller)
//So the best second thing I could think of was using composition and defining a class that handles this and just have 
//all VCs that require this service to have an instance of this BusyStatusManager
//I'm keeping this in a file named "Protocols" though, because I think that's what I really would like to do and probably
//will update this to use protocol extensions when swift 2.0 will be finalized

class BusyStatusManager {
    
    private var interactionDisabled = false
    private var activityIndicatorEnhancer: UIView!
    private var activityIndicator: UIActivityIndicatorView!
    private unowned var managedView: UIView
    
    //Using lazy initialization here is a bit overkill, but conceptually I think this
    //is the correct thing to do given that in this application the geometry of views cannot change
    //once they appear on screen (no rotation/transformation is ever performed) and hence
    //it shouldn't be necessary to re-evaluate the frame geometry every time we go into busy mode.
    //So, also test my understanding of lazy stored properties, I've used a "called-when-declared" closure whose 
    //return value is the frame we need, and that has the nice side effect to call addSubview, which we can
    //do since we're guaranteed this will be called only once
    //Of course it would be much easier if we could do these thing in viewDidLoad, but I'm quite sure 
    //working with view geometry there is not the right thing to do...
    private lazy var managedViewFrame: CGRect = {
        self.managedView.addSubview(self.activityIndicatorEnhancer)
        return CGRectMake(0, 0, CGRectGetWidth(self.managedView.bounds), CGRectGetHeight(self.managedView.bounds))
    }()
    
    
    init (forView view: UIView) {
        self.activityIndicatorEnhancer = UIView()
        self.activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
        self.activityIndicatorEnhancer.addSubview(self.activityIndicator)
        self.activityIndicatorEnhancer.backgroundColor = UIColor.clearColor().colorWithAlphaComponent(0.5)
        self.activityIndicatorEnhancer.hidden = true
        managedView = view
    }
    
    func setBusyStatus(busy: Bool, disableUserInteraction: Bool = false) {
        
        if busy {
            self.activityIndicatorEnhancer.frame = self.managedViewFrame //Let lazy property do the magic...
            self.activityIndicator.center = self.activityIndicatorEnhancer.center
        
            self.activityIndicatorEnhancer.hidden = false
            self.activityIndicator.startAnimating()
            if disableUserInteraction {
                UIApplication.sharedApplication().beginIgnoringInteractionEvents()
                interactionDisabled = true
            }
        } else {
            self.activityIndicator.stopAnimating()
            self.activityIndicatorEnhancer.hidden = true
            //Of course when disabling busy status, the passed in disableUseInterface argument is a don't care, and we just revert if/what we have done wrt user interactions when setting busy to true
            if interactionDisabled {
                UIApplication.sharedApplication().endIgnoringInteractionEvents()
                interactionDisabled = false
            }
        }
    }
}
