//
//  CurrencyPicker.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 13/05/23.
//

import SwiftUI

struct DefaultCurrencyPicker: View {
    
    @State private var filterCurrencyList = CurrencyList().currencyList
    @Binding var currenySelected: Currency
    
    var settingsController = SettingsController()
    
    var body: some View {
        NavigationLink(destination: {
            List {
                ForEach(filterCurrencyList, id: \.self) { (data) in
                    CurrencySelectionRow(currency: data, isSelected: self.currenySelected.name.elementsEqual(data.name), action: {
                        self.currenySelected = data
                        settingsController.setDefaultCurrency(newValue: data)
                    })
                }
                .listRowBackground(Color.white)
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Default Currency")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.navyBlue)
            .scrollContentBackground(.hidden)
            .foregroundColor(Color.navyBlue)
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
