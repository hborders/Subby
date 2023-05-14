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

struct NumberCellCoordinate {
    let x: Int
    let y: Int
}

struct AllCoordinate {
    let x: Int
    let y: Int
}

struct Grid {
    let seed: Int
    let size: Int
    let sizeAndTotal: Int
    let gridCellCount: Int
    var numberCells: [NumberCell]
    
    init(seed: Int, size: Int) {
        self.seed = seed
        self.size = size
        self.sizeAndTotal = size + 1
        self.gridCellCount = self.sizeAndTotal * self.sizeAndTotal
        
        var randomNumberGenerator = SplitMix64(seed: UInt64(seed))
        var numberCells: [NumberCell] = []
        for index in 0..<size*size {
            let puzzleValue = Int.random(in: 0...9, using: &randomNumberGenerator)
            let countsTowardTotal = Bool.random(using: &randomNumberGenerator)
            let numberCell = NumberCell(index: index, puzzleValue: puzzleValue, countsTowardTotal: countsTowardTotal, destiny: .undecided)
            numberCells.append(numberCell)
        }
        self.numberCells = numberCells
    }
    
    func allCoordinate(for indexPath: IndexPath) -> AllCoordinate {
        let x = indexPath.item % self.sizeAndTotal
        let y = indexPath.item / self.sizeAndTotal
        
        guard x < self.sizeAndTotal && y < self.sizeAndTotal else {
            fatalError("Item: \(indexPath.item) out of bounds: \(self.gridCellCount)")
        }
        
        return AllCoordinate(x: x, y: y)
    }
    
    func numberCellCoordinate(for indexPath: IndexPath) -> NumberCellCoordinate {
        let allCoordinate = allCoordinate(for: indexPath)
        guard allCoordinate.x < self.size && allCoordinate.y < self.size else {
            fatalError("Item: \(indexPath.item) at AllCoordinate: \(allCoordinate) is not in NumberCellCoordinate range: [0,\(self.size)), [0,\(self.size))")
        }
        
        return NumberCellCoordinate(x: allCoordinate.x, y: allCoordinate.y)
    }
    
    func indexPath(for numberCellCoordinate: NumberCellCoordinate) -> IndexPath {
        let item = numberCellCoordinate.y * self.sizeAndTotal + numberCellCoordinate.x
        return IndexPath(item: item, section: 0)
    }
    
    func indexPath(for allCoordinate: AllCoordinate) -> IndexPath {
        let item = allCoordinate.y * self.sizeAndTotal + allCoordinate.x
        return IndexPath(item: item, section: 0)
    }
    
    func totalGridCellIndexPaths(for numberCellCoordinate: NumberCellCoordinate) -> [IndexPath] {
        return [
            indexPath(for: AllCoordinate(x: self.size, y: numberCellCoordinate.y)),
            indexPath(for: AllCoordinate(x: numberCellCoordinate.x, y: self.size)),
        ]
    }
    
    func gridCell(for indexPath: IndexPath) -> GridCell {
        let allCoordinate = allCoordinate(for: indexPath)
        
        if allCoordinate.x == self.size && allCoordinate.y == self.size {
            return .blank
        } else if allCoordinate.x == self.size {
            let numberCellsStartIndex = self.size * allCoordinate.y
            let numberCellsEndIndex = numberCellsStartIndex + self.size
            var expectedTotal = 0
            var actualTotal = 0
            for i in numberCellsStartIndex..<numberCellsEndIndex {
                let numberCell = self.numberCells[i]
                expectedTotal += numberCell.expectedValue
                actualTotal += numberCell.actualValue
            }
            let finished = expectedTotal == actualTotal
            return .total(total: expectedTotal, finished: finished)
        } else if allCoordinate.y == self.size {
            let numberCellsStartIndex = allCoordinate.x
            let numberCellsEndIndex = numberCellsStartIndex + (self.size * self.size)
            var expectedTotal = 0
            var actualTotal = 0
            for i in stride(from: numberCellsStartIndex, to: numberCellsEndIndex, by: self.size) {
                let numberCell = self.numberCells[i]
                expectedTotal += numberCell.expectedValue
                actualTotal += numberCell.actualValue
            }
            let finished = expectedTotal == actualTotal
            return .total(total: expectedTotal, finished: finished)
        } else {
            let numberCellsIndex = allCoordinate.x + (self.size * allCoordinate.y)
            let numberCell = numberCells[numberCellsIndex]
            return .number(numberCell: numberCell)
        }
    }
    
