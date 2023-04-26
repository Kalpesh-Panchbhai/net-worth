//
//  WithComma.swift
//  net-worth
//
import Foundation

extension Double {
    func withCommas(decimalPlace: Int) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.roundingMode = .halfUp
        numberFormatter.minimumFractionDigits =  decimalPlace
        numberFormatter.maximumFractionDigits =  decimalPlace
        numberFormatter.paddingPosition = .afterPrefix
        numberFormatter.paddingCharacter = "0"
        return numberFormatter.string(from: NSNumber(value:self))!
    }
    
    func formatter() -> NumberFormatter {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.roundingMode = .halfUp
        numberFormatter.minimumFractionDigits =  4
        numberFormatter.maximumFractionDigits =  4
        numberFormatter.paddingPosition = .afterPrefix
        numberFormatter.paddingCharacter = "0"
        return numberFormatter
    }
    
    var stringFormat: String {
        if self > 10000 && self < 999999 {
            return String(format: "%.2fK", self / 1000).replacingOccurrences(of: ".0", with: "")
        }
        if self > 999999 {
            return String(format: "%.2fM", self / 1000000).replacingOccurrences(of: ".0", with: "")
        }
        
        return String(format: "%.0f", self)
    }
}
