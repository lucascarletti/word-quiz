import Foundation

public enum QuizEndPoint {
    case questions(ofIndex: Int)
}

extension QuizEndPoint: EndPointType {
    var baseURL: URL {
        guard let url = URL(string: "https://codechallenge.arctouch.com") else { fatalError("baseURL could not be configured.")}
        return url
    }
    
    var path: String {
        switch self {
        case .questions(let index):
            return "/quiz/\(index)"
        }
    }
    
    var httpMethod: HTTPMethod {
        switch self {
        case .questions:
            return .get
        }
    }
    
    var task: HTTPTask {
        switch self {
        case .questions:
            return .request
        }
    }
    
    var headers: HTTPHeaders? {
        return nil
    }
}
