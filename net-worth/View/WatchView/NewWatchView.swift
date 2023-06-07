//
//  NewWatchView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 14/02/23.
//

import SwiftUI

struct NewWatchView: View {
    
    var watchController = WatchController()
    
    @State var scenePhaseBlur = 0
    @State var watchListName = ""
    @State var isFieldEmpty = false
    
    @ObservedObject var watchViewModel: WatchViewModel
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        VStack {
            Form {
                Section("New Watch List") {
                    TextField("Watch List name", text: $watchListName)
                        .foregroundColor(Color.theme.text)
                }
                .listRowBackground(Color.theme.background)
                .foregroundColor(Color.theme.text)
            }
            VStack {
                Text("Submit")
            }.frame(width: 350, height: 50)
                .foregroundColor(Color.theme.text)
                .background(Color.theme.green)
                .bold()
                .cornerRadius(10)
                .onTapGesture {
                    if(watchListName.isEmpty) {
                        isFieldEmpty.toggle()
                    } else {
                        var watch = Watch()
                        watch.accountName = watchListName
                        watchController.addWatchList(watchList: watch)
                        Task.init {
                            await watchViewModel.getAllWatchList()
                        }
                        dismiss()
                    }
                }
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
