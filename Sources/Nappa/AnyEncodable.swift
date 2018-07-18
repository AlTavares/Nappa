//
//  AnyEncodable.swift
//  Nappa
//
//  Created by Alexandre Mantovani Tavares on 28/05/18.
//  Copyright © 2018 Nappa. All rights reserved.
//

import Foundation

public struct AnyEncodable: Encodable {
    
    private let encodable: Encodable
    
    public init(_ encodable: Encodable) {
        self.encodable = encodable
    }
    
    public func encode(to encoder: Encoder) throws {
        try encodable.encode(to: encoder)
    }
    
}

//Internal methods
extension AnyEncodable {
    
    var json: Data? {
        return try? JSONEncoder().encode(self)
    }
    
    var dictionary: [String: Any]? {
        guard let data = self.json else { return nil }
        return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments))  as? [String: Any]
    }
    
    var formData: Data? {
        var components = URLComponents()
        components.queryItems = self.urlQueryItems
        if let query = components.query {
            return query.data(using: String.Encoding.utf8)
        }
        return nil
    }
    
    var urlQueryItems: [URLQueryItem] {
        var queryItems = [URLQueryItem]()
        if let dictionary = self.dictionary {
            for (key, value) in dictionary {
                queryItems.append(contentsOf: queryComponents(fromKey: key, value: value))
            }
        }
        return queryItems
    }
    
    private func queryComponents(fromKey key: String, value: Any) -> [URLQueryItem] {
        var components = [URLQueryItem]()
        if let dictionary = value as? [String: Any] {
            for (nestedKey, value) in dictionary {
                components += queryComponents(fromKey: "\(key)[\(nestedKey)]", value: value)
            }
        } else if let array = value as? [Any] {
            for value in array {
                components += queryComponents(fromKey: "\(key)[]", value: value)
            }
        } else if let bool = value as? Bool {
            components.append(URLQueryItem(name: key, value: (bool ? "1" : "0")))
        } else {
            components.append(URLQueryItem(name: key, value: "\(value)"))
        }
        
        return components
    }
}
