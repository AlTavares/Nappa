
import Quick
import Nimble
import Result
@testable import Nappa

let testHost = "https://httpbin.org"
class NappaSpec: QuickSpec {
    override func spec() {
        describe("A network request") {
            it("calls an endpoint and returns valid data using GET") {
                let urlString = testHost + "/get"
                self.test(url: urlString, method: HTTPMethod.get, withEncoding: ParameterEncoding.url, params: Stubs.params, expectedParams: Stubs.expectedParams)
            }
            it("calls an endpoint and returns valid data using GET and nested parameters") {
                let urlString = testHost + "/get"
                self.test(url: urlString, method: HTTPMethod.get, withEncoding: ParameterEncoding.url, params: Stubs.nestedParams, expectedParams: Stubs.expectedNestedParams)
            }
            it("calls an endpoint and returns valid data using DELETE") {
                let urlString = testHost + "/delete"
                self.test(url: urlString, method: HTTPMethod.delete, withEncoding: ParameterEncoding.url, params: Stubs.params, expectedParams: Stubs.expectedParams)
            }
            it("calls an endpoint and returns valid data using DELETE and nested parameters") {
                let urlString = testHost + "/delete"
                self.test(url: urlString, method: HTTPMethod.delete, withEncoding: ParameterEncoding.url, params: Stubs.nestedParams, expectedParams: Stubs.expectedNestedParams)
            }
            context("when calling an endpoint using POST") {
                it("returns valid data with encoded params") {
                    let urlString = testHost + "/post"
                    let service = HTTPService()
                    waitUntil(timeout: 5) { done in
                        service.request(method: .post, url: urlString, payload: TestData.expectedObject)
                            .responseObject(keyPath: "json") { (response: ObjectResponse<TestObject>) in
                                expect(response.result.value) == TestData.expectedObject
                                done()
                        }
                    }
                }
                it("returns valid data with JSON content type") {
                    let urlString = testHost + "/post"
                    self.test(url: urlString, method: HTTPMethod.post, withEncoding: ParameterEncoding.json, params: Stubs.nestedParams, expectedParams: Stubs.expectedJSONNestedParams)
                }
                it("returns valid data with Form Data encoding") {
                    let urlString = testHost + "/post"
                    self.test(url: urlString, method: HTTPMethod.post, withEncoding: ParameterEncoding.form, params: Stubs.params, expectedParams: Stubs.expectedParams)
                }
                it("returns valid data with Form Data encoding and nested params") {
                    let urlString = testHost + "/post"
                    self.test(url: urlString, method: HTTPMethod.post, withEncoding: ParameterEncoding.form, params: Stubs.nestedParams, expectedParams: Stubs.expectedNestedParams)
                }
            }
            context("when calling an endpoint using PUT") {
                it("returns valid data with JSON content type") {
                    let urlString = testHost + "/put"
                    self.test(url: urlString, method: HTTPMethod.put, withEncoding: ParameterEncoding.json, params: Stubs.nestedParams, expectedParams: Stubs.expectedJSONNestedParams)
                }
                it("returns valid data with Form Data encoding") {
                    let urlString = testHost + "/put"
                    self.test(url: urlString, method: HTTPMethod.put, withEncoding: ParameterEncoding.form, params: Stubs.params, expectedParams: Stubs.expectedParams)
                }
                it("returns valid data with Form Data encoding and nested params") {
                    let urlString = testHost + "/put"
                    self.test(url: urlString, method: HTTPMethod.put, withEncoding: ParameterEncoding.form, params: Stubs.nestedParams, expectedParams: Stubs.expectedNestedParams)
                }
            }
        }
    }
    
    func test<T: Encodable>(url urlString: String, method: HTTPMethod, withEncoding encoding: ParameterEncoding, params: T, expectedParams: [String: Any]) {
        let service = HTTPService()
        waitUntil(timeout: 5) { done in
            service.request(method: method, url: urlString, payload: params, headers: Stubs.headers, parameterEncoding: encoding).responseJSON { response in
                self.testResult(response: response, params: expectedParams, headers: Stubs.headers, parameterEncoding: encoding)
                done()
            }
        }

    }
    
    func testResult(response: JSONResponse, params: [String: Any] = [:], headers: [String: String] = [:], parameterEncoding: ParameterEncoding) {
        let json = response.result.value as! [String: Any]
        
        let actualHeaders = json["headers"] as! [String: String]
        for (key, value) in headers {
            expect(actualHeaders[key]).to(equal(value))
        }
        
        if params.count > 0 {
            let dict: [ParameterEncoding: String] = [
                .json: "json",
                .form: "form",
                .url: "args",
                ]
            let p = json[dict[parameterEncoding]!]
            let parameters = p as! [String: Any]
            let dictionaryIsEqual = (params as NSDictionary).isEqual(to: parameters)
            expect(dictionaryIsEqual).to(beTrue(), description: "expected parameters: \(params)\nactual parameters: \(parameters)")
        }
    }
}

private struct Stubs {
    static let headers = [
        "Header1": "value1",
        "Header2": "value2",
        ]
    static let params: Parameters = [
        "foo": AnyEncodable("bar"),
        "inseto": AnyEncodable("formiga"),
        "mamifero": AnyEncodable("cachorro"),
        "numero": AnyEncodable(10),
        "bool": AnyEncodable(true),
        "falseBool": AnyEncodable(false),
        ]
    
    static let expectedParams: [String: Any] = [
        "foo": "bar",
        "inseto": "formiga",
        "mamifero": "cachorro",
        "numero": "10",
        "bool": "1",
        "falseBool": "0",
        ]
    
    static let expectedJSONParams: [String: Any] = [
        "foo": "bar",
        "inseto": "formiga",
        "mamifero": "cachorro",
        "numero": 10,
        "bool": true,
        "falseBool": false,
        ]
    
    static let nestedParams: Parameters = [
        "array": AnyEncodable(["valor1", "valor2"]),
        "numero": AnyEncodable(2),
        "doce": AnyEncodable("bolo"),
        "user": AnyEncodable([
            "nome": AnyEncodable("alfredo"),
            "senha": AnyEncodable("alf"),
            "idade": AnyEncodable(70),
        ]),
        "bool": AnyEncodable(true),
        "falseBool": AnyEncodable(false),
        ]
    
    static let expectedNestedParams: [String: Any] = [
        "array[]": ["valor1", "valor2"],
        "numero": "2",
        "doce": "bolo",
        "user[nome]": "alfredo",
        "user[senha]": "alf",
        "user[idade]": "70",
        "bool": "1",
        "falseBool": "0",
        ]
    
    static let expectedJSONNestedParams: [String: Any] = [
        "array": ["valor1", "valor2"],
        "numero": 2,
        "doce": "bolo",
        "user": [
            "nome": "alfredo",
            "senha": "alf",
            "idade": 70,
        ],
        "bool": true,
        "falseBool": false,
        ]
}

