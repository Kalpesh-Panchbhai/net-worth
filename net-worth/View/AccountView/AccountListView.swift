//
//  AccountListView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 10/02/23.
//

import SwiftUI

struct AccountListView: View {
    
    var accountType: String
    var accountController = AccountController()
    
    @State var searchText = ""
    @State var isNewTransactionViewOpen = false
    @State var isChartViewOpen = false
    @State var isPresentingAccountDeleteConfirm = false
    @State var deletedAccount = AccountRestModel()
    
    @EnvironmentObject var accountViewModel: AccountViewModel
    @EnvironmentObject var watchViewModel: WatchViewModel
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()
            VStack {
                if(!accountType.elementsEqual("Inactive Account") && !accountViewModel.sectionContent(key: accountType, searchKeyword: searchText).isEmpty) {
                    VStack {
                        BalanceCardView(accountType: accountType, isWatchListCardView: false, watchList: WatchRestModel())
                    }
                }
                Divider()
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack {
                        ForEach(accountViewModel.sectionContent(key: accountType, searchKeyword: searchText), id: \.self) { account in
                            NavigationLink(destination: {
                                AccountDetailView(accountID: account.id)
                            }, label: {
                                AccountRowView(account: account, fromWatchView: accountType.elementsEqual("Inactive Account"), isInActiveAccount: accountType.elementsEqual("Inactive Account"))
                            })
                        }
                    }
                }
                .padding(10)
            }
        }
        .navigationTitle(accountType)
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
        .navigationBarItems(
            trailing: Button(action: {
                self.isChartViewOpen.toggle()
            }) {
                ZStack {
                    Circle()
                        .frame(width: 25, height: 25)
                        .foregroundColor(ColorTheme().foreground)
                    Image(systemName: ConstantUtils.chartImageName)
                        .foregroundColor(Color.theme.primaryText)
                        .font(.system(size: 12))
                }
            }
                .font(.system(size: 14).bold())
        )
        .sheet(isPresented: $isChartViewOpen, onDismiss: {
            
        }, content: {
            AccountChartView(id: accountType, type: accountType == "Broker" ? "broker_type" : "non_broker_type")
        })
        .searchable(text: $searchText)
    }
}

