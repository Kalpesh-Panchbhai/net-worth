//
//  SingleWatchListView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 15/02/23.
//

import SwiftUI

struct SingleWatchListView: View {
    
    var watchList: Watch
    
    var body: some View {
        VStack {
            ScrollView(.vertical, showsIndicators: false) {
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
