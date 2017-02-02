//
//  SearchResultsView.swift
//  hoods
//
//  Created by Andrew Carvajal on 1/27/17.
//  Copyright © 2017 YugeTech. All rights reserved.
//

import UIKit

class SearchResultsView: UIView {
    
    var roundedCornerRadius = CGFloat()
    var tableView = UITableView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        roundedCornerRadius = frame.size.width / 20
        
        layer.cornerRadius = roundedCornerRadius
        layer.masksToBounds = true
        backgroundColor = UIColor.white
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorColor = .clear
        addSubview(tableView)
        
        let constraints: [NSLayoutConstraint] = [
            tableView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor, constant: DataSource.si.viewSize!.height + DataSource.si.hoodViewHeight!),
            tableView.leftAnchor.constraint(equalTo: layoutMarginsGuide.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: layoutMarginsGuide.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
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
