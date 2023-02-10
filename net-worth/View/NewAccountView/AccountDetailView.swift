//
//  AccountDetailView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 10/02/23.
//

import SwiftUI

struct AccountDetailView: View {
    
    private var account: Account
    private var dates = Array(1...28)
    
    private var accountController = AccountController()
    
    @State private var isNewTransactionViewOpen = false
    @State private var paymentDate = 0
    
    @StateObject var accountViewModel = AccountViewModel()
    @StateObject var financeListViewModel = FinanceListViewModel()
    
    @Environment(\.presentationMode) var presentationMode
    
    init(account: Account) {
        self.account = account
    }
    
    var body: some View {
        VStack {
            AccountDetailCardView(financeListViewModel: financeListViewModel, accountViewModel: accountViewModel)
                .cornerRadius(20)
                .shadow(color: Color.gray, radius: 3)
            TransactionsView(accountViewModel: accountViewModel)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        self.isNewTransactionViewOpen.toggle()
                    }, label: {
                        Label("Add Transaction", systemImage: "square.and.pencil")
                    })
                    if(accountViewModel.account.accountType != "Saving") {
                        if(!accountViewModel.account.paymentReminder) {
                            Picker(selection: $paymentDate, content: {
                                Text("Select a date").tag(0)
                                ForEach(dates, id: \.self) {
                                    Text("\($0.formatted(.number.grouping(.never)))").tag($0)
                                }
                            }, label: {
                                Label("Enable Notification", systemImage: "speaker.wave.1.fill")
                            })
                            .onChange(of: paymentDate) { _ in
                                accountViewModel.account.paymentReminder = true
                                accountViewModel.account.paymentDate = paymentDate
                                accountController.updateAccount(account: accountViewModel.account)
                                NotificationController().enableNotification(account: accountViewModel.account)
                            }
                            .pickerStyle(MenuPickerStyle())
                        } else {
                            Button(action: {
                                accountViewModel.account.paymentReminder = false
                                accountViewModel.account.paymentDate = 0
                                accountController.updateAccount(account: accountViewModel.account)
                                NotificationController().removeNotification(id: accountViewModel.account.id!)
                                paymentDate = 0
                            }, label: {
                                Label("Disable Notification", systemImage: "speaker.slash.fill")
                            })
                            Picker(selection: $paymentDate, content: {
                                ForEach(dates, id: \.self) {
                                    Text("\($0.formatted(.number.grouping(.never)))").tag($0)
                                }
                            }, label: {
                                Label("Change Payment date", systemImage: "calendar.circle.fill")
                            })
                            .onChange(of: paymentDate) { _ in
                                accountViewModel.account.paymentDate = paymentDate
                                accountController.updateAccount(account: accountViewModel.account)
                                NotificationController().removeNotification(id: accountViewModel.account.id!)
                                NotificationController().enableNotification(account: accountViewModel.account)
                            }
                            .pickerStyle(MenuPickerStyle())
                            
                        }
                    }
                    Button(action: {
                        accountController.deleteAccount(account: accountViewModel.account)
                        self.presentationMode.wrappedValue.dismiss()
                    }, label: {
                        Label("Delete", systemImage: "trash")
                    })
                }
            label: {
                Label("", systemImage: "ellipsis.circle")
            }
            }
        }
        .halfSheet(showSheet: $isNewTransactionViewOpen) {
            UpdateBalanceAccountView(accountViewModel: accountViewModel, financeListViewModel: financeListViewModel)
        }
        .onAppear {
            Task.init {
                await financeListViewModel.getSymbolDetails(symbol: account.symbol)
                await accountViewModel.getAccount(id: account.id!)
                await accountViewModel.getAccountTransactionList(id: account.id!)
                await accountViewModel.getLastTwoAccountTransactionList(id: account.id!)
            }
        }
        .background(.black)
    }
}
