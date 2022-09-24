//
//  ViewController.swift
//  AppleFrameworkWithModalAndCombine
//
//

import UIKit
import Combine

enum Section {
    case main
}

class FrameworkViewController: UIViewController {
    typealias Item = AppleFramework
    var dataSource: UICollectionViewDiffableDataSource<Section, Item>!
    
    @IBOutlet weak var collectionView: UICollectionView!

    var selectedFramework = PassthroughSubject<AppleFramework, Never>()
    var frameworkListPublisher = CurrentValueSubject<[AppleFramework], Never>(AppleFramework.list)
    
    var subscriptions = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
        collectionView.delegate = self
        collectionView.collectionViewLayout = layout()
    }
    
    private func bind() {
        // input -> 사용자 입력을 받아서 처리
        // - 아이템 선택 되었을때 처리
        selectedFramework
            .receive(on: RunLoop.main)
            .sink { [unowned self] framework in
            let storyboard = UIStoryboard(name: "Detail", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "FrameworkDetailViewController") as! FrameworkDetailViewController
                vc.selectedApp.send(framework)
            self.present(vc, animated: true)
        }.store(in: &subscriptions)
        
        // output -> data, state에 따라서 UI 업데이트
        // - items가 세팅 되었을때 collectionView 업데이트
        
        frameworkListPublisher
            .receive(on: RunLoop.main)
            .sink { [unowned self] list in
                self.configureCollectionView()
                self.applyItemsToSection(list)
            }.store(in: &subscriptions)
    }
    
    private func applyItemsToSection(_ items: [Item], section: Section = .main) {
        var snapshot = NSDiffableDataSourceSnapshot<Section,Item>()
        snapshot.appendSections([section])
        snapshot.appendItems(items, toSection: section)
        dataSource.apply(snapshot)
    }
    
    private func configureCollectionView() {
        dataSource = UICollectionViewDiffableDataSource<Section,Item>(collectionView: collectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FrameworkCollectionViewCell", for: indexPath) as? FrameworkCollectionViewCell else {
                return nil
            }
            cell.configure(itemIdentifier)
            return cell
        })
    }
    
    private func layout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.33), heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalWidth(0.33))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 3)
        
        let section = NSCollectionLayoutSection(group: group)
        
        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }
}

extension FrameworkViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let framework = frameworkListPublisher.value[indexPath.item]
        print(">>> selected: \(framework.name)")
        selectedFramework.send(framework)
    }
}

