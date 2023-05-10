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
                .foregroundColor(Color.navyBlue)
                .onChange(of: watchListSelected, perform: { _ in
                    Task.init {
                        await accountViewModel.getAccountsForWatchList(accountID: watchListSelected.accountID)
                    }
                })
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
            }
            .navigationTitle("Chart")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.navyBlue)
            .scrollContentBackground(.hidden)
        }
        .onAppear {
            watchListSelected = watchViewModel.watchList.filter {
                $0.accountName.elementsEqual("All")
            }.first!
        }
    }
}
