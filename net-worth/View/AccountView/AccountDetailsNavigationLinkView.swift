//
//  AccountDetailsView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 11/11/22.
//

import SwiftUI
import SlidingTabView

struct AccountDetailsNavigationLinkView: View {
    
    @State private var account: Account
    
    @State private var paymentDate = 0
    @State var dates = Array(1...28)
    
    @State private var isTransactionOpen: Bool = false
    @State private var isDatePickerOpen: Bool = false
    
    private var accountController: AccountController
    
    @State private var selectedTabIndex = 0
    
    @ObservedObject var accountViewModel : AccountViewModel
    
    init(account: Account, accountViewModel: AccountViewModel) {
        self.account = account
        self.accountController = AccountController()
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
            .navigationBarTitle(self.account.accountName)
            if(selectedTabIndex == 0) {
                AccountDetailsView(account: self.account)
            }else {
                AccountHistoryView(account: self.account)
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
                    if(self.account.accountType != "Saving") {
                        if(!account.paymentReminder) {
                            Picker(selection: $paymentDate, content: {
                                Text("Select a date").tag(0)
                                ForEach(dates, id: \.self) {
                                    Text("\($0.formatted(.number.grouping(.never)))").tag($0)
                                }
                            }, label: {
                                Label("Enable Notification", systemImage: "speaker.wave.1.fill")
                            })
                            .onChange(of: paymentDate) { _ in
                                account.paymentReminder = true
                                account.paymentDate = paymentDate
                                AccountController().updateAccount(account: account)
                                NotificationController().enableNotification(account: account)
                            }
                            .pickerStyle(MenuPickerStyle())
                        } else {
                            Button(action: {
                                account.paymentReminder = false
                                account.paymentDate = 0
                                AccountController().updateAccount(account: account)
                                NotificationController().removeNotification(id: account.id!)
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
                                account.paymentDate = paymentDate
                                AccountController().updateAccount(account: account)
                                NotificationController().removeNotification(id: account.id!)
                                NotificationController().enableNotification(account: account)
                            }
                            .pickerStyle(MenuPickerStyle())
                            
                        }
                    }
                    Button(action: {
                        AccountController().deleteAccount(account: account)
                        Task.init {
                            await accountViewModel.getAccountList()
                            await accountViewModel.getAccount(id: account.id!)
                            await accountViewModel.getTotalBalance()
                        }
                        account = accountViewModel.account
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
            UpdateBalanceAccountView(account: $account, accountViewModel: accountViewModel)
        }
        .padding(.top)
    }
}
