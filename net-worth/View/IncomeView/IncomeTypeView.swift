//
//  IncomeTypeView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 21/02/23.
//

import SwiftUI

struct IncomeTypeView: View {
    
    @ObservedObject var incomeViewModel = IncomeViewModel()
    
    @State var addNewIncomeTypeOpenView = false
    
    private var incomeController = IncomeController()
    
    var body: some View {
        NavigationView {
            if(incomeViewModel.incomeTypeList.count == 0) {
                ZStack {
                    HStack {
                        Text("Click on")
                        Image(systemName: "plus")
                        Text("Icon to add new Income Type.")
                    }
                }
            } else {
                List {
                    ForEach(incomeViewModel.incomeTypeList, id: \.self) { item in
                        VStack(alignment: .leading) {
                            Text(item.name)
                            if(item.isdefault) {
                                Text("DEFAULT")
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                            }
                        }
                        .contextMenu {
                            if(!item.isdefault) {
                                Button(action: {
                                    incomeController.makeOtherIncomeTypeNonDefault(documentID: item.id!)
                                    var updatedIncomeType = item
                                    updatedIncomeType.isdefault = true
                                    incomeController.updateIncomeType(type: updatedIncomeType)
                                    Task.init {
                                        incomeViewModel.incomeTypeList = [IncomeType]()
                                        await incomeViewModel.getIncomeTypeList()
                                    }
                                }, label: {
                                    Text("Make default")
                                })
                            }
                        }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem {
                Button(action: {
                    self.addNewIncomeTypeOpenView.toggle()
                }, label: {
                    Label("Add Income Type", systemImage: "plus")
                })
            }
        }
        .sheet(isPresented: $addNewIncomeTypeOpenView, content: {
            NewIncomeTypeView(incomeViewModel: incomeViewModel)
        })
        .onAppear {
            Task.init {
                await incomeViewModel.getIncomeTypeList()
            }
        }
        .navigationTitle("Income Type")
    }
}
