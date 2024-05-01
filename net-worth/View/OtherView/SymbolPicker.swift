//
//  FinancePicker.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 30/11/23.
//

import SwiftUI

struct SymbolPicker: View {
    
    @StateObject var financeViewModel = FinanceViewModel()
    
    @State var search = ""
    
    @Binding var symbolSelected: SymbolDetailModel
    
    var body: some View {
        NavigationLink(destination: {
            List {
                ForEach(financeViewModel.symbolList, id: \.self) { (symbol) in
                    SymbolPickerRow(symbol: symbol, isSelected: symbolSelected.symbol!.elementsEqual(symbol.symbol!), action: {
                        self.symbolSelected = symbol
                    })
                }
                .listRowBackground(Color.theme.foreground)
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Symbol")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.theme.background)
            .scrollContentBackground(.hidden)
            .foregroundColor(Color.theme.primaryText)
            .searchable(text: $search)
            .onChange(of: search, perform: { _ in
                Task.init {
                    await financeViewModel.getAllSymbol(search: search)
                }
            })
        }, label: {
            if(symbolSelected.symbol!.isEmpty) {
                HStack {
                    Text("Search Symbol")
                }
            } else {
                HStack {
                    Text("Symbol")
                    Spacer()
                    Text(symbolSelected.longname ?? "")
                }
            }
        })
        .onAppear(perform: {
            Task.init {
                await financeViewModel.getAllSymbol(search: search)
            }
        })
    }
}
