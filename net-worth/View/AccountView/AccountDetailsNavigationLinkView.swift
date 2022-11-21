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
                AccountDetailsView(account: self.account)
            }
            Spacer()
        }.padding(.top)
    }
    
    private let accountFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter
    }()
}

struct AccountDetailsNavigationLinkView_Previews: PreviewProvider {
    static var previews: some View {
        AccountDetailsNavigationLinkView(uuid: UUID())
    }
}
