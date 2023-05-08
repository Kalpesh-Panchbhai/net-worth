//
//  IncomeTagView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 21/02/23.
//

import SwiftUI

struct IncomeTagView: View {
    
    @ObservedObject var incomeViewModel = IncomeViewModel()
    
    @State var addNewIncomeTagOpenView = false
    
    private var incomeController = IncomeController()
    
    var body: some View {
        NavigationView {
            if(incomeViewModel.incomeTagList.count == 0) {
                ZStack {
                    HStack {
                        Text("Click on")
                        Image(systemName: "plus")
                        Text("Icon to add new Income Tag.")
                    }
                }
            } else {
                List {
                    ForEach(incomeViewModel.incomeTagList, id: \.self) { item in
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
                                    incomeController.makeOtherIncomeTagNonDefault(documentID: item.id!)
                                    var updatedIncomeTag = item
                                    updatedIncomeTag.isdefault = true
                                    incomeController.updateIncomeTag(tag: updatedIncomeTag)
                                    Task.init {
                                        incomeViewModel.incomeTagList = [IncomeTag]()
                                        await incomeViewModel.getIncomeTagList()
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
                    self.addNewIncomeTagOpenView.toggle()
                }, label: {
                    Label("Add Income Tag", systemImage: "plus")
                })
            }
        }
        .sheet(isPresented: $addNewIncomeTagOpenView, content: {
            NewIncomeTagView(incomeViewModel: incomeViewModel)
        })
        .onAppear {
            Task.init {
                await incomeViewModel.getIncomeTagList()
            }
        }
        .navigationTitle("Income Tag")
    }
}
