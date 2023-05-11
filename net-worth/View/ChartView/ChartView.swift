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
    @State var multiWatchListCompare = false
    @State var multiple = false
    @State var selections: [Watch: Double] = [:]
    
    var body: some View {
        NavigationView {
            List {
                Picker(selection: $watchListSelected, content: {
                    ForEach(watchViewModel.watchList, id: \.self, content: {
                        Text($0.accountName).tag($0)
                    })
                }, label: {
                    Text("Watch List")
                })
                .listRowBackground(Color.white)
                .colorMultiply(Color.navyBlue)
                .onChange(of: watchListSelected, perform: { _ in
                    multiple = false
                    Task.init {
                        await accountViewModel.getAccountsForWatchList(accountID: watchListSelected.accountID)
                    }
                })
                
                Toggle(isOn: $multiWatchListCompare, label: {
                    Text("Compare WatchList")
                })
                .listRowBackground(Color.white)
                .foregroundColor(Color.navyBlue)
                
                if(!multiple) {
                    PieChartView(
                        values: accountViewModel.accountList.sorted(by: {
                            $0.currentBalance > $1.currentBalance
                        }).map {
                            $0.currentBalance
                        },
                        names: accountViewModel.accountList.sorted(by: {
                            $0.currentBalance > $1.currentBalance
                        }).map {
                            $0.accountName
                        },
                        formatter: {value in String(format: "%.2f", value)},
                        colors: accountViewModel.accountList.sorted(by: {
                            $0.currentBalance > $1.currentBalance
                        }).map { _ in
                                .random
                        }, backgroundColor: Color.white)
                    
                    .listRowBackground(Color.white)
                    .foregroundColor(Color.navyBlue)
                    .frame(minHeight: 550)
                } else {
                    PieChartView(
                        values: Array(selections.sorted(by: {
                            $0.value > $1.value
                        }).map({
                            $0.value
                        })),
                        names: Array(selections.sorted(by: {
                            $0.value > $1.value
                        }).map({
                            $0.key.accountName
                        })),
                        formatter: {value in String(format: "%.2f", value)},
                        colors: Array(selections.values).map { _ in
                                .random
                        }, backgroundColor: Color.white)
                    
                    .listRowBackground(Color.white)
                    .foregroundColor(Color.navyBlue)
                    .frame(minHeight: 550)
                }
            }
            .sheet(isPresented: $multiWatchListCompare, onDismiss: {
                multiple = true
            }, content: {
                multipleSelectView
            })
            .navigationTitle("Chart")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.navyBlue)
            .scrollContentBackground(.hidden)
        }
        .onAppear {
            watchListSelected = watchViewModel.watchList.filter {
                $0.accountName.elementsEqual("All")
            }.first ?? Watch()
        }
    }
    
    var multipleSelectView: some View {
        VStack {
            List {
                ForEach(watchViewModel.watchList, id: \.self) { item in
                    MultipleSelectionRow(title: item.accountName, isSelected: self.selections.contains(where: { key, value in
                        key.accountName.elementsEqual(item.accountName)
                    })) {
                        Task.init {
                            if self.selections.contains(where: { key, value in
                                key.accountName.elementsEqual(item.accountName)
                            }) {
                                self.selections.removeValue(forKey: item)
                            }
                            else {
                                Task.init {
                                    await accountViewModel.getAccountsForWatchList(accountID: item.accountID)
                                    await accountViewModel.getTotalBalance(accountList: accountViewModel.accountList)
                                    self.selections.updateValue(accountViewModel.totalBalance.currentValue, forKey: item)
                                }
                                
                            }
                        }
                    }
                }
            }
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
                    Image(systemName: "checkmark")
                }
            }
        }
    }
}
