//
//  ImageExtension.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 08/02/23.
//
import SwiftUI

extension Image {
    func data(url: URL) -> Self {
        if let data = try? Data(contentsOf: url) {
            return Image(uiImage: UIImage(data: data)!)
                .resizable()
        }
        return self
            .resizable()
    }
}
