//
//  IncomeView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 14/11/22.
//

import SwiftUI
import CoreData

struct IncomeView: View {
    
    @StateObject var incomeViewModel: IncomeViewModel
    
    @State var isOpen: Bool = false
    @State var isChartViewOpen: Bool = false
    @State var filterIncomeType = ""
    @State var filterIncomeTag = ""
    @State var filterYear = ""
    @State var filterFinancialYear = ""
    
    var incomeController = IncomeController()
    
    @State private var showingSelectDefaultCurrencyAlert = false
    
    fileprivate func financialYear(startYear: String, endYear: String) -> Text {
        return Text(startYear + "-" + endYear)
    }
    
    private func getFinancialYear(startYear: String, endYear: String) -> String {
        return startYear + "-" + endYear
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                if(incomeViewModel.incomeList.isEmpty) {
                    ZStack {
                        HStack {
                            Text("Click on")
                            Image(systemName: "plus")
                            Text("Icon to add new Income.")
                        }
                    }
                } else {
                    List {
                        ForEach(incomeViewModel.incomeList, id: \.self) { income in
                            NavigationLink(destination: {
                                IncomeDetailView(income: income)
                                    .toolbarRole(.editor)
                            }, label: {
                                ChildIncomeView(income: income)
                            })
                            .contextMenu {
                                Label(income.id!, systemImage: "info.square")
                            }
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
                    .sheet(isPresented: $isChartViewOpen) {
                        IncomeChartView()
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
                                        if(incomeViewModel.incomeTypeList.count > 0) {
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
                                                Label("Income Type", systemImage: "tray.and.arrow.down")
                                            })
                                        }
                                        
                                        if(incomeViewModel.incomeTagList.count > 0) {
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
                                                Label("Income Tag", systemImage: "tag.square")
                                            })
                                        }
                                        
                                        if(incomeViewModel.incomeYearList.count > 0) {
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
                                                Label("Year", systemImage: "calendar.badge.clock")
                                            })
                                        }
                                        
                                        if(incomeViewModel.incomeFinancialYearList.count > 0) {
                                            Menu(content: {
                                                ForEach(incomeViewModel.incomeFinancialYearList, id: \.self) { item in
                                                    Button(action: {
                                                        filterYear = ""
                                                        filterFinancialYear = item
                                                        Task.init {
                                                            await incomeViewModel.getTotalBalance(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear)
                                                            await incomeViewModel.getIncomeList(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear)
                                                        }
                                                    }, label: {
                                                        Text(item)
                                                    })
                                                }
                                            }, label: {
                                                Label("Financial year", systemImage: "calendar.badge.clock")
                                            })
                                        }
                                        
                                    }, label: {
                                        Label("Filter by", systemImage: "line.3.horizontal.decrease.circle")
                                    })
                                    
                                }, label: {
                                    Image(systemName: "ellipsis")
                                })
                            }
                            ToolbarItem {
                                Button(action: {
                                    self.isChartViewOpen.toggle()
                                }, label: {
                                    Label("Income Chart", systemImage: "chart.line.uptrend.xyaxis")
                                })
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
                }
            }
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        self.isOpen.toggle()
                    }, label: {
                        Label("Add Income", systemImage: "plus")
                    })
                }
            }
            .sheet(isPresented: $isOpen, content: {
                NewIncomeView(incomeViewModel: incomeViewModel)
            })
            .navigationTitle("Income")
            .navigationBarTitleDisplayMode(.inline)
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
                    await incomeViewModel.getIncomeYearList()
                    await incomeViewModel.getIncomeFinancialYearList()
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
            VStack {
                Text("\(income.currency) " + income.amount.withCommas(decimalPlace: 2))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Text("\(income.currency) \(income.avgAmount.withCommas(decimalPlace: 2))").font(.system(size: 12))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .foregroundColor(.gray)
            }
        }
    }
}
