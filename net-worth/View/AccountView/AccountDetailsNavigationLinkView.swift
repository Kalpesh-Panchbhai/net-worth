//
//  AccountDetailsView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 11/11/22.
//

import SwiftUI
import SlidingTabView

struct AccountDetailsNavigationLinkView: View {
    
    private var uuid: UUID
    
    @State private var paymentDate = 0
    @State var dates = Array(1...28)
    
    @State private var isTransactionOpen: Bool = false
    @State private var isDatePickerOpen: Bool = false
    
    private var accountController: AccountController
    
    private var account: Account
    
    @State private var selectedTabIndex = 0
    
    init(uuid: UUID) {
        self.uuid = uuid
        self.accountController = AccountController()
        self.account = accountController.getAccount(uuid: uuid)
    }
    
    var body: some View {
        VStack {
            SlidingTabView(selection: self.$selectedTabIndex
                           , tabs: ["Details", "History"]
                           , animation: .easeOut
                           , activeAccentColor: .blue
                           , inactiveAccentColor: .blue
                           , selectionBarColor: .blue)
            .navigationBarTitleDisplayMode(NavigationBarItem.TitleDisplayMode.inline)
            .navigationBarTitle(self.account.accountname!)
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
                    if(self.account.accounttype != "Saving") {
                        if(!account.paymentreminder) {
                            Picker(selection: $paymentDate, content: {
                                Text("Select a date").tag(0)
                                ForEach(dates, id: \.self) {
                                    Text("\($0.formatted(.number.grouping(.never)))").tag($0)
                                }
                            }, label: {
                                Label("Enable Notification", systemImage: "speaker.wave.1.fill")
                            })
                            .onChange(of: paymentDate) { _ in
                                account.paymentreminder = true
                                account.paymentdate = Int16(paymentDate)
                                AccountController().updateAccount()
                                NotificationController().enableNotification(account: account)
                            }
                            .pickerStyle(MenuPickerStyle())
                        } else {
                            Button(action: {
                                account.paymentreminder = false
                                account.paymentdate = 0
                                AccountController().updateAccount()
                                NotificationController().removeNotification(id: account.sysid!)
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
                                account.paymentdate = Int16(paymentDate)
                                AccountController().updateAccount()
                                NotificationController().removeNotification(id: account.sysid!)
                                NotificationController().enableNotification(account: account)
                            }
                            .pickerStyle(MenuPickerStyle())
                            
                        }
                    }
                    Button(action: {
                        AccountController().deleteAccount(account: account)
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
            UpdateBalanceAccountView(account: self.account)
        }
        .padding(.top)
    }
}

struct AccountDetailsNavigationLinkView_Previews: PreviewProvider {
    static var previews: some View {
        AccountDetailsNavigationLinkView(uuid: UUID())
    }
}
