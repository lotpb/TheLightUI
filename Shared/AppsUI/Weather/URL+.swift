//
//  URL+.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/26/21.
//

import Foundation

extension URL {
    func load<T: Decodable>() throws -> T {
        let data = try Data(contentsOf: self)
        return try JSONDecoder().decode(T.self, from: data)
    }
}
