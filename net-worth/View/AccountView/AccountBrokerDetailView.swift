//
//  AccountBrokerView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 01/12/23.
//

import SwiftUI

struct AccountBrokerDetailView: View {
    
    var AccountInbroker: AccountInBrokerRestModel
    
    @State var tabItem = 1
    @EnvironmentObject var accountViewModel: AccountViewModel
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            Picker(selection: $tabItem, content: {
                Text("Transactions").tag(1)
                Text("Chart").tag(2)
            }, label: {
                Text("Account Broker Tab View")
            })
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: tabItem) {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
            }
            if(tabItem == 1) {
                AccountTransactionView(id: AccountInbroker.id, type: "account_broker")
            } else {
                SingleLineLollipopChartView(chartDataList: [ChartData]())
            }
        }
        .onAppear {
            Task.init {
                await accountViewModel.getAccountTransactionList(accountID: AccountInbroker.id, type: "account_broker")
            }
        }
        .navigationTitle(AccountInbroker.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
            leading: Button(action: {
                self.presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: ConstantUtils.backbuttonImageName)
                    .foregroundColor(Color.theme.primaryText)
                    .bold()
            }
                .font(.system(size: 14).bold())
        )
        .background(Color.theme.background)
    }

}
