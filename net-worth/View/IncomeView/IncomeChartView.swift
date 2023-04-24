//
//  IncomeChartView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 21/04/23.
//

import SwiftUI
import Charts

struct IncomeChartView: View {
    
    @ObservedObject var incomeViewModel = IncomeViewModel()
    
    @State var filterIncomeType = ""
    @State var filterIncomeTag = ""
    @State var filterYear = ""
    @State var filterFinancialYear = ""
    
    @State var cumulative = false
    
    fileprivate func financialYear(startYear: String, endYear: String) -> Text {
        return Text(startYear + "-" + endYear)
    }
    
    private func getFinancialYear(startYear: String, endYear: String) -> String {
        return startYear + "-" + endYear
    }
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    List {
                        Toggle("Cumulative", isOn: $cumulative)
                            .onChange(of: cumulative) { newValue in
                                Task.init {
                                    await incomeViewModel.getIncomeList(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear)
                                }
                            }
                        Chart {
                            ForEach(incomeViewModel.incomeList, id: \.self) { item in
                                LineMark(
                                    x: .value("Mount", item.creditedOn),
                                    y: cumulative ? .value("Value", item.cumulative) : .value("Value", item.amount)
                                )
                            }
                        }
                        .frame(height: 250)
                    }
                }
            }
            .onAppear {
                Task.init {
                    await incomeViewModel.getIncomeList()
                    await incomeViewModel.getIncomeTypeList()
                    await incomeViewModel.getIncomeTagList()
                    await incomeViewModel.getIncomeYearList()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if(!filterIncomeType.isEmpty || !filterIncomeTag.isEmpty || !filterYear.isEmpty || !filterFinancialYear.isEmpty) {
                        Button(action: {
                            filterIncomeType = ""
                            filterIncomeTag = ""
                            filterYear = ""
                            filterFinancialYear = ""
                            Task.init {
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
        }
    }
}
