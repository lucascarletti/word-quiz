import Foundation
import UIKit

internal enum QuizState {
    case runing
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
        }
    }
    
    @IBOutlet var bottomViewConstraint: NSLayoutConstraint!
    
    var state: QuizState? {
        didSet {
            guard let state = state else { return }
            refreshQuizState(from: state)
        }
    }
    
    //MARK: - Class Variables
    
    private var viewModel: QuizViewModel? = {
        return QuizViewModel()
    }()
    
    var hittenWordsDataSource: [String]?  = {
        return [String]()
    }()
    
    //MARK: - ViewController LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    func setup() {
        self.state = .stopped
        self.mainContentView.alpha = 0
        setQuizManagerButtonTitle(fromState: .stopped)
        
        registerForKeyboardNotifications()
        registerViewModelCallBacks()
        
        viewModel?.initialize()
    }

    func registerViewModelCallBacks() {
        viewModel?.onQuizRefreshed = { [weak self] quiz in
            guard let quizAnswers = quiz.answer else { return }

            DispatchQueue.main.sync { [weak self] in
                self?.questionTitleLabel.text = quiz.question
                self?.setProgressWith(current: 0, andLimitOf: quizAnswers.count)
                self?.mainContentView.alpha = 1
            }
        }
        
        viewModel?.onHittenWord = { [weak self] (hittenWord, wordsDataSource) in
            guard let wordsDataSource = wordsDataSource else { return }
            
            self?.hittenWordsDataSource?.append(hittenWord)
            self?.tableView.reloadData()
            self?.setProgressWith(current: self?.hittenWordsDataSource?.count ?? 1, andLimitOf: wordsDataSource.count)
            self?.wordsTextField.text = ""
        }
        
    }
    
    func refreshQuizState(from state: QuizState) {
        setQuizManagerButtonTitle(fromState: state)
        switch state {
        case .runing:
            setRuningState()
            
        case .stopped:
            setStoppedState()
        }
    }
    
    @IBAction func didTouchStateManagerButton(_ sender: Any) {
        guard let state = state else { return }
        switch state {
        case .runing:
            self.state = .stopped
        case .stopped:
            self.state = .runing
        }
    }
}

//MARK: - TextField Delegate and Methods
extension QuizViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if self.state == .stopped {
            setStoppedState()
            return false
        }
        
        if let text = textField.text, let textRange = Range(range, in: text) {
            let updatedText = text.replacingCharacters(in: textRange, with: string)
            viewModel?.didUpdateTextFieldText(withText: updatedText)
        }
        return true
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return self.state == .runing
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

//MARK: - TableView DataSource
extension QuizViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return hittenWordsDataSource?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: WordTableViewCell.cellIdentifier) as? WordTableViewCell else {
            return UITableViewCell()
        }
        
        guard let word = hittenWordsDataSource?[indexPath.row] else { return UITableViewCell() }
        cell.setWord(fromText: word)
        return cell
    }
}

//MARK: - Keyboard Notification's Management
extension QuizViewController {
    func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrameNotification), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillChangeFrameNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            let endFrameY = endFrame?.origin.y ?? 0
            let duration:TimeInterval = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIView.AnimationOptions.curveEaseInOut.rawValue
            let animationCurve:UIView.AnimationOptions = UIView.AnimationOptions(rawValue: animationCurveRaw)
            if endFrameY >= UIScreen.main.bounds.size.height {
                self.bottomViewConstraint.constant = 0.0
            } else {
                let size = endFrame?.size.height ?? 0.0
                self.bottomViewConstraint.constant = size - 40
            }
            UIView.animate(withDuration: duration,
                           delay: TimeInterval(0),
                           options: animationCurve,
                           animations: { self.view.layoutIfNeeded() },
                           completion: nil)
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if bottomViewConstraint.constant != 0 {
            bottomViewConstraint.constant = 0
        }
    }
}

//MARK: - Counter Progress Management
extension QuizViewController {
    func resetProgress(withMaximumProgressOf limit: Int) {
        progressLabel.text = "0/\(limit)"
    }
    
    func setProgressWith(current progress: Int, andLimitOf limit: Int) {
        progressLabel.text = "\(progress)/\(limit)"
    }
}

//MARK: - Timer Progress Management

//MARK: - Reset/Start Button Management

extension QuizViewController {
    func setQuizManagerButtonTitle(fromState state: QuizState) {
        var buttonTitle: String?
        
        switch state {
        case .runing:
            buttonTitle = "Reset"
        case .stopped:
            buttonTitle = "Start"
        }
        
        guard let btnTitle = buttonTitle else { return }

        stateManagerButton.setTitle(btnTitle, for: .normal)
    }
}

//MARK: - Quiz State Manager

extension QuizViewController {
    func setStoppedState() {
        self.hittenWordsDataSource?.removeAll()
        self.tableView.reloadData()
        self.wordsTextField.resignFirstResponder()
        self.wordsTextField.text = ""
        self.setProgressWith(current: 0, andLimitOf: 50)
    }
    
    func setRuningState() {
        
    }
    
    func setSuccessfullFinishState() {
        
    }
    
    func setFailureFinishState(){
        
    }
}
