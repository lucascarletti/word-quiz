import UIKit

protocol LoadingProtocol {
    func startLoading()
    func stopLoading()
}

class LoadingBuilder: NSObject {
    
    @objc private dynamic var alertWindow: UIWindow?
    
    private var message: String? = "Loading...\n\n"
    private var viewController: UIViewController?
    
    func message(_ message: String?) -> LoadingBuilder {
        self.message = message
        return self
    }
    
    func build() -> UIViewController? {
        let storyboard = UIStoryboard.init(name: "Quiz", bundle: nil)
        viewController = storyboard.instantiateViewController(withIdentifier: "LoaderViewController")
        if let loader = viewController as? LoaderViewController {
            loader.setup(message: message)
        }
        return viewController
    }
    
    func show() {
        alertWindow = UIWindow(frame: UIScreen.main.bounds)
        alertWindow?.rootViewController = UIViewController()
        // Move it to the top
        let topWindow = UIApplication.shared.windows.last
        alertWindow?.windowLevel = (topWindow?.windowLevel ?? UIWindow.Level(rawValue: UIWindow.Level.RawValue(0))) + 1
        // and present it
        alertWindow?.makeKeyAndVisible()
        if let alertController = build() {
            alertWindow?.rootViewController?.present(alertController, animated: true, completion: nil)
        }
    }
    
    func hide() {
        viewController?.dismiss(animated: false, completion: nil)
        viewController = nil
        alertWindow?.isHidden = true
        alertWindow = nil
    }
}

extension LoadingBuilder: LoadingProtocol {
    func startLoading() {
        DispatchQueue.main.async {
            self.show()
        }
    }
    func stopLoading() {
        DispatchQueue.main.async {
            self.hide()
        }
    }
}
