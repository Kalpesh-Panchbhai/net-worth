//
//  WithComma.swift
//  net-worth
//
import Foundation

extension Double {
    func withCommas() -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.roundingMode = .halfUp
        numberFormatter.maximumFractionDigits =  4
        return numberFormatter.string(from: NSNumber(value:self))!
    }
}
