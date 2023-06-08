//
//  SwiftUIView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 25/05/23.
//

import SwiftUI

struct RowWatchToAccountView: View {
    
    var account: Account
    var watchController = WatchController()
    
    @State var watch: Watch
    @State var isAdded: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(watch.accountName)
            }
            .padding()
            Spacer()
            VStack {
                if(isAdded) {
                    Image(systemName: "bookmark.fill")
                        .foregroundColor(watch.accountName.elementsEqual("All") ? .gray : Color.theme.primaryText)
                        .bold()
                        .onTapGesture {
                            isAdded.toggle()
                            self.watch.accountID = self.watch.accountID.filter { item in
                                item != account.id
                            }
                            watchController.addAccountToWatchList(watch: watch)
                        }
                } else {
                    Image(systemName: "bookmark")
                        .foregroundColor(Color.theme.primaryText)
                        .bold()
                        .onTapGesture {
                            isAdded.toggle()
                            self.watch.accountID.append(account.id!)
                            watchController.addAccountToWatchList(watch: watch)
                        }
                }
            }
            .disabled(watch.accountName.elementsEqual("All"))
            .padding()
        }
        .frame(width: 350, height: 50)
        .background(Color.theme.foreground)
        .foregroundColor(Color.theme.primaryText)
        .cornerRadius(10)
    }
}
