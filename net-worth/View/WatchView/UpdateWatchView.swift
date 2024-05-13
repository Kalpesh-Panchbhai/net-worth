//
//  UpdateWatchView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 14/02/23.
//

import SwiftUI

struct UpdateWatchView: View {
    
    var watchController = WatchController()
    @State var watch: Watch
    
    @State var scenePhaseBlur = 0
    @State var isFieldEmpty = false
    
    @EnvironmentObject var watchViewModel: WatchViewModel
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        VStack {
            Form {
                Section("Update Watch List") {
                    TextField("Updated Watch List name", text: $watch.name)
                }
                .listRowBackground(Color.theme.foreground)
                .foregroundColor(Color.theme.primaryText)
            }
            VStack {
                Text("Update")
            }.frame(width: 350, height: 50)
                .foregroundColor(Color.theme.primaryText)
                .background(Color.theme.green)
                .bold()
                .cornerRadius(10)
                .onTapGesture {
                    if(watch.name.isEmpty) {
                        isFieldEmpty.toggle()
                    } else {
                        Task.init {
                            await watchController.updateWatchList(watch: watch)
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
