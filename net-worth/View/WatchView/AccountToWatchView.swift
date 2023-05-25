//
//  AddAccountWatchListView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 14/02/23.
//

import SwiftUI

struct AccountToWatchView: View {
    
    @State private var scenePhaseBlur = 0
    @State var watch: Watch
    @State private var searchText = ""
    
    @ObservedObject var accountViewModel = AccountViewModel()
    
    @Environment(\.scenePhase) private var scenePhase
    
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
                                        .foregroundColor(Color.lightBlue)
                                        .font(.system(size: 15))
                                }
                                ForEach(accountViewModel.sectionContent(key: accountType, searchKeyword: searchText), id: \.self) { account in
                                    RowAccountToWatchView(account: account, watch: $watch, isAdded: watch.accountID.contains(account.id!), accountViewModel: accountViewModel)
                                }
                            }
                        }
                    }
                }
            }
            .background(Color.navyBlue)
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
