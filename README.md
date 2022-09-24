# AppleFrameworkWithModalAndCombine

## 🍎 작동 화면
| 작동 화면 | 
| :-: | 
| ![](https://i.imgur.com/0YmtRoG.gif) | 

## 🍎 기존 AppleFrameworkWithModal 프로젝트에서 바뀐점
- 기존 프로젝트에서는 아이템이 클릭이 되거나, 화면을 구성할 때그에 맞는 함수들이 호출되는 형식이였다.
- 이번 프로젝트는 Combine으로 데이터가 들어오면 이미 만들어진 파이프라인을 통해 처리하는 방식으로 구현했다. 

## 🍎 첫 화면 (Grid 형태) 코드 분석
```swift
// 프로젝트 내 FrameworkViewController.swift

import UIKit
import Combine

enum Section {
    case main
}

class FrameworkViewController: UIViewController {
    // ... (중략) ...

    var selectedFramework = PassthroughSubject<AppleFramework, Never>() 
    // 선택 되었을때 값을 방출할 퍼블리셔
    
    var frameworkListPublisher = CurrentValueSubject<[AppleFramework], Never>(AppleFramework.list)
    // 화면을 구성하는 퍼블리셔. 현재 프로젝트에서는 값이 바뀔일이 없어 퍼블리셔로 만들지 않아도 되지만,
    // 컴바인 연습 목적으로 파이프라인을 구축해 업스트림의 데이터가 들어올때마다 자동으로 업데이트 할 수 있게 만들어봄.
    
    var subscriptions = Set<AnyCancellable>() // 구독권을 저장하기 위함.
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bind() // 화면이 띄워짐과 동시에 파이프라인 구축
        collectionView.delegate = self
        collectionView.collectionViewLayout = layout()
    }
    
    private func bind() {
        // - 아이템이 선택 되었을때 처리
        selectedFramework
            .receive(on: RunLoop.main)
            .sink { [unowned self] framework in
            let storyboard = UIStoryboard(name: "Detail", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "FrameworkDetailViewController") as! FrameworkDetailViewController
            vc.selectedApp.send(framework)
            // 디테일 뷰에서 받는 프로퍼티 또한 퍼블리셔이므로 send 메서드 사용
            
            self.present(vc, animated: true)
        }.store(in: &subscriptions)
        
        // - items가 세팅 되었을때 collectionView 업데이트
        
        frameworkListPublisher
            .receive(on: RunLoop.main)
            .sink { [unowned self] list in
                self.configureCollectionView() // cell 구성
                self.applyItemsToSection(list) // snapshot 구성 후 datasource에 적용
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
        // ... (중략) ...
    }
}

extension FrameworkViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let framework = frameworkListPublisher.value[indexPath.item]
        print(">>> selected: \(framework.name)")
        selectedFramework.send(framework) // 선택된 데이터를 퍼블리셔에 보냄
    }
}
```

## 🍎 상세 설명 화면 코드 분석 
```swift
// 프로젝트 내 FrameworkDetailViewController.swift
import UIKit
import Combine
import SafariServices

class FrameworkDetailViewController: UIViewController {

    var buttonTapped = PassthroughSubject<AppleFramework, Never>() 
    // learn more 버튼이 클릭 되었을 때 데이터를 방출할 퍼블리셔
    var selectedApp = CurrentValueSubject<AppleFramework, Never>(AppleFramework(name: "", imageName: "", urlString: "", description: ""))
    // 이전 VC에서 값을 넘겨받을 퍼블리셔. -> bind()가 되자마자 바로 데이터 방출
    var subscriptions = Set<AnyCancellable>()
    
    // ... (중략) ...
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
    }
    
    private func bind() {
        // input -> 사용자 입력
        buttonTapped
            .receive(on: RunLoop.main)
            .compactMap { URL(string: $0.urlString)} // string으로 URL을 만들수 있는지 확인
            .sink { [unowned self] url in
                let safari = SFSafariViewController(url: url)
                self.present(safari, animated: true)
            }.store(in: &subscriptions)
        
        // output -> 데이터 변경으로 인한 UI업데이트
        selectedApp
            .receive(on: RunLoop.main)
            .sink { [unowned self] selectedAppData in
                self.updateUI(selectedAppData)
            }.store(in: &subscriptions)
    }
    
    private func updateUI(_ data: AppleFramework) {
        appImageView.image = UIImage(named: data.imageName)
        titleLabel.text = data.name
        descriptionLabel.text = data.description
    }
    
    @IBAction func learnMoreButtonTapped(_ sender: UIButton) {
        buttonTapped.send(selectedApp.value)
        // value는 퍼블리셔 클래스의 프로퍼티이고 value의 정의부에 들어가면 아래와 같은 코드를 볼 수 있다.
        // The value wrapped by this subject, published as a new element whenever it changes.
        // final public var value: Output
        // 즉 value는 Output 타입이니 결국 selectedApp = CurrentValueSubject<AppleFramework, Never>에서의 Output 타입인 AppleFramework를 의미한다.
    }
}
```
