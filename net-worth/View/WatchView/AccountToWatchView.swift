//
//  AddAccountWatchListView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 14/02/23.
//

import SwiftUI

struct AccountToWatchView: View {
    
    @State var scenePhaseBlur = 0
    @State var watch: Watch
    @State var searchText = ""
    
    @ObservedObject var accountViewModel = AccountViewModel()
    
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer(minLength: 20)
                ScrollView(.vertical) {
                    LazyVStack {
                        ForEach(accountViewModel.sectionHeaders, id: \.self) { accountType in
                            if(accountViewModel.sectionContent(key: accountType, searchKeyword: searchText).count > 0) {
                                HStack {
                                    Text(accountType.uppercased())
                                        .bold()
                                        .foregroundColor(Color.theme.primaryText)
                                        .font(.system(size: 15))
                                }
                                ForEach(accountViewModel.sectionContent(key: accountType, searchKeyword: searchText), id: \.self) { account in
                                    RowAccountToWatchView(account: account, watch: $watch, isAdded: watch.accountID.contains(account.id!), accountViewModel: accountViewModel)
                                        .padding(.bottom, 10)
                                }
                                Divider()
                            }
                        }
                    }
                }
            }
            .background(Color.theme.background)
        }
        .blur(radius: CGFloat(scenePhaseBlur))
        .onChange(of: scenePhase, perform: { value in
            if(value == .active) {
                scenePhaseBlur = 0
            } else {
                scenePhaseBlur = 5
            }
        })
        .searchable(text: $searchText)
        .onAppear {
            Task.init {
                await accountViewModel.getAccountList()
            }
        }
    }
}
