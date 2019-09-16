import Foundation

public typealias NetworkRouterCompletion = (_ data: Data?,_ response: URLResponse?,_ error: Error?) -> ()

protocol NetworkRouter: class {
    func request(_ endPoint: EndPointType, completion: @escaping NetworkRouterCompletion)
    func cancel()
}

