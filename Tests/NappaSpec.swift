
import Quick
import Nimble
import Result
@testable import Nappa

class NappaSpec: QuickSpec {
    override func spec() {
        let testHost = "https://httpbin.org"
        describe("A network request") {
            it("calls an endpoint and returns valid data using GET") {
                let urlString = testHost + "/get"
                self.test(url: urlString, method: .get, withEncoding: .url, params: Stubs.params, expectedParams: Stubs.expectedParams)
            }
            it("calls an endpoint and returns valid data using GET and nested parameters") {
                let urlString = testHost + "/get"
                self.test(url: urlString, method: .get, withEncoding: .url, params: Stubs.nestedParams, expectedParams: Stubs.expectedNestedParams)
            }
            it("calls an endpoint and returns valid data using DELETE") {
                let urlString = testHost + "/delete"
                self.test(url: urlString, method: .delete, withEncoding: .url, params: Stubs.params, expectedParams: Stubs.expectedParams)
            }
            it("calls an endpoint and returns valid data using DELETE and nested parameters") {
                let urlString = testHost + "/delete"
                self.test(url: urlString, method: .delete, withEncoding: .url, params: Stubs.nestedParams, expectedParams: Stubs.expectedNestedParams)
            }
            context("when calling an endpoint using POST") {
                it("returns valid data with JSON content type") {
                    let urlString = testHost + "/post"
                    self.test(url: urlString, method: .post, withEncoding: .json, params: Stubs.nestedParams, expectedParams: Stubs.nestedParams)
                }
                it("returns valid data with Form Data encoding") {
                    let urlString = testHost + "/post"
                    self.test(url: urlString, method: .post, withEncoding: .form, params: Stubs.params, expectedParams: Stubs.expectedParams)
                }
                it("returns valid data with Form Data encoding and nested params") {
                    let urlString = testHost + "/post"
                    self.test(url: urlString, method: .post, withEncoding: .form, params: Stubs.nestedParams, expectedParams: Stubs.expectedNestedParams)
                }
            }
            context("when calling an endpoint using PUT") {
                it("returns valid data with JSON content type") {
                    let urlString = testHost + "/put"
                    self.test(url: urlString, method: .put, withEncoding: .json, params: Stubs.nestedParams, expectedParams: Stubs.nestedParams)
                }
                it("returns valid data with Form Data encoding") {
                    let urlString = testHost + "/put"
                    self.test(url: urlString, method: .put, withEncoding: .form, params: Stubs.params, expectedParams: Stubs.expectedParams)
                }
                it("returns valid data with Form Data encoding and nested params") {
                    let urlString = testHost + "/put"
                    self.test(url: urlString, method: .put, withEncoding: .form, params: Stubs.nestedParams, expectedParams: Stubs.expectedNestedParams)
                }
            }
        }
    }
    
    func test(url urlString: String, method: HTTPMethod, withEncoding encoding: ParameterEncoding, params: Parameters, expectedParams: Parameters) {
        let service = HTTPService()
        var response: JSONResponse!
        waitUntil(timeout: 5) { done in
            service.request(method: method, url: urlString, parameters: params, headers: Stubs.headers, parameterEncoding: encoding).responseJSON { res in
                response = res
                done()
            }
        }
        self.testResult(response: response, params: expectedParams, headers: Stubs.headers, parameterEncoding: encoding)
    }
    
    func testResult(response: JSONResponse, params: Parameters = [:], headers: [String: String] = [:], parameterEncoding: ParameterEncoding) {
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
            let parameters = p as! Parameters
            expect((params as NSDictionary).isEqual(to: parameters)).to(beTrue())
        }
    }
}

private struct Stubs {
    static let headers = [
        "Header1": "value1",
        "Header2": "value2",
        ]
    static let params: Parameters = [
        "foo": "bar",
        "inseto": "formiga",
        "mamifero": "cachorro",
        "numero": 10,
        "bool": true,
        "falseBool": false,
        ]
    
    static let expectedParams: Parameters = [
        "foo": "bar",
        "inseto": "formiga",
        "mamifero": "cachorro",
        "numero": "10",
        "bool": "1",
        "falseBool": "0",
        ]
    
    static let nestedParams: Parameters = [
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
    
    static let expectedNestedParams: Parameters = [
        "array[]": ["valor1", "valor2"],
        "numero": "2",
        "doce": "bolo",
        "user[nome]": "alfredo",
        "user[senha]": "alf",
        "user[idade]": "70",
        "bool": "1",
        "falseBool": "0",
        ]
}
