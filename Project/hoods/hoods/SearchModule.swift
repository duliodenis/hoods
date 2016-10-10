//
//  SearchModule.swift
//  hoods
//
//  Created by Andrew Carvajal on 9/26/16.
//  Copyright © 2016 YugeTech. All rights reserved.
//

import UIKit

class SearchModule: ModuleView {

    var searchBar = UISearchBar()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        layer.cornerRadius = 0
        
        searchBar.sizeToFit()
        searchBar.searchBarStyle = .minimal
        searchBar.placeholder = "Search an address or hood"
        
        let views = [searchBar]
        
        for view in views {
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }
        
        let constraints: [NSLayoutConstraint] = [
            searchBar.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            searchBar.leftAnchor.constraint(equalTo: layoutMarginsGuide.leftAnchor),
            searchBar.rightAnchor.constraint(equalTo: layoutMarginsGuide.rightAnchor),
            searchBar.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
