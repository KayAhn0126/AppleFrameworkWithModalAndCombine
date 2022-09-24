//
//  FrameworkDetailViewController.swift
//  AppleFrameworkWithModalAndCombine
//
//

import UIKit
import SafariServices

class FrameworkDetailViewController: UIViewController {

    var selectedApp: AppleFramework = AppleFramework(name: "", imageName: "", urlString: "", description: "")
    
    @IBOutlet weak var appImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var learnMoreButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
    }
    
    func updateUI() {
        appImageView.image = UIImage(named: selectedApp.imageName)
        titleLabel.text = selectedApp.name
        descriptionLabel.text = selectedApp.description
    }
    
    @IBAction func learnMoreButtonTapped(_ sender: UIButton) {
        guard let url = URL(string: selectedApp.urlString) else { return}
        let safari = SFSafariViewController(url: url)
        present(safari, animated: true)
    }
}
