//
//  HTTPService.swift
//  Nappa
//
//  Created by Alexandre Tavares on 25/10/16.
//  Copyright © 2016 Nappa. All rights reserved.
//

import Foundation

/// HTTP method definitions.
///
/// See https://tools.ietf.org/html/rfc7231#section-4.3
public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case head = "HEAD"
}

public enum ParameterEncoding {
    case json
    case form
    case url
    case none

    init(method: HTTPMethod) {
        switch method {
        case .get, .delete, .head:
            self = .url
        case .post, .put:
            self = .json
        }
    }

    var contentType: String? {
        switch self {
        case .json:
            return "application/json"
        case .form:
            return "application/x-www-form-urlencoded"
        default:
            return "text/plain"
        }
    }
}

/// A dictionary of parameters to apply to a `URLRequest`.
public typealias Parameters = [String: Any]
public typealias Headers = [String: String]

public struct HTTPService {

    public struct Configuration {
        static var urlSessionConfiguration: URLSessionConfiguration = URLSessionConfiguration.default
        static var adapter: HTTPRequestAdapter = DefaultRequestAdapter()
    }

    private var adapter: HTTPRequestAdapter

    public init(adapter: HTTPRequestAdapter = Configuration.adapter) {
        self.adapter = adapter
    }

    public func request(method: HTTPMethod, url: String, parameters: Parameters? = nil, headers: [String: String]? = nil, parameterEncoding: ParameterEncoding? = nil) -> HTTPRequest {
        return HTTPRequest(method: method, url: url, parameters: parameters, headers: headers, parameterEncoding: parameterEncoding, adapter: adapter)
    }

    public func request(withData data: Data, method: HTTPMethod, url: String, headers: [String: String]? = nil, parameterEncoding: ParameterEncoding? = nil) -> HTTPRequest {
        return HTTPRequest(method: method, url: url, data: data, headers: headers, parameterEncoding: parameterEncoding, adapter: adapter)
    }
}

public struct HTTPRequest {
    public let method: HTTPMethod
    public let url: String
    public let parameters: Parameters?
    public let bodyData: Data?
    public let headers: Headers?
    public let parameterEncoding: ParameterEncoding
    let adapter: HTTPRequestAdapter

    fileprivate init(method: HTTPMethod, url: String, parameters: Parameters? = nil, data: Data? = nil, headers: [String: String]? = nil, parameterEncoding: ParameterEncoding? = nil, adapter: HTTPRequestAdapter) {
        self.method = method
        self.url = url
        self.parameters = parameters
        bodyData = data
        self.headers = headers
        self.parameterEncoding = parameterEncoding ?? ParameterEncoding(method: method)
        self.adapter = adapter
    }

    /// Only performs the request and doesn' call back
    public func perform(queue: DispatchQueue = DispatchQueue.main) {
        response(queue: queue) { response in
            print(response)
        }
    }

    public func response(queue: DispatchQueue = DispatchQueue.main, completionHandler: @escaping (DataResponse) -> Void) {

        guard var url = URLComponents(string: self.url) else {
            completionHandler(DataResponse(error: .invalidUrl(self.url)))
            return
        }

        var httpBody: Data?
        if let params = parameters {
            switch parameterEncoding {
            case .form:
                httpBody = encodeFormData(parameters: params)
            case .json:
                do {
                    httpBody = try JSONSerialization.data(withJSONObject: params)
                } catch {
                    completionHandler(DataResponse(error: .other(error)))
                    return
                }
            case .url:
                addQuery(to: &url, fromParameters: parameters)
            default:
                break
            }
        }

        guard let requestUrl = url.url else {
            completionHandler(DataResponse(error: .invalidUrl(String(describing: url.url))))
            return
        }

        var request = URLRequest(url: requestUrl)
        request.httpMethod = method.rawValue
        var headerFields = headers ?? Headers()

        request.httpBody = bodyData ?? httpBody
        if request.httpBody != nil && headerFields["Content-Type"] == nil {
            headerFields["Content-Type"] = parameterEncoding.contentType
        }
        request.allHTTPHeaderFields = headerFields

        adapter.performRequest(request: request, queue: queue, completionHandler: completionHandler)
    }

    public func responseJSON(queue: DispatchQueue = DispatchQueue.main, completionHandler: @escaping (JSONResponse) -> Void) {
        response(queue: queue) { dataResponse in
            completionHandler(JSONResponse(response: dataResponse))
        }
    }

    public func responseString(queue: DispatchQueue = DispatchQueue.main, completionHandler: @escaping (StringResponse) -> Void) {
        response(queue: queue) { dataResponse in
            completionHandler(StringResponse(response: dataResponse))
        }
    }

    // MARK: Encoding
    private func addQuery(to url: inout URLComponents, fromParameters parameters: Parameters?) {
        guard let parameters = parameters else { return }
        let queryItems = urlQueryItems(fromDictionary: parameters)
        if url.queryItems != nil {
            url.queryItems!.append(contentsOf: queryItems)
            return
        }
        url.queryItems = queryItems
    }

    private func encodeFormData(parameters: Parameters) -> Data? {
        var components = URLComponents()
        components.queryItems = urlQueryItems(fromDictionary: parameters)
        if let query = components.query {
            return query.data(using: String.Encoding.utf8)
        }
        return nil
    }

    private func urlQueryItems(fromDictionary parameters: Parameters) -> [URLQueryItem] {
        var queryItems = [URLQueryItem]()
        for (key, value) in parameters {
            queryItems.append(contentsOf: queryComponents(fromKey: key, value: value))
        }
        return queryItems
    }

    private func queryComponents(fromKey key: String, value: Any) -> [URLQueryItem] {
        var components = [URLQueryItem]()
        if let dictionary = value as? [String: Any] {
            for (nestedKey, value) in dictionary {
                components += queryComponents(fromKey: "\(key)[\(nestedKey)]", value: value)
            }
        } else if let array = value as? [Any] {
            for value in array {
                components += queryComponents(fromKey: "\(key)[]", value: value)
            }
        } else if let bool = value as? Bool {
            components.append(URLQueryItem(name: key, value: (bool ? "1" : "0")))
        } else {
            components.append(URLQueryItem(name: key, value: "\(value)"))
        }

        return components
    }
}

extension String: Error {}
