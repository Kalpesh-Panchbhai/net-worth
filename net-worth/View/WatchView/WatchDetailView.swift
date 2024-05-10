//
//  SingleWatchListView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 15/02/23.
//

import SwiftUI

struct WatchDetailView: View {
    
    var watch: Watch
    var watchController = WatchController()
    
    @State var isNewTransactionViewOpen = false
    @State var isChartViewOpen = false
    @State var addAccountViewOpen = false
    @State var isAscendingByAlphabetEnabled = true
    @State var isAscendingByAmountEnabled = false
    @State var hideInactiveAccount = true
    @State var hideZeroBalanceAccount = true
    @State var isAscendingEnabled = true
    
    @ObservedObject var accountViewModel: AccountViewModel
    @ObservedObject var watchViewModel: WatchViewModel
    
    @Environment(\.presentationMode) var presentationMode
    
    init(watch: Watch, accountViewModel: AccountViewModel, watchViewModel: WatchViewModel) {
        self.watch = watch
        self.accountViewModel = accountViewModel
        self.watchViewModel = watchViewModel
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.theme.background.ignoresSafeArea()
                VStack {
                    if(watch.accountList.count > 0) {
                        // MARK: Balance Card
                        VStack {
                            BalanceCardView(accountType: watch.name, isWatchListCardView: true, watchList: watch, accountViewModel: accountViewModel)
                                .frame(width: 360, height: 70)
                                .cornerRadius(10)
                        }
                        .padding(.top, 5)
                        Divider()
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack {
                                ForEach(watch.accountList, id: \.self) { accountID in
                                    NavigationLink(destination: {
                                        // MARK: Account Detail View
                                        AccountDetailView(accountID: accountID, accountViewModel: accountViewModel, watchViewModel: watchViewModel)
                                            .toolbarRole(.editor)
                                    }, label: {
                                        AccountRowView(account: getAccountForWatchListAccount(accountId: accountID), fromWatchView: true)
                                            .contextMenu {
                                                Label(accountID, systemImage: ConstantUtils.infoIconImageName)
                                            }
                                    })
                                }
                                .padding(10)
                            }
                        }
                        .padding(10)
                    }
                }
            }
        }
        .navigationTitle(watch.name)
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
        .toolbar {
            if(accountViewModel.originalAccountList.count > 0) {
                ToolbarItem(content: {
                    Button(action: {
                        self.isChartViewOpen.toggle()
                    }, label: {
                        Image(systemName: ConstantUtils.chartImageName)
                            .foregroundColor(Color.theme.primaryText)
                            .bold()
                    })
                    .font(.system(size: 14).bold())
                })
            }
            if(!watch.name.elementsEqual("All")) {
                ToolbarItem(content: {
                    Button(action: {
                        self.addAccountViewOpen.toggle()
                    }, label: {
                        Image(systemName: ConstantUtils.plusImageName)
                            .foregroundColor(Color.theme.primaryText)
                            .bold()
                    })
                    .font(.system(size: 14).bold())
                })
            }
        }
        .sheet(isPresented: $isChartViewOpen, content: {
            AccountWatchChartView(id: watch.id)
        })
        .sheet(isPresented: $addAccountViewOpen, content: {
            AccountToWatchView(watch: watch, accountViewModel: accountViewModel)
        })
    }
    
    func not(_ value: Binding<Bool>) -> Binding<Bool> {
        Binding<Bool>(
            get: { !value.wrappedValue },
            set: { value.wrappedValue = !$0 }
        )
    }
    
    private func getAccountForWatchListAccount(accountId: String) -> Account {
        return accountViewModel.accountList.first {
            return $0.id.elementsEqual(accountId)
        }!
    }
}
