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
            return String(format: "%.1fK", self / 1000).replacingOccurrences(of: ".0", with: "")
        }
        if self > 999999 {
            return String(format: "%.1fM", self / 1000000).replacingOccurrences(of: ".0", with: "")
        }
        
        return String(format: "%.0f", self)
    }
    
    static var random: Double {
        return Double(arc4random()) / Double(UInt32.max)
    }
    
    func abbreviated() -> String {
        let num = abs(self)
        let sign = self < 0 ? "-" : ""

        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0
        formatter.locale = Locale.current

        let (value, suffix): (Double, String) = {
            switch num {
            case 1_000_000_000...:
                return (self / 1_000_000_000, "B")
            case 1_000_000...:
                return (self / 1_000_000, "M")
            case 1_000...:
                return (self / 1_000, "K")
            default:
                return (self, "")
            }
        }()

        let formattedNumber = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        return "\(formattedNumber)\(suffix)"
    }
}
