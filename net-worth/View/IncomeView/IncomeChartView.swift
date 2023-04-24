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
                            RuleMark(y: .value("Value", incomeViewModel.incomeList.first?.avg ?? 0.0))
                                        .foregroundStyle(.red)
                        }
                        .frame(height: 250)
                        HStack {
                            Text("Income Tag")
                            Spacer()
                            Text(filterIncomeTag.isEmpty ? "All" : filterIncomeTag)
                        }
                        HStack {
                            Text("Income Type")
                            Spacer()
                            Text(filterIncomeType.isEmpty ? "All" : filterIncomeType)
                        }
                        HStack {
                            Text("Year")
                            Spacer()
                            Text(filterYear.isEmpty ? "All" : filterYear)
                        }
                        HStack {
                            Text("Financial Year")
                            Spacer()
                            Text(filterFinancialYear.isEmpty ? "All" : filterFinancialYear)
                        }
                        HStack {
                            Text("Average")
                            Spacer()
                            Text("\((incomeViewModel.incomeList.first?.avg ?? 0.0).withCommas(decimalPlace: 2))")
                        }
                    }
                }
            }
            .onAppear {
                Task.init {
                    await incomeViewModel.getIncomeList()
                    await incomeViewModel.getIncomeTypeList()
                    await incomeViewModel.getIncomeTagList()
                    await incomeViewModel.getIncomeYearList()
                    await incomeViewModel.getIncomeFinancialYearList()
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
                            
                            if(incomeViewModel.incomeFinancialYearList.count > 1) {
                                Menu(content: {
                                    ForEach(incomeViewModel.incomeFinancialYearList, id: \.self) { item in
                                        Button(action: {
                                            filterYear = ""
                                            filterFinancialYear = item
                                            Task.init {
                                                await incomeViewModel.getIncomeList(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear)
                                            }
                                        }, label: {
                                            Text(item)
                                        })
                                    }
                                }, label: {
                                    Text("Financial Year")
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
