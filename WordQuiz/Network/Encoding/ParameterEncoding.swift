import Foundation

public typealias Parameters = [String: Any]

public protocol ParameterEncoder {
    static func encode(urlRequest: inout URLRequest, with parameters: Parameters) throws
}

public enum NetworkError: String, Error {   
    case encodingFailed = "Parameters encoding failed"
    case missingURL = "URL is nil"
}
