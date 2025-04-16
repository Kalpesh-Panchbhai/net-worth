//
//  ColorExtension.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 10/05/23.
//

import Foundation
import SwiftUI

extension Color {
    
    static let theme = ColorTheme()
    
    static var random: Color {
        return Color(red: .random, green: .random, blue: .random)
    }
}

struct ColorTheme {
    
    let background = Color("ColorBackground")
    let foreground = Color("ColorForeground")
    let primaryText = Color("ColorPrimaryText")
    let secondaryText = Color("ColorSecondaryText")
    let green = Color("ColorGreen")
    let red = Color("ColorRed")
}
