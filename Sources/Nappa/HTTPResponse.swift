//
//  DataResponse.swift
//  Nappa
//
//  Created by Alexandre Tavares on 27/10/16.
//  Copyright © 2016 Nappa. All rights reserved.
//

import Foundation
import Result

public protocol Response: CustomStringConvertible, CustomDebugStringConvertible {
    associatedtype Value
    /// The URL request sent to the server.
    var request: URLRequest? { get set }

    /// The server's response to the URL request.
    var response: HTTPURLResponse? { get set }

    /// The data returned by the server.
    var data: Data? { get set }

    /// The result of response serialization.
    var result: Result<Value, HTTPResponseError> { get }

    /// The error that may be occurred in the request.
    var error: HTTPServiceError? { get set }

    init()

    // Method to decode the result
    func decodeResult() -> Result<Value, HTTPResponseError>
}

public extension Response {

    /// The textual representation used when written to an output stream, which includes whether the result was a
    /// success or failure.
    public var description: String {
        return result.debugDescription
    }

    /// The debug textual representation used when written to an output stream, which includes the URL request, the URL
    /// response, the server data, the response serialization result and the timeline.
    public var debugDescription: String {
        var output: [String] = []

        output.append("[Request]: \(String(describing: request))")
        output.append("[Response]: \(String(describing: response))")
        output.append("[Data]: \(data?.count ?? 0) bytes")
        output.append("[Result]: \(result.debugDescription)")

        return output.joined(separator: "\n")
    }

    public init(request: URLRequest? = nil, response: HTTPURLResponse? = nil, data: Data? = nil, error: HTTPServiceError? = nil) {
        self.init()
        self.request = request
        self.response = response
        self.data = data
        self.error = error
    }

    public init<SomeResponse: Response>(response: SomeResponse) {
        self.init(request: response.request, response: response.response, data: response.data, error: response.error)
    }

    public var result: Result<Value, HTTPResponseError> {
        if let error = error {
            return .failure(.serviceError(error))
        }
        return decodeResult()
    }

    fileprivate func decodeData() -> Result<Data, HTTPResponseError> {
        guard let response = response else {
            return .failure(.responseNil)
        }

        if emptyDataStatusCodes.contains(response.statusCode) { return .success(Data()) }

        guard let validData = data else {
            return .failure(.emptyData)
        }

        return .success(validData)
    }
}

public struct DataResponse: Response {
    public var request: URLRequest?
    public var response: HTTPURLResponse?
    public var data: Data?
    public var error: HTTPServiceError?

    public init() {}

    public func decodeResult() -> Result<Data, HTTPResponseError> {
        return decodeData()
    }
}

public struct JSONResponse: Response {
    public var request: URLRequest?
    public var response: HTTPURLResponse?
    public var data: Data?
    public var error: HTTPServiceError?

    public init() {}

    public func decodeResult() -> Result<Any, HTTPResponseError> {
        return decodeResult(options: .allowFragments)
    }

    public func decodeResult(options: JSONSerialization.ReadingOptions) -> Result<Any, HTTPResponseError> {

        let validData: Data
        switch decodeData() {
        case .success(let data):
            validData = data
        case .failure(let error):
            return .failure(error)
        }

        do {
            let json = try JSONSerialization.jsonObject(with: validData, options: options)
            return .success(json)
        } catch {
            return .failure(.unableToDecodeJSON(error))
        }
    }
}

public struct StringResponse: Response {
    public var request: URLRequest?
    public var response: HTTPURLResponse?
    public var data: Data?
    public var error: HTTPServiceError?

    public init() {}

    public func decodeResult() -> Result<String, HTTPResponseError> {
        return decodeResult(encoding: String.Encoding.utf8)
    }

    public func decodeResult(encoding: String.Encoding) -> Result<String, HTTPResponseError> {
        let validData: Data
        switch decodeData() {
        case .success(let data):
            validData = data
        case .failure(let error):
            return .failure(error)
        }

        if let string = String(data: validData, encoding: encoding) {
            return .success(string)
        } else {
            return .failure(.unableToDecodeString)
        }
    }

}

public struct ObjectResponse<Value: Decodable>: Response {
    public var request: URLRequest?
    public var response: HTTPURLResponse?
    public var data: Data?
    public var error: HTTPServiceError?

    public init() {}

    public func decodeResult() -> Result<Value, HTTPResponseError> {
        return decodeResult(decoder: JSONDecoder())
    }

    public func decodeResult(decoder: JSONDecoder) -> Result<Value, HTTPResponseError> {
        let validData: Data
        switch decodeData() {
        case .success(let data):
            validData = data
        case .failure(let error):
            return .failure(error)
        }
        do {
            let result = try decoder.decode(Value.self, from: validData)
            return .success(result)
        } catch {
            return .failure(.unableToDecodeJSON(error))
        }
    }
}

/// A set of HTTP response status code that do not contain response data.
private let emptyDataStatusCodes: Set<Int> = [204, 205]
