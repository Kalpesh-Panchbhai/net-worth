//
//  SingleWatchListView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 15/02/23.
//

import SwiftUI

struct WatchDetailView: View {
    
    var watch: Watch
    var watchController = WatchController()
    
    @State var isNewTransactionViewOpen = false
    @State var isChartViewOpen = false
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
                                            .contextMenu {
                                                Label(accountID, systemImage: ConstantUtils.infoIconImageName)
                                            }
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
            //
                        if(accountViewModel.originalAccountList.count > 0) {
                            ToolbarItem(content: {
                                Button(action: {
                                    self.isChartViewOpen.toggle()
                                }, label: {
                                    Image(systemName: ConstantUtils.chartImageName)
                                        .foregroundColor(Color.theme.primaryText)
                                        .bold()
                                })
                                .font(.system(size: 14).bold())
                            })
                        }
            //
            //            if(watchViewModel.watch.accountID.count > 1) {
            //                ToolbarItem(content: {
            //
            //                    Menu(content: {
            //                        Menu(content: {
            //                            Button(action: {
            //                                if(isAscendingEnabled) {
            //                                    watchViewModel.watch.accountID = accountViewModel
            //                                        .accountList
            //                                        .sorted(by: {
            //                                            $0.accountName < $1.accountName
            //                                        }).map({
            //                                            $0.id!
            //                                        })
            //                                    self.isAscendingByAlphabetEnabled = true
            //                                    self.isAscendingByAmountEnabled = false
            //                                } else {
            //                                    watchViewModel.watch.accountID = accountViewModel
            //                                        .accountList
            //                                        .sorted(by: {
            //                                            $0.accountName > $1.accountName
            //                                        }).map({
            //                                            $0.id!
            //                                        })
            //                                    self.isAscendingByAlphabetEnabled = true
            //                                    self.isAscendingByAmountEnabled = false
            //                                }
            //                            }, label: {
            //                                if(isAscendingByAlphabetEnabled) {
            //                                    Label("Name", systemImage: "checkmark")
            //                                } else {
            //                                    Text("Name")
            //                                }
            //                            })
            //
            //                            Button(action: {
            //                                if(isAscendingEnabled) {
            //                                    watchViewModel.watch.accountID = accountViewModel
            //                                        .accountList
            //                                        .sorted(by: {
            //                                            $0.currentBalance < $1.currentBalance
            //                                        }).map({
            //                                            $0.id!
            //                                        })
            //                                    self.isAscendingByAmountEnabled = true
            //                                    self.isAscendingByAlphabetEnabled = false
            //                                } else {
            //                                    watchViewModel.watch.accountID = accountViewModel
            //                                        .accountList
            //                                        .sorted(by: {
            //                                            $0.currentBalance > $1.currentBalance
            //                                        }).map({
            //                                            $0.id!
            //                                        })
            //                                    self.isAscendingByAmountEnabled = true
            //                                    self.isAscendingByAlphabetEnabled = false
            //                                }
            //                            }, label: {
            //                                if(isAscendingByAmountEnabled) {
            //                                    Label("Amount", systemImage: "checkmark")
            //                                } else {
            //                                    Text("Amount")
            //                                }
            //                            })
            //
            //                            Divider()
            //
            //                            Button(action: {
            //                                isAscendingEnabled = true
            //                                if(isAscendingByAlphabetEnabled) {
            //                                    watchViewModel.watch.accountID = accountViewModel
            //                                        .accountList
            //                                        .sorted(by: {
            //                                            $0.accountName < $1.accountName
            //                                        }).map({
            //                                            $0.id!
            //                                        })
            //                                } else {
            //                                    watchViewModel.watch.accountID = accountViewModel
            //                                        .accountList
            //                                        .sorted(by: {
            //                                            $0.currentBalance < $1.currentBalance
            //                                        }).map({
            //                                            $0.id!
            //                                        })
            //                                }
            //                            }, label: {
            //                                if(isAscendingEnabled) {
            //                                    Label("Ascending", systemImage: "checkmark")
            //                                } else {
            //                                    Text("Ascending")
            //                                }
            //                            })
            //
            //                            Button(action: {
            //                                isAscendingEnabled = false
            //                                if(isAscendingByAlphabetEnabled) {
            //                                    watchViewModel.watch.accountID = accountViewModel
            //                                        .accountList
            //                                        .sorted(by: {
            //                                            $0.accountName > $1.accountName
            //                                        }).map({
            //                                            $0.id!
            //                                        })
            //                                } else {
            //                                    watchViewModel.watch.accountID = accountViewModel
            //                                        .accountList
            //                                        .sorted(by: {
            //                                            $0.currentBalance > $1.currentBalance
            //                                        }).map({
            //                                            $0.id!
            //                                        })
            //                                }
            //                            }, label: {
            //                                if(!isAscendingEnabled) {
            //                                    Label("Descending", systemImage: "checkmark")
            //                                } else {
            //                                    Text("Descending")
            //                                }
            //                            })
            //
            //                        }, label: {
            //                            Label("Sort Account By", systemImage: "arrow.up.arrow.down")
            //                            if(isAscendingByAlphabetEnabled) {
            //                                Text("Name")
            //                            } else {
            //                                Text("Amount")
            //                            }
            //                        })
            //
            //                        Divider()
            //
            //                        Toggle(isOn: $hideInactiveAccount, label: {
            //                            Text("Hide Inactive Accounts")
            //                        })
            //
            //                        Toggle(isOn: $hideZeroBalanceAccount, label: {
            //                            Text("Hide Zero Balance Accounts")
            //                        })
            //                    }, label: {
            //                        Image(systemName: ConstantUtils.menuImageName)
            //                            .foregroundColor(Color.theme.primaryText)
            //                            .bold()
            //                    })
            //                    .font(.system(size: 14).bold())
            //                })
            //            }
        }
        .sheet(isPresented: $isChartViewOpen, content: {
            AccountWatchChartView(id: watch.id)
        })
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
