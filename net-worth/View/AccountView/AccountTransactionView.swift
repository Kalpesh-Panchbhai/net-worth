//
//  AccountBrokerView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 01/12/23.
//

import SwiftUI

struct AccountTransactionView: View {
        
    var accountTransactionController = AccountTransactionController()
    var id: Int
    var type: String
    
    @EnvironmentObject var accountViewModel: AccountViewModel
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                ForEach(accountViewModel.accountTransactionList, id: \.self, content: { accountTransaction in
                    TransactionRow(accountTransaction: accountTransaction)
                        .contextMenu {
                            Button(role: .destructive, action: {
                                Task.init {
                                    await accountTransactionController.deleteAccountTransaction(id: accountTransaction.id)
                                    await accountViewModel.getAccountTransactionList(accountID: id, type: type)
                                }
                            }, label: {
                                Label("Delete", systemImage: ConstantUtils.deleteImageName)
                            })
                        }
                })
                .listRowBackground(Color.theme.foreground)
                .foregroundColor(Color.theme.primaryText)
            }
            .background(Color.theme.background)
            .scrollContentBackground(.hidden)
        }
    }
}

struct TransactionRow: View {
    
    var accountTransaction: AccountTransactionRestModel
    
    var body: some View {
        VStack {
            HStack {
                Text(accountTransaction.transactionDate.toFullDateFormat().getDateAndFormat())
                    .foregroundColor(Color.theme.primaryText)
                    .font(.system(size: 11).bold())
                Spacer()
                Text(SettingsController().getDefaultCurrency().code)
                    .foregroundColor(Color.theme.primaryText)
                    .font(.system(size: 11).bold())
                Text(accountTransaction.value.withCommas(decimalPlace: 2))
                    .foregroundColor(Color.theme.primaryText)
                    .font(.system(size: 11).bold())
            }
        }
    }
}
