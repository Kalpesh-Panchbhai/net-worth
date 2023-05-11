//
//  AddAccountWatchListView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 14/02/23.
//

import SwiftUI

struct AddAccountToWatchListView: View {
    
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
                                        .foregroundColor(Color.lightBlue)
                                        .font(.system(size: 15))
                                }
                                ForEach(accountViewModel.sectionContent(key: accountType, searchKeyword: searchText), id: \.self) { account in
                                    AddAccountWatchView(account: account, watch: $watch, isAdded: watch.accountID.contains(account.id!), accountViewModel: accountViewModel)
                                }
                            }
                        }
                    }
                }
            }
            .background(Color.navyBlue)
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
    
    @ObservedObject var accountViewModel: AccountViewModel
    
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
                        .foregroundColor(Color.navyBlue)
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
                        .foregroundColor(Color.navyBlue)
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
        .background(Color.white)
        .foregroundColor(Color.navyBlue)
        .cornerRadius(10)
    }
}
