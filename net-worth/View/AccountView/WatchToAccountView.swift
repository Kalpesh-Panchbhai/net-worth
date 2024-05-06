//
//  AddWatchListAccountView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 05/05/23.
//

import SwiftUI

struct WatchToAccountView: View {
    
    var accountID: String
    
    @State var scenePhaseBlur = 0
    
    @ObservedObject var watchViewModel: WatchViewModel
    
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                ScrollView(.vertical) {
                    LazyVStack {
                        ForEach(watchViewModel.watchList, id: \.self) { watchList in
                            RowWatchToAccountView(accountID: accountID, watch: watchList, isAdded: watchList.accountList.contains(accountID), watchViewModel: watchViewModel)
                                .padding(.top, 10)
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
    }
}
