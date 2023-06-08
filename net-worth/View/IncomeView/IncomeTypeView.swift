//
//  IncomeTypeView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 21/02/23.
//

import SwiftUI

struct IncomeTypeView: View {
    
    var incomeController = IncomeController()
    var incomeTypeController = IncomeTypeController()
    
    @State var addNewIncomeTypeOpenView = false
    
    @StateObject var incomeViewModel: IncomeViewModel
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            if(incomeViewModel.incomeTypeList.isEmpty) {
                // MARK: Empty View
                ZStack {
                    Color.theme.background.ignoresSafeArea()
                    HStack {
                        Text("Click on")
                        Image(systemName: "plus")
                        Text("Icon to add new Income Type.")
                    }
                    .foregroundColor(Color.theme.primaryText)
                    .bold()
                }
            } else {
                List {
                    ForEach(incomeViewModel.incomeTypeList, id: \.self) { item in
                        HStack {
                            Text(item.name)
                            Spacer()
                            if(item.isdefault) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.theme.green.opacity(0.5))
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
                                    Task.init {
                                        await incomeTypeController.makeOtherIncomeTypeNonDefault(documentID: item.id!)
                                        var updatedIncomeType = item
                                        updatedIncomeType.isdefault = true
                                        incomeTypeController.updateIncomeType(type: updatedIncomeType)
                                        incomeViewModel.incomeTypeList = [IncomeType]()
                                        await incomeViewModel.getIncomeTypeList()
                                    }
                                }, label: {
                                    Text("Make default")
                                })
                            }
                        }
                    }
                    .listRowBackground(Color.theme.foreground)
                    .foregroundColor(Color.theme.primaryText)
                }
                .background(Color.theme.background)
                .scrollContentBackground(.hidden)
            }
        }
        .toolbar {
            // MARK: Add Income Type ToolbarItem
            ToolbarItem {
                Button(action: {
                    self.addNewIncomeTypeOpenView.toggle()
                }, label: {
                    Image(systemName: "plus")
                        .foregroundColor(Color.theme.primaryText)
                        .bold()
                })
                .font(.system(size: 14).bold())
            }
        }
        // MARK: Add New Income Type Sheet View
        .sheet(isPresented: $addNewIncomeTypeOpenView, content: {
            NewIncomeTypeView(incomeViewModel: incomeViewModel)
                .presentationDetents([.medium])
        })
        .onAppear {
            Task.init {
                await incomeViewModel.getIncomeTypeList()
            }
        }
        .navigationTitle("Income Type")
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
            leading: Button(action: {
                self.presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(Color.theme.primaryText)
                    .bold()
            }
                .font(.system(size: 14).bold())
        )
    }
}
