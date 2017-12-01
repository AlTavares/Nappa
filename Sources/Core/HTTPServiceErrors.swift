//
//  HTTPServiceErrors.swift
//  Nappa
//
//  Created by Alexandre Tavares on 14/02/17.
//  Copyright © 2017 Nappa. All rights reserved.
//

import Foundation

public enum HTTPServiceError: Error {
    case invalidUrl(String)
    case other(Error)
}

public enum HTTPResponseError: Error {
    case emptyData
    case responseNil
    case jsonSerialization(Error)
    case unableToEncodeString
}
