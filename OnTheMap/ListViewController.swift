//
//  ListTableViewController.swift
//  OnTheMap
//
//  Created by Andrea Bigagli on 11/7/15.
//  Copyright (c) 2015 Andrea Bigagli. All rights reserved.
//

import UIKit

class ListViewController: UITableViewController {
    
    //MARK: Table view data source
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ParseAPIClient.sharedInstance.students.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("studentLocationCell", forIndexPath: indexPath) 

        cell.textLabel?.text = ParseAPIClient.sharedInstance.students[indexPath.row].fullName

        //Not sure if parse API can ever return something without a valid mapString, but just to be on the safe side I safely unwrap it
        if let mapString = ParseAPIClient.sharedInstance.students[indexPath.row].mapString {
            cell.detailTextLabel?.text = mapString
        }
        
        return cell
    }
    
    //MARK: State
    var lastUpdate: NSTimeInterval = 0
    
    //MARK: Table view delegate
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        UIApplication.sharedApplication().openURL(NSURL(string: ParseAPIClient.sharedInstance.students[indexPath.row].mediaURL!)!)
    }
    
    //MARK: Business Logic
    func refreshData() {
        self.tableView.reloadData()
        self.lastUpdate = ParseAPIClient.sharedInstance.lastStudentsUpdate
    }
}
