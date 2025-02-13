//
//  IncomeTagView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 21/02/23.
//

import SwiftUI

struct IncomeTagView: View {
    
    var incomeController = IncomeController()
    var incomeTagController = IncomeTagController()
    
    @State var addNewIncomeTagOpenView = false
    
    @EnvironmentObject var incomeViewModel: IncomeViewModel
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            if(incomeViewModel.incomeTagList.isEmpty) {
                // MARK: Empty View
                ZStack {
                    Color.theme.background.ignoresSafeArea()
                    HStack {
                        Text("Click on")
                        Image(systemName: ConstantUtils.plusImageName)
                        Text("Icon to add new Income Tag.")
                    }
                    .foregroundColor(Color.theme.primaryText)
                    .bold()
                }
            } else {
                List {
                    ForEach(incomeViewModel.incomeTagList, id: \.self) { item in
                        HStack {
                            Text(item.name)
                            Spacer()
                            if(item.isDefault) {
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
                            if(!item.isDefault) {
                                Button(action: {
                                    Task.init {
                                        var updatedIncomeTag = item
                                        updatedIncomeTag.isDefault = true
                                        await incomeTagController.updateIncomeTag(tag: updatedIncomeTag)
                                        await incomeViewModel.getIncomeTagList()
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
            // MARK: Add Income Tag ToolbarItem
            ToolbarItem {
                Button(action: {
                    self.addNewIncomeTagOpenView.toggle()
                }, label: {
                    ZStack {
                        Circle()
                            .frame(width: 25, height: 25)
                            .foregroundColor(ColorTheme().green)
                        Image(systemName: ConstantUtils.plusImageName)
                            .foregroundColor(Color.theme.background)
                            .font(.system(size: 12))
                    }
                })
                .font(.system(size: 14))
            }
        }
        // MARK: Add New Income Tag Sheet View
        .sheet(isPresented: $addNewIncomeTagOpenView, content: {
            NewIncomeTagView()
                .presentationDetents([.medium])
        })
        .navigationTitle("Income Tag")
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
            leading: Button(action: {
                self.presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: ConstantUtils.backbuttonImageName)
                    .foregroundColor(Color.theme.primaryText)
                    .bold()
            }
                .font(.system(size: 14).bold())
        )
    }
}
