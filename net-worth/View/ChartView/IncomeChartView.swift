//
//  NewIncomeChartView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 26/04/23.
//

import SwiftUI
import Charts

struct IncomeChartView: View {
    
    @State var scenePhaseBlur = 0
    
    @State var currentActiveIncome: Income?
    @State var plotWidth: CGFloat = 0
    
    // MARK: List Filter Variables
    @State var filterIncomeType = [String]()
    @State var filterIncomeTag = [String]()
    @State var filterYear = [String]()
    @State var filterFinancialYear = [String]()
    
    @State var cumulativeView = false
    @State var taxPaidView = false
    @State var averageView = false
    
    @State var incomeChartDataList = [ChartData]()
    @State var incomeAvg = 0.0
    
    @ObservedObject var incomeViewModel = IncomeViewModel()
    
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        NavigationStack {
            VStack {
                VStack(alignment: .leading) {
                    List {
                        let totalAmount = incomeViewModel.incomeList.reduce(0.0) { partialResult, item in
                            item.amount + partialResult
                        }
                        
                        let totalTaxPaid = incomeViewModel.incomeList.reduce(0.0) { partialResult, item in
                            item.taxpaid + partialResult
                        }
                        
                        HStack {
                            if(taxPaidView) {
                                Text(totalTaxPaid.stringFormat)
                                    .foregroundColor(Color.theme.primaryText)
                                    .font(.system(size: 15))
                            } else {
                                Text(totalAmount.stringFormat)
                                    .foregroundColor(Color.theme.primaryText)
                                    .font(.system(size: 15))
                            }
                            Spacer()
                            Button("Cumulative") {
                                self.cumulativeView.toggle()
                                self.averageView = false
                                updateChartData()
                            }.buttonStyle(.borderedProminent)
                                .tint(self.cumulativeView ? Color.theme.green : .blue)
                                .font(.system(size: 10))
                            Button("Tax Paid") {
                                self.taxPaidView.toggle()
                                updateChartData()
                            }.buttonStyle(.borderedProminent)
                                .tint(self.taxPaidView ? Color.theme.green : .blue)
                                .font(.system(size: 10))
                            
                            Button("Average") {
                                self.averageView.toggle()
                                self.cumulativeView = false
                                updateChartData()
                            }.buttonStyle(.borderedProminent)
                                .tint(self.averageView ? Color.theme.green : .blue)
                                .font(.system(size: 10))
                        }
                        .listRowBackground(Color.theme.foreground)
                        
                        if(cumulativeView || averageView) {
                            SingleLineLollipopChartView(chartDataList: incomeChartDataList, isColorChart: false)
                                .listRowBackground(Color.theme.foreground)
                        } else {
                            BarLollipopChartView(chartDataList: incomeChartDataList, average: incomeAvg, isAverageChart: true)
                                .listRowBackground(Color.theme.foreground)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding()
            .navigationTitle("Income Chart")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.theme.background)
            .toolbar {
                if !incomeViewModel.incomeList.isEmpty {
                    ToolbarItem(placement: .navigationBarLeading) {
                        if(!filterIncomeType.isEmpty || !filterIncomeTag.isEmpty || !filterYear.isEmpty || !filterFinancialYear.isEmpty) {
                            Button(action: {
                                filterIncomeType = [String]()
                                filterIncomeTag = [String]()
                                filterYear = [String]()
                                filterFinancialYear = [String]()
                                
                                updateChartData()
                            }, label: {
                                Text("Reset")
                                    .foregroundColor(Color.theme.primaryText)
                                    .bold()
                            })
                            .font(.system(size: 14).bold())
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu(content: {
                            Menu(content: {
                                if(incomeViewModel.incomeTypeList.count > 0) {
                                    Menu(content: {
                                        ForEach(incomeViewModel.incomeTypeList, id: \.self) { item in
                                            Button(action: {
                                                if(filterIncomeType.contains(item.name)) {
                                                    filterIncomeType = filterIncomeType.filter { value in
                                                        !value.elementsEqual(item.name)
                                                    }
                                                } else {
                                                    filterIncomeType.append(item.name)
                                                }
                                                updateChartData()
                                            }, label: {
                                                if(filterIncomeType.contains(item.name)) {
                                                    Label(item.name, systemImage: "checkmark")
                                                } else {
                                                    Text(item.name)
                                                }
                                            })
                                        }
                                    }, label: {
                                        Label("Income Type", systemImage: filterIncomeType.isEmpty ? "tray.and.arrow.down" : "tray.and.arrow.down.fill")
                                    })
                                }
                                
                                if(incomeViewModel.incomeTagList.count > 0) {
                                    Menu(content: {
                                        ForEach(incomeViewModel.incomeTagList, id: \.self) { item in
                                            Button(action: {
                                                if(filterIncomeTag.contains(item.name)) {
                                                    filterIncomeTag = filterIncomeTag.filter { value in
                                                        !value.elementsEqual(item.name)
                                                    }
                                                } else {
                                                    filterIncomeTag.append(item.name)
                                                }
                                                updateChartData()
                                            }, label: {
                                                if(filterIncomeTag.contains(item.name)) {
                                                    Label(item.name, systemImage: "checkmark")
                                                } else {
                                                    Text(item.name)
                                                }
                                            })
                                        }
                                    }, label: {
                                        Label("Income Tag", systemImage: filterIncomeTag.isEmpty ? "tag.square" : "tag.square.fill")
                                    })
                                }
                                
                                if(incomeViewModel.incomeYearList.count > 0) {
                                    Menu(content: {
                                        ForEach(incomeViewModel.incomeYearList, id: \.self) { item in
                                            Button(action: {
                                                if(filterYear.contains(item)) {
                                                    filterYear = filterYear.filter { value in
                                                        !value.elementsEqual(item)
                                                    }
                                                } else {
                                                    filterYear.append(item)
                                                }
                                                filterFinancialYear = [String]()
                                                updateChartData()
                                            }, label: {
                                                if(filterYear.contains(item)) {
                                                    Label(item, systemImage: "checkmark")
                                                } else {
                                                    Text(item)
                                                }
                                            })
                                        }
                                    }, label: {
                                        Label("Year", systemImage: filterYear.isEmpty ? "calendar.circle" : "calendar.circle.fill")
                                    })
                                }
                                
                                if(incomeViewModel.incomeFinancialYearList.count > 0) {
                                    Menu(content: {
                                        ForEach(incomeViewModel.incomeFinancialYearList, id: \.self) { item in
                                            Button(action: {
                                                filterYear = [String]()
                                                if(filterFinancialYear.contains(item)) {
                                                    filterFinancialYear = filterFinancialYear.filter { value in
                                                        !value.elementsEqual(item)
                                                    }
                                                } else {
                                                    filterFinancialYear.append(item)
                                                }
                                                updateChartData()
                                            }, label: {
                                                if(filterFinancialYear.contains(item)) {
                                                    Label(item, systemImage: "checkmark")
                                                } else {
                                                    Text(item)
                                                }
                                            })
                                        }
                                    }, label: {
                                        Label("Financial year", systemImage: filterFinancialYear.isEmpty ? "calendar.circle" : "calendar.circle.fill")
                                    })
                                }
                                
                            }, label: {
                                Label("Filter by", systemImage: "line.3.horizontal.decrease.circle")
                            })
                        }, label: {
                            Image(systemName: "ellipsis")
                                .foregroundColor(Color.theme.primaryText)
                                .font(.system(size: 14).bold())
                        })
                        .font(.system(size: 14).bold())
                    }
                }
            }
        }
        .blur(radius: CGFloat(scenePhaseBlur))
        .onChange(of: scenePhase, perform: { value in
            if(value == .active) {
                scenePhaseBlur = 0
            } else {
                scenePhaseBlur = 5
            }
        })
        .onAppear {
            Task.init {
                await incomeViewModel.getIncomeList(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear)
                await incomeViewModel.getIncomeTagList()
                await incomeViewModel.getIncomeTypeList()
                await incomeViewModel.getIncomeYearList()
                await incomeViewModel.getIncomeFinancialYearList()
                
                updateChartData()
            }
        }
    }
    
    private func updateChartData() {
        incomeChartDataList = [ChartData]()
        incomeAvg = 0.0
        Task.init {
            await incomeViewModel.getIncomeList(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear)
            for income in incomeViewModel.incomeList {
                incomeChartDataList.append(ChartData(date: income.creditedOn, value: getValue(income: income)))
            }
            
            incomeAvg = taxPaidView ? (incomeViewModel.incomeList.first?.avgTaxPaid ?? 0.0) : (incomeViewModel.incomeList.first?.avgAmount ?? 0.0)
            
            incomeChartDataList.reverse()
        }
    }
    
    private func getValue(income: IncomeCalculation) -> Double {
        if(cumulativeView) {
            if(taxPaidView) {
                return income.cumulativeTaxPaid
            } else {
                return income.cumulativeAmount
            }
        } else {
            if(taxPaidView) {
                if(averageView) {
                    return income.avgTaxPaid
                } else {
                    return income.taxpaid
                }
            } else {
                if(averageView) {
                    return income.avgAmount
                } else {
                    return income.amount
                }
            }
        }
    }
}
