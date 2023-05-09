//
//  ChartView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 09/05/23.
//

import SwiftUI

extension Double {
    static var random: Double {
        return Double(arc4random()) / Double(UInt32.max)
    }
}

extension Color {
    static var random: Color {
        return Color(red: .random, green: .random, blue: .random)
    }
}

struct ChartView: View {
    
    @ObservedObject var watchViewModel: WatchViewModel
    
    @ObservedObject var accountViewModel: AccountViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                PieChartView(
                    values: accountViewModel.accountList.filter {
                        $0.currentBalance >= 0
                    }.sorted(by: {
                        $0.currentBalance > $1.currentBalance
                    }).map {
                        $0.currentBalance
                    },
                    names: accountViewModel.accountList.filter {
                        $0.currentBalance >= 0
                    }.sorted(by: {
                        $0.currentBalance > $1.currentBalance
                    }).map {
                        $0.accountName
                    },
                    formatter: {value in String(format: "%.2f", value)},
                    colors: accountViewModel.accountList.filter {
                        $0.currentBalance >= 0
                    }.map { _ in
                            .random
                    })
            }
        }
    }
}
