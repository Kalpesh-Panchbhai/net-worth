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
    
    let accent = Color("AccentColor")
    let background = Color("BackgroundColor")
    let foreground = Color("ForegroundColor")
    let foreground2 = Color("ForegroundColor2")
    let primaryText = Color("PrimaryTextColor")
    let secondaryText = Color("SecondaryTextColor")
    let green = Color("GreenColor")
    let red = Color("RedColor")
}

