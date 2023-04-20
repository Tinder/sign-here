//
//  Network.swift
//  CoreLibrary
//
//  Created by Connor Wybranowski on 3/9/21.
//

import Foundation

/// @mockable
public protocol DataTaskHandler {

    func executeDataTask(
        with request: URLRequest,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
    )
}

/// @mockable
public protocol Network {

    func execute(request: URLRequest) throws -> Data
    func executeWithStatusCode(
        request: URLRequest
    ) throws -> (data: Data, allHeaderFields: [AnyHashable: Any], statusCode: Int)
}

public final class NetworkImp: Network {

    public enum Error: Swift.Error, CustomStringConvertible {
        case networkError(Swift.Error)
        case missingData
        case missingStatusCode
        case missingHeaderFields

        public var description: String {
            switch self {
            case let .networkError(error):
                return "[NetworkImp] Networking error: \(error)"
            case .missingData:
                return "[NetworkImp] Missing response data"
            case .missingStatusCode:
                return "[NetworkImp] Missing status code in response"
            case .missingHeaderFields:
                return "[NetworkImp] Missing header fields in response"
            }
        }
    }

    private let handler: DataTaskHandler

    public init(handler: DataTaskHandler = URLSession.shared) {
        self.handler = handler
    }

    public func execute(request: URLRequest) throws -> Data {
        let (data, _, _) = try executeWithStatusCode(request: request)
        return data
    }

    public func executeWithStatusCode(
        request: URLRequest
    ) throws -> (data: Data, allHeaderFields: [AnyHashable: Any], statusCode: Int) {
        let semaphore: DispatchSemaphore = .init(value: 0)
        var outputData: Data?
        var statusCode: Int?
        var allHeaderFields: [AnyHashable: Any]?
        var outputError: Swift.Error?

        handler.executeDataTask(with: request) { data, response, error in
            defer { semaphore.signal() }
            if let error: Swift.Error = error {
                outputError = Error.networkError(error)
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                statusCode = httpResponse.statusCode
                allHeaderFields = httpResponse.allHeaderFields
            }

            if let data: Data = data {
                outputData = data
            }
        }
        semaphore.wait()

        if let outputError: Swift.Error = outputError {
            throw outputError
        } else if let outputData: Data = outputData {
            if let statusCode: Int = statusCode {
                if let allHeaderFields: [AnyHashable: Any] = allHeaderFields {
                    return (data: outputData, allHeaderFields: allHeaderFields, statusCode: statusCode)
                } else {
                    throw Error.missingHeaderFields
                }
            } else {
                throw Error.missingStatusCode
            }
        } else {
            throw Error.missingData
        }
    }
}
