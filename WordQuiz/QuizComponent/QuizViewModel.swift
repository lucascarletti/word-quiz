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

protocol QuizViewModelDelegate: class {
    func quizUpdated(questionTitle: String?, words: [String]?, error: AlertMessageModel?)
    
    func onHittenWord(hittenWords: [String], words: [String])
    
    func startQuiz()
    func stopQuiz(wordsCount: Int)
    
    func quizFinished(alert: AlertMessageModel)
}

class QuizViewModel {
    static let timeInMinutes: TimeInterval = 5
    
    private(set) var state: QuizState = .stopped {
        didSet {
            quizStateUpdated(newState: state)
        }
    }
    
    private(set) var wordsDataSource = [String]()
    
    private(set) var hittenWords = [String]()
    
    private let service: QuizServiceProtocol
    
    weak var delegate: QuizViewModelDelegate?
    
    init(service: QuizServiceProtocol = QuizService()) {
        self.service = service
    }
    
    // MARK : - Public methods
    func initialize() {
        // NOTE: Current index has default value 1 as we only have a single quiz on our API
        let endPoint = QuizEndPoint.questions(ofIndex: 1)
        service.getQuestions(endPoint: endPoint) { [weak self] quiz, errorMessage in
            self?.handleAPIResponse(quiz: quiz, errorMessage: errorMessage)
        }
    }
    
    func didUpdateTextField(withText text: String) {
        let hasHitten = hasHittenWord(withText: text)
        
        if hasHitten && !hittenWords.contains(text) {
            hittenWords.insert(text, at: 0)
            delegate?.onHittenWord(hittenWords: hittenWords, words: wordsDataSource)
            validateQuizCompletion()
        }
    }
    
    func shouldChangeQuizState() {
        switch state {
        case .running:
          self.state = .stopped
        case .stopped:
          self.state = .running
        }
    }
    
    func timerDidEnd() {
        let hitten = hittenWords.count
        let total = wordsDataSource.count
        
        let alertModel = AlertMessageModel(title: "Time finished!",
                                           message: "Sorry! Time is up. You got \(hitten) out of \(total)",
                                           buttonTitle: "Try Again")
        delegate?.quizFinished(alert: alertModel)
    }
    
    // MARK: - Private methods
    private func hasHittenWord(withText text: String) -> Bool {
        return wordsDataSource.contains(text)
    }
    
    private func quizStateUpdated(newState: QuizState) {
        switch newState {
        case .running:
            delegate?.startQuiz()
            
        case .stopped:
            hittenWords.removeAll()
            delegate?.stopQuiz(wordsCount: wordsDataSource.count)
        }
    }
    
    private func validateQuizCompletion() {
        if hittenWords.count == wordsDataSource.count, !wordsDataSource.isEmpty {
            let alertModel = AlertMessageModel(title: "Congratulations",
                                               message: "Good job! You found all the answers on time. Keep up with great work.",
                                               buttonTitle: "Play Again")
            delegate?.quizFinished(alert: alertModel)
        }
    }
    
    private func handleAPIResponse(quiz: Quiz?, errorMessage: String?) {
        if let errorMessage = errorMessage {
            delegate?.quizUpdated(questionTitle: nil,
                                  words: nil,
                                  error: (AlertMessageModel(title: "Ops",
                                                            message: errorMessage,
                                                            buttonTitle: "Try Again")))
            
        } else if let quiz = quiz, let answer = quiz.answer {
            wordsDataSource = answer
            delegate?.quizUpdated(questionTitle: quiz.question,
                                  words: answer,
                                  error: nil)
            
        } else {
            delegate?.quizUpdated(questionTitle: nil,
                                  words: nil,
                                  error: (AlertMessageModel(title: "Ops",
                                                            message: "Something went wrong",
                                                            buttonTitle: "Try Again")))
        }
    }
}
