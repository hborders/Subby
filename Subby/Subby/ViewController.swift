//
//  ViewController.swift
//  Subby
//
//  Created by Heath Borders on 5/8/23.
//

import UIKit

// This is a fixed-increment version of Java 8's SplittableRandom generator.
// It is a very fast generator passing BigCrush, with 64 bits of state.
// See http://dx.doi.org/10.1145/2714064.2660195 and
// http://docs.oracle.com/javase/8/docs/api/java/util/SplittableRandom.html
//
// Derived from public domain C implementation by Sebastiano Vigna
// See http://xoshiro.di.unimi.it/splitmix64.c
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    public init(seed: UInt64) {
        self.state = seed
    }

    public mutating func next() -> UInt64 {
        self.state &+= 0x9e3779b97f4a7c15
        var z: UInt64 = self.state
        z = (z ^ (z &>> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z &>> 27)) &* 0x94d049bb133111eb
        return z ^ (z &>> 31)
    }
}

struct Grid {
    let size: Int
    let sizeAndTotal: Int
    let gridCellCount: Int
    var numberCells: [NumberCell]
    
    init(size: Int) {
        self.size = size
        self.sizeAndTotal = size + 1
        self.gridCellCount = self.sizeAndTotal * self.sizeAndTotal
        
        var randomNumberGenerator = SplitMix64(seed:69)
        var numberCells: [NumberCell] = []
        for _ in 0..<size*size {
            let puzzleValue = Int.random(in: 0...9, using: &randomNumberGenerator)
            let countsTowardTotal = Bool.random(using: &randomNumberGenerator)
            let numberCell = NumberCell(puzzleValue: puzzleValue, countsTowardTotal: countsTowardTotal, destiny: .undecided)
            numberCells.append(numberCell)
        }
        self.numberCells = numberCells
    }
    
    func gridCell(for indexPath: IndexPath) -> GridCell {
        let x = indexPath.item % self.sizeAndTotal
        let y = indexPath.item / self.sizeAndTotal
        
        guard x < self.sizeAndTotal && y < self.sizeAndTotal else {
            fatalError("Item: \(indexPath.item) out of bounds: \(self.gridCellCount)")
        }
        if x == self.size && y == self.size {
            return .blank
        } else if x == self.size {
            let numberCellsStartIndex = self.size * y
            let numberCellsEndIndex = numberCellsStartIndex + self.size
            var total = 0
            for i in numberCellsStartIndex..<numberCellsEndIndex {
                let numberCell = self.numberCells[i]
                total += numberCell.totalValue
            }
            return .total(total: total)
        } else if y == self.size {
            let numberCellsStartIndex = x
            let numberCellsEndIndex = numberCellsStartIndex + (self.size * self.size)
            var total = 0
            for i in stride(from: numberCellsStartIndex, to: numberCellsEndIndex, by: self.size) {
                let numberCell = self.numberCells[i]
                total += numberCell.totalValue
            }
            return .total(total: total)
        } else {
            let numberCellsIndex = x + (self.size * y)
            let numberCell = numberCells[numberCellsIndex]
            return .number(numberCell: numberCell)
        }
    }
}

enum GridCell {
    case number(numberCell: NumberCell)
    case total(total: Int)
    case blank
}

struct NumberCell {
    let puzzleValue: Int
    let countsTowardTotal: Bool
    var destiny: Destiny
    
    enum Destiny {
        case undecided
        case yes
        case no
    }
    
    var totalValue: Int {
        if (self.countsTowardTotal) {
            return self.puzzleValue
        } else {
            return 0
        }
    }
}

class ViewController: UIViewController {
    
    let grid: Grid
    
    init(size: Int) {
        self.grid = Grid(size: size)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    init() {
        abort()
    }
    
    @available(*, unavailable)
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        abort()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        abort()
    }
    
    var collectionView: UICollectionView!
    
    override func loadView() {
        super.loadView()
        
        self.view.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.backgroundColor = UIColor.red
        let collectionViewFlowLayout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
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

struct Coordinate {
    let x: Int
    let y: Int
}

extension ViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.grid.gridCellCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch self.grid.gridCell(for: indexPath) {
        case .blank:
            return collectionView.dequeueBlankCollectionViewCell(for: indexPath)
        case .number(let numberCell):
            let numberCollectionViewCell = collectionView.dequeueNumberCollectionViewCell(for: indexPath)
            numberCollectionViewCell.setNumber(numberCell.puzzleValue)
            if numberCell.countsTowardTotal {
                numberCollectionViewCell.backgroundColor = UIColor.blue
            }
            return numberCollectionViewCell
        case .total(let total):
            let totalCollectionViewCell = collectionView.dequeueTotalCollectionViewCell(for: indexPath)
            totalCollectionViewCell.setTotal(total)
            return totalCollectionViewCell
        }
    }
}

extension ViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let collectionViewFlowLayout = collectionViewLayout as? UICollectionViewFlowLayout,
              let collectionView = collectionViewFlowLayout.collectionView else {
            abort()
        }
        
        let dimension = min(collectionView.frame.width, collectionView.frame.height) / Double(self.grid.sizeAndTotal) - collectionViewFlowLayout.minimumInteritemSpacing
        return CGSize(width: dimension, height: dimension)
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
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
        self.numberLabel.font = UIFont.systemFont(ofSize: 14)
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
        
        self.backgroundColor = UIColor.yellow
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
        self.totalLabel.font = UIFont.boldSystemFont(ofSize: 14)
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
