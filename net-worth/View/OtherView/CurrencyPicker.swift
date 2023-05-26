//
//  CurrencyPicker.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 13/05/23.
//

import SwiftUI

struct CurrencyPicker: View {
    
    @State var filterCurrencyList = CurrencyList().currencyList
    @Binding var currenySelected: Currency
    
    var body: some View {
        NavigationLink(destination: {
            List {
                ForEach(filterCurrencyList, id: \.self) { (data) in
                    CurrencySelectionRow(currency: data, isSelected: self.currenySelected.name.elementsEqual(data.name), action: {
                        self.currenySelected = data
                    })
                }
                .listRowBackground(Color.white)
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Currency")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.navyBlue)
            .scrollContentBackground(.hidden)
            .foregroundColor(Color.navyBlue)
        }, label: {
            if(currenySelected.name.isEmpty) {
                HStack {
                    Text("Select Currency")
                }
            } else {
                HStack {
                    Text("Currency")
                    Spacer()
                    Text(currenySelected.name)
                }
            }
        })
    }
}
