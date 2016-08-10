//
//  CalloutViewController.swift
//  Yuge
//
//  Created by Andrew Carvajal on 5/22/16.
//  Copyright © 2016 YugeTech. All rights reserved.
//

import Mapbox

class CalloutViewController: UIView, MGLCalloutView {
    
    weak var delegate: MGLCalloutViewDelegate?
    var representedObject: MGLAnnotation
    var leftAccessoryView = UIView()
    var rightAccessoryView = UIView()
    let mainBody: UIButton
    
    // store the represented object's title
    required init(representedObject: MGLAnnotation) {
        self.representedObject = representedObject
        mainBody = UIButton(type: .System)
        
        super.init(frame: CGRectZero)
        
        addSubview(self.mainBody)
        DataSource.sharedInstance.calloutRepresentedObjectTitle = representedObject.title!!
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: MGLCalloutView API
    
    func presentCalloutFromRect(rect: CGRect, inView view: UIView, constrainedToView constrainedView: UIView, animated: Bool) {
        
        // if representedObject has no title or is the user location annotation, return
        if !representedObject.respondsToSelector(Selector("title")) || representedObject.respondsToSelector(Selector("heading")) {
            return
        }
        
        view.addSubview(self)
        
        if isCalloutTappable() {
            
            // Handle taps and eventually try to send them to the delegate (usually the map view)
            mainBody.addTarget(self, action: #selector(CalloutViewController.calloutTapped), forControlEvents: .TouchUpInside)
        } else {
            
            // Disable tapping and highlighting
            mainBody.userInteractionEnabled = false
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName("AnnotationTapped", object: nil)
    }
    
    func dismissCalloutAnimated(animated: Bool) {}
    
    
    // MARK: Callout interaction handlers
    
    func isCalloutTappable() -> Bool {
        if let delegate = delegate {
            if delegate.respondsToSelector(#selector(MGLCalloutViewDelegate.calloutViewShouldHighlight(_:))) {
                return delegate.calloutViewShouldHighlight!(self)
            }
        }
        return false
    }
    
    func calloutTapped() {
        if isCalloutTappable() && delegate!.respondsToSelector(#selector(MGLCalloutViewDelegate.calloutViewTapped(_:))) {
            delegate!.calloutViewTapped!(self)
        }
    }
}
