//
//  MapViewController.swift
//  OnTheMap
//
//  Created by Andrea Bigagli on 10/7/15.
//  Copyright (c) 2015 Andrea Bigagli. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {
    //MARK: Outlets
    @IBOutlet weak var mapView: MKMapView!
    
    
    //MARK: Business logic
    func refreshData() {
        //First remove all previous annotations, to avoid duplicates...
        self.mapView.removeAnnotations(self.mapView.annotations)
        
        for student in ParseAPIClient.sharedInstance.students {
            let studentLocationAnnotation = MKPointAnnotation()
            studentLocationAnnotation.coordinate = CLLocationCoordinate2D(latitude: student.latitude!, longitude: student.longitude!)
            studentLocationAnnotation.title = student.fullName

            //Not sure if parse API can ever return something without a valid mediaURL, but just to be on the safe side I safely unwrap it
            studentLocationAnnotation.subtitle = student.mediaURL != nil ? student.mediaURL! : "No URL"

            self.mapView.addAnnotation(studentLocationAnnotation)
        }
        
        //Force displaying of annotations by "re-centering" the map exactly where it was before
        self.mapView.setCenterCoordinate(self.mapView.region.center, animated: true)
        
        self.lastUpdate = ParseAPIClient.sharedInstance.lastStudentsUpdate
    }
    
    //MARK: State
    
    var lastUpdate: NSTimeInterval = 0
}

//MARK: Protocol conformance

extension MapViewController: MKMapViewDelegate
{
        func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "studentLocationPin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinColor = .Red
            pinView!.rightCalloutAccessoryView = UIButton(type: UIButtonType.DetailDisclosure)
            
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(mapView: MKMapView, annotationView: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        if let annotation = annotationView.annotation {
            if control == annotationView.rightCalloutAccessoryView {
                UIApplication.sharedApplication().openURL(NSURL(string: annotation.subtitle!!)!)
            }
        }
    }
}
