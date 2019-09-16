import Foundation
import UIKit

class LoaderViewController: UIViewController {
    fileprivate var message: String?
    
    @IBOutlet weak var textLabel: UILabel!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var spinnerView: UIView! {
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
