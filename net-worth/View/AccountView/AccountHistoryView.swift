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
            ForEach(accountTransactionList, id: \.self) { accountTransaction in
                HStack{
                    VStack {
                        Text("\(accountTransaction.timestamp!.getDateAndFormat())")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("\(accountTransaction.timestamp!.getTimeAndFormat())")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Text("\(accountTransaction.balancechange.withCommas())")
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding()
            }
        }
    }
}

struct AccountHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        AccountHistoryView(account: Account())
    }
}
