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
            tableView.delegate = self
            tableView.dataSource = self
            tableView.allowsSelection = false
        }
    }
    
    @IBOutlet var bottomViewConstraint: NSLayoutConstraint!
        
    //MARK: - Class Variables
    fileprivate lazy var loadingBuilder: LoadingProtocol = {
        let loadingView = AlertControllerBuilder()
        return loadingView
    }()
    
    fileprivate var viewModel: QuizViewModel? = QuizViewModel()
    
    private static let timeInMinutes: TimeInterval = 5
    
    private var timer: QuizTimer = QuizTimer(timeLimit: QuizViewController.timeInMinutes * 60)

    //MARK: - ViewController LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    private func setup() {
        loadingBuilder.startLoading()
        mainContentView.alpha = 0
        
        registerForKeyboardNotifications()
        registerViewModelCallBacks()
        setupTimer()
        
        viewModel?.initialize()
    }

    private func registerViewModelCallBacks() {
        viewModel?.onInformationChanged = { [weak self] (questionTitle, word) in
            DispatchQueue.main.async {
                self?.questionTitleLabel.text = questionTitle
                self?.setProgressWith(current: 0, andLimitOf: word.count)
                self?.mainContentView.alpha = 1
                self?.loadingBuilder.stopLoading()
            }
        }
        
        viewModel?.onInformationFailed = { [weak self] alertInfo in
            DispatchQueue.main.async {
                self?.showAlert(fromInfo: alertInfo) {
                    self?.viewModel?.initialize()
                }
            }
        }
        
        viewModel?.onHittenWord = { [weak self] (hittenWords, words) in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
                self?.setProgressWith(current: hittenWords.count,
                                      andLimitOf: words.count)
                self?.wordsTextField.text = ""
            }
        }
        
        viewModel?.onQuizStart = { [weak self] in
            DispatchQueue.main.async {
                self?.startQuiz()
            }
        }
        
        viewModel?.onQuizStopped = { [weak self] words in
            DispatchQueue.main.async {
                self?.stopQuiz(withLimit: words.count)
            }
        }
        
        viewModel?.onSuccessFinish = { [weak self] alertInfo in
            DispatchQueue.main.async {
                self?.wordsTextField.resignFirstResponder()
            
                self?.showAlert(fromInfo: alertInfo) {
                    self?.viewModel?.shouldChangeQuizState()
                }
            }
        }
        
        viewModel?.onFailureFinish = { [weak self] alertInfo in
            DispatchQueue.main.async { [weak self] in
                self?.wordsTextField.resignFirstResponder()
                self?.showAlert(fromInfo: alertInfo) {
                    self?.viewModel?.shouldChangeQuizState()
                }
            }
        }
    }
    
    private func setupTimer() {
        timer.onUpdateTimer = { [weak self] (minutes, seconds) in
            DispatchQueue.main.async { [weak self] in
                self?.setTimer(withMinutes: minutes, andSeconds: seconds)
            }
        }
        
        timer.onTimerFinished = { [weak self] in
            self?.viewModel?.timerDidEnd()
        }
        
        self.setTimer(withMinutes: Int(QuizViewController.timeInMinutes), andSeconds: 0)
    }

    @IBAction func didTouchStateManagerButton(_ sender: Any) {
        viewModel?.shouldChangeQuizState()
    }
    
    // MARK: - Private Methods
    private func startQuiz() {
        wordsTextField.becomeFirstResponder()
        stateManagerButton.setTitle("Reset", for: .normal)
        startTimer()
    }
    
    private func stopQuiz(withLimit limit: Int) {
        tableView.reloadData()
        wordsTextField.resignFirstResponder()
        wordsTextField.text = ""
        setProgressWith(current: 0, andLimitOf: limit)
        stateManagerButton.setTitle("Start", for: .normal)
        setTimer(withMinutes: Int(QuizViewController.timeInMinutes), andSeconds: 0)
        timer.stopTimer()
    }
    
    private func startTimer() {
        timer.startTimer()
    }
}

//MARK: - TextField Delegate and Methods
extension QuizViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if let text = textField.text, let textRange = Range(range, in: text) {
            let updatedText = text.replacingCharacters(in: textRange, with: string)
            let shouldReplace = viewModel?.shouldAllowTextFieldReplacementString(fromText: updatedText) ?? true
            
            viewModel?.didUpdateTextField(withText: updatedText)
            return shouldReplace
        }
        
        return true
    }
    
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
extension QuizViewController: UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
}

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
