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
    @State var sortOrder = "Asc"
    @State var sortType = "Name"
    @State var hideZeroAmountAccount = true
    @State var isZeroAmountAccountPresent = false
    
    @EnvironmentObject var accountViewModel: AccountViewModel
    @EnvironmentObject var watchViewModel: WatchViewModel
    
    @Environment(\.presentationMode) var presentationMode
    
    init(watch: WatchRestModel) {
        self.watch = watch
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.theme.background.ignoresSafeArea()
                VStack {
//                    if(watch.accountList.count > 0) {
//                        // MARK: Balance Card
//                        VStack {
//                            BalanceCardView(accountType: watch.name, isWatchListCardView: true, watchList: watch)
//                                .frame(width: 360, height: 70)
//                                .cornerRadius(10)
//                        }
//                        .padding(.top, 5)
//                        Divider()
//                        ScrollView(.vertical, showsIndicators: false) {
//                            LazyVStack {
//                                ForEach(getWatchListData(), id: \.self) { accountID in
//                                    NavigationLink(destination: {
//                                        // MARK: Account Detail View
//                                        AccountDetailView(accountID: accountID)
//                                            .toolbarRole(.editor)
//                                    }, label: {
//                                        AccountRowView(account: getAccountForWatchListAccount(accountId: accountID), fromWatchView: true)
//                                    })
//                                }
//                                .padding(10)
//                            }
//                        }
//                        .padding(10)
//                    }
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
                Menu(content: {
                    Menu(content: {
                        Button(action: {
                            sortType = "Name"
                        }, label: {
                            if(sortType.elementsEqual("Name")) {
                                Label("Name", systemImage: "checkmark")
                            } else {
                                Text("Name")
                            }
                        })
                        
                        Button(action: {
                            sortType = "Amount"
                        }, label: {
                            if(sortType.elementsEqual("Amount")){
                                Label("Amount", systemImage: "checkmark")
                            } else {
                                Text("Amount")
                            }
                        })
                        
                        Button(action: {
                            sortType = "Price Change"
                        }, label: {
                            if(sortType.elementsEqual("Price Change")){
                                Label("Price Change", systemImage: "checkmark")
                            } else {
                                Text("Price Change")
                            }
                        })
                        
                        Button(action: {
                            sortType = "Percentage Change"
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
                        }, label: {
                            if(sortOrder.elementsEqual("Asc")){
                                Label("Ascending", systemImage: "checkmark")
                            } else {
                                Text("Ascending")
                            }
                        })
                        
                        Button(action: {
                            sortOrder = "Desc"
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
//            self.watch = self.watchViewModel.watchList.first(where: {
//                return $0.id.elementsEqual(watch.id)
//            })!
//            var watchSorted = self.watch
//            watchSorted.accountList.sort(by: { item1, item2 in
//                accountViewModel.accountList.filter { account1 in
//                    account1.id == item1
//                }.first!.name <= accountViewModel.accountList.filter { account2 in
//                    account2.id == item2
//                }.first!.name
//            })
//            self.watch = watchSorted
        }, content: {
            AccountToWatchView(watch: watch)
        })
        .onAppear {
//            let accountList = accountViewModel.accountList.filter {
//                return watch.accountList.contains($0.id)
//            }
//            let count = accountList.filter {
//                return $0.value.currentBalance.isZero
//            }.count
//            
//            isZeroAmountAccountPresent = count > 0
        }
    }
    
    private func getAccountForWatchListAccount(accountId: String) -> AccountRestModel {
        return accountViewModel.accountList.first { _ in
            return true
//            return $0.id == accountId
        }!
    }
    
    private func getWatchListData() -> [String] {
        var accountList = accountViewModel.accountList.filter { _ in
            return true
//            return watch.accountList.contains($0.id)
        }
        
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
        return [String]()
//        return accountList.map { $0.id }
    }
    
    private func getOneDayChange(account: AccountRestModel) -> Double {
        return areOneDayTransactions(account: account) ? account.value.currentValue - account.value.previousValue : 0.0
    }
    
    private func getOneDayPercentageChange(account: AccountRestModel) -> Double {
        return areOneDayTransactions(account: account) ? CommonController.getGrowthPercentageInDouble(previousBalance: account.value.previousValue, currentBalance: account.value.currentValue) : 0.0
    }
    
    private func areOneDayTransactions(account: AccountRestModel) -> Bool {
        return true
//        return account.name != "" && account.value.currentBalance.dateTime.UTCToLocalDate() >= Date.now.addingTimeInterval(-86400)
    }
}
