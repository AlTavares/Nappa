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
    func performRequest(request: URLRequest, queue: DispatchQueue, completionHandler: @escaping (DataResponse) -> Void)
}

public extension HTTPRequestAdapter{
    public var cookieStorage: HTTPCookieStorage {
        return HTTPCookieStorage.shared
    }
}

public struct SimpleRequestAdapter: HTTPRequestAdapter {
    var urlSession: URLSession

    public var cookieStorage: HTTPCookieStorage {
        return urlSession.configuration.httpCookieStorage ?? HTTPCookieStorage.shared
    }

    public init(configuration: URLSessionConfiguration) {
        self.urlSession = URLSession(configuration: configuration)
    }

    public func performRequest(request: URLRequest, queue: DispatchQueue, completionHandler: @escaping (DataResponse) -> Void) {

        let dataTask = urlSession.dataTask(with: request) { (data, response, error) in
            if let httpResponse = response as? HTTPURLResponse, error == nil {
                queue.async {
                    completionHandler(DataResponse(request: request, response: httpResponse, data: data))
                }
                return
            }
            queue.async {
                completionHandler(DataResponse(error: .other(error!)))
            }
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
