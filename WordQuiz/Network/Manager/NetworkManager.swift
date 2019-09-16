import Foundation

struct NetworkManager {    
    public static func handleNetworkResponse(_ response: HTTPURLResponse) -> Result<String> {
        switch response.statusCode {
        case 200...299: return .success
        case 401...500: return .failure(NetworkResponse.authenticationError.rawValue)
        case 501...599: return .failure(NetworkResponse.badRequest.rawValue)
        case 600: return .failure(NetworkResponse.outdated.rawValue)
        default: return .failure(NetworkResponse.failed.rawValue)
        }
    }
}

enum NetworkResponse: String {
    case success
    case authenticationError = "You need to be authenticated first."
    case badRequest = "Bad request"
    case outdated = "Requested url is outdated."
    case failed = "Network request failed"
    case noData = "Response returned without data"
    case unableToDecode = "Unable to decode response"
    case connectionError = "Please, check your network connection and try again"
}

enum Result<String> {
    case success
    case failure(String)
}
