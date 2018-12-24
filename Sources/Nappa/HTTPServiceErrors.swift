//
//  HTTPServiceErrors.swift
//  Nappa
//
//  Created by Alexandre Tavares on 14/02/17.
//  Copyright © 2017 Nappa. All rights reserved.
//

import Foundation

public enum HTTPResponseError: Error, CustomStringConvertible {
    case emptyData
    case responseNil
    case unableToDecodeString
    case unableToDecodeJSON(Error)
    case requestError(Error)
    case invalidURL(String)

    public var localizedDescription: String {
        return description
    }

    public var description: String {
        switch self {
        case .emptyData:
            return "Empty response data"
        case .responseNil:
            return "Response is nil"
        case .unableToDecodeJSON(let error):
            return "Unable to decode JSON: \(error.localizedDescription)"
        case .unableToDecodeString:
            return "Unable to decode String"
        case .requestError(let error):
            return "Request error: \(error.localizedDescription)"
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        }
    }
}
