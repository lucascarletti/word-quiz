import Foundation
import UIKit

extension UIViewController {
    func showAlert(fromInfo info: AlertMessageModel, onCompletion: (() -> Void)?) {
        
        let alert = UIAlertController(title: info.title, message: info.message, preferredStyle: .alert)
        let action = UIAlertAction(title: info.buttonTitle, style: .default, handler: { action in
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
