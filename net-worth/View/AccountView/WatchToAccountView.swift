//
//  AddWatchListAccountView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 05/05/23.
//

import SwiftUI

struct WatchToAccountView: View {
    
    var accountID: Int
    
    @State var scenePhaseBlur = 0
    
    @EnvironmentObject var watchViewModel: WatchViewModel
    @EnvironmentObject var watchAccountViewModel: WatchAccountViewModel
    
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                ScrollView(.vertical) {
                    LazyVStack {
                        ForEach(watchViewModel.watchList, id: \.self) { watchList in
                            RowWatchToAccountView(accountID: accountID, rowId: watchAccountViewModel.allWatchListByAccountID.first { $0.watchId == watchList.id}?.id ?? 0, watch: watchList, isAdded: watchAccountViewModel.allWatchListByAccountID.map{ $0.watchId }.contains(watchList.id))
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
