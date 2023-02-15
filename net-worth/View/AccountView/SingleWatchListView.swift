//
//  SingleWatchListView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 15/02/23.
//

import SwiftUI

struct SingleWatchListView: View {
    
    var watchList: Watch
    
    @StateObject private var accountViewModel = AccountViewModel()
    
    var body: some View {
        VStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack {
                    BalanceCardView(accountViewModel: accountViewModel, accountType: watchList.accountName, isWatchListCardView: true, watchList: watchList)
                        .frame(width: 360)
                        .cornerRadius(10)
                }
                .shadow(color: Color.gray, radius: 3)
                
                LazyVStack {
                    ForEach(watchList.accountID, id: \.self) { account in
                        AccountRowView(account: Account(id: account))
                            .shadow(color: Color.gray, radius: 3)
                    }
                    .padding(10)
                }
            }
        }
    }
}
