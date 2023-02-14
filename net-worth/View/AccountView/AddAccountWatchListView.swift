//
//  AddAccountWatchListView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 14/02/23.
//

import SwiftUI

struct AddAccountWatchListView: View {
    
    @ObservedObject var accountViewModel = AccountViewModel()
    @ObservedObject var watchViewModel: WatchViewModel
    @State var watch: Watch
    
    var body: some View {
        VStack {
            ScrollView(.vertical) {
                LazyVStack {
                    ForEach(accountViewModel.accountList, id: \.self) { account in
                        AddAccountWatchView(account: account, watch: $watch, isAdded: watch.accountID.contains(account.id!), watchViewModel: watchViewModel)
                    }
                }
            }
        }
        .onAppear {
            Task.init {
                await accountViewModel.getAccountList()
            }
        }
    }
}

struct AddAccountWatchView: View {
    
    var account: Account
    var watchController = WatchController()
    
    @Binding var watch: Watch
    @State var isAdded: Bool
    var watchViewModel: WatchViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(account.accountName)
                Text(account.accountType)
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }
            .padding()
            Spacer()
            VStack {
                if(isAdded) {
                    Image(systemName: "bookmark.fill")
                        .foregroundColor(.blue)
                        .onTapGesture {
                            isAdded.toggle()
                            self.watch.accountID = self.watch.accountID.filter { item in
                                item != account.id
                            }
                            watchController.addAccountToWatchList(watch: watch)
//                            Task.init {
//                                await watchViewModel.getAllWatchList()
//                            }
                        }
                } else {
                    Image(systemName: "bookmark")
                        .onTapGesture {
                            isAdded.toggle()
                            self.watch.accountID.append(account.id!)
                            watchController.addAccountToWatchList(watch: watch)
//                            Task.init {
//                                await watchViewModel.getAllWatchList()
//                            }
                        }
                }
            }
            .padding()
        }
        .frame(width: 350, height: 50)
        .background(.black)
        .foregroundColor(.white)
        .cornerRadius(10)
//        .padding()
    }
}
