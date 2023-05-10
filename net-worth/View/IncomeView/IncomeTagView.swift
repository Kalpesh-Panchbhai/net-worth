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
            if(incomeViewModel.incomeTagList.isEmpty) {
                ZStack {
                    Color.navyBlue.ignoresSafeArea()
                    HStack {
                        Text("Click on")
                        Image(systemName: "plus")
                        Text("Icon to add new Income Tag.")
                    }
                    .foregroundColor(Color.lightBlue)
                    .bold()
                }
            } else {
                List {
                    ForEach(incomeViewModel.incomeTagList, id: \.self) { item in
                        VStack(alignment: .leading) {
                            Text(item.name)
                            if(item.isdefault) {
                                Text("DEFAULT")
                                    .font(.system(size: 10))
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
                    .listRowBackground(Color.white)
                    .foregroundColor(Color.navyBlue)
                }
                .background(Color.navyBlue)
                .scrollContentBackground(.hidden)
            }
        }
        .toolbar {
            ToolbarItem {
                Button(action: {
                    self.addNewIncomeTagOpenView.toggle()
                }, label: {
                    Image(systemName: "plus")
                        .foregroundColor(Color.lightBlue)
                        .bold()
                })
                .font(.system(size: 14).bold())
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
