//
//  AccountBrokerView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 01/12/23.
//

import SwiftUI

struct AccountBrokerView: View {
    
    var brokerID: Int
    @Binding var sortOrder: String
    @Binding var sortType: String
    
    var accountInBrokerController = AccountInBrokerController()
    
    @State var isPresentingAccountDeleteConfirm = false
    @State var isNewTransactionViewOpen = false
    @State var selectedAccount = AccountInBroker()

    
    @EnvironmentObject var accountViewModel: AccountViewModel
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack {
                    Spacer()
                    ForEach(0..<getAccountsInBrokerList().count, id: \.self) { i in
                        AccountBrokerRowView(account: getAccountsInBrokerList()[i])
                            .frame(width: 360, height: 40)
                            .padding(8)
                            .background(Color.theme.foreground)
                            .cornerRadius(10)
                            .contextMenu {
                                Button(action: {
                                    self.isNewTransactionViewOpen.toggle()
                                    self.selectedAccount = getAccountsInBrokerList()[i]
                                }, label: {
                                    Label("New Transaction", systemImage: ConstantUtils.newTransactionImageName)
                                })
                                
                                Button(role: .destructive, action: {
                                    self.isPresentingAccountDeleteConfirm.toggle()
                                    self.selectedAccount = getAccountsInBrokerList()[i]
                                }, label: {
                                    Label("Delete", systemImage: ConstantUtils.deleteImageName)
                                })
                            }
                    }
                }
                .confirmationDialog("Are you sure?",
                                    isPresented: $isPresentingAccountDeleteConfirm) {
                    Button("Delete account " + selectedAccount.name + "?", role: .destructive) {
                        Task.init {
                            await accountInBrokerController.deleteAccountInBroker(accountId: selectedAccount.id)
                            await accountViewModel.getAccountInBrokerList(brokerID: brokerID)
                        }
                    }
                }
            }
            .sheet(isPresented: $isNewTransactionViewOpen, content: {
                UpdateBalanceAccountBrokerView(brokerID: brokerID, accountBroker: selectedAccount)
                    .presentationDetents([.medium])
            })
            .padding(8)
            .background(Color.theme.background)
        }
    }
    
    private func getAccountsInBrokerList() -> [AccountInBroker] {
        var accountsInBrokerList = accountViewModel.accountsInBroker
        if(sortType.elementsEqual("Name")) {
            if(sortOrder.elementsEqual("Asc")) {
                accountsInBrokerList.sort(by: {
                    return $0.name <= $1.name
                })
            } else {
                accountsInBrokerList.sort(by: {
                    return $0.name >= $1.name
                })
            }
        } else if(sortType.elementsEqual("Amount")) {
            if(sortOrder.elementsEqual("Asc")) {
                accountsInBrokerList.sort(by: {
                    return $0.balance.currentBalance <= $1.balance.currentBalance
                })
            } else {
                accountsInBrokerList.sort(by: {
                    return $0.balance.currentBalance >= $1.balance.currentBalance
                })
            }
        } else if(sortType.elementsEqual("Price Change")) {
            if(sortOrder.elementsEqual("Asc")) {
                accountsInBrokerList.sort(by: {
                    return getOneDayChange(account: $0) <= getOneDayChange(account: $1)
                })
            } else {
                accountsInBrokerList.sort(by: {
                    return getOneDayChange(account: $0) >= getOneDayChange(account: $1)
                })
            }
        } else if(sortType.elementsEqual("Percentage Change")) {
            if(sortOrder.elementsEqual("Asc")) {
                accountsInBrokerList.sort(by: {
                    return getOneDayPercentageChange(account: $0) <= getOneDayPercentageChange(account: $1)
                })
            } else {
                accountsInBrokerList.sort(by: {
                    return getOneDayPercentageChange(account: $0) >= getOneDayPercentageChange(account: $1)
                })
            }
        }
        return accountsInBrokerList
    }
    
    private func getOneDayChange(account: AccountInBroker) -> Double {
        return areOneDayTransactions(account: account) ? account.balance.currentBalance - account.balance.previousBalance : 0.0
    }
    
    private func getOneDayPercentageChange(account: AccountInBroker) -> Double {
        return areOneDayTransactions(account: account) ? CommonController.getGrowthPercentageInDouble(previousBalance: account.balance.previousBalance, currentBalance: account.balance.currentBalance) : 0.0
    }
    
    private func areOneDayTransactions(account: AccountInBroker) -> Bool {
        return true
//        return account.name != "" && account.balance.currentBalance.dateTime.UTCToLocalDate() >= Date.now.addingTimeInterval(-86400)
    }
}
