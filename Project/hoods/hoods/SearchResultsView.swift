//
//  SearchResultsView.swift
//  hoods
//
//  Created by Andrew Carvajal on 10/4/16.
//  Copyright © 2016 YugeTech. All rights reserved.
//

import UIKit

class SearchResultsView: UIView {
    
    var roundedCornerRadius = CGFloat()
    var searchTableView = UITableView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        roundedCornerRadius = frame.size.width / 20
        layer.cornerRadius = roundedCornerRadius
        layer.masksToBounds = true
        
        backgroundColor = UIColor.white
        
        searchTableView.backgroundColor = UIColor.black
        
        let views: [UIView] = [searchTableView]
        
        for view in views {
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }
        
        let constraints: [NSLayoutConstraint] = [
            searchTableView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            searchTableView.leftAnchor.constraint(equalTo: layoutMarginsGuide.leftAnchor),
            searchTableView.rightAnchor.constraint(equalTo: layoutMarginsGuide.rightAnchor),
            searchTableView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor)
            ]
        NSLayoutConstraint.activate(constraints)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /*
     // Only override drawRect: if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func drawRect(rect: CGRect) {
     // Drawing code
     }
     */
    
}
