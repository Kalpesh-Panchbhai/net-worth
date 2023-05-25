//
//  IncomeTagView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 21/02/23.
//

import SwiftUI

struct IncomeTagView: View {
    
    var incomeController = IncomeController()
    
    @State var addNewIncomeTagOpenView = false
    
    @StateObject var incomeViewModel = IncomeViewModel()
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            if(incomeViewModel.incomeTagList.isEmpty) {
                // MARK: Empty View
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
                        HStack {
                            Text(item.name)
                            Spacer()
                            if(item.isdefault) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.green.opacity(0.5))
                                        .frame(width: 60, height: 15)
                                    Text("DEFAULT")
                                        .font(.system(size: 10))
                                        .bold()
                                }
                            }
                        }
                        .contextMenu {
                            Label(item.id!, systemImage: "info.square")
                            
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
            // MARK: Add Income Tag ToolbarItem
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
        // MARK: Add New Income Tag Sheet View
        .sheet(isPresented: $addNewIncomeTagOpenView, content: {
            NewIncomeTagView(incomeViewModel: incomeViewModel)
                .presentationDetents([.medium])
        })
        .onAppear {
            Task.init {
                await incomeViewModel.getIncomeTagList()
            }
        }
        .navigationTitle("Income Tag")
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
            leading: Button(action: {
                self.presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(Color.lightBlue)
                    .bold()
            }
                .font(.system(size: 14).bold())
        )
    }
}
