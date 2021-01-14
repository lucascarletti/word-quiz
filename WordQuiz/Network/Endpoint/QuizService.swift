import Foundation

protocol QuizServiceProtocol {
    func getQuestions(endPoint: QuizEndPoint, completion: ((Quiz?, String?) -> Void)?)
}

struct QuizService: QuizServiceProtocol {
    private let router = Router()
    
    func getQuestions(endPoint: QuizEndPoint, completion: ((Quiz?, String?) -> Void)?) {
        router.request(endPoint) { (data, response, error) in
            if error != nil {
                completion?(nil, NetworkResponse.connectionError.rawValue)
            } else if let httpResponse = response as? HTTPURLResponse, let data = data {
                let result = NetworkManager.handleNetworkResponse(httpResponse)
                switch result {
                case .success:
                    do {
                        let quiz = try JSONDecoder().decode(Quiz.self, from: data)
                        completion?(quiz, nil)
                    } catch {
                        completion?(nil, NetworkResponse.unableToDecode.rawValue)
                    }
                case .failure(let errorMessage):
                    completion?(nil, errorMessage)
                }
            } else {
                completion?(nil, NetworkResponse.noData.rawValue)
            }
        }
    }
}
