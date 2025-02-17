//
//  AccountChartView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 01/12/23.
//

import SwiftUI

struct AccountChartView: View {
    
    var id: Any
    var type: String
    
    @State var range: String = "1M"
    @State var scenePhaseBlur = 0
    
    @EnvironmentObject var accountViewModel: AccountViewModel
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        NavigationStack {
            HStack(alignment: .top) {
                VStack(alignment: .center) {
                    HStack {
                        SingleLineLollipopChartView(chartDataList: accountViewModel.chartDataList)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(15)
                    .background(Color.theme.foreground)
                    .cornerRadius(10)
                    
                    Spacer()
                    
                    Picker(selection: $range, content: {
                        Text("1M").tag("1M")
                        Text("3M").tag("3M")
                        Text("6M").tag("6M")
                        Text("1Y").tag("1Y")
                        Text("2Y").tag("2Y")
                        Text("5Y").tag("5Y")
                        Text("Max").tag("Max")
                    }, label: {
                        Text("Account Chart Tab View")
                    })
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: range) {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        
                        Task.init {
                            await accountViewModel.getChartDataList(id: id, type: type, range: range)
                        }
                    }
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding()
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
        .onAppear {
            Task.init {
                await accountViewModel.getChartDataList(id: id, type: type, range: range)
            }
        }
    }

}
