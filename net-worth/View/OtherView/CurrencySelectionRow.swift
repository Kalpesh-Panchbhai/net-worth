//
//  CurrenySelectionRow.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 13/05/23.
//

import SwiftUI

struct CurrencySelectionRow: View {
    
    var currency: Currency
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: self.action) {
            HStack {
                Text(currency.name)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(currency.symbol + " " + currency.code)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                if self.isSelected {
                    Spacer()
                    Image(systemName: "checkmark")
                }
            }
        }
    }
}
