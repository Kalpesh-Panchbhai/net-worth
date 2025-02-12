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
//                        Text(income.type)
//                            .font(.system(size: 10))
//                            .bold()
                    }
                }
                if(!groupBy.elementsEqual("Tag")) {
                    ZStack{
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.5))
                            .frame(height: 15)
//                        HStack{
//                            Text("    " + income.tag + "    ")
//                                .font(.system(size: 10))
//                                .bold()
//                        }
                    }.fixedSize()
                }
                Spacer()
                Text(income.creditedDate.getDateAndFormat())
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
                    Text("(\(incomeCumulativePercent(income: income).withCommas(decimalPlace: 2))%)")
                        .font(.system(size: 8))
                        .italic()
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
                    Text("(\(taxPaidCumulativePercent(income: income).withCommas(decimalPlace: 2))%)")
                        .font(.system(size: 8))
                        .italic()
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
                    Text("(100%)")
                        .font(.system(size: 8))
                        .italic()
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
                    Text("(\(incomeAveragePercent(income: income).withCommas(decimalPlace: 2))%)")
                        .font(.system(size: 8))
                        .italic()
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
                    Text("(\(taxPaidAveragePercent(income: income).withCommas(decimalPlace: 2))%)")
                        .font(.system(size: 8))
                        .italic()
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
                    Text("(100%)")
                        .font(.system(size: 8))
                        .italic()
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
                    Text("(\(incomePercent(income: income).withCommas(decimalPlace: 2))%)")
                        .font(.system(size: 8))
                        .italic()
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
                    Text("(\(taxPaidPercent(income: income).withCommas(decimalPlace: 2))%)")
                            .font(.system(size: 8))
                            .italic()
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
                        Text("(100%)")
                            .font(.system(size: 8))
                            .italic()
                }
            }
        }
        .background(Color.theme.foreground)
    }
    
    private func addIncomeAndTaxPaid(income: Income) -> Double {
        return income.amount + income.taxpaid
    }
    
    private func incomePercent(income: Income) -> Double {
        return income.amount / addIncomeAndTaxPaid(income: income) * 100
    }
    
    private func taxPaidPercent(income: Income) -> Double {
        return income.taxpaid / addIncomeAndTaxPaid(income: income) * 100
    }
    
    private func addIncomeAndTaxPaidCumulative(income: IncomeCalculation) -> Double {
        return income.cumulativeAmount + income.cumulativeTaxPaid
    }
    
    private func incomeCumulativePercent(income: IncomeCalculation) -> Double {
        return income.cumulativeAmount / addIncomeAndTaxPaidCumulative(income: income) * 100
    }
    
    private func taxPaidCumulativePercent(income: IncomeCalculation) -> Double {
        return income.cumulativeTaxPaid / addIncomeAndTaxPaidCumulative(income: income) * 100
    }
    
    private func addIncomeAndTaxPaidAverage(income: IncomeCalculation) -> Double {
        return income.avgAmount + income.avgTaxPaid
    }
    
    private func incomeAveragePercent(income: IncomeCalculation) -> Double {
        return income.avgAmount / addIncomeAndTaxPaidAverage(income: income) * 100
    }
    
    private func taxPaidAveragePercent(income: IncomeCalculation) -> Double {
        return income.avgTaxPaid / addIncomeAndTaxPaidAverage(income: income) * 100
    }
}
