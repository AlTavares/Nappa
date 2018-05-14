//
//  ErrorsTest.swift
//  Nappa
//
//  Created by Alexandre Tavares on 14/05/18.
//  Copyright © 2018 Nappa. All rights reserved.
//

import XCTest
import Quick
import Nimble
@testable import Nappa

class ErrorsTest: QuickSpec {

    override func spec() {
        let service = HTTPService(adapter: adapter)
        describe("a request with errors") {
            it("should return error for invalid url") {
                waitUntil { done in
                    let url = "not an url"
                    service.request(method: .get, url: url)
                        .responseData(completionHandler: { response in
                            expect(response.error).toNot(beNil())
                            switch response.error! {
                            case .invalidUrl:
                                break
                            default:
                                fail("Error different than expected. Got \(response.error!), expected \(HTTPServiceError.invalidUrl(url))")
                            }
                            done()
                        })
                }
            }
            it("should return error for timeout") {
                waitUntil { done in
                    let url = "http://google.com:81/"
                    service.request(method: .get, url: url)
                        .responseData(completionHandler: { response in
                            expect(response.error).toNot(beNil())
                            switch response.error! {
                            case .networkError(let cfNetworkError):
                                expect(cfNetworkError) == CFNetworkErrors.cfurlErrorTimedOut
                            default:
                                fail("Error different than expected. Got \(response.error!), expected \(HTTPServiceError.networkError(CFNetworkErrors.cfurlErrorTimedOut))")
                            }
                            done()
                        })
                }
            }
        }
    }

    var adapter: HTTPRequestAdapter {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 0.1
        configuration.timeoutIntervalForResource = 0.1
        return SimpleRequestAdapter(configuration: configuration)
    }

}
