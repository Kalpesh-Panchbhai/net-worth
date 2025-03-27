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
                ForEach(0..<accountViewModel.accountTransactionList.count, id: \.self, content: { rowIndex in
                    TransactionRow(accountTransaction: accountViewModel.accountTransactionList[rowIndex], type: type, change: getDifference(currentIndex: rowIndex, previousIndex: rowIndex + 1))
                        .contextMenu {
                            Button(role: .destructive, action: {
                                Task.init {
                                    await accountTransactionController.deleteAccountTransaction(id: accountViewModel.accountTransactionList[rowIndex].id)
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
    
    func getDifference(currentIndex: Int, previousIndex: Int) -> Double {
        return accountViewModel.accountTransactionList[currentIndex].value - (previousIndex == accountViewModel.accountTransactionList.count ? 0.0 : accountViewModel.accountTransactionList[previousIndex].value)
    }
}

struct TransactionRow: View {
    
    var accountTransaction: AccountTransactionRestModel
    var type: String
    var change: Double
    
    var body: some View {
        VStack {
            HStack {
                Text(accountTransaction.transactionDate.toFullDateFormat().getDateAndFormat())
                    .foregroundColor(Color.theme.primaryText)
                    .font(.system(size: 11).bold())
                Spacer()
                if(type.elementsEqual("account")) {
                    Text(SettingsController().getDefaultCurrency().code)
                        .foregroundColor(Color.theme.primaryText)
                        .font(.system(size: 11).bold())
                }
                Text(accountTransaction.value.withCommas(decimalPlace: 4))
                    .foregroundColor(Color.theme.primaryText)
                    .font(.system(size: 11).bold())
            }
            HStack {
                Spacer()
                if(change < 0) {
                    Text((type.elementsEqual("account") ? (SettingsController().getDefaultCurrency().code) : "") + " (\(change.withCommas(decimalPlace: 4)))")
                        .font(.system(size: 10))
                        .foregroundColor(Color.theme.red)
                        .padding(.leading)
                } else if(change > 0) {
                    Text((type.elementsEqual("account") ? (SettingsController().getDefaultCurrency().code) : "") + " (\(change.withCommas(decimalPlace: 4)))")
                        .font(.system(size: 10))
                        .foregroundColor(Color.theme.green)
                        .padding(.leading)
                }
            }
        }
    }
}
