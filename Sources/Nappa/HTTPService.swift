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
public typealias Parameters = [String: Encodable]
public typealias Headers = [String: String]

public struct HTTPService {
    public let adapter: HTTPRequestAdapter

    public init(adapter: HTTPRequestAdapter = DefaultRequestAdapter) {
        self.adapter = adapter
    }

    public func request(method: HTTPMethod, url: String, payload: [String: Encodable], headers: Headers? = nil, parameterEncoding: ParameterEncoding? = nil) -> HTTPRequest {
        return request(method: method, url: url, payload: AnyEncodable(payload), headers: headers, parameterEncoding: parameterEncoding)
    }

    public func request<T: Encodable>(method: HTTPMethod, url: String, payload: T, headers: Headers? = nil, parameterEncoding: ParameterEncoding? = nil) -> HTTPRequest {
        return HTTPRequest(method: method, url: url, payload: AnyEncodable(payload), headers: headers, parameterEncoding: parameterEncoding, adapter: adapter)
    }

    public func request(method: HTTPMethod, url: String, data: Data, headers: Headers? = nil) -> HTTPRequest {
        return HTTPRequest(method: method, url: url, data: data, headers: headers, adapter: adapter)
    }

    public func request(method: HTTPMethod, url: String, headers: Headers? = nil) -> HTTPRequest {
        return HTTPRequest(method: method, url: url, headers: headers, adapter: adapter)
    }
}

public struct HTTPRequest {
    public let method: HTTPMethod
    public let url: String
    public let headers: Headers?
    public let parameterEncoding: ParameterEncoding
    let adapter: HTTPRequestAdapter
    let payload: AnyEncodable?
    let data: Data?
    public var body: Data? {
        if data != nil {
            return data
        }
        guard let payload = self.payload else { return nil }
        switch parameterEncoding {
        case .form:
            return payload.formData
        case .json:
            return payload.json
        default:
            return nil
        }
    }

    fileprivate init(method: HTTPMethod, url: String, payload: AnyEncodable? = nil, data: Data? = nil, headers: Headers? = nil, parameterEncoding: ParameterEncoding? = nil, adapter: HTTPRequestAdapter) {
        self.method = method
        self.url = url
        self.payload = payload
        self.data = data
        self.headers = headers
        self.parameterEncoding = parameterEncoding ?? ParameterEncoding(method: method)
        self.adapter = adapter
    }

    /// Only performs the request and doesn' call back
    public func perform(queue: DispatchQueue = DispatchQueue.main) -> RequestTask? {
        return response { _ in }
    }

    // MARK: Response

    private func response(completionHandler: @escaping (DataResponse) -> Void) -> RequestTask? {
        do {
            var request = try buildRequest(forUrl: url).get()

            request.httpMethod = method.rawValue
            var headerFields = headers ?? Headers()

            request.httpBody = body
            if request.httpBody != nil && headerFields["Content-Type"] == nil {
                headerFields["Content-Type"] = parameterEncoding.contentType
            }
            request.allHTTPHeaderFields = headerFields

            return adapter.performRequest(request: request, completionHandler: completionHandler)
        } catch {
            completionHandler(DataResponse(error: error as? HTTPResponseError))
            return nil
        }
    }

    @discardableResult
    public func responseData(queue: DispatchQueue = DispatchQueue.main, completionHandler: @escaping (DataResponse) -> Void) -> RequestTask? {
        return response { dataResponse in
            queue.async {
                completionHandler(dataResponse)
            }
        }
    }

    @discardableResult
    public func responseString(queue: DispatchQueue = DispatchQueue.main, completionHandler: @escaping (StringResponse) -> Void) -> RequestTask? {
        return responseData(queue: queue) { dataResponse in
            completionHandler(StringResponse(response: dataResponse))
        }
    }

    @discardableResult
    public func responseJSON(keyPath: String? = nil, queue: DispatchQueue = DispatchQueue.main, completionHandler: @escaping (JSONResponse) -> Void) -> RequestTask? {
        return response { dataResponse in
            let jsonResponse = JSONResponse(response: dataResponse)
            if let keyPath = keyPath {
                jsonResponse.data = self.jsonData(json: jsonResponse.decodeResult().value, fromKeyPath: keyPath)
            }
            queue.async {
                completionHandler(jsonResponse)
            }
        }
    }

    @discardableResult
    public func responseObject<Value>(keyPath: String? = nil, queue: DispatchQueue = DispatchQueue.main, completionHandler: @escaping (ObjectResponse<Value>) -> Void) -> RequestTask? {
        return response { dataResponse in
            let objectResponse = ObjectResponse<Value>(response: dataResponse)
            if let keyPath = keyPath {
                objectResponse.data = self.jsonData(json: JSONResponse(response: dataResponse).result.value, fromKeyPath: keyPath)
            }
            queue.async {
                completionHandler(objectResponse)
            }
        }
    }

    private func jsonData(json: Any?, fromKeyPath keypathString: String) -> Data? {
        guard var json = json else { return nil }
        let keypath = keypathString.components(separatedBy: ".")
        for key in keypath {
            if let subjson = json as? [String: Any] {
                json = subjson[key] as Any
            }
        }
        return try? JSONSerialization.data(withJSONObject: json)
    }

    // MARK: Request

    private func buildRequest(forUrl url: String) -> Result<URLRequest, HTTPResponseError> {
        guard var urlComponents = URLComponents(string: url) else {
            return .failure(.invalidURL(url))
        }

        if parameterEncoding == .url, let payload = payload {
            var queryItems = urlComponents.queryItems ?? [URLQueryItem]()
            queryItems.append(contentsOf: payload.urlQueryItems)
            urlComponents.queryItems = queryItems
        }

        guard let requestUrl = urlComponents.url else {
            return .failure(.invalidURL(String(describing: urlComponents.url)))
        }

        return .success(URLRequest(url: requestUrl))
    }
}
