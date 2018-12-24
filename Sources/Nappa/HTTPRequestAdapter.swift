//
//  HTTPRequestAdapter.swift
//  Nappa
//
//  Created by Alexandre Tavares on 09/02/17.
//  Copyright © 2017 Nappa. All rights reserved.
//

import Foundation
import Result

public protocol RequestTask {
    func resume()
    func cancel()
    func suspend()

    var state: URLSessionTask.State { get }
}

extension URLSessionDataTask: RequestTask {}

public protocol HTTPRequestAdapter {
    var cookieStorage: HTTPCookieStorage { get }
    func performRequest(request: URLRequest, completionHandler: @escaping (DataResponse) -> Void) -> RequestTask?
}

public extension HTTPRequestAdapter {
    public var cookieStorage: HTTPCookieStorage {
        return HTTPCookieStorage.shared
    }
}

public struct SimpleRequestAdapter: HTTPRequestAdapter {
    var urlSession: URLSession

    public var cookieStorage: HTTPCookieStorage {
        return self.urlSession.configuration.httpCookieStorage ?? HTTPCookieStorage.shared
    }

    public init(configuration: URLSessionConfiguration) {
        self.urlSession = URLSession(configuration: configuration)
    }

    public func performRequest(request: URLRequest, completionHandler: @escaping (DataResponse) -> Void)  -> RequestTask? {
        let dataTask = urlSession.dataTask(with: request) { data, response, error in
            let httpResponse = response as? HTTPURLResponse
            if let error = error {
                return completionHandler(DataResponse(request: request, response: httpResponse, data: data, error: .requestError(error)))
            }
            return completionHandler(DataResponse(request: request, response: httpResponse, data: data))
        }
        dataTask.resume()
        return dataTask
    }
}

public var DefaultRequestAdapter: HTTPRequestAdapter {
    return SimpleRequestAdapter(configuration: .default)
}

public var EphemeralRequestAdapter: HTTPRequestAdapter {
    return SimpleRequestAdapter(configuration: .ephemeral)
}
