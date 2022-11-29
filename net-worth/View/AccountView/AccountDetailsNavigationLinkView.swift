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
    
    private var accountController: AccountController
    
    private var account: Account
    
    @State private var selectedTabIndex = 0
    
    @State var isTransactionOpen: Bool = false
    
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
            if(account.accounttype == "Stock") {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Shares", action: {
                        self.isTransactionOpen.toggle()
                    }).sheet(isPresented: $isTransactionOpen, content: {
                        AddTransactionAccountView(account: self.account)
                    })
                }
            } else if(account.accounttype == "Mutual Fund") {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Units", action: {
                        self.isTransactionOpen.toggle()
                    }).sheet(isPresented: $isTransactionOpen, content: {
                        AddTransactionAccountView(account: self.account)
                    })
                }
            } else {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Transaction", action: {
                        self.isTransactionOpen.toggle()
                    }).sheet(isPresented: $isTransactionOpen, content: {
                        AddTransactionAccountView(account: self.account)
                    })
                }
            }
        }
        .padding(.top)
    }
}

struct AccountDetailsNavigationLinkView_Previews: PreviewProvider {
    static var previews: some View {
        AccountDetailsNavigationLinkView(uuid: UUID())
    }
}
