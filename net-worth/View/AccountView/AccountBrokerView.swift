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
                            AccountBrokerDetailView(brokerID: brokerID, accountBroker: accountViewModel.accountsInBroker[i])
                        }, label: {
                            AccountBrokerRowView(accountBroker: accountViewModel.accountsInBroker[i])
                                .frame(width: 360)
                                .padding(8)
                                .background(Color.theme.foreground)
                                .cornerRadius(10)
                        })
                    }
                }
            }
            .padding(8)
            .background(Color.theme.background)
        }
    }
}
