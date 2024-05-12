//
//  SingleWatchListView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 15/02/23.
//

import SwiftUI

struct WatchDetailView: View {
    
    var watchController = WatchController()
    
    @State var watch: Watch
    @State var isNewTransactionViewOpen = false
    @State var addAccountViewOpen = false
    @State var isAscendingByAlphabetEnabled = true
    @State var isAscendingByAmountEnabled = false
    @State var hideInactiveAccount = true
    @State var hideZeroBalanceAccount = true
    @State var isAscendingEnabled = true
    
    @ObservedObject var accountViewModel: AccountViewModel
    @ObservedObject var watchViewModel: WatchViewModel
    
    @Environment(\.presentationMode) var presentationMode
    
    init(watch: Watch, accountViewModel: AccountViewModel, watchViewModel: WatchViewModel) {
        self.watch = watch
        self.accountViewModel = accountViewModel
        self.watchViewModel = watchViewModel
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.theme.background.ignoresSafeArea()
                VStack {
                    if(watch.accountList.count > 0) {
                        // MARK: Balance Card
                        VStack {
                            BalanceCardView(accountType: watch.name, isWatchListCardView: true, watchList: watch, accountViewModel: accountViewModel)
                                .frame(width: 360, height: 70)
                                .cornerRadius(10)
                        }
                        .padding(.top, 5)
                        Divider()
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack {
                                ForEach(watch.accountList, id: \.self) { accountID in
                                    NavigationLink(destination: {
                                        // MARK: Account Detail View
                                        AccountDetailView(accountID: accountID, accountViewModel: accountViewModel, watchViewModel: watchViewModel)
                                            .toolbarRole(.editor)
                                    }, label: {
                                        AccountRowView(account: getAccountForWatchListAccount(accountId: accountID), fromWatchView: true)
                                    })
                                }
                                .padding(10)
                            }
                        }
                        .padding(10)
                    }
                }
            }
        }
        .navigationTitle(watch.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
            leading: Button(action: {
                self.presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: ConstantUtils.backbuttonImageName)
                    .foregroundColor(Color.theme.primaryText)
                    .bold()
            }
                .font(.system(size: 14).bold())
        )
        .toolbar {
            if(!watch.name.elementsEqual("All")) {
                ToolbarItem(content: {
                    Button(action: {
                        self.addAccountViewOpen.toggle()
                    }, label: {
                        Image(systemName: ConstantUtils.plusImageName)
                            .foregroundColor(Color.theme.primaryText)
                            .bold()
                    })
                    .font(.system(size: 14).bold())
                })
            }
        }
        .sheet(isPresented: $addAccountViewOpen, onDismiss: {
            self.watch = self.watchViewModel.watchList.first(where: {
                return $0.id.elementsEqual(watch.id)
            })!
            var watchSorted = self.watch
            watchSorted.accountList.sort(by: { item1, item2 in
                accountViewModel.accountList.filter { account1 in
                    account1.id.elementsEqual(item1)
                }.first!.accountName <= accountViewModel.accountList.filter { account2 in
                    account2.id.elementsEqual(item2)
                }.first!.accountName
            })
            self.watch = watchSorted
        }, content: {
            AccountToWatchView(watch: watch, accountViewModel: accountViewModel, watchViewModel: watchViewModel)
        })
        .onAppear {
            var watchSorted = self.watch
            watchSorted.accountList.sort(by: { item1, item2 in
                accountViewModel.accountList.filter { account1 in
                    account1.id.elementsEqual(item1)
                }.first!.accountName <= accountViewModel.accountList.filter { account2 in
                    account2.id.elementsEqual(item2)
                }.first!.accountName
            })
            self.watch = watchSorted
        }
    }
    
    func not(_ value: Binding<Bool>) -> Binding<Bool> {
        Binding<Bool>(
            get: { !value.wrappedValue },
            set: { value.wrappedValue = !$0 }
        )
    }
    
    private func getAccountForWatchListAccount(accountId: String) -> Account {
        return accountViewModel.accountList.first {
            return $0.id.elementsEqual(accountId)
        }!
    }
}
