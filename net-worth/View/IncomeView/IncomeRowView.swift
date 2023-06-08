//
//  IncomeRowView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 25/05/23.
//

import SwiftUI

struct IncomeRowView: View {
    
    var income: Income
    
    @Binding var showTaxPaid: Bool
    
    var body: some View {
        HStack{
            VStack {
                Text(income.type)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(Color.theme.primaryText)
                Text(income.creditedOn.getDateAndFormat()).font(.system(size: 12))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(Color.theme.primaryText.opacity(0.5))
                Text(income.tag).font(.system(size: 10))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(Color.theme.primaryText.opacity(0.5))
            }
            if(showTaxPaid) {
                VStack {
                    Text("\(income.currency) " + income.taxpaid.withCommas(decimalPlace: 2))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .foregroundColor(Color.theme.primaryText)
                    Text("\(income.currency) \(income.avgTaxPaid.withCommas(decimalPlace: 2))").font(.system(size: 12))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .foregroundColor(Color.theme.primaryText.opacity(0.5))
                    Text("\(income.currency) \(income.cumulativeTaxPaid.withCommas(decimalPlace: 2))").font(.system(size: 12))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .foregroundColor(Color.theme.primaryText.opacity(0.5))
                }
            } else {
                VStack {
                    Text("\(income.currency) " + income.amount.withCommas(decimalPlace: 2))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .foregroundColor(Color.theme.primaryText)
                    Text("\(income.currency) \(income.avgAmount.withCommas(decimalPlace: 2))").font(.system(size: 12))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .foregroundColor(Color.theme.primaryText.opacity(0.5))
                    Text("\(income.currency) \(income.cumulativeAmount.withCommas(decimalPlace: 2))").font(.system(size: 12))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .foregroundColor(Color.theme.primaryText.opacity(0.5))
                }
            }
        }
    }
}
