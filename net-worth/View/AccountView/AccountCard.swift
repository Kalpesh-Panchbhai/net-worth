//
//  SwiftUIView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 12/06/23.
//

import SwiftUI

struct AccountCard: View {
    
    var account: Account
    
    @Binding var isNewTransactionViewOpen: Bool
    @Binding var isPresentingAccountDeleteConfirm: Bool
    @Binding var deletedAccount: Account
    
    @ObservedObject var accountViewModel: AccountViewModel
    @ObservedObject var watchViewModel: WatchViewModel
    
    var body: some View {
        VStack {
            NavigationLink(destination: {
                AccountDetailView(account: account,accountViewModel:  accountViewModel, watchViewModel: watchViewModel)
                    .toolbarRole(.editor)
            }) {
                AccountCardView(account: account)
                    .contextMenu {
                        
                        Label(account.id!, systemImage: "info.square")
                        
                        Button(role: .destructive, action: {
                            isPresentingAccountDeleteConfirm.toggle()
                            deletedAccount = account
                        }, label: {
                            Label("Delete", systemImage: "trash")
                        })
                        
                        if(account.active) {
                            Button {
                                Task.init {
                                    await accountViewModel.getAccount(id: account.id!)
                                }
                                isNewTransactionViewOpen.toggle()
                            } label: {
                                Label("New Transaction", systemImage: "square.and.pencil")
                            }
                        }
                    }
            }
        }
    }
}
