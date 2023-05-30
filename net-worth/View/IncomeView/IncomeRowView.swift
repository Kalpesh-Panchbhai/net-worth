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
                Text(income.creditedOn.getDateAndFormat()).font(.system(size: 12))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(Color.navyBlue.opacity(0.9))
                Text(income.tag).font(.system(size: 10))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(Color.navyBlue.opacity(0.9))
            }
            if(showTaxPaid) {
                VStack {
                    Text("\(income.currency) " + income.taxpaid.withCommas(decimalPlace: 2))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    Text("\(income.currency) \(income.avgTaxPaid.withCommas(decimalPlace: 2))").font(.system(size: 12))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .foregroundColor(Color.navyBlue.opacity(0.9))
                }
            } else {
                VStack {
                    Text("\(income.currency) " + income.amount.withCommas(decimalPlace: 2))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    Text("\(income.currency) \(income.avgAmount.withCommas(decimalPlace: 2))").font(.system(size: 12))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .foregroundColor(Color.navyBlue.opacity(0.9))
                }
            }
        }
    }
}
