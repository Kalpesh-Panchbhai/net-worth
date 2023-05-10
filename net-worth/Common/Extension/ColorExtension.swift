//
//  ColorExtension.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 10/05/23.
//

import Foundation
import SwiftUI

extension Color {
    static var random: Color {
        return Color(red: .random, green: .random, blue: .random)
    }
    
    static var navyBlue: Color {
        return Color(#colorLiteral(red: 0.06666666667, green: 0.1529411765, blue: 0.4352941176, alpha: 1))
    }
    
    static var lightBlue: Color {
        return Color(#colorLiteral(red: 0.3490196078, green: 0.7411764706, blue: 0.9568627451, alpha: 1))
    }
    
    static var white: Color {
        return Color(#colorLiteral(red: 0.9058823529, green: 0.9490196078, blue: 0.9803921569, alpha: 1))
    }
}
