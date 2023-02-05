//
//  AccountHistoryView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 28/11/22.
//

import SwiftUI

struct AccountHistoryView: View {
    
    @ObservedObject var accountViewModel = AccountViewModel()
    
    private var accountController = AccountController()
    
    private var account: Accountss
    
    init(account: Accountss) {
        self.account = account
    }
    
    var body: some View {
        List {
            ForEach(0..<accountViewModel.accountTransactionList.count, id: \.self) { i in
                HStack{
                    VStack {
                        Text("\(accountViewModel.accountTransactionList[i].timestamp.getDateAndFormat())")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("\(accountViewModel.accountTransactionList[i].timestamp.getTimeAndFormat())")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    VStack {
                        if(self.account.accountType == "Saving" || self.account.accountType == "Credit Card" || self.account.accountType == "Loan" || self.account.accountType == "Other") {
                            Text((account.currency) + " \(accountViewModel.accountTransactionList[i].balanceChange.withCommas(decimalPlace: 4))")
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        else {
                            Text(" \(accountViewModel.accountTransactionList[i].balanceChange.withCommas(decimalPlace: 4))")
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        if( i < accountViewModel.accountTransactionList.count - 1) {
                            if((accountViewModel.accountTransactionList[i].balanceChange - accountViewModel.accountTransactionList[i + 1].balanceChange) > 0 ) {
                                Text("+\((accountViewModel.accountTransactionList[i].balanceChange - accountViewModel.accountTransactionList[i + 1].balanceChange).withCommas(decimalPlace: 2))")
                                    .frame(maxWidth: .infinity, alignment: .trailing).foregroundColor(.green)
                            } else if((accountViewModel.accountTransactionList[i].balanceChange - accountViewModel.accountTransactionList[i + 1].balanceChange) < 0 ) {
                                Text("\((accountViewModel.accountTransactionList[i].balanceChange - accountViewModel.accountTransactionList[i + 1].balanceChange).withCommas(decimalPlace: 2))")
                                    .frame(maxWidth: .infinity, alignment: .trailing).foregroundColor(.red)
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            accountViewModel.getAccountTransactionList(id: account.id ?? "")
        }
    }
}
