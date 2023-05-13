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
    @State var multipleWatchListSelection = Set<Watch>()
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
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
                    .disabled(watchListSelected.accountName.elementsEqual("Select") || watchListSelected.accountName.isEmpty)
                    .foregroundColor((watchListSelected.accountName.elementsEqual("Select") || watchListSelected.accountName.isEmpty) ? Color.gray : Color.lightBlue)
                    .bold()
                    
                    Spacer()
                    
                    Button(action: {
                        watchListSelected = Watch()
                        showingAssetsData = true
                        chartDataList = [Account]()
                        compareAssetsToLiabilities = false
                        multipleWatchListSelection = Set<Watch>()
                    }, label: {
                        Text("Reset")
                    })
                    .font(.system(size: 14))
                    .disabled((watchListSelected.accountName.isEmpty && chartDataList.isEmpty && !compareAssetsToLiabilities && multipleWatchListSelection.isEmpty))
                    .foregroundColor(((watchListSelected.accountName.isEmpty && chartDataList.isEmpty && !compareAssetsToLiabilities && multipleWatchListSelection.isEmpty) ? Color.gray : Color.lightBlue))
                    .bold()
                }
                .padding(.horizontal, 20)
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
                            multipleWatchListSelection = Set<Watch>()
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
                                multipleWatchListSelection = Set<Watch>()
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
                    
                    NavigationLink(destination: {
                        selectMultipleWatchListForCompare
                    }, label: {
                        Text("Compare Multiple WatchLists")
                    })
                    .listRowBackground(Color.white)
                    .foregroundColor(Color.navyBlue)
                    
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
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Chart")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.navyBlue)
            .scrollContentBackground(.hidden)
        }
    }
    
    var selectMultipleWatchListForCompare: some View {
        List {
            ForEach(watchViewModel.watchList.filter({ !$0.accountName.elementsEqual("All")}), id: \.self, content: { watch in
                MultipleSelectionRow(title: watch.accountName, isSelected: self.multipleWatchListSelection.contains(watch)) {
                    if self.multipleWatchListSelection.contains(watch) {
                        self.multipleWatchListSelection.remove(watch)
                        self.chartDataList.removeAll(where: {
                            $0.accountName.elementsEqual(watch.accountName)
                        })
                    }
                    else {
                        if(self.multipleWatchListSelection.isEmpty) {
                            self.chartDataList = [Account]()
                        }
                        self.multipleWatchListSelection.insert(watch)
                        
                        let accountList = getAccountsForWatchList(watch: watch)
                        let totalAmount = accountList.map( {
                            $0.currentBalance
                        }).reduce(0, +)
                        var account = Account()
                        account.accountName = watch.accountName
                        account.currentBalance = totalAmount
                        self.chartDataList.append(account)
                        self.chartDataList.sort(by: {
                            $0.currentBalance > $1.currentBalance
                        })
                    }
                    compareAssetsToLiabilities = false
                    watchListSelected = defaultWatchListSelected
                }
            })
            .listRowBackground(Color.white)
        }
        .navigationTitle("Select Watch Lists")
        .foregroundColor(Color.navyBlue)
        .background(Color.navyBlue)
        .scrollContentBackground(.hidden)
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
    
    private func calculateTotalAmountForAccountList(accountList: [Account]) -> Double {
        return accountList.map {
            $0.currentBalance
        }.reduce(0, +)
    }
}

struct MultipleSelectionRow: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: self.action) {
            HStack {
                Text(self.title)
                if self.isSelected {
                    Spacer()
                    Image(systemName: "checkmark")
                }
            }
        }
    }
}
