//
//  AccountHistoryView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 28/11/22.
//

import SwiftUI

struct AccountHistoryView: View {
    
    var accountTransactionList: [AccountTransaction]
    
    private var accountController = AccountController()
    
    init(account: Account) {
        accountTransactionList = self.accountController.getAccountTransaction(sysId: account.sysid!)
    }
    
    var body: some View {
        List {
            ForEach(0..<accountTransactionList.count, id: \.self) { i in
                HStack{
                    VStack {
                        Text("\(accountTransactionList[i].timestamp!.getDateAndFormat())")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("\(accountTransactionList[i].timestamp!.getTimeAndFormat())")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    VStack {
                        Text("\(accountTransactionList[i].balancechange.withCommas())")
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        if( i < accountTransactionList.count - 1) {
                            if((accountTransactionList[i].balancechange - accountTransactionList[i + 1].balancechange) > 0 ) {
                                Text("+\((accountTransactionList[i].balancechange - accountTransactionList[i + 1].balancechange).withCommas())")
                                    .frame(maxWidth: .infinity, alignment: .trailing).foregroundColor(.green)
                            } else if((accountTransactionList[i].balancechange - accountTransactionList[i + 1].balancechange) < 0 ) {
                                Text("\((accountTransactionList[i].balancechange - accountTransactionList[i + 1].balancechange).withCommas())")
                                    .frame(maxWidth: .infinity, alignment: .trailing).foregroundColor(.red)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct AccountHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        AccountHistoryView(account: Account())
    }
}
