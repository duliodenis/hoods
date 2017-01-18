//
//  CalloutViewController.swift
//  hoods
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
        
        // set local and data source represented object to one passed in
        self.representedObject = representedObject
        DataSource.si.calloutRepresentedObject = representedObject

        mainBody = UIButton(type: .system)
        
        // init after represented object and button are set up
        super.init(frame: CGRect.zero)
        
        addSubview(self.mainBody)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: MGLCalloutView API
    
    func presentCallout(from rect: CGRect, in view: UIView, constrainedTo constrainedView: UIView, animated: Bool) {
        
        // if representedObject has no title or is the user location annotation, return
        if !representedObject.responds(to: #selector(getter: MGLAnnotation.title)) || representedObject.responds(to: #selector(getter: MGLMapCamera.heading)) {
            return
        }
        
        view.addSubview(self)
        
        if isCalloutTappable() {
            
            // Handle taps and eventually try to send them to the delegate (usually the map view)
            mainBody.addTarget(self, action: #selector(CalloutViewController.calloutTapped), for: .touchUpInside)
        } else {
            
            // Disable tapping and highlighting
            mainBody.isUserInteractionEnabled = false
        }
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "AnnotationTapped"), object: nil)
    }
    
    func dismissCallout(animated: Bool) {}
    
    
    // MARK: Callout interaction handlers
    
    func isCalloutTappable() -> Bool {
        if let delegate = delegate {
            if delegate.responds(to: #selector(MGLCalloutViewDelegate.calloutViewShouldHighlight(_:))) {
                return delegate.calloutViewShouldHighlight!(self)
            }
        }
        return false
    }
    
    func calloutTapped() {
        if isCalloutTappable() && delegate!.responds(to: #selector(MGLCalloutViewDelegate.calloutViewTapped(_:))) {
            delegate!.calloutViewTapped!(self)
        }
    }
}
