//
//  HTTPRequestAdapter.swift
//  Nappa
//
//  Created by Alexandre Tavares on 09/02/17.
//  Copyright © 2017 Nappa. All rights reserved.
//

import Foundation

public protocol HTTPRequestAdapter {
    func performRequest(request: URLRequest, queue: DispatchQueue, completionHandler: @escaping (DataResponse) -> Void)
}

struct DefaultRequestAdapter: HTTPRequestAdapter {
    var configuration: URLSessionConfiguration

    init() {
        configuration = Nappa.Configuration.urlSessionConfiguration
    }

    func performRequest(request: URLRequest, queue: DispatchQueue, completionHandler: @escaping (DataResponse) -> Void) {
        let urlSession = URLSession(configuration: configuration)

        let dataTask = urlSession.dataTask(with: request) { data, response, error in
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
