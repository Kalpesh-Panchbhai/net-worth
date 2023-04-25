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
    
    @State var cumulativeAmount = false
    @State var showTaxPaid = false
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    List {
                        Chart {
                            ForEach(incomeViewModel.incomeList, id: \.self) { item in
                                LineMark(
                                    x: .value("Mount", item.creditedOn),
                                    y: cumulativeAmount ? (showTaxPaid ? .value("Value", item.cumulativeTaxPaid) : .value("Value", item.cumulativeAmount)) : (showTaxPaid ? .value("Value", item.taxPaid) : .value("Value", item.amount))
                                ).foregroundStyle(.green)
                            }
                            RuleMark(y: .value("Value", incomeViewModel.incomeList.first?.avgAmount ?? 0.0))
                                .foregroundStyle(.red)
                            
                            RuleMark(y: .value("Value", incomeViewModel.incomeList.first?.avgTaxPaid ?? 0.0))
                                .foregroundStyle(.purple)
                        }
                        .frame(height: 250)
                        HStack {
                            Picker(selection: $filterIncomeTag, label: Text("Income Tag")) {
                                Text("All").tag("All")
                                ForEach(incomeViewModel.incomeTagList, id: \.self) {
                                    Text($0.name).tag($0.name)
                                }
                            }
                            .onChange(of: filterIncomeTag) { value in
                                Task.init {
                                    if(value == "All") {
                                        filterIncomeTag = ""
                                    }
                                    await incomeViewModel.getIncomeList(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear)
                                }
                            }
                        }
                        HStack {
                            Picker(selection: $filterIncomeType, label: Text("Income Type")) {
                                Text("All").tag("All")
                                ForEach(incomeViewModel.incomeTypeList, id: \.self) {
                                    Text($0.name).tag($0.name)
                                }
                            }
                            .onChange(of: filterIncomeType) { value in
                                Task.init {
                                    if(value == "All") {
                                        filterIncomeType = ""
                                    }
                                    await incomeViewModel.getIncomeList(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear)
                                }
                            }
                        }
                        HStack {
                            Picker(selection: $filterYear, label: Text("Year")) {
                                Text("All").tag("All")
                                ForEach(incomeViewModel.incomeYearList, id: \.self) {
                                    Text($0).tag($0)
                                }
                            }
                            .onChange(of: filterYear) { value in
                                Task.init {
                                    if(value == "All") {
                                        filterYear = ""
                                    }
                                    await incomeViewModel.getIncomeList(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear)
                                }
                            }
                        }
                        HStack {
                            Picker(selection: $filterFinancialYear, label: Text("Financial Year")) {
                                Text("All").tag("All")
                                ForEach(incomeViewModel.incomeFinancialYearList, id: \.self) {
                                    Text($0).tag($0)
                                }
                            }
                            .onChange(of: filterFinancialYear) { value in
                                Task.init {
                                    if(value == "All") {
                                        filterFinancialYear = ""
                                    }
                                    await incomeViewModel.getIncomeList(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear)
                                }
                            }
                        }
                        HStack {
                            Text("Total Amount")
                            Spacer()
                            Text("\((incomeViewModel.incomeList.first?.cumulativeAmount ?? 0.0).withCommas(decimalPlace: 2))")
                        }
                        HStack {
                            Text("Average Amount")
                            Spacer()
                            Text("\((incomeViewModel.incomeList.first?.avgAmount ?? 0.0).withCommas(decimalPlace: 2))")
                        }
                        HStack {
                            Text("Total Tax Paid")
                            Spacer()
                            Text("\((incomeViewModel.incomeList.first?.cumulativeTaxPaid ?? 0.0).withCommas(decimalPlace: 2))")
                        }
                        HStack {
                            Text("Average Tax Paid")
                            Spacer()
                            Text("\((incomeViewModel.incomeList.first?.avgTaxPaid ?? 0.0).withCommas(decimalPlace: 2))")
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
                            Toggle("Cumulative Amount", isOn: $cumulativeAmount)
                            Toggle("Tax Paid", isOn: $showTaxPaid)
                        }, label: {
                            Text("Show by")
                        })
                        
                    }, label: {
                        Image(systemName: "ellipsis")
                    })
                }
            }
        }
    }
}
