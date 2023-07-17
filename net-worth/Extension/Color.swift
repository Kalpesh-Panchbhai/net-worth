//
//  ColorExtension.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 10/05/23.
//

import Foundation
import SwiftUI

extension Color {
    
    static let theme = ColorTheme2()
    
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

struct ColorTheme2 {
    
    let accent = Color("AccentColorNew")
    let background = Color("BackgroundColorNew")
    let foreground = Color("ForegroundColorNew")
    let foreground2 = Color("ForegroundColor2New")
    let primaryText = Color("PrimaryTextColorNew")
    let secondaryText = Color("SecondaryTextColorNew")
    let green = Color("GreenColorNew")
    let red = Color("RedColorNew")
}
