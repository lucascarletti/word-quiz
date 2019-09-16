import Foundation
import UIKit

extension UIViewController {
    func showAlert(withTitle title: String, message: String, buttonTitle: String, onCompletion: (() -> Void)?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: buttonTitle, style: .default, handler: { action in
            switch action.style {
            case .default:
                onCompletion?()
            default:
                alert.dismiss(animated: true, completion: nil)
            }
        })
        
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)
    }
}
