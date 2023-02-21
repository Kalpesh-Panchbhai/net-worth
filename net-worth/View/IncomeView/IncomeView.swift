//
//  IncomeView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 14/11/22.
//

import SwiftUI
import CoreData

struct IncomeView: View {
    
    @ObservedObject var incomeViewModel = IncomeViewModel()
    
    @State var isOpen: Bool = false
    @State var filterIncomeType = ""
    @State var filterIncomeTag = ""
    
    private var incomeController = IncomeController()
    
    @State private var showingSelectDefaultCurrencyAlert = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(incomeViewModel.incomeList, id: \.self) { income in
                    ChildIncomeView(income: income)
                }
                .onDelete(perform: deleteIncome)
            }
            .refreshable {
                Task.init {
                    await incomeViewModel.getTotalBalance()
                    await incomeViewModel.getIncomeList()
                }
            }
            .sheet(isPresented: $isOpen) {
                NewIncomeView(incomeViewModel: incomeViewModel)
            }
            .listStyle(.insetGrouped)
            .toolbar {
                if !incomeViewModel.incomeList.isEmpty {
                    ToolbarItem(placement: .navigationBarLeading) {
                        EditButton()
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        if(!filterIncomeType.isEmpty || !filterIncomeTag.isEmpty) {
                            Button(action: {
                                filterIncomeType = ""
                                filterIncomeTag = ""
                                Task.init {
                                    await incomeViewModel.getTotalBalance()
                                    await incomeViewModel.getIncomeList()
                                }
                            }, label: {
                                Text("Clear")
                            })
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu(content: {
                            Menu(content: {
                                Menu(content: {
                                    ForEach(incomeViewModel.incomeTypeList, id: \.self) { item in
                                        Button(action: {
                                            filterIncomeType = item.name
                                            Task.init {
                                                await incomeViewModel.getTotalBalance(incomeType: filterIncomeType, incomeTag: filterIncomeTag)
                                                await incomeViewModel.getIncomeList(incomeType: filterIncomeType, incomeTag: filterIncomeTag)
                                            }
                                        }, label: {
                                            Text(item.name)
                                        })
                                    }
                                }, label: {
                                    Text("Income Type")
                                })
                                
                                Menu(content: {
                                    ForEach(incomeViewModel.incomeTagList, id: \.self) { item in
                                        Button(action: {
                                            filterIncomeTag = item.name
                                            Task.init {
                                                await incomeViewModel.getTotalBalance(incomeType: filterIncomeType, incomeTag: filterIncomeTag)
                                                await incomeViewModel.getIncomeList(incomeType: filterIncomeType, incomeTag: filterIncomeTag)
                                            }
                                        }, label: {
                                            Text(item.name)
                                        })
                                    }
                                }, label: {
                                    Text("Income Tag")
                                })
                                
                            }, label: {
                                Text("Filter by")
                            })
                            
                        }, label: {
                            Image(systemName: "ellipsis")
                        })
                    }
                }
                ToolbarItem {
                    Button(action: {
                        if(SettingsController().getDefaultCurrency().name == "") {
                            showingSelectDefaultCurrencyAlert = true
                        } else {
                            self.isOpen.toggle()
                        }
                    }, label: {
                        Label("Add Income", systemImage: "plus")
                    })
                    .alert("Please select the default currency in the settings tab to add an Income.", isPresented: $showingSelectDefaultCurrencyAlert) {
                        Button("OK", role: .cancel) { }
                    }
                }
                ToolbarItem(placement: .bottomBar){
                    let balance = incomeViewModel.incomeTotalAmount
                    HStack {
                        Text("Total Income: \(SettingsController().getDefaultCurrency().code) \(balance.withCommas(decimalPlace: 2))")
                            .foregroundColor(.blue)
                            .font(.title2)
                    }
                }
            }
            .navigationTitle("Income")
        }
        .onAppear {
            Task.init {
                await incomeViewModel.getTotalBalance()
                await incomeViewModel.getIncomeList()
                await incomeViewModel.getIncomeTypeList()
                await incomeViewModel.getIncomeTagList()
            }
        }
    }
    
    private func deleteIncome(offsets: IndexSet) {
        var id = ""
        withAnimation {
            offsets.map {
                id = incomeViewModel.incomeList[$0].id ?? ""
            }.forEach {
                Task.init {
                    await incomeController.deleteIncome(income: id)
                    await incomeViewModel.getTotalBalance()
                    await incomeViewModel.getIncomeList()
                }
            }
        }
    }
    
}

struct ChildIncomeView: View {
    
    var income: Income
    
    var body: some View {
        HStack{
            VStack {
                Text(income.type)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(income.creditedOn.getDateAndFormat()).font(.system(size: 12))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(.gray)
                Text(income.tag).font(.system(size: 10))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(.gray)
            }
            Text("\(income.currency) " + income.amount.withCommas(decimalPlace: 2))
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}
