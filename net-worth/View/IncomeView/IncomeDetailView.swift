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
                HStack {
                    Text("Income Type")
                    Spacer()
                    Text(income.type)
                }
                HStack {
                    Text("Amount")
                    Spacer()
                    Text("\(income.amount.withCommas(decimalPlace: 2))")
                }
                HStack {
                    Text("Tax Paid")
                    Spacer()
                    Text("\(income.taxpaid.withCommas(decimalPlace: 2))")
                }
                HStack {
                    Text("Credited On")
                    Spacer()
                    Text(income.creditedOn.getDateAndFormat())
                }
                HStack {
                    Text("Currency")
                    Spacer()
                    Text(income.currency)
                }
            }
        }
    }
}
