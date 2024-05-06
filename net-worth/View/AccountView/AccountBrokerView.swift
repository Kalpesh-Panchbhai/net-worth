//
//  AccountBrokerView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 01/12/23.
//

import SwiftUI

struct AccountBrokerView: View {
    
    var brokerID: String
    
    var accountInBrokerController = AccountInBrokerController()
    
    @State var isPresentingAccountDeleteConfirm = false
    @State var deletedAccount = AccountInBroker()
    
    @ObservedObject var accountViewModel: AccountViewModel
    
    var body: some View {
        VStack {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack {
                    Spacer()
                    ForEach(0..<accountViewModel.accountsInBroker.count, id: \.self) { i in
                        NavigationLink(destination: {
                            AccountBrokerDetailView(accountID: accountViewModel.accountsInBroker[i].id, accountViewModel: accountViewModel)
                        }, label: {
                            AccountBrokerRowView(account: accountViewModel.accountsInBroker[i])
                                .frame(width: 360, height: 40)
                                .padding(8)
                                .background(Color.theme.foreground)
                                .cornerRadius(10)
                        })
                        .contextMenu {
                            Label(accountViewModel.accountsInBroker[i].id, systemImage: ConstantUtils.infoIconImageName)
                            
//                            Button(role: .destructive, action: {
//                                isPresentingAccountDeleteConfirm.toggle()
//                                deletedAccount = accountViewModel.accountsInBroker[i]
//                            }, label: {
//                                Label("Delete", systemImage: ConstantUtils.deleteImageName)
//                            })
                        }
//                        .confirmationDialog("Are you sure?",
//                                            isPresented: $isPresentingAccountDeleteConfirm) {
//                            Button("Delete account " + deletedAccount.name + "?", role: .destructive) {
//                            }
//                        }
                    }
                }
            }
            .padding(8)
            .background(Color.theme.background)
        }
    }
}
