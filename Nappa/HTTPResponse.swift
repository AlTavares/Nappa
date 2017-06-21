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
}

public struct DataResponse: Response {
    public var request: URLRequest?
    public var response: HTTPURLResponse?
    public var data: Data?
    public var error: HTTPServiceError?

    public var result: Result<Data, HTTPResponseError> {
        return serializeResponseData()
    }

    public func serializeResponseData() -> Result<Data, HTTPResponseError> {
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

public struct JSONResponse: Response {
    public var request: URLRequest?
    public var response: HTTPURLResponse?
    public var data: Data?
    public var error: HTTPServiceError?

    public var result: Result<Any, HTTPResponseError> {
        return serializeResponseJSON()
    }

    public func serializeResponseJSON(options: JSONSerialization.ReadingOptions = .allowFragments) -> Result<Any, HTTPResponseError> {

        guard let validData = data, validData.count > 0 else {
            return .failure(.emptyData)
        }
        do {
            let json = try JSONSerialization.jsonObject(with: validData, options: options)
            return .success(json)
        } catch {
            return .failure(.jsonSerialization(error))
        }
    }
}

public struct StringResponse: Response {
    public var request: URLRequest?
    public var response: HTTPURLResponse?
    public var data: Data?
    public var error: HTTPServiceError?

    public var result: Result<String, HTTPResponseError> {
        return serializeResponseString()
    }

    ///Serialize string using passed encoding, if none is passed it tries to get the encoding from the server, falling back to the http default
    public func serializeResponseString(encoding: String.Encoding? = nil) -> Result<String, HTTPResponseError> {
        guard let response = response else {
            return .failure(.responseNil)
        }

        if emptyDataStatusCodes.contains(response.statusCode) { return .success("") }

        guard let validData = data else {
            return .failure(.emptyData)
        }

        var convertedEncoding = encoding
        if let encodingName = response.textEncodingName as CFString?, convertedEncoding == nil {
            convertedEncoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(
                CFStringConvertIANACharSetNameToEncoding(encodingName))
            )
        }

        let actualEncoding = convertedEncoding ?? String.Encoding.isoLatin1
        if let string = String(data: validData, encoding: actualEncoding) {
            return .success(string)
        } else {
            return .failure(.unableToEncodeString)
        }
    }
}

/// A set of HTTP response status code that do not contain response data.
private let emptyDataStatusCodes: Set<Int> = [204, 205]
