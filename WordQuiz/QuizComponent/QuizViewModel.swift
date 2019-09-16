import Foundation
import UIKit

class QuizViewModel {
    
    var timer: QuizTimer?
    
    var onQuizRefreshed: ((Quiz) -> Void)?
    var onRestartQuiz: (() -> Void)?
    var onHittenWord: ((String, [String]?) -> Void)?

    var onSuccessFinish: ((String) -> Void)?
    var onFailureFinish: ((String) -> Void)?
    
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
    
    private(set) var hittenWord = [String]()
    
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
        let hitten = self.hasHittenWord(withText: text)
        if hitten {
            onHittenWord?(text, wordsDataSource)
        }
    }
    
    func hasHittenWord(withText text: String) -> Bool {
        return wordsDataSource?.contains(text) ?? false
    }
    
    func quizStateUpdated(newState state: QuizState) {
        switch state {
        case .runing:
            onQuizStart?()
        
        case .stopped:
            onQuizStopped?()
            
        }
    }
    
    func didTouchStateManagerButton() {
        if let state = state {
            switch state {
            case .runing:
                self.state = .stopped
            case .stopped:
                self.state = .runing
            }
        } else {
            //this case means that state has not yet initialized, as it starts in a "stopped" state, we can start runing quiz once it's nil and hitted
            self.state = .runing
        }
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