    mutating func updatedIndexPathsAfterTappingGridCell(at indexPath: IndexPath) -> [IndexPath] {
        let gridCell = gridCell(for: indexPath)
        switch gridCell {
        case .blank, .total:
            return []
        case .number(var numberCell):
            numberCell.tap()
            self.numberCells[numberCell.index] = numberCell
            
            let numberCellCoordinate = numberCellCoordinate(for: indexPath)
            let totalGridCellIndexPaths = totalGridCellIndexPaths(for: numberCellCoordinate)
            return totalGridCellIndexPaths + [indexPath]
        }
    }
    
    mutating func clear() {
        var numberCells: [NumberCell] = []
        for var numberCell in self.numberCells {
            numberCell.destiny = .undecided
            numberCells.append(numberCell)
        }
        self.numberCells = numberCells
    }
}

enum GridCell {
    case number(numberCell: NumberCell)
    case total(total: Int, finished: Bool)
    case blank
}

struct NumberCell {
    let index: Int
    let puzzleValue: Int
    let countsTowardTotal: Bool
    var destiny: Destiny
    
    enum Destiny {
        case undecided
        case no
        case yes
        
        func next() -> Destiny {
            switch self {
            case .undecided:
                return .no
            case .no:
                return .yes
            case .yes:
                return .undecided
            }
        }
    }
    
    mutating func tap() {
        self.destiny = self.destiny.next()
    }
    
    var expectedValue: Int {
        if (self.countsTowardTotal) {
            return self.puzzleValue
        } else {
            return 0
        }
    }
    
    var actualValue: Int {
        switch self.destiny {
        case .undecided:
            return self.puzzleValue
        case .no:
            return 0
        case .yes:
            return self.puzzleValue
        }
    }
}

class ViewController: UIViewController {
    
    var grid: Grid
    
    init(seed: Int, size: Int) {
        self.grid = Grid(seed: seed, size: size)
        
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
    
    var collectionViewFlowLayout: UICollectionViewFlowLayout!
    var collectionView: UICollectionView!
    var stackView: UIStackView!
    var stackViewPortraitConstraints: [NSLayoutConstraint]!
    var stackViewLandscapeConstraints: [NSLayoutConstraint]!
    
    var clearButton: UIButton!
    var newGridButton: UIButton!
    
    override func loadView() {
        super.loadView()
        
        self.view.translatesAutoresizingMaskIntoConstraints = false
        
        self.collectionViewFlowLayout = UICollectionViewFlowLayout()
        self.collectionViewFlowLayout.minimumInteritemSpacing = 0
        self.collectionViewFlowLayout.minimumLineSpacing = 0
        self.collectionViewFlowLayout.sectionInset = .zero
        
        self.collectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: collectionViewFlowLayout)
        self.collectionView.register(BlankCollectionViewCell.self, forCellWithReuseIdentifier: BlankCollectionViewCell.identifier)
        self.collectionView.register(NumberCollectionViewCell.self, forCellWithReuseIdentifier: NumberCollectionViewCell.identifier)
        self.collectionView.register(TotalCollectionViewCell.self, forCellWithReuseIdentifier: TotalCollectionViewCell.identifier)
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        
        self.clearButton = UIButton(configuration: .plain(), primaryAction: UIAction(title: "Clear", handler: { [weak self] action in
            guard let self = self else {
                return
            }
            
            self.grid.clear()
            self.collectionView.reloadData()
        }))
        self.newGridButton = UIButton(configuration: .plain(), primaryAction: UIAction(title: "New Puzzle", handler: { [weak self] action in
            guard let self = self else {
                return
            }
            
            self.grid = Grid(seed: self.grid.seed + 1, size: self.grid.size)
            self.collectionView.reloadData()
        }))
        
        self.stackView = UIStackView(arrangedSubviews: [
            self.clearButton,
            self.newGridButton,
        ])
        
        self.view.addSubview(self.collectionView)
        self.view.addSubview(self.stackView)
        
        self.collectionView.backgroundColor = UIColor.orange
        
        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.stackView.translatesAutoresizingMaskIntoConstraints = false
        
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
        
        stackViewPortraitConstraints = [
            self.stackView.centerXAnchor.constraint(equalTo: self.collectionView.centerXAnchor),
            self.stackView.topAnchor.constraint(equalTo: self.collectionView.bottomAnchor),
        ]
        stackViewLandscapeConstraints = [
            self.stackView.leadingAnchor.constraint(equalTo: self.collectionView.trailingAnchor),
            self.stackView.centerYAnchor.constraint(equalTo: self.collectionView.centerYAnchor),
        ]
        
        self.updateLayout()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: nil) { _ in
            self.updateLayout()
        }
    }
    
    private func updateLayout() {
        if (self.view.bounds.width < self.view.bounds.height) {
            self.stackView.alignment = .firstBaseline
            self.stackView.axis = .horizontal
            NSLayoutConstraint.deactivate(self.stackViewLandscapeConstraints)
            NSLayoutConstraint.activate(self.stackViewPortraitConstraints)
        } else {
            self.stackView.alignment = .leading
            self.stackView.axis = .vertical
            self.stackView.spacing = UIStackView.spacingUseSystem
            NSLayoutConstraint.deactivate(self.stackViewPortraitConstraints)
            NSLayoutConstraint.activate(self.stackViewLandscapeConstraints)
        }
        self.collectionViewFlowLayout.invalidateLayout()
    }
}

