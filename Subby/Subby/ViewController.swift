//
//  ViewController.swift
//  Subby
//
//  Created by Heath Borders on 5/8/23.
//

import UIKit

class ViewController: UIViewController {

    override func loadView() {
        super.loadView()
        
        self.view.backgroundColor = UIColor.white
        
        let label = UILabel()
        label.frame = self.view.bounds
        label.text = "Hello World!"
        label.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(label)
    }
}

