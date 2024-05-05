//
//  TransactionView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 09/02/23.
//

import SwiftUI

struct TransactionsView: View {
    
    var account: Account
    var accountTransactionList: [AccountTransaction]
    var accountTransactionController = AccountTransactionController()
    
    var body: some View {
        VStack {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack {
                    Spacer()
                    ForEach(0..<accountTransactionList.count, id: \.self) { i in
                        HStack{
                            VStack(alignment: .leading) {
                                Text(accountTransactionList[i].timestamp.convertFromGlideDateTimeFormat().getDateAndFormat())
                                    .font(.headline)
                                    .foregroundColor(Color.theme.primaryText)
                                    .padding(.horizontal)
                                HStack {
                                    Text(accountTransactionList[i].timestamp.convertFromGlideDateTimeFormat().getTimeAndFormat())
                                        .font(.system(size: 12))
                                        .foregroundColor(Color.theme.secondaryText)
                                        .padding(.leading)
                                    if(account.loanType.elementsEqual("Consumer")) {
                                        if(accountTransactionList[i].paid) {
                                            Text("Paid")
                                                .font(.system(size: 12).bold())
                                                .foregroundColor(Color.theme.green)
                                        } else {
                                            Text("Not Paid")
                                                .font(.system(size: 12).bold())
                                                .foregroundColor(Color.theme.red)
                                        }
                                    }
                                }
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                HStack {
                                    Text(account.currency)
                                        .font(.system(size: 14))
                                        .foregroundColor(Color.theme.secondaryText)
                                    Text(accountTransactionList[i].amount.withCommas(decimalPlace: 4))
                                        .font(.headline)
                                        .foregroundColor(Color.theme.primaryText)
                                }
                                .padding(.horizontal)
                                if( i < accountTransactionList.count - 1) {
                                    if(calculateOneDayChange(amount1: accountTransactionList[i].amount, amount2: accountTransactionList[i + 1].amount) > 0) {
                                        HStack {
                                            Text("+\(calculateOneDayChange(amount1: accountTransactionList[i].amount, amount2: accountTransactionList[i + 1].amount).withCommas(decimalPlace: 4))")
                                                .font(.system(size: 12))
                                                .foregroundColor(Color.theme.green)
                                            if(i < accountTransactionList.count - 1) {
                                                Text("(+" + calculatePercentChange(amount1: accountTransactionList[i].amount, amount2: accountTransactionList[i + 1].amount) + ")")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(Color.theme.green)
                                            }
                                        }
                                        .padding(.horizontal)
                                    } else if(calculateOneDayChange(amount1: accountTransactionList[i].amount, amount2: accountTransactionList[i + 1].amount) < 0) {
                                        HStack {
                                            Text("\(calculateOneDayChange(amount1: accountTransactionList[i].amount, amount2: accountTransactionList[i + 1].amount).withCommas(decimalPlace: 4))")
                                                .font(.system(size: 12))
                                                .foregroundColor(Color.theme.red)
                                            if(i < accountTransactionList.count - 1) {
                                                Text("(" + calculatePercentChange(amount1: accountTransactionList[i].amount, amount2: accountTransactionList[i + 1].amount) + ")")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(Color.theme.red)
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                        }
                        .frame(width: 360)
                        .contextMenu {
                            Label(accountTransactionList[i].id, systemImage: ConstantUtils.infoIconImageName)
                        }
                        .padding(8)
                        .background(Color.theme.foreground)
                        .cornerRadius(10)
                    }
                }
            }
            .padding(8)
            .background(Color.theme.background)
        }
    }
    
    private func calculateOneDayChange(amount1: Double, amount2: Double) -> Double {
        return amount1 - amount2
    }
    
    private func calculatePercentChange(amount1: Double, amount2: Double) -> String {
        return CommonController.getGrowthPercentage(previousBalance: amount2, currentBalance: amount1)
    }
}
