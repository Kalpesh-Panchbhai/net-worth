//
//  SwiftUIView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 25/05/23.
//

import SwiftUI

struct RowAccountToWatchView: View {
    
    var account: AccountRestModel
    var watchController = WatchController()
    
    @Binding var watch: WatchRestModel
    @State var isAdded: Bool
    
    @EnvironmentObject var watchViewModel: WatchViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(account.name)
                    .foregroundColor(Color.theme.primaryText)
            }
            .padding()
            Spacer()
            VStack {
                if(isAdded) {
                    Image(systemName: ConstantUtils.bookmarkImageName)
                        .foregroundColor(Color.theme.primaryText)
                        .bold()
//                        .onTapGesture {
//                            isAdded.toggle()
//                            self.watch.accountList = self.watch.accountList.filter { item in
//                                item != account.id
//                            }
//                            Task.init {
//                                await watchController.updateWatchList(watch: watch)
//                                await watchViewModel.getAllWatchList()
//                            }
//                        }
                } else {
                    Image(systemName: ConstantUtils.notBookmarkImageName)
                        .foregroundColor(Color.theme.primaryText)
                        .bold()
//                        .onTapGesture {
//                            isAdded.toggle()
//                            self.watch.accountList.append(account.id)
//                            Task.init {
//                                await watchController.updateWatchList(watch: watch)
//                                await watchViewModel.getAllWatchList()
//                            }
//                        }
                }
            }
            .padding()
        }
        .frame(width: 350, height: 50)
        .background(Color.theme.foreground)
        .foregroundColor(Color.theme.primaryText)
        .cornerRadius(10)
    }
}
