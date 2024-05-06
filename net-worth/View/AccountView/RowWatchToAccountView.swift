//
//  SwiftUIView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 25/05/23.
//

import SwiftUI

struct RowWatchToAccountView: View {
    
    var accountID: String
    var watchController = WatchController()
    
    @State var watch: Watch
    @State var isAdded: Bool
    
    @ObservedObject var watchViewModel: WatchViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(watch.name)
            }
            .padding()
            Spacer()
            VStack {
                if(isAdded) {
                    Image(systemName: ConstantUtils.bookmarkImageName)
                        .foregroundColor(watch.name.elementsEqual("All") ? .gray : Color.theme.primaryText)
                        .bold()
                        .onTapGesture {
                            isAdded.toggle()
                            self.watch.accountList = self.watch.accountList.filter { item in
                                item != accountID
                            }
                            Task.init {
                                await watchController.updateWatchList(watch: watch)
                                await watchViewModel.getAllWatchList()
                            }
                        }
                } else {
                    Image(systemName: ConstantUtils.notBookmarkImageName)
                        .foregroundColor(Color.theme.primaryText)
                        .bold()
                        .onTapGesture {
                            isAdded.toggle()
                            self.watch.accountList.append(accountID)
                            Task.init {
                                await watchController.updateWatchList(watch: watch)
                                await watchViewModel.getAllWatchList()
                            }
                        }
                }
            }
            .disabled(watch.name.elementsEqual("All"))
            .padding()
        }
        .frame(width: 350, height: 50)
        .background(Color.theme.foreground)
        .foregroundColor(Color.theme.primaryText)
        .cornerRadius(10)
    }
}
