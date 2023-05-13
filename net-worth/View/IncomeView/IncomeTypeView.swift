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
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            if(incomeViewModel.incomeTypeList.isEmpty) {
                ZStack {
                    Color.navyBlue.ignoresSafeArea()
                    HStack {
                        Text("Click on")
                        Image(systemName: "plus")
                        Text("Icon to add new Income Type.")
                    }
                    .foregroundColor(Color.lightBlue)
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
                                        .fill(Color.green.opacity(0.5))
                                        .frame(width: 60, height: 15)
                                    Text("DEFAULT")
                                        .font(.system(size: 10))
                                        .bold()
                                }
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
                    self.addNewIncomeTypeOpenView.toggle()
                }, label: {
                    Image(systemName: "plus")
                        .foregroundColor(Color.lightBlue)
                        .bold()
                })
                .font(.system(size: 14).bold())
            }
        }
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
                    .foregroundColor(Color.lightBlue)
                    .bold()
            }
                .font(.system(size: 14).bold())
        )
    }
}
