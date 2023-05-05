//
//  AddWatchListAccountView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 05/05/23.
//

import SwiftUI

struct AddWatchListAccountView: View {
    
    @ObservedObject var watchViewModel: WatchViewModel
    
    var account: Account
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer(minLength: 20)
                ScrollView(.vertical) {
                    LazyVStack {
                        ForEach(watchViewModel.watchList, id: \.self) { watchList in
                            AddWatchListForAccountView(account: account, watch: watchList, isAdded: watchList.accountID.contains(account.id!))
                        }
                    }
                }
            }
        }
        .onAppear {
            Task.init {
                await watchViewModel.getAllWatchList()
            }
        }
    }
}

struct AddWatchListForAccountView: View {
    
    var account: Account
    var watchController = WatchController()
    
    @State var watch: Watch
    @State var isAdded: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(watch.accountName)
            }
            .padding()
            Spacer()
            VStack {
                if(isAdded) {
                    Image(systemName: "bookmark.fill")
                        .foregroundColor(watch.accountName.elementsEqual("All") ? .gray : .blue)
                        .onTapGesture {
                            isAdded.toggle()
                            self.watch.accountID = self.watch.accountID.filter { item in
                                item != account.id
                            }
                            watchController.addAccountToWatchList(watch: watch)
                        }
                } else {
                    Image(systemName: "bookmark")
                        .onTapGesture {
                            isAdded.toggle()
                            self.watch.accountID.append(account.id!)
                            watchController.addAccountToWatchList(watch: watch)
                        }
                }
            }
            .disabled(watch.accountName.elementsEqual("All"))
            .padding()
        }
        .frame(width: 350, height: 50)
        .background(.black)
        .foregroundColor(.white)
        .cornerRadius(10)
    }
}
