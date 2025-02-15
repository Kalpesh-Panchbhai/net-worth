//
//  AccountChartView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 01/12/23.
//

import SwiftUI

struct AccountChartView: View {
    
    var id: Any
    var type: String
    
    @EnvironmentObject var accountViewModel: AccountViewModel
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            SingleLineLollipopChartView(chartDataList: accountViewModel.chartDataList)
        }
        .onAppear {
            Task.init {
                await accountViewModel.getChartDataList(id: id, type: type)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.theme.background)
    }

}
