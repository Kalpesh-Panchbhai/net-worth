//
//  AccountGroupedView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 07/02/23.
//

import SwiftUI

struct AccountGroupedView: View {
    
    @ObservedObject var accountViewModel : AccountViewModel
    
    var selection : Binding<Set<Account>>
    var searchKeyWord : Binding<String>
    
    var accountController = AccountController()
    
    init(accountViewModel: AccountViewModel, selection: Binding<Set<Account>>, searchKeyWord: Binding<String>) {
        self.accountViewModel = accountViewModel
        self.selection = selection
        self.searchKeyWord = searchKeyWord
    }
    
    var body: some View {
        VStack {
            List(selection: selection) {
                ForEach(accountViewModel.sectionHeaders, id: \.self) { key in
                    Section(header: Text(key).font(.title3).foregroundColor(.blue)) {
                        ForEach(accountViewModel.sectionContent(key: key, searchKeyword: searchKeyWord.wrappedValue), id: \.self) { account in
                            NavigationLink(destination: AccountDetailsNavigationLinkView(id: account.id!, accountViewModel: accountViewModel), label: {
                                 HStack{
                                     VStack {
                                         Text(account.accountName)
                                             .frame(maxWidth: .infinity, alignment: .leading)
                                         Text(account.accountType.uppercased()).font(.system(size: 10))
                                             .frame(maxWidth: .infinity, alignment: .leading)
                                             .foregroundColor(.gray)
                                     }
                                     Spacer()
                                     AccountFinanceView(account: account)
                                 }
                                 .foregroundColor(Color.blue)
                                 .padding()
                             })
                             .swipeActions {
                                 Button{
                                     accountController.deleteAccount(account: account)
                                     Task.init {
                                         await accountViewModel.getAccountList()
                                         await accountViewModel.getTotalBalance()
                                     }
                                 } label: {
                                     Label("Delete", systemImage: "trash")
                                 }
                                 .tint(.red)
                             }
                        }
                    }
                }
            }
        }
    }
}
