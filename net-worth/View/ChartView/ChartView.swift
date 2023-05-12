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
    
    @State var showingAssetsData = true
    
    @State var accountListChartData = [Account]()
    
    var body: some View {
        NavigationView {
            List {
                Picker(selection: $watchListSelected, content: {
                    Text("Select").tag(Watch())
                    ForEach(watchViewModel.watchList, id: \.self, content: {
                        Text($0.accountName).tag($0)
                    })
                }, label: {
                    Text("Watch List")
                })
                .listRowBackground(Color.white)
                .colorMultiply(Color.navyBlue)
                .onChange(of: watchListSelected, perform: { _ in
                    Task.init {
                        await accountViewModel.getAccountsForWatchList(accountID: watchListSelected.accountID)
                        self.accountListChartData = accountViewModel.accountList.filter {
                            $0.currentBalance > 0
                        }.sorted(by: {
                            $0.currentBalance > $1.currentBalance
                        })
                        showingAssetsData = true
                    }
                })
                
                HStack {
                    Spacer()
                    Button(action: {
                        if(showingAssetsData) {
                            accountListChartData = accountViewModel.accountList.filter {
                                $0.currentBalance < 0
                            }.sorted(by: {
                                $0.currentBalance < $1.currentBalance
                            })
                            showingAssetsData.toggle()
                        } else {
                            accountListChartData = accountViewModel.accountList.filter {
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
                }.disabled(watchListSelected.accountName.isEmpty)
                .listRowBackground(Color.white)
                .foregroundColor(watchListSelected.accountName.isEmpty ? Color.gray : Color.navyBlue)
                
                PieChartView(
                    values: accountListChartData.map {
                        $0.currentBalance
                    },
                    names: accountListChartData.map {
                        $0.accountName
                    },
                    formatter: {value in String(format: "%.2f", value)},
                    colors: accountListChartData.map { _ in
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
            .onAppear {
                Task.init {
                    watchListSelected = watchViewModel.watchList.filter {
                        $0.accountName.elementsEqual("All")
                    }.first ?? Watch()
                    await accountViewModel.getAccountsForWatchList(accountID: watchListSelected.accountID)
                    self.accountListChartData = accountViewModel.accountList.filter {
                        $0.currentBalance > 0
                    }.sorted(by: {
                        $0.currentBalance > $1.currentBalance
                    })
                }
            }
        }
        
    }
}
