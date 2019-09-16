import Foundation
import UIKit

class QuizViewModel {
    
    var onQuizRefreshed: ((Quiz) -> Void)?
    var onRestartQuiz: (() -> Void)?
    var onHittenWord: ((String, [String]?) -> Void)?

    var onSuccessFinish: ((String) -> Void)?
    var onFailureFinish: ((String) -> Void)?
    
    var onInformationFailed: ((String?) -> Void)?

    private(set) var wordsDataSource: [String]? = {
        return [String]()
    }()
    
    private(set) var hittenWord = [String]()
    
    func didUpdateTextFieldText(withText text: String) {
        let hitten = self.hasHittenWord(withText: text)
        if hitten {
            onHittenWord?(text, wordsDataSource)
        }
        debugPrint(hitten)
    }
    
    func hasHittenWord(withText text: String) -> Bool {
        return wordsDataSource?.contains(text) ?? false
    }
    
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

class QuizTimer {
    var displayLink: CADisplayLink?
    
    func initTimer() {
        displayLink = CADisplayLink(target: self, selector: #selector(timer))
        displayLink?.add(to: RunLoop.main, forMode: RunLoop.Mode.default)
    }
    
    let quizStartDate = Date()
    let fiveMinutes = Date(timeInterval: 5 * 60, since: Date())
    
    var onTimerUpdate: ((/*???*/) -> Void)?

    @objc func timer() {
        let difference = quizStartDate.timeIntervalSinceNow
        let newDate = fiveMinutes.addingTimeInterval(difference)
        let timeInterval = newDate.timeIntervalSinceNow
        let minutes = Int(timeInterval / 60)
        let seconds = Int(60 + difference)
        debugPrint("Diff: \(difference)")
        debugPrint("Time: \(timeInterval)")
        debugPrint("Min: \(minutes)")
        debugPrint("Sec: \(seconds)")
        
        if Date() > fiveMinutes {
            debugPrint("Logica de terminar o timer")
            displayLink?.invalidate()
        }
        
        debugPrint("---- Date: \(Date())")
    }
}
