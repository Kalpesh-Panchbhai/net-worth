//
//  IncomeDetailView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 25/04/23.
//

import SwiftUI

struct IncomeDetailView: View {
    
    var income: Income
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        Form {
            Section("Income detail") {
                HStack {
                    Text("Income Tag")
                    Spacer()
                    Text(income.tag)
                }
                
                HStack {
                    Text("Income Type")
                    Spacer()
                    Text(income.type)
                }
                
                HStack {
                    Text("Amount")
                    Spacer()
                    Text(income.currency + " \(income.amount.withCommas(decimalPlace: 2))")
                }
                
                HStack {
                    Text("Tax Paid")
                    Spacer()
                    Text(income.currency + " \(income.taxpaid.withCommas(decimalPlace: 2))")
                }
                
                HStack {
                    Text("Credited On")
                    Spacer()
                    Text(income.creditedOn.getDateAndFormat())
                }
                
            }
            .listRowBackground(Color.theme.foreground)
            .foregroundColor(Color.theme.primaryText)
        }
        .background(Color.theme.background)
        .scrollContentBackground(.hidden)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
            leading: Button(action: {
                self.presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(Color.theme.primaryText)
                    .bold()
            }
                .font(.system(size: 14).bold())
        )
    }
}
