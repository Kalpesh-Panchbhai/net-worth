//
//  UpdateWatchView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 14/02/23.
//

import SwiftUI

struct UpdateWatchView: View {
    
    @State private var isFieldEmpty = false
    
    @Environment(\.dismiss) var dismiss
    
    var watchController = WatchController()
    
    @ObservedObject var watchViewModel: WatchViewModel
    
    var body: some View {
        VStack {
            Form {
                Section("New Watch List") {
                    TextField("Watch List name", text: $watchViewModel.watch.accountName)
                }
            }
            VStack {
                Text("Update")
            }.frame(width: 350, height: 50)
                .foregroundColor(.white)
                .background(.green)
                .bold()
                .cornerRadius(10)
                .onTapGesture {
                    if(watchViewModel.watch.accountName.isEmpty) {
                        isFieldEmpty.toggle()
                    } else {
                        watchController.updateWatchList(watchList: watchViewModel.watch)
                        Task.init {
                            await watchViewModel.getAllWatchList()
                        }
                        dismiss()
                    }
                }
            Spacer()
        }
        .alert(isPresented: $isFieldEmpty) {
            Alert(title: Text("Watch List Name cannot be empty"))
        }
    }
}
