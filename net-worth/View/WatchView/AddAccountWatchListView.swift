//
//  AddAccountWatchListView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 14/02/23.
//

import SwiftUI

struct AddAccountWatchListView: View {
    
    @ObservedObject var accountViewModel = AccountViewModel()
    @State var watch: Watch
    
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer(minLength: 20)
                ScrollView(.vertical) {
                    LazyVStack {
                        ForEach(accountViewModel.sectionHeaders, id: \.self) { accountType in
                            if(accountViewModel.sectionContent(key: accountType, searchKeyword: searchText).count > 0) {
                                HStack {
                                    Text(accountType.uppercased())
                                        .bold()
                                        .foregroundColor(.white)
                                        .font(.system(size: 15))
                                }
                                ForEach(accountViewModel.sectionContent(key: accountType, searchKeyword: searchText), id: \.self) { account in
                                    AddAccountWatchView(account: account, watch: $watch, isAdded: watch.accountID.contains(account.id!))
                                }
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText)
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
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(account.accountName)
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
            .padding()
        }
        .frame(width: 350, height: 50)
        .background(.black)
        .foregroundColor(.white)
        .cornerRadius(10)
    }
}
