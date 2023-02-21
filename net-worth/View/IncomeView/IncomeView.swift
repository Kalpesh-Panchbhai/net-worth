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
    @State var filterYear = ""
    @State var filterFinancialYear = ""
    
    private var incomeController = IncomeController()
    
    @State private var showingSelectDefaultCurrencyAlert = false
    
    fileprivate func financialYear(startYear: String, endYear: String) -> Text {
        return Text(startYear + "-" + endYear)
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(incomeViewModel.incomeList, id: \.self) { income in
                    ChildIncomeView(income: income)
                }
                .onDelete(perform: deleteIncome)
            }
            .refreshable {
                if(!filterIncomeType.isEmpty || !filterIncomeTag.isEmpty || !filterYear.isEmpty || !filterFinancialYear.isEmpty) {
                    Task.init {
                        await incomeViewModel.getTotalBalance(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear)
                        await incomeViewModel.getIncomeList(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear)
                    }
                } else {
                    Task.init {
                        await incomeViewModel.getTotalBalance()
                        await incomeViewModel.getIncomeList()
                    }
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
                        if(!filterIncomeType.isEmpty || !filterIncomeTag.isEmpty || !filterYear.isEmpty || !filterFinancialYear.isEmpty) {
                            Button(action: {
                                filterIncomeType = ""
                                filterIncomeTag = ""
                                filterYear = ""
                                filterFinancialYear = ""
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
                                if(incomeViewModel.incomeTypeList.count > 1) {
                                    Menu(content: {
                                        ForEach(incomeViewModel.incomeTypeList, id: \.self) { item in
                                            Button(action: {
                                                filterIncomeType = item.name
                                                Task.init {
                                                    await incomeViewModel.getTotalBalance(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear)
                                                    await incomeViewModel.getIncomeList(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear)
                                                }
                                            }, label: {
                                                Text(item.name)
                                            })
                                        }
                                    }, label: {
                                        Text("Income Type")
                                    })
                                }
                                
                                if(incomeViewModel.incomeTagList.count > 1) {
                                    Menu(content: {
                                        ForEach(incomeViewModel.incomeTagList, id: \.self) { item in
                                            Button(action: {
                                                filterIncomeTag = item.name
                                                Task.init {
                                                    await incomeViewModel.getTotalBalance(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear)
                                                    await incomeViewModel.getIncomeList(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear)
                                                }
                                            }, label: {
                                                Text(item.name)
                                            })
                                        }
                                    }, label: {
                                        Text("Income Tag")
                                    })
                                }
                                
                                if(incomeViewModel.incomeYearList.count > 1) {
                                    Menu(content: {
                                        ForEach(incomeViewModel.incomeYearList, id: \.self) { item in
                                            Button(action: {
                                                filterYear = item
                                                filterFinancialYear = ""
                                                Task.init {
                                                    await incomeViewModel.getTotalBalance(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear)
                                                    await incomeViewModel.getIncomeList(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear)
                                                }
                                            }, label: {
                                                Text(item)
                                            })
                                        }
                                    }, label: {
                                        Text("Year")
                                    })
                                }
                                
                                if(incomeViewModel.incomeYearList.count > 1) {
                                    Menu(content: {
                                        ForEach(-1..<incomeViewModel.incomeYearList.count - 1, id: \.self) { item in
                                            Button(action: {
                                                if(item == -1) {
                                                    filterFinancialYear = getFinancialYear(startYear: incomeViewModel.incomeYearList[item + 1], endYear:  String((Int(incomeViewModel.incomeYearList[item + 1]) ?? 0) + 1))
                                                } else {
                                                    filterFinancialYear = getFinancialYear(startYear: incomeViewModel.incomeYearList[item + 1], endYear: incomeViewModel.incomeYearList[item])
                                                }
                                                filterYear = ""
                                                Task.init {
                                                    await incomeViewModel.getTotalBalance(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear)
                                                    await incomeViewModel.getIncomeList(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear)
                                                }
                                            }, label: {
                                                if(item == -1) {
                                                    financialYear(startYear: incomeViewModel.incomeYearList[item + 1], endYear: String((Int(incomeViewModel.incomeYearList[item + 1]) ?? 0) + 1))
                                                } else {
                                                    financialYear(startYear: incomeViewModel.incomeYearList[item + 1], endYear: incomeViewModel.incomeYearList[item])
                                                }
                                            })
                                        }
                                    }, label: {
                                        Text("Financial year")
                                    })
                                }
                                
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
                await incomeViewModel.getIncomeYearList()
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
    
    private func getFinancialYear(startYear: String, endYear: String) -> String {
        return startYear + "-" + endYear
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
