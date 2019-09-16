import Foundation

public typealias HTTPHeaders = [String: String] // not used, but added thinking about further development.

public enum HTTPTask {
    case request
    case requestParameters(bodyParameters: Parameters?, urlParameters: Parameters)
    case requestParametersWithHeaders(bodyParameters: Parameters?, urlParameters: Parameters, additionalHeaders: HTTPHeaders)
}
