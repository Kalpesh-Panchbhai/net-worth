//
//  ChartView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 09/05/23.
//

import SwiftUI

struct ChartView: View {
    
    @ObservedObject var watchViewModel: WatchViewModel
    
    @ObservedObject var accountViewModel: AccountViewModel
    
    @State var watchListSelected = Watch()
    let defaultWatchListSelected = Watch(accountName: "Select")
    
    @State var showingAssetsData = true
    
    @State var chartDataList = [Account]()
    
    @State var compareAssetsToLiabilities = false
    
    @State var compareWatchLists = false
    
    var body: some View {
        NavigationView {
            List {
                Picker(selection: $watchListSelected, content: {
                    Text("Select").tag(defaultWatchListSelected)
                    ForEach(watchViewModel.watchList, id: \.self, content: {
                        Text($0.accountName).tag($0)
                    })
                }, label: {
                    Text("Watch List")
                })
                .listRowBackground(Color.white)
                .colorMultiply(Color.navyBlue)
                .onChange(of: watchListSelected, perform: { _ in
                    if(watchListSelected.accountName.elementsEqual("Select")) {
                        compareAssetsToLiabilities = true
                    } else {
                        compareAssetsToLiabilities = false
                        compareWatchLists = false
                        var accountList = getAccountsForWatchList(watch: watchListSelected).filter {
                            $0.currentBalance > 0
                        }
                        accountList.sort(by: {
                            $0.currentBalance > $1.currentBalance
                        })
                        self.chartDataList = accountList
                        
                        showingAssetsData = true
                    }
                })
                Toggle("Compare Assets and Liabilities", isOn: $compareAssetsToLiabilities)
                    .listRowBackground(Color.white)
                    .foregroundColor(Color.navyBlue)
                    .onChange(of: compareAssetsToLiabilities) { value in
                        if(value) {
                            watchListSelected = defaultWatchListSelected
                            compareWatchLists =  false
                            Task.init {
                                self.chartDataList = [Account]()
                                var assetAccount = Account()
                                assetAccount.accountName = "Assets"
                                assetAccount.currentBalance = getAccounts().filter {
                                    $0.currentBalance > 0
                                }.map {
                                    $0.currentBalance
                                }.reduce(0, +)
                                
                                self.chartDataList.append(assetAccount)
                                
                                var liabilitiesAccount = Account()
                                liabilitiesAccount.accountName = "Liabilities"
                                liabilitiesAccount.currentBalance = getAccounts().filter {
                                    $0.currentBalance < 0
                                }.map {
                                    $0.currentBalance
                                }.reduce(0, -)
                                
                                self.chartDataList.append(liabilitiesAccount)
                                self.chartDataList.sort(by: {
                                    $0.currentBalance > $1.currentBalance
                                })
                            }
                        }
                        else {
                            self.chartDataList = [Account]()
                        }
                    }
                
                Toggle("Compare WatchList", isOn: $compareWatchLists)
                    .listRowBackground(Color.white)
                    .foregroundColor(Color.navyBlue)
                    .onChange(of: compareWatchLists) { value in
                        if(value) {
                            watchListSelected = defaultWatchListSelected
                            compareAssetsToLiabilities =  false
                            var accountList = getAllWatchListWithAllAccountsExceptAllWatchList()
                            accountList.sort(by: {
                                $0.currentBalance > $1.currentBalance
                            })
                            self.chartDataList = accountList
                        } else {
                            self.chartDataList = [Account]()
                        }
                    }
                HStack {
                    Spacer()
                    Button(action: {
                        if(showingAssetsData) {
                            chartDataList = getAccountsForWatchList(watch: watchListSelected).filter {
                                $0.currentBalance < 0
                            }.sorted(by: {
                                $0.currentBalance < $1.currentBalance
                            })
                            showingAssetsData.toggle()
                        } else {
                            chartDataList = getAccountsForWatchList(watch: watchListSelected).filter {
                                $0.currentBalance > 0
                            }.sorted(by: {
                                $0.currentBalance > $1.currentBalance
                            })
                            showingAssetsData.toggle()
                        }
                    }, label: {
                        if(showingAssetsData) {
                            Text("Show Liabilities")
                        } else {
                            Text("Show Assets")
                        }
                    })
                    .font(.system(size: 14))
                }.disabled(watchListSelected.accountName.elementsEqual("Select") || watchListSelected.accountName.isEmpty)
                .listRowBackground(Color.white)
                .foregroundColor((watchListSelected.accountName.elementsEqual("Select") || watchListSelected.accountName.isEmpty) ? Color.gray : Color.navyBlue)
                
                PieChartView(
                    values: chartDataList.map {
                        $0.currentBalance
                    },
                    names: chartDataList.map {
                        $0.accountName
                    },
                    formatter: {value in String(format: "%.2f", value)},
                    colors: chartDataList.map { _ in
                            .random
                    }, backgroundColor: Color.white)
                
                .listRowBackground(Color.white)
                .foregroundColor(Color.navyBlue)
                .frame(minHeight: 550)
            }
            .navigationTitle("Chart")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.navyBlue)
            .scrollContentBackground(.hidden)
        }
    }

    private func getAccounts() -> [Account] {
        return accountViewModel.accountList
    }
    
    private func getWatchLists() -> [Watch] {
        return watchViewModel.watchList
    }
    
    private func getAccountsForWatchList(watch: Watch) -> [Account] {
        return getAccounts().filter {
            watch.accountID.contains($0.id!)
        }
    }
    
    private func getAllWatchListWithAllAccountsExceptAllWatchList() -> [Account] {
        var returnChartDataList = [Account]()
        for watch in getWatchLists() {
            if(!watch.accountName.elementsEqual("All")) {
                var account = Account()
                account.accountName = watch.accountName
                account.currentBalance = calculateTotalAmountForAccountList(accountList: getAccountsForWatchList(watch: watch))
                returnChartDataList.append(account)
            }
        }
        return returnChartDataList
    }
    
    private func calculateTotalAmountForAccountList(accountList: [Account]) -> Double {
        return accountList.map {
            $0.currentBalance
        }.reduce(0, +)
    }
}
