//
//  AccountBrokerView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 01/12/23.
//

import SwiftUI

struct AccountBrokerView: View {
    
    var brokerID: String
    
    @ObservedObject var accountViewModel: AccountViewModel
    
    var body: some View {
        VStack {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack {
                    Spacer()
                    ForEach(0..<accountViewModel.accountsInBroker.count, id: \.self) { i in
                        NavigationLink(destination: {
                            AccountBrokerDetailView(brokerID: brokerID, accountID: accountViewModel.accountsInBroker[i].id!)
                        }, label: {
                            AccountBrokerRowView(brokerID: brokerID, accountID: accountViewModel.accountsInBroker[i].id!)
                                .frame(width: 360, height: 40)
                                .padding(8)
                                .background(Color.theme.foreground)
                                .cornerRadius(10)
                        })
                        .contextMenu {
                            Label(accountViewModel.accountsInBroker[i].id!, systemImage: "info.square")
                        }
                    }
                }
            }
            .padding(8)
            .background(Color.theme.background)
        }
    }
}
