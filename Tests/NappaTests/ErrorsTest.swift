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
        let service = HTTPService()
        describe("a request with errors") {
            it("should return error for invalid url") {
                waitUntil { done in
                    let url = "not an url"
                    service.request(method: .get, url: url)
                        .responseData(completionHandler: { response in
                            expect(response.error).toNot(beNil())
                            switch response.error! {
                            case .invalidURL:
                                break
                            default:
                                fail("Error different than expected. Got \(response.error!), expected \(HTTPResponseError.invalidURL(url))")
                            }
                            done()
                        })
                }
            }
        }
    }

}
