//
//  ViewController.swift
//  Subby
//
//  Created by Heath Borders on 5/8/23.
//

import UIKit

class ViewController: UIViewController {
    
    var collectionView: UICollectionView!
    
    override func loadView() {
        super.loadView()
        
        self.view.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.backgroundColor = UIColor.red
        let collectionViewFlowLayout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        //        let dimension = min(self.view.bounds.width, self.view.bounds.height) / 3 - collectionViewFlowLayout.minimumInteritemSpacing
        //        collectionViewFlowLayout.itemSize = CGSize(width: dimension, height: dimension)
        self.collectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: collectionViewFlowLayout)
        self.collectionView.register(BlankCollectionViewCell.self, forCellWithReuseIdentifier: BlankCollectionViewCell.identifier)
        self.collectionView.register(NumberCollectionViewCell.self, forCellWithReuseIdentifier: NumberCollectionViewCell.identifier)
        self.collectionView.register(TotalCollectionViewCell.self, forCellWithReuseIdentifier: TotalCollectionViewCell.identifier)
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        
        self.view.addSubview(self.collectionView)
        
        self.collectionView.backgroundColor = UIColor.orange
        
        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            self.collectionView.widthAnchor.constraint(equalTo: self.collectionView.heightAnchor),
            self.view.layoutMarginsGuide.centerXAnchor.constraint(equalTo: self.collectionView.centerXAnchor),
            self.view.layoutMarginsGuide.centerYAnchor.constraint(equalTo: self.collectionView.centerYAnchor),
            self.collectionView.widthAnchor.constraint(lessThanOrEqualTo: self.view.layoutMarginsGuide.widthAnchor),
            self.collectionView.heightAnchor.constraint(lessThanOrEqualTo: self.view.layoutMarginsGuide.heightAnchor),
        ])
        
        // this can be either width or height since width = height above
        let lowPriorityWidthConstraint = self.collectionView.widthAnchor.constraint(equalTo:self.view.layoutMarginsGuide.widthAnchor)
        lowPriorityWidthConstraint.priority = .defaultHigh
        lowPriorityWidthConstraint.isActive = true
    }
}

extension ViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 9
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch (indexPath.item) {
        case 0:
            let numberCollectionViewCell = collectionView.dequeueNumberCollectionViewCell(for: indexPath)
            numberCollectionViewCell.setNumber(0)
            return numberCollectionViewCell
        case 1:
            let numberCollectionViewCell = collectionView.dequeueNumberCollectionViewCell(for: indexPath)
            numberCollectionViewCell.setNumber(1)
            return numberCollectionViewCell
        case 2:
            let totalCollectionViewCell = collectionView.dequeueTotalCollectionViewCell(for: indexPath)
            totalCollectionViewCell.setTotal(1)
            return totalCollectionViewCell
        case 3:
            let numberCollectionViewCell = collectionView.dequeueNumberCollectionViewCell(for: indexPath)
            numberCollectionViewCell.setNumber(3)
            return numberCollectionViewCell
        case 4:
            let numberCollectionViewCell = collectionView.dequeueNumberCollectionViewCell(for: indexPath)
            numberCollectionViewCell.setNumber(4)
            return numberCollectionViewCell
        case 5:
            let totalCollectionViewCell = collectionView.dequeueTotalCollectionViewCell(for: indexPath)
            totalCollectionViewCell.setTotal(7)
            return totalCollectionViewCell
        case 6:
            let totalCollectionViewCell = collectionView.dequeueTotalCollectionViewCell(for: indexPath)
            totalCollectionViewCell.setTotal(3)
            return totalCollectionViewCell
        case 7:
            let totalCollectionViewCell = collectionView.dequeueTotalCollectionViewCell(for: indexPath)
            totalCollectionViewCell.setTotal(5)
            return totalCollectionViewCell
        case 8:
            return collectionView.dequeueBlankCollectionViewCell(for: indexPath)
        default:
            abort()
        }
    }
}

