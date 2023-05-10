//
//  CardView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 09/02/23.
//

import SwiftUI

struct AccountCardView: View {
    
    private var account: Account

    @StateObject var accountViewModel = AccountViewModel()
    
    init(account: Account) {
        self.account = account
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
            HStack {
                Text(account.accountName)
                    .foregroundColor(.black)
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                Spacer()
                if(account.paymentReminder && account.accountType != "Saving") {
                    Label("", systemImage: "bell.fill")
                        .foregroundColor(.black)
                        .font(.caption.bold())
                    Text("\(account.paymentDate)")
                        .foregroundColor(.black)
                        .font(.caption.bold())
                } else if(account.accountType != "Saving") {
                    Label("", systemImage: "bell.slash.fill")
                        .foregroundColor(.black)
                        .font(.caption.bold())
                }
            }
            Spacer()
            HStack(alignment: .center) {
                Text(account.currency)
                    .foregroundColor(.black)
                    .font(.caption.bold())
                Text("\(account.currentBalance.withCommas(decimalPlace: 2))")
                    .foregroundColor(.black)
                    .font(.caption.bold())
            }
            HStack {
                if(getTotalChangeForNonSymbol() >= 0) {
                    Text("\(getTotalChangeForNonSymbol().withCommas(decimalPlace: 2))")
                        .foregroundColor(.green)
                        .font(.system(size: 11).bold())
                        .padding(.bottom)
                    Text("(\(getOneDayPercentageChangeForNonSymbol().withCommas(decimalPlace: 2))%)")
                        .foregroundColor(.green)
                        .font(.system(size: 11).bold())
                        .padding(.bottom)
                } else {
                    Text("\(getTotalChangeForNonSymbol().withCommas(decimalPlace: 2))")
                        .foregroundColor(.red)
                        .font(.system(size: 11).bold())
                        .padding(.bottom)
                    Text("(\(getOneDayPercentageChangeForNonSymbol().withCommas(decimalPlace: 2))%)")
                        .foregroundColor(.red)
                        .font(.system(size: 11).bold())
                        .padding(.bottom)
                }
            }
        }
        .onAppear {
            Task.init {
                await accountViewModel.getLastTwoAccountTransactionList(id: account.id ?? "")
            }
        }
        .frame(width: 150, height: 100)
        .padding(8)
        .background(Color(#colorLiteral(red: 0.9058823529, green: 0.9490196078, blue: 0.9803921569, alpha: 1)))
        .cornerRadius(10)
    }
    
    func getTotalChangeForNonSymbol() -> Double {
        return accountViewModel.accountLastTwoTransactionList.count > 1 ? (accountViewModel.accountLastTwoTransactionList[0].balanceChange) : 0.0
    }
    
    func getOneDayPercentageChangeForNonSymbol() -> Double {
        return accountViewModel.accountLastTwoTransactionList.count > 1 ? ((getTotalChangeForNonSymbol() * 100 ) / accountViewModel.accountLastTwoTransactionList[1].currentBalance) : 0.0
    }
}
