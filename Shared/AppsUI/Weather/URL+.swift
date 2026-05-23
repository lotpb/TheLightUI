//
//  URL+.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/26/21.
//

import Foundation

extension URL {
    func load<T: Decodable>(
        _ type: T.Type = T.self,
        decoder: JSONDecoder = JSONDecoder()
    ) throws -> T {
        let data = try Data(contentsOf: self)
        return try decoder.decode(type, from: data)
    }
}
