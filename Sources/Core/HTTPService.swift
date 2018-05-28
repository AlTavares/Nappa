//
//  HTTPService.swift
//  Nappa
//
//  Created by Alexandre Tavares on 25/10/16.
//  Copyright © 2016 Nappa. All rights reserved.
//

import Foundation
import Result

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
    public let adapter: HTTPRequestAdapter

    public init(adapter: HTTPRequestAdapter = DefaultRequestAdapter) {
        self.adapter = adapter
    }

    public func request(method: HTTPMethod, url: String, parameters: Parameters, headers: Headers? = nil, parameterEncoding: ParameterEncoding? = nil) -> HTTPRequest {
        return HTTPRequest(method: method, url: url, parameters: parameters, headers: headers, parameterEncoding: parameterEncoding, adapter: adapter)
    }

    public func request<T: Encodable>(method: HTTPMethod, url: String, object: T, headers: Headers? = nil, parameterEncoding: ParameterEncoding? = nil, encoder: JSONEncoder = JSONEncoder()) -> HTTPRequest {
        let data = try? encoder.encode(object)
        return HTTPRequest(method: method, url: url, data: data, headers: headers, parameterEncoding: parameterEncoding, adapter: adapter)
    }

    public func request(method: HTTPMethod, url: String, data: Data, headers: Headers? = nil, parameterEncoding: ParameterEncoding? = nil) -> HTTPRequest {
        return HTTPRequest(method: method, url: url, data: data, headers: headers, parameterEncoding: parameterEncoding, adapter: adapter)
    }

    public func request(method: HTTPMethod, url: String, headers: Headers? = nil, parameterEncoding: ParameterEncoding? = nil) -> HTTPRequest {
        return HTTPRequest(method: method, url: url, headers: headers, parameterEncoding: parameterEncoding, adapter: adapter)
    }

}

public struct HTTPRequest {
    public let method: HTTPMethod
    public let url: String
    public let parameters: Parameters?
    private let _body: Data?
    public var body: Data? {
        if _body != nil {
            return _body
        }
        if let params = parameters {
            switch parameterEncoding {
            case .form:
                return encodeFormData(parameters: params)
            case .json:
                return try? JSONSerialization.data(withJSONObject: params)
            default:
                return nil
            }
        }
        return nil
    }

    public let headers: Headers?
    public let parameterEncoding: ParameterEncoding
    let adapter: HTTPRequestAdapter

    fileprivate init(method: HTTPMethod, url: String, parameters: Parameters? = nil, data: Data? = nil, headers: Headers? = nil, parameterEncoding: ParameterEncoding? = nil, adapter: HTTPRequestAdapter) {
        self.method = method
        self.url = url
        self.parameters = parameters
        _body = data
        self.headers = headers
        self.parameterEncoding = parameterEncoding ?? ParameterEncoding(method: method)
        self.adapter = adapter
    }

    /// Only performs the request and doesn' call back
    public func perform(queue: DispatchQueue = DispatchQueue.main) {
        response { response in
            print(response)
        }
    }

    // MARK: Response

    private func response(completionHandler: @escaping (DataResponse) -> Void) {
        var request: URLRequest
        switch buildRequest(forUrl: url) {
        case .success(let urlRequest):
            request = urlRequest
        case .failure(let error):
            return completionHandler(DataResponse(error: error))
        }

        request.httpMethod = method.rawValue
        var headerFields = headers ?? Headers()

        request.httpBody = body
        if request.httpBody != nil && headerFields["Content-Type"] == nil {
            headerFields["Content-Type"] = parameterEncoding.contentType
        }
        request.allHTTPHeaderFields = headerFields

        adapter.performRequest(request: request, completionHandler: completionHandler)
    }

    public func responseData(queue: DispatchQueue = DispatchQueue.main, completionHandler: @escaping (DataResponse) -> Void) {
        response { dataResponse in
            queue.async {
                completionHandler(dataResponse)
            }
        }
    }

    public func responseJSON(queue: DispatchQueue = DispatchQueue.main, completionHandler: @escaping (JSONResponse) -> Void) {
        responseData(queue: queue) { dataResponse in
            completionHandler(JSONResponse(response: dataResponse))
        }
    }

    public func responseString(queue: DispatchQueue = DispatchQueue.main, completionHandler: @escaping (StringResponse) -> Void) {
        responseData(queue: queue) { dataResponse in
            completionHandler(StringResponse(response: dataResponse))
        }
    }

    public func responseObject<Value>(keyPath: String? = nil, queue: DispatchQueue = DispatchQueue.main, completionHandler: @escaping (ObjectResponse<Value>) -> Void) {
        response { dataResponse in
            var objectResponse = ObjectResponse<Value>(response: dataResponse)
            defer {
                queue.async {
                    completionHandler(objectResponse)
                }
            }
            guard let keyPath = keyPath else { return }
            switch JSONResponse(response: dataResponse).result {
            case .success(let json):
                objectResponse.data = self.jsonData(json: json, fromKeyPath: keyPath)
            case .failure:
                return
            }
        }
    }

    private func jsonData(json: Any, fromKeyPath keypathString: String) -> Data? {
        let keypath = keypathString.components(separatedBy: ".")
        var json = json
        for key in keypath {
            if let subjson = json as? [String: Any] {
                json = subjson[key] as Any
            }
        }
        return try? JSONSerialization.data(withJSONObject: json)
    }

    // MARK: Request

    private func buildRequest(forUrl: String) -> Result<URLRequest, HTTPServiceError> {
        guard var urlComponents = URLComponents(string: url) else {
            return .failure(.invalidUrl(url))
        }

        if parameterEncoding == .url, let params = parameters {
            urlComponents.queryItems = appendQueryItems(to: urlComponents, usingParameters: params)
        }

        guard let requestUrl = urlComponents.url else {
            return .failure(.invalidUrl(String(describing: urlComponents.url)))
        }

        return .success(URLRequest(url: requestUrl))
    }

    // MARK: Encoding
    private func appendQueryItems(to url: URLComponents, usingParameters parameters: Parameters) -> [URLQueryItem] {
        var queryItems = url.queryItems ?? [URLQueryItem]()
        queryItems.append(contentsOf: urlQueryItems(fromDictionary: parameters))
        return queryItems
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
