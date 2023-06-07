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
                .listRowBackground(Color.theme.background)
            }
            .shadow(color: Color.theme.text.opacity(0.3), radius: 10, x: 0, y: 5)
            .scrollIndicators(.hidden)
            .navigationTitle("Default Currency")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.theme.background)
            .scrollContentBackground(.hidden)
            .foregroundColor(Color.theme.text)
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
