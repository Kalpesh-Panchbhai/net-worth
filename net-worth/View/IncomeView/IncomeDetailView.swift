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
                .foregroundColor(Color.navyBlue)
                
                HStack {
                    Text("Income Type")
                    Spacer()
                    Text(income.type)
                }
                .foregroundColor(Color.navyBlue)
                
                HStack {
                    Text("Amount")
                    Spacer()
                    Text(income.currency + " \(income.amount.withCommas(decimalPlace: 2))")
                }
                .foregroundColor(Color.navyBlue)
                
                HStack {
                    Text("Tax Paid")
                    Spacer()
                    Text(income.currency + " \(income.taxpaid.withCommas(decimalPlace: 2))")
                }
                .foregroundColor(Color.navyBlue)
                
                HStack {
                    Text("Credited On")
                    Spacer()
                    Text(income.creditedOn.getDateAndFormat())
                }
                .foregroundColor(Color.navyBlue)
                
            }
            .listRowBackground(Color.white)
            .foregroundColor(Color.lightBlue)
        }
        .background(Color.navyBlue)
        .scrollContentBackground(.hidden)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
            leading: Button(action: {
                self.presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(Color.lightBlue)
                    .bold()
            }
                .font(.system(size: 14).bold())
        )
    }
}
