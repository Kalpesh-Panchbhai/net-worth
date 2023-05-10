//
//  IncomeDetailView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 25/04/23.
//

import SwiftUI

struct IncomeDetailView: View {
    
    var income: Income
    
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
                    Text("\(income.amount.withCommas(decimalPlace: 2))")
                }
                .foregroundColor(Color.navyBlue)
                
                HStack {
                    Text("Tax Paid")
                    Spacer()
                    Text("\(income.taxpaid.withCommas(decimalPlace: 2))")
                }
                .foregroundColor(Color.navyBlue)
                
                HStack {
                    Text("Credited On")
                    Spacer()
                    Text(income.creditedOn.getDateAndFormat())
                }
                .foregroundColor(Color.navyBlue)
                
                HStack {
                    Text("Currency")
                    Spacer()
                    Text(income.currency)
                }
                .foregroundColor(Color.navyBlue)
                
            }
            .listRowBackground(Color.white)
        }
        .background(Color.navyBlue)
        .scrollContentBackground(.hidden)
    }
}
