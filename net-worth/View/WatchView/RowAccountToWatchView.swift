//
//  SwiftUIView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 25/05/23.
//

import SwiftUI

struct RowAccountToWatchView: View {
    
    var account: AccountRestModel
    var watchAccountController = WatchAccountController()
    var rowId: Int
    
    @Binding var watch: WatchRestModel
    @State var isAdded: Bool
    
    @EnvironmentObject var watchAccountViewModel: WatchAccountViewModel
    
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
                        .onTapGesture {
                            isAdded.toggle()
                            Task.init {
                                await watchAccountController.deleteWatchAccount(id: rowId)
                            }
                        }
                } else {
                    Image(systemName: ConstantUtils.notBookmarkImageName)
                        .foregroundColor(Color.theme.primaryText)
                        .bold()
                        .onTapGesture {
                            isAdded.toggle()
                            Task.init {
                                await watchAccountController.addWatchAccount(watch: WatchAccountRestModel(accountId: account.id, watchId: watch.id))
                            }
                        }
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
