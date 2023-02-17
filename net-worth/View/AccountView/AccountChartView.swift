//
//  AccountChartView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 17/02/23.
//

import SwiftUI
import Charts

struct AccountChartView: View {
    
    @ObservedObject var accountViewModel: AccountViewModel
    @State var range = "1M"
    
    var body: some View {
        VStack {
            HStack {
                List {
                    Chart {
                        ForEach(accountViewModel.accountTransactionListWithRange, id: \.self) { item in
                            LineMark(
                                x: .value("Mount", item.timestamp),
                                y: .value("Value", item.balanceChange)
                            )
                        }
                    }
                    .frame(height: 250)
                    
                    Picker(selection: $range, content: {
                        Text("1M").tag("1M")
                        Text("3M").tag("3M")
                        Text("6M").tag("6M")
                        Text("1Y").tag("1Y")
                        Text("2Y").tag("2Y")
                        Text("5Y").tag("5Y")
                        Text("All").tag("All")
                    }, label: {
                        
                    })
                    .onChange(of: range) { value in
                        Task.init {
                            await accountViewModel.getAccountTransactionListWithRange(id: accountViewModel.account.id!, range: value)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
        }
        .onAppear {
            Task.init {
                await accountViewModel.getAccountTransactionListWithRange(id: accountViewModel.account.id!, range: range)
            }
        }
    }
}
