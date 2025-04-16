//
//  SingleWatchListView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 15/02/23.
//

import SwiftUI

struct WatchDetailView: View {
    
    @State var watch: WatchRestModel
    @State var addAccountViewOpen = false
    @State var chartViewOpen = false
    @State var sortOrder = "Asc"
    @State var sortType = "Name"
    @State var hideZeroAmountAccount = true
    @State var isZeroAmountAccountPresent = false
    @State var accountListToShown = [Int]()
    
    @EnvironmentObject var accountViewModel: AccountViewModel
    @EnvironmentObject var watchViewModel: WatchViewModel
    @EnvironmentObject var watchAccountViewModel: WatchAccountViewModel
    
    @Environment(\.presentationMode) var presentationMode
    
    init(watch: WatchRestModel) {
        self.watch = watch
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.theme.background.ignoresSafeArea()
                VStack {
                    // MARK: Balance Card
                    VStack {
                        BalanceCardView(accountType: watch.name, isWatchListCardView: true, watchList: watch)
                            .frame(width: 360, height: 70)
                            .cornerRadius(10)
                    }
                    .padding(.top, 5)
                    Divider()
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack {
                            ForEach(accountListToShown, id: \.self) { accountID in
                                NavigationLink(destination: {
                                    // MARK: Account Detail View
                                    AccountDetailView(accountID: accountID)
                                        .toolbarRole(.editor)
                                }, label: {
                                    AccountRowView(account: getAccountForWatchListAccount(accountId: accountID), fromWatchView: true)
                                })
                            }
                        }
                    }
                    .padding(10)
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
                        ZStack {
                            Circle()
                                .frame(width: 25, height: 25)
                                .foregroundColor(ColorTheme().green)
                            Image(systemName: ConstantUtils.plusImageName)
                                .foregroundColor(Color.theme.background)
                                .font(.system(size: 12))
                        }
                    })
                    .font(.system(size: 14))
                })
            }
            
            ToolbarItem(content: {
                Button(action: {
                    self.chartViewOpen.toggle()
                }, label: {
                    ZStack {
                        Circle()
                            .frame(width: 25, height: 25)
                            .foregroundColor(ColorTheme().foreground)
                        Image(systemName: ConstantUtils.chartImageName)
                            .foregroundColor(Color.theme.primaryText)
                            .font(.system(size: 12))
                    }
                })
                .font(.system(size: 14))
            })
            
            ToolbarItem(content: {
                Menu(content: {
                    Menu(content: {
                        Button(action: {
                            sortType = "Name"
                            getWatchListData()
                        }, label: {
                            if(sortType.elementsEqual("Name")) {
                                Label("Name", systemImage: "checkmark")
                            } else {
                                Text("Name")
                            }
                        })
                        
                        Button(action: {
                            sortType = "Amount"
                            getWatchListData()
                        }, label: {
                            if(sortType.elementsEqual("Amount")){
                                Label("Amount", systemImage: "checkmark")
                            } else {
                                Text("Amount")
                            }
                        })
                        
                        Button(action: {
                            sortType = "Price Change"
                            getWatchListData()
                        }, label: {
                            if(sortType.elementsEqual("Price Change")){
                                Label("Price Change", systemImage: "checkmark")
                            } else {
                                Text("Price Change")
                            }
                        })
                        
                        Button(action: {
                            sortType = "Percentage Change"
                            getWatchListData()
                        }, label: {
                            if(sortType.elementsEqual("Percentage Change")){
                                Label("Percentage Change", systemImage: "checkmark")
                            } else {
                                Text("Percentage Change")
                            }
                        })
                        
                        Divider()
                        
                        Button(action: {
                            sortOrder = "Asc"
                            getWatchListData()
                        }, label: {
                            if(sortOrder.elementsEqual("Asc")){
                                Label("Ascending", systemImage: "checkmark")
                            } else {
                                Text("Ascending")
                            }
                        })
                        
                        Button(action: {
                            sortOrder = "Desc"
                            getWatchListData()
                        }, label: {
                            if(sortOrder.elementsEqual("Desc")){
                                Label("Descending", systemImage: "checkmark")
                            } else {
                                Text("Descending")
                            }
                        })
                        
                    }, label: {
                        Text("Sort Account By")
                        Text(sortType + "," + sortOrder)
                    })
                    if(isZeroAmountAccountPresent) {
                        Toggle(isOn: $hideZeroAmountAccount, label: {
                            Text("Hide zero amount accounts")
                        })
                        .onChange(of: hideZeroAmountAccount) {
                            getWatchListData()
                        }
                    }
                    
                }, label: {
                    ZStack {
                        Circle()
                            .frame(width: 25, height: 25)
                            .foregroundColor(ColorTheme().foreground)
                        Image(systemName: ConstantUtils.menuImageName)
                            .foregroundColor(Color.theme.primaryText)
                            .font(.system(size: 12))
                    }
                })
                .font(.system(size: 14).bold())
            })
        }
        .sheet(isPresented: $addAccountViewOpen, onDismiss: {
            Task.init {
                await watchViewModel.getAllWatchList()
                await watchAccountViewModel.getAllAccountsByWatchID(watchID: watch.id)
                getWatchListData()
            }
        }, content: {
            AccountToWatchView(watch: watch)
        })
        .sheet(isPresented: $chartViewOpen, onDismiss: {
            
        }, content: {
            AccountChartView(id: watch.id, type: watch.name == "All" ? "all_watch" : "non_all_watch")
        })
        .onAppear {
            Task.init {
                await watchAccountViewModel.getAllAccountsByWatchID(watchID: watch.id)
                getWatchListData()
            }
        }
    }
    
    private func getAccountForWatchListAccount(accountId: Int) -> AccountRestModel {
        return accountViewModel.accountList.first {
            return $0.id == accountId
        }!
    }
    
    private func getWatchListData() {
        let accountListInAWatch = watchAccountViewModel.allAccountsByWatchID.map { $0.accountId }
        var accountList = accountViewModel.accountList.filter { account in
            return accountListInAWatch.contains(account.id)
        }
        let count = accountList.filter {
            return $0.value.currentValue.isZero
        }.count
        
        isZeroAmountAccountPresent = count > 0
        
        if(sortType.elementsEqual("Name")) {
            if(sortOrder.elementsEqual("Asc")) {
                accountList.sort(by: {
                    return $0.name <= $1.name
                })
            } else {
                accountList.sort(by: {
                    return $0.name >= $1.name
                })
            }
        } else if(sortType.elementsEqual("Amount")) {
            if(sortOrder.elementsEqual("Asc")) {
                accountList.sort(by: {
                    return $0.value.currentValue <= $1.value.currentValue
                })
            } else {
                accountList.sort(by: {
                    return $0.value.currentValue >= $1.value.currentValue
                })
            }
        } else if(sortType.elementsEqual("Price Change")) {
            if(sortOrder.elementsEqual("Asc")) {
                accountList.sort(by: {
                    return getOneDayChange(account: $0) <= getOneDayChange(account: $1)
                })
            } else {
                accountList.sort(by: {
                    return getOneDayChange(account: $0) >= getOneDayChange(account: $1)
                })
            }
        } else if(sortType.elementsEqual("Percentage Change")) {
            if(sortOrder.elementsEqual("Asc")) {
                accountList.sort(by: {
                    return getOneDayPercentageChange(account: $0) <= getOneDayPercentageChange(account: $1)
                })
            } else {
                accountList.sort(by: {
                    return getOneDayPercentageChange(account: $0) >= getOneDayPercentageChange(account: $1)
                })
            }
        }
        if(hideZeroAmountAccount) {
            accountList = accountList.filter {
                return !$0.value.currentValue.isZero
            }
        }
        accountListToShown = accountList.map { $0.id }
    }
    
    private func getOneDayChange(account: AccountRestModel) -> Double {
        return account.value.currentValue - account.value.previousValue
    }
    
    private func getOneDayPercentageChange(account: AccountRestModel) -> Double {
        return CommonController.getGrowthPercentageInDouble(previousBalance: account.value.previousValue, currentBalance: account.value.currentValue)
    }
}
