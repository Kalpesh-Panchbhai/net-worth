//
//  DictionaryExtension.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 05/06/23.
//

import Foundation

extension Dictionary {
    mutating func switchKey(fromKey: Key, toKey: Key) {
        if let entry = removeValue(forKey: fromKey) {
            self[toKey] = entry
        }
    }
}
