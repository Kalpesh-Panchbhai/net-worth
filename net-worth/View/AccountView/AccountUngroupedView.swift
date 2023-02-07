//
//  AccountUngroupedView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 07/02/23.
//

import SwiftUI

struct AccountUngroupedView: View {
    
    @ObservedObject var accountViewModel : AccountViewModel
    
    var selection : Binding<Set<Account>>
    
    var searchKeyWord : Binding<String>
    
    var accountController = AccountController()
    
    init(accountViewModel: AccountViewModel, selection: Binding<Set<Account>>, searchKeyWord: Binding<String>) {
        self.accountViewModel = accountViewModel
        self.selection = selection
        self.searchKeyWord = searchKeyWord
    }
    
    var searchResults: [Account] {
        accountViewModel.accountList.filter { account in
            if(searchKeyWord.wrappedValue.isEmpty) {
                return true
            } else {
                return account.accountName.lowercased().contains(searchKeyWord.wrappedValue.lowercased()) || account.accountType.lowercased().contains(searchKeyWord.wrappedValue.lowercased())
            }
        }
    }
    
    var body: some View {
        VStack {
            List(selection: selection) {
                ForEach(searchResults, id: \.self) { account in
                    NavigationLink(destination: AccountDetailsNavigationLinkView(account: account, accountViewModel: accountViewModel), label: {
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
                            accountViewModel.getAccountList()
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
