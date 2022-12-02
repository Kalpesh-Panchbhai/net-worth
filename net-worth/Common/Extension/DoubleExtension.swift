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
}
