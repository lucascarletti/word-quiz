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
    
    var timer: QuizTimer?
    
    var onQuizRefreshed: ((Quiz) -> Void)?
    var onRestartQuiz: (() -> Void)?
    var onHittenWord: ((String, [String]?) -> Void)?

    var onSuccessFinish: ((AlertMessageModel) -> Void)?
    var onFailureFinish: ((AlertMessageModel) -> Void)?
    
    var onQuizStart: (() -> Void)?
    var onQuizStopped: (() -> Void)?
    
    var onInformationFailed: ((String?) -> Void)?

    private(set) var state: QuizState? {
        didSet {
            guard let state = state else { return }
            quizStateUpdated(newState: state)
        }
    }

    private(set) var wordsDataSource: [String]? = {
        return [String]()
    }()
    
    private(set) var hittenWords = [String]()
    
    func initialize() {
        getQuiz { [weak self] quiz, errorMessage in
            guard let quiz = quiz, let answer = quiz.answer else {
                return
            }
            
            self?.wordsDataSource = answer
            self?.onQuizRefreshed?(quiz)
            //todo: on success, remove loader spinning, update tableView and let user start
        }
    }
    
    func didUpdateTextFieldText(withText text: String) {
        let hasHittenWord = self.hasHittenWord(withText: text)
        
        if hasHittenWord && !hittenWords.contains(text) {
            hittenWords.append(text)
            onHittenWord?(text, wordsDataSource)
            validateQuizCompletion()
        }
    }
    
    func shouldAllowTextFieldReplacementString(fromText text: String) -> Bool {
        let hasHittenWord = self.hasHittenWord(withText: text)
        if hasHittenWord && !hittenWords.contains(text) {
            return false
        }
        
        return true
    }
    
    func hasHittenWord(withText text: String) -> Bool {
        return wordsDataSource?.contains(text) ?? false
    }
    
    func quizStateUpdated(newState state: QuizState) {
        switch state {
        case .runing:
            onQuizStart?()
        
        case .stopped:
            hittenWords.removeAll()
            onQuizStopped?()
        }
    }
    
    func shouldChangeQuizState() {
        if let state = state {
            switch state {
            case .runing:
                self.state = .stopped
            case .stopped:
                self.state = .runing
            }
        } else {
            //this else case means that, state has not yet initialized, as it starts in a "stopped" state, we can start runing quiz once it's nil and hitted
            self.state = .runing
        }
    }
    
    func validateQuizCompletion() {
        if hittenWords.count == wordsDataSource?.count {
            let alertModel = AlertMessageModel(title: "Congratulations",
                                               message: "Good job! You found all the answers on time. Keep up with great work.",
                                               buttonTitle: "Play Again")
            onSuccessFinish?(alertModel)
        }
    }
    
    func timerDidEnd() {
        let hitten = hittenWords.count
        let total = wordsDataSource?.count ?? 0
        
        let alertModel = AlertMessageModel(title: "Time finished!",
                                           message: "Sorry! Time is up. You got \(hitten) out of \(total)",
                                           buttonTitle: "Try Again")
        onSuccessFinish?(alertModel)
    }
}

//MARK: - Network Management
extension QuizViewModel {
    // MARK: - Request Quiz from API
    // current index has default value 1 as we only have a single quiz on our API
    func getQuiz(ofIndex index: Int = 1, completion: @escaping (_ quiz: Quiz?, _ error: String?) -> ()) {
        QuizEndPoint.router.request(.getQuestion(ofIndex: index)) { data, response, error in
            if error != nil {
                completion(nil, NetworkResponse.connectionError.rawValue)
            } else if let httpResponse = response as? HTTPURLResponse, let data = data {
                let result = NetworkManager.handleNetworkResponse(httpResponse)
                switch result {
                case .success:
                    do {
                        let quiz = try JSONDecoder().decode(Quiz.self, from: data)
                        completion(quiz, nil)
                    } catch {
                        completion(nil, NetworkResponse.unableToDecode.rawValue)
                    }
                case .failure(let errorMessage):
                    completion(nil, errorMessage)
                }
            } else {
                completion(nil, NetworkResponse.noData.rawValue)
            }
        }
    }
}