extension ViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let collectionViewFlowLayout = collectionViewLayout as? UICollectionViewFlowLayout,
              let collectionView = collectionViewFlowLayout.collectionView else {
            abort()
        }
        
        let dimension = min(collectionView.frame.width, collectionView.frame.height) / 3 - collectionViewFlowLayout.minimumInteritemSpacing
        return CGSize(width: dimension, height: dimension)
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch (indexPath.item) {
        case 0,1:
            print("Toggled number: \(indexPath.item)")
        case 2:
            break
        case 3,4:
            print("Toggled number: \(indexPath.item)")
        case 5,6,7,8:
            break
        default:
            abort()
        }
    }
}

extension UICollectionView {
    func dequeueBlankCollectionViewCell(for indexPath: IndexPath) -> BlankCollectionViewCell {
        return self.dequeueReusableCell(withReuseIdentifier: BlankCollectionViewCell.identifier, for: indexPath) as! BlankCollectionViewCell
    }
    func dequeueNumberCollectionViewCell(for indexPath: IndexPath) -> NumberCollectionViewCell {
        return self.dequeueReusableCell(withReuseIdentifier: NumberCollectionViewCell.identifier, for: indexPath) as! NumberCollectionViewCell
    }
    func dequeueTotalCollectionViewCell(for indexPath: IndexPath) -> TotalCollectionViewCell {
        return self.dequeueReusableCell(withReuseIdentifier: TotalCollectionViewCell.identifier, for: indexPath) as! TotalCollectionViewCell
    }
}

class BlankCollectionViewCell: UICollectionViewCell {
    static let identifier: String = "\(BlankCollectionViewCell.self)"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.black
    }
    
    required init?(coder: NSCoder) {
        abort()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
    }
}

class NumberCollectionViewCell: UICollectionViewCell {
    static let identifier: String = "\(NumberCollectionViewCell.self)"
    
    private let numberLabel: UILabel
    
    override init(frame: CGRect) {
        self.numberLabel = UILabel()
        self.numberLabel.textAlignment = .center
        
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.yellow
        
        self.contentView.addSubview(self.numberLabel)
        
        self.numberLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.contentView.layoutMarginsGuide.topAnchor.constraint(equalTo: self.numberLabel.topAnchor),
            self.contentView.layoutMarginsGuide.leadingAnchor.constraint(equalTo: self.numberLabel.leadingAnchor),
            self.contentView.layoutMarginsGuide.bottomAnchor.constraint(equalTo: self.numberLabel.bottomAnchor),
            self.contentView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: self.numberLabel.trailingAnchor),
        ])
    }
    
    required init?(coder: NSCoder) {
        abort()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
    }
    
    func setNumber(_ number: Int) {
        self.numberLabel.text = "\(number)"
    }
}

class TotalCollectionViewCell: UICollectionViewCell {
    static let identifier: String = "\(TotalCollectionViewCell.self)"
    
    private let totalLabel: UILabel
    
    override init(frame: CGRect) {
        self.totalLabel = UILabel()
        self.totalLabel.font = UIFont.boldSystemFont(ofSize: 16)
        self.totalLabel.textAlignment = .center
        
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.green
        
        self.contentView.addSubview(self.totalLabel)
        
        self.totalLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.contentView.layoutMarginsGuide.topAnchor.constraint(equalTo: self.totalLabel.topAnchor),
            self.contentView.layoutMarginsGuide.leadingAnchor.constraint(equalTo: self.totalLabel.leadingAnchor),
            self.contentView.layoutMarginsGuide.bottomAnchor.constraint(equalTo: self.totalLabel.bottomAnchor),
            self.contentView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: self.totalLabel.trailingAnchor),
        ])
    }
    
    required init?(coder: NSCoder) {
        abort()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
    }
    
    func setTotal(_ total: Int) {
        self.totalLabel.text = "\(total)"
    }
}
