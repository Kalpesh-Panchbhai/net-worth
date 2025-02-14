//
//  SwiftUIView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 25/05/23.
//

import SwiftUI

struct RowWatchToAccountView: View {
    
    var accountID: Int
    var rowId: Int
    var watchAccountController = WatchAccountController()
    
    @State var watch: WatchRestModel
    @State var isAdded: Bool
    
    @EnvironmentObject var watchViewModel: WatchViewModel
    
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
                                await watchAccountController.addWatchAccount(watch: WatchAccountRestModel(accountId: accountID, watchId: watch.id))
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
