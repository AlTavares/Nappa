//
//  ObjectResponseTest.swift
//  Nappa
//
//  Created by Alexandre Tavares on 15/12/17.
//  Copyright © 2017 Nappa. All rights reserved.
//

import XCTest
import Quick
import Nimble
@testable import Nappa

class ResponseTest: QuickSpec {

    override func spec() {
        let url = "http://test.url"
        let service = HTTPService(adapter: FakeRequestAdapter(data: TestData.jsonData))
        let request = service.request(method: .get, url: url)
        describe("a response object") {
            it("should decode the data into a valid data") {
                waitUntil { done in
                    request.response { dataResponse in
                        expect(dataResponse.result.isSuccess) == true
                        expect(dataResponse.result.value) == TestData.jsonData
                        done()
                    }
                }
            }
            it("should decode the data into a string") {
                waitUntil { done in
                    request.responseString { stringResponse in
                        expect(stringResponse.result.isSuccess) == true
                        expect(stringResponse.result.value) == TestData.jsonString
                        done()
                    }
                }
            }
            it("should decode the json into a map") {
                waitUntil { done in
                    request.responseJSON { jsonResponse in
                        expect(jsonResponse.result.isSuccess) == true
                        expect((jsonResponse.result.value as! [String: String])) == TestData.expectedMap
                        done()
                    }
                }
            }
            it("should decode the json into an object") {
                waitUntil { done in
                    request.responseObject { (objectResponse: ObjectResponse<TestObject>) in
                        expect(objectResponse.result.isSuccess) == true
                        expect(objectResponse.result.value) == TestData.expectedObject
                        done()
                    }
                }
            }
        }
    }

}

fileprivate struct TestObject: Codable, Equatable {
    var propertyOne: String
    var propertyTwo: String

    enum CodingKeys: String, CodingKey {
        case propertyOne = "property_one"
        case propertyTwo = "property_two"
    }

    static func ==(lhs: TestObject, rhs: TestObject) -> Bool {
        guard lhs.propertyOne == rhs.propertyOne else { return false }
        guard lhs.propertyTwo == rhs.propertyTwo else { return false }
        return true
    }
}

fileprivate struct FakeRequestAdapter: HTTPRequestAdapter {

    var data: Data

    func performRequest(request: URLRequest, queue: DispatchQueue, completionHandler: @escaping (DataResponse) -> Void) {

        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let dataResponse = DataResponse(request: request, response: response, data: data, error: nil)

        completionHandler(dataResponse)
    }
}

fileprivate struct TestData {
    static let jsonString = """
    {
        "property_one" : "value one",
        "property_two" : "value two"
    }
"""
    static let jsonData = TestData.jsonString.data(using: .utf8)!

    static let expectedMap = [
        "property_one": "value one",
        "property_two": "value two",
    ]
    static let expectedObject = TestObject(propertyOne: "value one", propertyTwo: "value two")
}
