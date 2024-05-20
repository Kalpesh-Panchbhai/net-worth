//
//  ChartView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 09/05/23.
//

import SwiftUI

struct ChartView: View {
    
    @State var watchListSelected = Watch()
    @State var showingAssetsData = true
    @State var chartDataList = [Account]()
    @State var compareAssetsToLiabilities = false
    @State var multipleWatchListSelection = Set<Watch>()
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
                    chartView
                        .padding(.top, 20)
                } else {
                    EmptyView(name: "Chart")
                }
            }
            .padding(.horizontal, 20)
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
                            selectMultipleWatchListForCompare
                        }, label: {
                            Text("Compare Multiple WatchLists")
                            Text(multipleWatchListSelection.map {
                                return $0.name
                            }.joined(separator: ","))
                        })
                        
                        compareAssetsAndLiabilitiesToggle
                    }, label: {
                        Image(systemName: ConstantUtils.menuImageName)
                    })
                    .font(.system(size: 14).bold())
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
                chartDataList = getAccountsForWatchList(watch: watchListSelected).filter {
                    return $0.balance.currentDayValue.value < 0
                }.sorted(by: {
                    $0.balance.currentDayValue.value > $1.balance.currentDayValue.value
                })
                showingAssetsData.toggle()
            } else {
                chartDataList = getAccountsForWatchList(watch: watchListSelected).filter {
                    return $0.balance.currentDayValue.value >= 0
                }.sorted(by: {
                    $0.balance.currentDayValue.value < $1.balance.currentDayValue.value
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
        .disabled(watchListSelected.name.elementsEqual("Select") || watchListSelected.name.isEmpty)
        .foregroundColor((watchListSelected.name.elementsEqual("Select") || watchListSelected.name.isEmpty) ? Color.gray : Color.theme.primaryText)
        .bold()
    }
    
    var rightTopView: some View {
        Button(action: {
            watchListSelected = Watch()
            showingAssetsData = true
            chartDataList = [Account]()
            compareAssetsToLiabilities = false
            multipleWatchListSelection = Set<Watch>()
            self.isChartDataEnabled = false
        }, label: {
            Text("Reset")
        })
        .font(.system(size: 14))
        .disabled((watchListSelected.name.isEmpty && chartDataList.isEmpty && !compareAssetsToLiabilities && multipleWatchListSelection.isEmpty))
        .foregroundColor(((watchListSelected.name.isEmpty && chartDataList.isEmpty && !compareAssetsToLiabilities && multipleWatchListSelection.isEmpty) ? Color.gray : Color.theme.primaryText))
        .bold()
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
                    if(self.multipleWatchListSelection.isEmpty) {
                        self.chartDataList = [Account]()
                    }
                    self.multipleWatchListSelection.insert(watch)
                    
                    let accountList = getAccountsForWatchList(watch: watch)
                    var totalAmount = accountList.map( {
                        $0.balance.currentDayValue.value
                    }).reduce(0, +)
                    totalAmount = totalAmount < 0 ? totalAmount * -1.0 : totalAmount * 1.0
                    var account = Account()
                    account.accountName = watch.name
                    account.balance.currentDayValue.value = totalAmount
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
                compareAssetsToLiabilities = false
                watchListSelected = Watch()
            }
            .listRowBackground(Color.theme.foreground)
        })
    }
    
    var watchListPicker: some View {
        Picker(selection: $watchListSelected, content: {
            Text("Select").tag(Watch())
            ForEach(watchViewModel.watchList, id: \.self, content: {
                Text($0.name).tag($0)
            })
        }, label: {
            Text("Watch List")
        })
        .listRowBackground(Color.theme.foreground)
        .onChange(of: watchListSelected, perform: { _ in
            if(watchListSelected.name.elementsEqual("Select")) {
                compareAssetsToLiabilities = true
                isChartDataEnabled = false
            } else {
                isChartDataEnabled = true
                compareAssetsToLiabilities = false
                multipleWatchListSelection = Set<Watch>()
                var accountList = getAccountsForWatchList(watch: watchListSelected).filter {
                    return $0.balance.currentDayValue.value >= 0
                }
                accountList.sort(by: {
                    $0.balance.currentDayValue.value > $1.balance.currentDayValue.value
                })
                self.chartDataList = accountList
                
                showingAssetsData = true
            }
        })
    }
    
    var compareAssetsAndLiabilitiesToggle: some View {
        Toggle("Compare Assets and Liabilities", isOn: $compareAssetsToLiabilities)
            .onChange(of: compareAssetsToLiabilities) { value in
                if(value) {
                    isChartDataEnabled = true
                    watchListSelected = Watch()
                    multipleWatchListSelection = Set<Watch>()
                    Task.init {
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
                }
                else {
                    isChartDataEnabled = false
                    self.chartDataList = [Account]()
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
        .frame(minHeight: 550)
        .listRowBackground(Color.theme.foreground)
    }
    
    private func getAccounts() -> [Account] {
        return accountViewModel.accountList
    }
    
    private func getWatchLists() -> [Watch] {
        return watchViewModel.watchList
    }
    
    private func getAccountsForWatchList(watch: Watch) -> [Account] {
        return getAccounts().filter {
            watch.accountList.contains($0.id)
        }
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
