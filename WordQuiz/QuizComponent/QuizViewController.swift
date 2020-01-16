import Foundation
import UIKit

internal enum QuizState {
    case running
    case stopped
}

class QuizViewController: UIViewController {
    
    @IBOutlet var mainContentView: UIView!
    
    //MARK: - Footer View Outlets
    @IBOutlet var progressLabel: UILabel!
    
    @IBOutlet var stateManagerButton: UIButton! {
        didSet {
            stateManagerButton.cornerRadius = 8
        }
    }
    
    @IBOutlet var timerLabel: UILabel!
    
    //MARK: - Header View Outlets
    @IBOutlet var questionTitleLabel: UILabel!
    
    @IBOutlet var wordsTextField: UITextField! {
        didSet {
            wordsTextField.delegate = self
            wordsTextField.cornerRadius = 8
            wordsTextField.layer.sublayerTransform = CATransform3DMakeTranslation(8, 0, 0)
        }
    }
    
    //MARK: - Other outlets
    @IBOutlet var tableView: UITableView! {
        didSet {
            tableView.dataSource = self
            tableView.allowsSelection = false
            tableView.tableFooterView = UIView()
        }
    }
    
    @IBOutlet var bottomViewConstraint: NSLayoutConstraint!
    
    //MARK: - Class Variables
    fileprivate lazy var loadingBuilder: LoadingProtocol = {
        let loadingView = LoadingBuilder()
        return loadingView
    }()
    
    // If this code was supposed to be used in different contexts, this view model could be injected instead of being instanciated here, this would help making this view more reusable.
    fileprivate var viewModel: QuizViewModel? = QuizViewModel()
    
    private static let timeInMinutes: TimeInterval = 5
    
    private var timer: QuizTimer = QuizTimer(timeLimit: QuizViewModel.timeInMinutes * 60)
    
    //MARK: - ViewController LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    private func setup() {
        mainContentView.alpha = 0
        
        registerForKeyboardNotifications()
        setupTimer()
        setupTextField()

        viewModel?.delegate = self
        viewModel?.initialize()
    }
    
    func setupTextField() {
        wordsTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }
    
    private func setupTimer() {
        timer.onUpdateTimer = { [weak self] (minutes, seconds) in
            DispatchQueue.main.async {
                self?.setTimer(withMinutes: minutes, andSeconds: seconds)
            }
        }
        
        timer.onTimerFinished = { [weak self] in
            DispatchQueue.main.async {
                self?.viewModel?.timerDidEnd()
            }
        }
        
        setTimer(withMinutes: Int(QuizViewController.timeInMinutes), andSeconds: 0)
    }
    
    @IBAction func didTouchStateManagerButton(_ sender: Any) {
        viewModel?.shouldChangeQuizState()
    }
    
    // MARK: - Private Methods
    private func stopQuiz(withLimit limit: Int) {
        tableView.reloadData()
        wordsTextField.resignFirstResponder()
        wordsTextField.text = ""
        setProgressWith(current: 0, andLimitOf: limit)
        stateManagerButton.setTitle("Start", for: .normal)
        timer.stopTimer()
        setTimer(withMinutes: Int(QuizViewController.timeInMinutes), andSeconds: 0)
    }
    
    private func startTimer() {
        timer.startTimer()
    }
}

//MARK: - TextField Delegate and Methods
extension QuizViewController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return viewModel?.state == .running
    }
}

//MARK: - Counter Progress Management
private extension QuizViewController {
    func setProgressWith(current progress: Int, andLimitOf limit: Int) {
        progressLabel.text = "\(progress)/\(limit)"
    }
}

private extension QuizViewController {
    func setTimer(withMinutes minutes: Int, andSeconds seconds: Int) {
        self.timerLabel.text = "\(String(format: "%.2d", minutes)):\(String(format: "%.2d", seconds))"
    }
}

//MARK: - TableView DataSource
extension QuizViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel?.hittenWords.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: WordTableViewCell.cellIdentifier, for: indexPath)
        if let cell = cell as? WordTableViewCell {
            let word = viewModel?.hittenWords[indexPath.row]
            cell.setWord(fromText: word)
        }
        return cell
    }
}


//MARK: - TableView Delegate
//extension QuizViewController: UITableViewDelegate {
//    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
//        return UIView()
//    }
//}

//MARK: - Keyboard Notification's Management
private extension QuizViewController {
    func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrameNotification), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillChangeFrameNotification(notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }
        let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        let endFrameY = endFrame?.origin.y ?? 0
        if endFrameY >= UIScreen.main.bounds.size.height {
            bottomViewConstraint.constant = 0.0
        } else {
            let size = endFrame?.size.height ?? 0.0
            if #available(iOS 11.0, *) {
                bottomViewConstraint.constant = size - view.safeAreaInsets.bottom
            } else {
                bottomViewConstraint.constant = size
            }
        }
        
        let curveRawNumber = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber
        let curveRaw = curveRawNumber?.uintValue ?? UIView.AnimationOptions.curveEaseInOut.rawValue
        let animationCurve = UIView.AnimationOptions(rawValue: curveRaw)
        
        let duration: TimeInterval = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
        UIView.animate(withDuration: duration, delay: 0, options: animationCurve, animations: { [weak self] in
            self?.view.layoutIfNeeded()
            }, completion: nil)
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if bottomViewConstraint.constant != 0 {
            bottomViewConstraint.constant = 0
        }
    }
}

// MARK: - Text Field
extension QuizViewController {
    @objc func textFieldDidChange(textField: UITextField) {
        guard let text = textField.text else { return }
        viewModel?.didUpdateTextField(withText: text)
    }
}

extension QuizViewController: QuizViewModelDelegate {
    func startQuiz() {
        DispatchQueue.main.async { [weak self] in
            self?.wordsTextField.becomeFirstResponder()
            self?.stateManagerButton.setTitle("Reset", for: .normal)
            self?.startTimer()
        }
    }
    
    func quizUpdated(questionTitle: String?, words: [String]?, error: AlertMessageModel?) {
        DispatchQueue.main.async { [weak self] in
            if let error = error {
                self?.showAlert(fromInfo: error) { [weak self] in
                    self?.viewModel?.initialize()
                }
                return
            }
            
            guard let words = words else {
                self?.viewModel?.initialize()
                return
            }
            
            self?.questionTitleLabel.text = questionTitle
            self?.mainContentView.alpha = 1
            self?.setProgressWith(current: 0, andLimitOf: words.count)
            self?.loadingBuilder.stopLoading()
        }
    }
    
    func onHittenWord(hittenWords: [String], words: [String]) {
        DispatchQueue.main.async { [weak self] in
            
            self?.tableView.reloadData()
            self?.setProgressWith(current: hittenWords.count,
                                  andLimitOf: words.count)
            self?.wordsTextField.text = ""
        }
    }
    
    func stopQuiz(wordsCount: Int) {
        DispatchQueue.main.async { [weak self] in
            self?.stopQuiz(withLimit: wordsCount)
        }
    }
    
    func quizFinished(alert: AlertMessageModel) {
        DispatchQueue.main.async { [weak self] in
            self?.wordsTextField.resignFirstResponder()
            self?.showAlert(fromInfo: alert) { [weak self] in
                self?.viewModel?.shouldChangeQuizState()
            }
        }
    }
}
