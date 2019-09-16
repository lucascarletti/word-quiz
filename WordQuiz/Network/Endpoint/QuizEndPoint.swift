import Foundation

public enum QuizEndPoint {
    case getQuestion(ofIndex: Int)
    
    static let router = Router<QuizEndPoint>()
}

extension QuizEndPoint: EndPointType {
    var baseURL: URL {
        guard let url = URL(string: "https://codechallenge.arctouch.com") else { fatalError("baseURL could not be configured.")}
        return url
    }
    
    var path: String {
        switch self {
        case .getQuestion(let index):
            return "/quiz/\(index)"
        }
    }
    
    var httpMethod: HTTPMethod {
        switch self {
        case .getQuestion:
            return .get
        }
    }
    
    var task: HTTPTask {
        switch self {
        case .getQuestion:
            return .request
        }
    }
    
    var headers: HTTPHeaders? {
        return nil
    }
}
