//
//  FrameworkDetailViewController.swift
//  AppleFrameworkWithModalAndCombine
//
//

import UIKit
import Combine
import SafariServices

class FrameworkDetailViewController: UIViewController {

    var buttonTapped = PassthroughSubject<AppleFramework, Never>()
    var selectedApp = CurrentValueSubject<AppleFramework, Never>(AppleFramework(name: "", imageName: "", urlString: "", description: ""))
    var subscriptions = Set<AnyCancellable>()
    
    @IBOutlet weak var appImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var learnMoreButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
    }
    
    private func bind() {
        // input -> 사용자 입력
        buttonTapped
            .receive(on: RunLoop.main)
            .compactMap { URL(string: $0.urlString)}
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
    }
}
