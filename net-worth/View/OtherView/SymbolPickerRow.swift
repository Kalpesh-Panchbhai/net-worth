//
//  SymbolPickerRow.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 30/11/23.
//

import SwiftUI

struct SymbolPickerRow: View {
    
    var symbol: SymbolDetailModel
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: self.action) {
            VStack {
                HStack {
                    Text(symbol.longname ?? "")
                    Spacer()
                    Text(symbol.symbol ?? "")
                }
                HStack {
                    ZStack{
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.5))
                            .frame(height: 15)
                        HStack{
                            Text("    " + (symbol.quoteType ?? "") + "    ")
                                .font(.system(size: 10))
                                .bold()
                        }
                    }.fixedSize()
                    Spacer()
                    ZStack{
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.5))
                            .frame(height: 15)
                        HStack{
                            Text("    " + (symbol.exchange ?? "") + "    ")
                                .font(.system(size: 10))
                                .bold()
                        }
                    }.fixedSize()
                    if self.isSelected {
                        Image(systemName: "checkmark")
                    }
                }
            }
        }
    }
}
