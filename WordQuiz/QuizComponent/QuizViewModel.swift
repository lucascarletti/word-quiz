import Foundation
import UIKit

struct AlertMessageModel {
    let title: String
    let message: String
    let buttonTitle: String
    
    init(title: String, message: String, buttonTitle: String) {
        self.title = title
        self.message = message
        self.buttonTitle = buttonTitle
    }
}

class QuizViewModel {
    
    /// when quiz is received from API
    var onInformationChanged: ((String?, [String]) -> Void)?
    var onInformationFailed: ((AlertMessageModel) -> Void)?

    var onHittenWord: (([String], [String]) -> Void)?

    var onSuccessFinish: ((AlertMessageModel) -> Void)?
    var onFailureFinish: ((AlertMessageModel) -> Void)?

    var onQuizStart: (() -> Void)?
    var onQuizStopped: (([String]) -> Void)?

    private(set) var state: QuizState? {
        didSet {
            guard let state = state else { return }
            quizStateUpdated(newState: state)
        }
    }

    private(set) var wordsDataSource = [String]()
    
    private(set) var hittenWords = [String]()
    
    private let service: QuizServiceProtocol
    
    init(service: QuizServiceProtocol = QuizService()) {
        self.service = service
    }
    
    // MARK : - Public methods
    func initialize() {
        // NOTE: Current index has default value 1 as we only have a single quiz on our API
        let endpoint = QuizEndPoint.questions(ofIndex: 1)
        service.getQuestions(endpoint: endpoint) { [weak self] quiz, errorMessage in
            if let errorMessage = errorMessage {
                self?.onInformationFailed?(AlertMessageModel(title: "Ops",
                                                             message: errorMessage,
                                                             buttonTitle: "Try Again"))
            } else if let quiz = quiz, let answer = quiz.answer {
                self?.wordsDataSource = answer
                self?.onInformationChanged?(quiz.question, answer)
                //todo: on success, remove loader spinning, update tableView and let user start
            } else {
                self?.onInformationFailed?(AlertMessageModel(title: "Ops",
                                                             message: "Something went wrong",
                                                             buttonTitle: "Try Again"))
            }
        }
    }
    
    func didUpdateTextField(withText text: String) {
        let hasHitten = hasHittenWord(withText: text)
        
        if hasHitten && !hittenWords.contains(text) {
            hittenWords.insert(text, at: 0)
            onHittenWord?(hittenWords, wordsDataSource)
            validateQuizCompletion()
        }
    }
    
    func shouldAllowTextFieldReplacementString(fromText text: String) -> Bool {
        let hasHitten = hasHittenWord(withText: text)
        if hasHitten && !hittenWords.contains(text) {
            return false
        }
        
        return true
    }
    
    func shouldChangeQuizState() {
        if let state = state {
            switch state {
            case .running:
                self.state = .stopped
            case .stopped:
                self.state = .running
            }
        } else {
            //this else case means that, state has not yet initialized, as it starts in a "stopped" state, we can start running quiz once it's nil and hitted
            self.state = .running
        }
    }
    
    func timerDidEnd() {
        let hitten = hittenWords.count
        let total = wordsDataSource.count
        
        let alertModel = AlertMessageModel(title: "Time finished!",
                                           message: "Sorry! Time is up. You got \(hitten) out of \(total)",
            buttonTitle: "Try Again")
        onFailureFinish?(alertModel)
    }
    
    // MARK: - Private methods
    private func hasHittenWord(withText text: String) -> Bool {
        return wordsDataSource.contains(text)
    }
    
    private func quizStateUpdated(newState state: QuizState) {
        switch state {
        case .running:
            onQuizStart?()
            
        case .stopped:
            hittenWords.removeAll()
            onQuizStopped?(wordsDataSource)
        }
    }
    
    private func validateQuizCompletion() {
        if hittenWords.count == wordsDataSource.count, !wordsDataSource.isEmpty {
            let alertModel = AlertMessageModel(title: "Congratulations",
                                               message: "Good job! You found all the answers on time. Keep up with great work.",
                                               buttonTitle: "Play Again")
            onSuccessFinish?(alertModel)
        }
    }
}
