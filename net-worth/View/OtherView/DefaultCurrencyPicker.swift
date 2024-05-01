//
//  CurrencyPicker.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 13/05/23.
//

import SwiftUI

struct DefaultCurrencyPicker: View {
    
    var settingsController = SettingsController()
    
    @State var filterCurrencyList = CurrencyList().currencyList
    @Binding var currenySelected: Currency
    
    var body: some View {
        NavigationLink(destination: {
            List {
                ForEach(filterCurrencyList, id: \.self) { (data) in
                    CurrencySelectionRow(currency: data, isSelected: self.currenySelected.name.elementsEqual(data.name), action: {
                        self.currenySelected = data
                        settingsController.setDefaultCurrency(newValue: data)
                    })
                }
                .listRowBackground(Color.theme.foreground)
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Default Currency")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.theme.background)
            .scrollContentBackground(.hidden)
            .foregroundColor(Color.theme.primaryText)
        }, label: {
            Label(title: {
                HStack {
                    Text("Default Currency")
                    Spacer()
                    Text(currenySelected.name)
                }
            }, icon: {
                Image(systemName: "indianrupeesign.square")
            })
        })
    }
}
