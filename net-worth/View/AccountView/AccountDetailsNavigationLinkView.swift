//
//  AccountDetailsView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 11/11/22.
//

import SwiftUI
import SlidingTabView

struct AccountDetailsNavigationLinkView: View {
    
    private var id: String
    
    @State private var paymentDate = 0
    @State var dates = Array(1...28)
    
    @State private var isTransactionOpen: Bool = false
    @State private var isDatePickerOpen: Bool = false
    
    private var accountController = AccountController()
    
    @State private var selectedTabIndex = 0
    
    @ObservedObject var accountViewModel : AccountViewModel
    
    @Environment(\.presentationMode) var presentationMode
    
    init(id: String, accountViewModel: AccountViewModel) {
        self.id = id
        self.accountViewModel = accountViewModel
    }
    
    var body: some View {
        VStack {
            SlidingTabView(selection: self.$selectedTabIndex
                           , tabs: ["Details", "History"]
                           , animation: .spring()
                           , activeAccentColor: .blue
                           , inactiveAccentColor: .gray
                           , selectionBarColor: .blue
                           , selectionBarBackgroundHeight: 3)
            .navigationBarTitleDisplayMode(NavigationBarItem.TitleDisplayMode.inline)
            .navigationBarTitle(self.accountViewModel.account.accountName)
            if(selectedTabIndex == 0) {
                AccountDetailsView(accountViewModel: accountViewModel)
            }else {
                AccountHistoryView(accountViewModel: accountViewModel)
            }
            Spacer()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        self.isTransactionOpen.toggle()
                    }, label: {
                        Label("Update Balance", systemImage: "square.and.pencil")
                    })
                    if(self.accountViewModel.account.accountType != "Saving") {
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
                                Task.init {
                                    await accountViewModel.getAccountList()
                                    await accountViewModel.getAccount(id: id)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        } else {
                            Button(action: {
                                accountViewModel.account.paymentReminder = false
                                accountViewModel.account.paymentDate = 0
                                accountController.updateAccount(account: accountViewModel.account)
                                NotificationController().removeNotification(id: accountViewModel.account.id!)
                                paymentDate = 0
                                Task.init {
                                    await accountViewModel.getAccountList()
                                    await accountViewModel.getAccount(id: id)
                                }
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
                                Task.init {
                                    await accountViewModel.getAccountList()
                                    await accountViewModel.getAccount(id: id)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            
                        }
                    }
                    Button(action: {
                        accountController.deleteAccount(account: accountViewModel.account)
                        Task.init {
                            await accountViewModel.getAccountList()
                            await accountViewModel.getTotalBalance()
                        }
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
        .halfSheet(showSheet: $isTransactionOpen) {
            UpdateBalanceAccountView(accountViewModel: accountViewModel)
        }
        .onAppear {
            Task.init {
                await accountViewModel.getAccount(id: id)
                await accountViewModel.getAccountTransactionList(id: id)
            }
        }
        .padding(.top)
    }
}
