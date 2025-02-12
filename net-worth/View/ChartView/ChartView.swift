//
//  ChartView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 09/05/23.
//

import SwiftUI

struct ChartView: View {
    
    @State var watchListSelected = Watch()
    @State var brokerSelected = Account()
    @State var showingAssetsData = true
    @State var chartDataList = [Account]()
    @State var compareAssetsToLiabilities = false
    @State var multipleWatchListSelection = Set<Watch>()
    @State var filterSelected = ""
    @State var showNetWorthChart = false
    @State var isChartDataEnabled = false
    
    @EnvironmentObject var watchViewModel: WatchViewModel
    @EnvironmentObject var accountViewModel: AccountViewModel
    @EnvironmentObject var incomeViewModel: IncomeViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                if(isChartDataEnabled) {
                    topView
                    HStack {
                        chartView
                    }
                    .frame(maxWidth: 328)
                    .padding(15)
                    .background(Color.theme.foreground)
                    .cornerRadius(10)
                } else {
                    EmptyView(name: "Chart")
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu(content: {
                        Menu(content: {
                            watchListPicker
                        }, label: {
                            Text("Watch List")
                            Text(watchListSelected.name)
                        })
                        
                        Menu(content: {
                            brokerListPicker
                        }, label: {
                            Text("Broker List")
                            Text(brokerSelected.accountName)
                        })
                        
                        Menu(content: {
                            selectMultipleWatchListForCompare
                        }, label: {
                            Text("Compare Multiple WatchLists")
                            Text(multipleWatchListSelection.map {
                                return $0.name
                            }.joined(separator: ","))
                        })
                        
                        compareAssetsAndLiabilitiesToggle
                    }, label: {
                        ZStack {
                            Circle()
                                .frame(width: 25, height: 25)
                                .foregroundColor(ColorTheme().green)
                            Image(systemName: ConstantUtils.menuImageName)
                                .foregroundColor(Color.theme.background)
                                .font(.system(size: 12))
                        }
                        
                    })
                    .font(.system(size: 14))
                }
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Charts")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.theme.background)
            .scrollContentBackground(.hidden)
        }
    }
    
    var topView: some View {
        HStack {
            leftTopView
            Spacer()
            rightTopView
        }
        .padding(.horizontal, 20)
    }
    
    var leftTopView: some View {
        Button(action: {
            if(showingAssetsData) {
//                chartDataList = getAccountsForWatchList(watch: watchListSelected).filter {
//                    return $0.balance.currentDayValue.value < 0
//                }.sorted(by: {
//                    $0.balance.currentDayValue.value < $1.balance.currentDayValue.value
//                })
                showingAssetsData.toggle()
            } else {
//                chartDataList = getAccountsForWatchList(watch: watchListSelected).filter {
//                    return $0.balance.currentDayValue.value > 0
//                }.sorted(by: {
//                    $0.balance.currentDayValue.value > $1.balance.currentDayValue.value
//                })
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
        .disabled(watchListSelected.name.elementsEqual("Select") || watchListSelected.name.isEmpty)
        .foregroundColor((watchListSelected.name.elementsEqual("Select") || watchListSelected.name.isEmpty) ? Color.gray : Color.theme.primaryText)
        .bold()
    }
    
    var rightTopView: some View {
        Button(action: {
            watchListSelected = Watch()
            brokerSelected = Account()
            compareAssetsToLiabilities = false
            multipleWatchListSelection = Set<Watch>()
            chartDataList = [Account]()
            showingAssetsData = true
            self.isChartDataEnabled = false
            filterSelected = ""
        }, label: {
            Text("Reset")
        })
        .font(.system(size: 14))
        .disabled((watchListSelected.name.isEmpty && chartDataList.isEmpty && !compareAssetsToLiabilities && multipleWatchListSelection.isEmpty))
        .foregroundColor(((watchListSelected.name.isEmpty && chartDataList.isEmpty && !compareAssetsToLiabilities && multipleWatchListSelection.isEmpty) ? Color.gray : Color.theme.primaryText))
        .bold()
    }
    
    var watchListPicker: some View {
        Picker(selection: $watchListSelected, content: {
            ForEach(watchViewModel.watchList, id: \.self, content: {
                Text($0.name).tag($0)
            })
        }, label: {
            Text("Watch List")
        })
        .listRowBackground(Color.theme.foreground)
        .onChange(of: watchListSelected, perform: { _ in
            if(watchListSelected.name.isEmpty) {
                if(!filterSelected.elementsEqual("COMPARE")) {
                    compareAssetsToLiabilities = false
                }
                
                if(!filterSelected.elementsEqual("COMPARE_MULTIPLE")) {
                    multipleWatchListSelection = Set<Watch>()
                }
                if(filterSelected.isEmpty) {
                    isChartDataEnabled = false
                }
            } else {
                filterSelected = "WATCH"
                isChartDataEnabled = true
                brokerSelected = Account()
                compareAssetsToLiabilities = false
                multipleWatchListSelection = Set<Watch>()
//                var accountList = getAccountsForWatchList(watch: watchListSelected).filter {
//                    return $0.balance.currentDayValue.value > 0
//                }
//                accountList.sort(by: {
//                    $0.balance.currentDayValue.value > $1.balance.currentDayValue.value
//                })
//                self.chartDataList = accountList
                
                showingAssetsData = true
            }
        })
    }
    
    var brokerListPicker: some View {
        Picker(selection: $brokerSelected, content: {
            ForEach(getBrokerList(), id: \.self, content: {
                Text($0.accountName).tag($0)
            })
        }, label: {
            Text("Broker List")
        })
        .listRowBackground(Color.theme.foreground)
        .onChange(of: brokerSelected, perform: { _ in
            if(brokerSelected.accountName.isEmpty) {
                if(!filterSelected.elementsEqual("COMPARE")) {
                    compareAssetsToLiabilities = false
                }
                
                if(!filterSelected.elementsEqual("COMPARE_MULTIPLE")) {
                    multipleWatchListSelection = Set<Watch>()
                }
                if(filterSelected.isEmpty) {
                    isChartDataEnabled = false
                }
            } else {
                filterSelected = "BROKER"
                isChartDataEnabled = true
                watchListSelected = Watch()
                compareAssetsToLiabilities = false
                multipleWatchListSelection = Set<Watch>()
                Task.init {
                    await accountViewModel.getAccountInBrokerList(brokerID: brokerSelected.id)
                    var accountList = accountViewModel.accountsInBroker
                    accountList.sort(by: {
                        $0.balance.currentDayValue.value > $1.balance.currentDayValue.value
                    })
                    self.chartDataList = accountList.map {
                        return Account(accountName: $0.name, balance: $0.balance)
                    }
                }
            }
        })
    }
    
    var selectMultipleWatchListForCompare: some View {
        ForEach(watchViewModel.watchList.filter({ !$0.name.elementsEqual("All")}), id: \.self, content: { watch in
            MultipleSelectionRow(title: watch.name, isSelected: self.multipleWatchListSelection.contains(watch)) {
                if self.multipleWatchListSelection.contains(watch) {
                    self.multipleWatchListSelection.remove(watch)
                    self.chartDataList.removeAll(where: {
                        $0.accountName.elementsEqual(watch.name)
                    })
                }
                else {
                    filterSelected = "COMPARE_MULTIPLE"
                    if(self.multipleWatchListSelection.isEmpty) {
                        self.chartDataList = [Account]()
                    }
                    self.multipleWatchListSelection.insert(watch)
                    
//                    let accountList = getAccountsForWatchList(watch: watch)
//                    var totalAmount = accountList.map( {
//                        $0.balance.currentDayValue.value
//                    }).reduce(0, +)
//                    totalAmount = totalAmount < 0 ? totalAmount * -1.0 : totalAmount * 1.0
                    var account = Account()
                    account.accountName = watch.name
//                    account.balance.currentDayValue.value = totalAmount
                    self.chartDataList.append(account)
                    self.chartDataList.sort(by: {
                        $0.balance.currentDayValue.value > $1.balance.currentDayValue.value
                    })
                }
                if(multipleWatchListSelection.isEmpty) {
                    isChartDataEnabled = false
                } else {
                    isChartDataEnabled = true
                }
                
                if(!filterSelected.elementsEqual("WATCH")) {
                    watchListSelected = Watch()
                }
                
                if(!filterSelected.elementsEqual("BROKER")) {
                    brokerSelected = Account()
                }
                
                if(!filterSelected.elementsEqual("COMPARE")) {
                    compareAssetsToLiabilities = false
                }
            }
            .listRowBackground(Color.theme.foreground)
        })
    }
    
    var compareAssetsAndLiabilitiesToggle: some View {
        Toggle("Compare Assets and Liabilities", isOn: $compareAssetsToLiabilities)
            .onChange(of: compareAssetsToLiabilities) { value in
                if(value) {
                    filterSelected = "COMPARE"
                    
                    isChartDataEnabled = true
                    self.chartDataList = [Account]()
                    var assetAccount = Account()
                    assetAccount.accountName = "Assets"
                    assetAccount.balance.currentDayValue.value = getAccounts().filter {
                        return $0.balance.currentDayValue.value > 0
                    }.map {
                        $0.balance.currentDayValue.value
                    }.reduce(0, +)
                    self.chartDataList.append(assetAccount)
                    
                    var liabilitiesAccount = Account()
                    liabilitiesAccount.accountName = "Liabilities"
                    liabilitiesAccount.balance.currentDayValue.value = getAccounts().filter {
                        return $0.balance.currentDayValue.value < 0
                    }.map {
                        $0.balance.currentDayValue.value
                    }.reduce(0, +) * -1.0
                    self.chartDataList.append(liabilitiesAccount)
                    self.chartDataList.sort(by: {
                        $0.balance.currentDayValue.value > $1.balance.currentDayValue.value
                    })
                }
                else if(filterSelected.isEmpty || (filterSelected.elementsEqual("COMPARE") && !value)) {
                    filterSelected = ""
                    isChartDataEnabled = false
                    self.chartDataList = [Account]()
                }
                
                if(!filterSelected.elementsEqual("WATCH")) {
                    watchListSelected = Watch()
                }
                
                if(!filterSelected.elementsEqual("BROKER")) {
                    brokerSelected = Account()
                }
                
                if(!filterSelected.elementsEqual("COMPARE_MULTIPLE")) {
                    multipleWatchListSelection = Set<Watch>()
                }
            }
            .listRowBackground(Color.theme.foreground)
    }
    
    var chartView: some View {
        PieChartView(
            values: chartDataList.map {
                $0.balance.currentDayValue.value
            },
            names: chartDataList.map {
                $0.accountName
            },
            formatter: {value in String(format: "%.2f", value)},
            colors: chartDataList.map { _ in
                    .random
            }, backgroundColor: Color.theme.foreground)
        .frame(maxHeight: .infinity)
    }
    
    private func getAccounts() -> [Account] {
        return accountViewModel.accountList
    }
    
    private func getWatchLists() -> [Watch] {
        return watchViewModel.watchList
    }
    
    private func getBrokerList() -> [Account] {
        return getAccounts().filter {
            return $0.accountType.elementsEqual("Broker")
        }.sorted(by: {
            return $0.accountName < $1.accountName
        })
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
                    Image(systemName: ConstantUtils.checkmarkImageName)
                }
            }
        }
    }
}
