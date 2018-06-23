//
//  HTTPRequestAdapter.swift
//  Nappa
//
//  Created by Alexandre Tavares on 09/02/17.
//  Copyright © 2017 Nappa. All rights reserved.
//

import Foundation
import Result

public protocol HTTPRequestAdapter {
    var cookieStorage: HTTPCookieStorage { get }
    func performRequest(request: URLRequest, completionHandler: @escaping (DataResponse) -> Void)
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

    public func performRequest(request: URLRequest, completionHandler: @escaping (DataResponse) -> Void) {

        let dataTask = urlSession.dataTask(with: request) { data, response, error in
            let httpResponse = response as? HTTPURLResponse
            if let error = error {
                return completionHandler(DataResponse(request: request, response: httpResponse, data: data, error: .other(error)))
            }
            return completionHandler(DataResponse(request: request, response: httpResponse, data: data))

        }
        dataTask.resume()
    }
}

public var DefaultRequestAdapter: HTTPRequestAdapter {
    return SimpleRequestAdapter(configuration: .default)
}

public var EphemeralRequestAdapter: HTTPRequestAdapter {
    return SimpleRequestAdapter(configuration: .ephemeral)
}
