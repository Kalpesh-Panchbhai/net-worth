//
//  SwiftUIView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 25/05/23.
//

import SwiftUI

struct RowAccountToWatchView: View {
    
    var account: Account
    var watchController = WatchController()
    
    @Binding var watch: Watch
    @State var isAdded: Bool
    
    @ObservedObject var accountViewModel: AccountViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(account.accountName)
                    .foregroundColor(Color.theme.primaryText)
            }
            .padding()
            Spacer()
            VStack {
                if(isAdded) {
                    Image(systemName: "bookmark.fill")
                        .foregroundColor(Color.theme.primaryText)
                        .bold()
                        .onTapGesture {
                            isAdded.toggle()
                            self.watch.accountID = self.watch.accountID.filter { item in
                                item != account.id
                            }
                            watchController.addAccountToWatchList(watch: watch)
                        }
                } else {
                    Image(systemName: "bookmark")
                        .foregroundColor(Color.theme.primaryText)
                        .bold()
                        .onTapGesture {
                            isAdded.toggle()
                            self.watch.accountID.append(account.id!)
                            self.watch.accountID.sort(by: { item1, item2 in
                                accountViewModel.accountList.filter { account1 in
                                    account1.id!.elementsEqual(item1)
                                }.first!.accountName <= accountViewModel.accountList.filter { account2 in
                                    account2.id!.elementsEqual(item2)
                                }.first!.accountName
                            })
                            watchController.addAccountToWatchList(watch: watch)
                        }
                }
            }
            .padding()
        }
        .frame(width: 350, height: 50)
        .background(Color.theme.foreground)
        .foregroundColor(Color.theme.primaryText)
        .cornerRadius(10)
    }
}
