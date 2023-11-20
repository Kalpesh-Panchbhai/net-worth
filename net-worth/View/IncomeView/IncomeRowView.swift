//
//  IncomeRowView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 25/05/23.
//

import SwiftUI

struct IncomeRowView: View {
    
    var income: IncomeCalculation
    var groupBy: String = ""
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                if(!groupBy.elementsEqual("Type")) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.theme.green.opacity(0.5))
                            .frame(width: 60, height: 15)
                        Text(income.type)
                            .font(.system(size: 10))
                            .bold()
                    }
                }
                if(!groupBy.elementsEqual("Tag")) {
                    ZStack{
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.5))
                            .frame(height: 15)
                        HStack{
                            Text("    " + income.tag + "    ")
                                .font(.system(size: 10))
                                .bold()
                        }
                    }.fixedSize()
                }
                Spacer()
                Text(income.creditedOn.getDateAndFormat())
                    .font(.system(size: 10))
                    .bold()
            }
            HStack {
                Text("\(income.currency) " + income.taxpaid.withCommas(decimalPlace: 2))
                    .font(.system(size: 10))
                Spacer()
                Text("\(income.currency) " + income.amount.withCommas(decimalPlace: 2))
                    .font(.system(size: 10))
            }
            HStack {
                Text("\(income.currency) " + income.cumulativeTaxPaid.withCommas(decimalPlace: 2))
                    .font(.system(size: 10))
                Spacer()
                Text("\(income.currency) " + income.cumulativeAmount.withCommas(decimalPlace: 2))
                    .font(.system(size: 10))
            }
            HStack {
                Text("\(income.currency) " + income.avgTaxPaid.withCommas(decimalPlace: 2))
                    .font(.system(size: 10))
                Spacer()
                Text("\(income.currency) " + income.avgAmount.withCommas(decimalPlace: 2))
                    .font(.system(size: 10))
            }
        }
        .background(Color.theme.foreground)
    }
}
