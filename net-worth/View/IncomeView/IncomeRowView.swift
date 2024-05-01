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
    
    var showCumulative: Bool
    var showAverage: Bool
    
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
            if(showCumulative) {
                HStack {
                    Text("Cumulative Income: ")
                        .font(.system(size: 10))
                    Spacer()
                    Text("\(income.currency)")
                        .font(.system(size: 10))
                    Text(income.cumulativeAmount.withCommas(decimalPlace: 2))
                        .font(.system(size: 10))
                        .bold()
                }
                HStack {
                    Text("Cumulative Tax Paid: ")
                        .font(.system(size: 10))
                    Spacer()
                    Text("\(income.currency)")
                        .font(.system(size: 10))
                    Text(income.cumulativeTaxPaid.withCommas(decimalPlace: 2))
                        .font(.system(size: 10))
                        .bold()
                }
                HStack {
                    Text("Cumulative Total: ")
                        .font(.system(size: 10))
                    Spacer()
                    Text("\(income.currency)")
                        .font(.system(size: 10))
                    Text(addIncomeAndTaxPaidCumulative(income: income).withCommas(decimalPlace: 2))
                        .font(.system(size: 10))
                        .bold()
                }
            } else if(showAverage) {
                HStack {
                    Text("Average Income: ")
                        .font(.system(size: 10))
                    Spacer()
                    Text("\(income.currency)")
                        .font(.system(size: 10))
                    Text(income.avgAmount.withCommas(decimalPlace: 2))
                        .font(.system(size: 10))
                        .bold()
                }
                HStack {
                    Text("Average Tax Paid: ")
                        .font(.system(size: 10))
                    Spacer()
                    Text("\(income.currency)")
                        .font(.system(size: 10))
                    Text(income.avgTaxPaid.withCommas(decimalPlace: 2))
                        .font(.system(size: 10))
                        .bold()
                }
                HStack {
                    Text("Average Total: ")
                        .font(.system(size: 10))
                    Spacer()
                    Text("\(income.currency)")
                        .font(.system(size: 10))
                    Text(addIncomeAndTaxPaidAverage(income: income).withCommas(decimalPlace: 2))
                        .font(.system(size: 10))
                        .bold()
                }
            } else {
                HStack {
                    Text("Income: ")
                        .font(.system(size: 10))
                    Spacer()
                    Text("\(income.currency)")
                        .font(.system(size: 10))
                    Text(income.amount.withCommas(decimalPlace: 2))
                        .font(.system(size: 10))
                        .bold()
                }
                HStack {
                    Text("Tax Paid: ")
                        .font(.system(size: 10))
                    Spacer()
                    Text("\(income.currency)")
                        .font(.system(size: 10))
                    Text(income.taxpaid.withCommas(decimalPlace: 2))
                        .font(.system(size: 10))
                        .bold()
                }
                HStack {
                    Text("Total: ")
                        .font(.system(size: 10))
                    Spacer()
                    Text("\(income.currency)")
                        .font(.system(size: 10))
                    Text(addIncomeAndTaxPaid(income: income).withCommas(decimalPlace: 2))
                        .font(.system(size: 10))
                        .bold()
                }
            }
        }
        .background(Color.theme.foreground)
    }
    
    private func addIncomeAndTaxPaid(income: Income) -> Double {
        return income.amount + income.taxpaid
    }
    
    private func addIncomeAndTaxPaidCumulative(income: IncomeCalculation) -> Double {
        return income.cumulativeAmount + income.cumulativeTaxPaid
    }
    
    private func addIncomeAndTaxPaidAverage(income: IncomeCalculation) -> Double {
        return income.avgAmount + income.avgTaxPaid
    }
}
