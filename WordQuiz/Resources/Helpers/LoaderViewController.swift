import Foundation
import UIKit

class LoaderViewController: UIViewController {
    
    fileprivate var message: String?
    
    @IBOutlet var textLabel: UILabel!
    
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet var spinnerView: UIView! {
        didSet {
            spinnerView.cornerRadius = 8
        }
    }
    
    func setup(message: String?) {
        self.message = message
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textLabel.text = message
    }
}
