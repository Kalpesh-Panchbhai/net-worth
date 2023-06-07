//
//  UpdateWatchView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 14/02/23.
//

import SwiftUI

struct UpdateWatchView: View {
    
    var watchController = WatchController()
    
    @State var scenePhaseBlur = 0
    @State var isFieldEmpty = false
    
    @ObservedObject var watchViewModel: WatchViewModel
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        VStack {
            Form {
                Section("Update Watch List") {
                    TextField("Updated Watch List name", text: $watchViewModel.watch.accountName)
                }
                .listRowBackground(Color.theme.background)
                .foregroundColor(Color.theme.text)
            }
            .shadow(color: Color.theme.text.opacity(0.3), radius: 10, x: 0, y: 5)
            VStack {
                Text("Update")
            }.frame(width: 350, height: 50)
                .foregroundColor(Color.theme.text)
                .background(Color.theme.green)
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
                .shadow(color: Color.theme.text.opacity(0.3), radius: 10, x: 0, y: 5)
            Spacer()
        }
        .background(Color.theme.background)
        .scrollContentBackground(.hidden)
        .alert(isPresented: $isFieldEmpty) {
            Alert(title: Text("Watch List Name cannot be empty"))
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
