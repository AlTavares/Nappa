//
//  DataResponse.swift
//  Nappa
//
//  Created by Alexandre Tavares on 27/10/16.
//  Copyright © 2016 Nappa. All rights reserved.
//

import Foundation
import Result

public protocol ResponseResult: CustomStringConvertible, CustomDebugStringConvertible {
    associatedtype Value
    /// The result of response serialization.
    var result: Result<Value, HTTPResponseError> { get }
}

extension ResponseResult {
    /// The textual representation used when written to an output stream, which includes whether the result was a
    /// success or failure.
    public var description: String {
        return result.debugDescription
    }
}

extension ResponseResult where Self: Response {
    fileprivate func decodeData() -> Result<Data, HTTPResponseError> {
        if let error = error {
            return .failure(error)
        }
        guard let response = response else {
            return .failure(.responseNil)
        }

        if emptyDataStatusCodes.contains(response.statusCode) { return .success(Data()) }

        guard let validData = data else {
            return .failure(.emptyData)
        }

        return .success(validData)
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
}

public class Response {
    /// The URL request sent to the server.
    public var request: URLRequest?

    /// The server's response to the URL request.
    public var response: HTTPURLResponse?

    /// The data returned by the server.
    public var data: Data?

    /// The error that may be occurred in the request.
    public var error: HTTPResponseError?

    public init(request: URLRequest? = nil, response: HTTPURLResponse? = nil, data: Data? = nil, error: HTTPResponseError? = nil) {
        self.request = request
        self.response = response
        self.data = data
        self.error = error
    }

    public convenience init<SomeResponse: Response>(response: SomeResponse) {
        self.init(request: response.request, response: response.response, data: response.data, error: response.error)
    }
}

public class DataResponse: Response, ResponseResult {
    public lazy var result: Result<Data, HTTPResponseError> = decodeData()
}

public class JSONResponse: Response, ResponseResult {
    public lazy var result: Result<Any, HTTPResponseError> = decodeResult(options: .allowFragments)

    public func decodeResult(options: JSONSerialization.ReadingOptions = .allowFragments) -> Result<Any, HTTPResponseError> {
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

public class StringResponse: Response, ResponseResult {
    public lazy var result: Result<String, HTTPResponseError> = decodeResult(encoding: String.Encoding.utf8)

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

public class ObjectResponse<Value: Decodable>: Response, ResponseResult {
    public lazy var result: Result<Value, HTTPResponseError> = decodeResult(decoder: JSONDecoder())

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