extension ViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.grid.gridCellCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let gridCell = self.grid.gridCell(for: indexPath)
        switch gridCell {
        case .blank:
            return collectionView.dequeueBlankCollectionViewCell(for: indexPath)
        case .number(let numberCell):
            let numberCollectionViewCell = collectionView.dequeueNumberCollectionViewCell(for: indexPath)
            numberCollectionViewCell.update(number: numberCell.puzzleValue, destiny: numberCell.destiny)
            return numberCollectionViewCell
        case .total(let total, let finished):
            let totalCollectionViewCell = collectionView.dequeueTotalCollectionViewCell(for: indexPath)
            totalCollectionViewCell.update(total: total, finished: finished)
            return totalCollectionViewCell
        }
    }
}

extension ViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let dimension = min(collectionView.frame.width, collectionView.frame.height) / Double(self.grid.sizeAndTotal)
        return CGSize(width: dimension, height: dimension)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        var grid = self.grid
        let updatedIndexPaths = grid.updatedIndexPathsAfterTappingGridCell(at: indexPath)
        self.grid = grid
        if !updatedIndexPaths.isEmpty {
            collectionView.reloadItems(at: updatedIndexPaths)
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
    }
    
    func update(number: Int, destiny: NumberCell.Destiny) {
        self.numberLabel.text = "\(number)"
        let backgroundColor: UIColor
        switch destiny {
        case .undecided:
            backgroundColor = UIColor.yellow
        case .no:
            backgroundColor = UIColor.red
        case .yes:
            backgroundColor = UIColor.green
        }
        self.backgroundColor = backgroundColor
    }
}

class TotalCollectionViewCell: UICollectionViewCell {
    static let identifier: String = "\(TotalCollectionViewCell.self)"
    
    private let totalLabel: UILabel
    
    override init(frame: CGRect) {
        self.totalLabel = UILabel()
        self.totalLabel.textAlignment = .center
        
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.purple
        
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
    
    func update(total: Int, finished: Bool) {
        self.totalLabel.text = "\(total)"
        if finished {
            self.backgroundColor = .white
            self.totalLabel.font = UIFont.boldSystemFont(ofSize: 14)
            self.totalLabel.textColor = .black
        } else {
            self.backgroundColor = .purple
            self.totalLabel.font = UIFont.systemFont(ofSize: 14)
            self.totalLabel.textColor = .white
        }
    }
}
