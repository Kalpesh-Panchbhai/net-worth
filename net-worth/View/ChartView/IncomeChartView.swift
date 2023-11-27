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
    
    @State var groupByType = false
    @State var groupByTag = false
    @State var groupByYear = false
    @State var groupByFinancialYear = false
    
    @State var cumulativeView = false
    @State var taxPaidView = false
    @State var averageView = false
    
    @State var incomeChartDataList = [ChartData]()
    @State var incomeListByGroup = [String: Double]()
    @State var incomeAvg = 0.0
    
    @State var showTotal = false
    
    @ObservedObject var incomeViewModel = IncomeViewModel()
    
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        NavigationStack {
            VStack {
                VStack(alignment: .leading) {
                    List {
                        let totalIncomeAmount = incomeViewModel.incomeList.reduce(0.0) { partialResult, item in
                            item.amount + partialResult
                        }
                        
                        let totalTaxPaid = incomeViewModel.incomeList.reduce(0.0) { partialResult, item in
                            item.taxpaid + partialResult
                        }
                        
                        let totalAmount = totalIncomeAmount + totalTaxPaid
                        
                        HStack {
                            if(showTotal) {
                                Text(totalAmount.stringFormat)
                                    .foregroundColor(Color.theme.primaryText)
                                    .font(.system(size: 15))
                            } else {
                                if(taxPaidView) {
                                    Text(totalTaxPaid.stringFormat)
                                        .foregroundColor(Color.theme.primaryText)
                                        .font(.system(size: 15))
                                } else {
                                    Text(totalIncomeAmount.stringFormat)
                                        .foregroundColor(Color.theme.primaryText)
                                        .font(.system(size: 15))
                                }
                            }
                            Spacer()
                            if(!(groupByType || groupByTag || groupByYear || groupByFinancialYear)) {
                                Button("Cumulative") {
                                    self.cumulativeView.toggle()
                                    self.averageView = false
                                    updateChartData()
                                }.buttonStyle(.borderedProminent)
                                    .tint(self.cumulativeView ? Color.theme.green : .blue)
                                    .font(.system(size: 10))
                                if(!showTotal) {
                                    Button("Tax Paid") {
                                        self.taxPaidView.toggle()
                                        updateChartData()
                                    }.buttonStyle(.borderedProminent)
                                        .tint(self.taxPaidView ? Color.theme.green : .blue)
                                        .font(.system(size: 10))
                                }
                                
                                Button("Average") {
                                    self.averageView.toggle()
                                    self.cumulativeView = false
                                    updateChartData()
                                }.buttonStyle(.borderedProminent)
                                    .tint(self.averageView ? Color.theme.green : .blue)
                                    .font(.system(size: 10))
                            }
                        }
                        .listRowBackground(Color.theme.foreground)
                        
                        if(groupByType || groupByTag || groupByYear || groupByFinancialYear) {
                            BarLollipopGroupChartView(chartDataList: incomeListByGroup)
                                .listRowBackground(Color.theme.foreground)
                        } else {
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
                                        Label("Income Type", systemImage: filterIncomeType.isEmpty ? "tray.and.arrow.down" : "\(filterIncomeType.count).circle")
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
                                        Label("Income Tag", systemImage: filterIncomeTag.isEmpty ? "tag.square" : "\(filterIncomeTag.count).circle")
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
                                        Label("Year", systemImage: filterYear.isEmpty ? "calendar.circle" : "\(filterYear.count).circle")
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
                                        Label("Financial Year", systemImage: filterFinancialYear.isEmpty ? "calendar.circle" : "\(filterFinancialYear.count).circle")
                                    })
                                }
                                
                            }, label: {
                                Label("Filter by", systemImage: "line.3.horizontal.decrease.circle")
                            })
                            
                            Menu(content: {
                                
                                Button(action: {
                                    self.groupByType.toggle()
                                    if(groupByType) {
                                        self.groupByTag = false
                                        self.groupByYear = false
                                        self.groupByFinancialYear = false
                                        updateChartData()
                                    } else {
                                        updateChartData()
                                    }
                                }, label: {
                                    if(groupByType) {
                                        Label("Income Type", systemImage: "checkmark")
                                    } else {
                                        Text("Income Type")
                                    }
                                })
                                
                                Button(action: {
                                    self.groupByTag.toggle()
                                    if(groupByTag) {
                                        self.groupByType = false
                                        self.groupByYear = false
                                        self.groupByFinancialYear = false
                                        updateChartData()
                                    } else {
                                        updateChartData()
                                    }
                                }, label: {
                                    if(groupByTag) {
                                        Label("Income Tag", systemImage: "checkmark")
                                    } else {
                                        Text("Income Tag")
                                    }
                                })
                                
                                Button(action: {
                                    self.groupByYear.toggle()
                                    if(groupByYear) {
                                        self.groupByTag = false
                                        self.groupByType = false
                                        self.groupByFinancialYear = false
                                        updateChartData()
                                    } else {
                                        updateChartData()
                                    }
                                }, label: {
                                    if(groupByYear) {
                                        Label("Year", systemImage: "checkmark")
                                    } else {
                                        Text("Year")
                                    }
                                })
                                
                                Button(action: {
                                    self.groupByFinancialYear.toggle()
                                    if(groupByFinancialYear) {
                                        self.groupByTag = false
                                        self.groupByYear = false
                                        self.groupByType = false
                                        updateChartData()
                                    } else {
                                        updateChartData()
                                    }
                                }, label: {
                                    if(groupByFinancialYear) {
                                        Label("Financial Year", systemImage: "checkmark")
                                    } else {
                                        Text("Financial Year")
                                    }
                                })
                            }, label: {
                                Label("Group by", systemImage: "rectangle.3.group")
                            })
                            
                            Toggle("Show Total", isOn: $showTotal)
                                .onChange(of: showTotal, perform: { _ in
                                    self.taxPaidView = false
                                    updateChartData()
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
        incomeListByGroup = [String: Double]()
        incomeAvg = 0.0
        Task.init {
            if(!(groupByType || groupByTag || groupByYear || groupByFinancialYear)) {
                await incomeViewModel.getIncomeList(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear)
                for income in incomeViewModel.incomeList {
                    incomeChartDataList.append(ChartData(date: income.creditedOn, value: getValue(income: income)))
                }
                if(showTotal) {
                    incomeAvg = (incomeViewModel.incomeList.first?.avgAmount ?? 0.0) + (incomeViewModel.incomeList.first?.avgTaxPaid ?? 0.0)
                } else {
                    incomeAvg = taxPaidView ? (incomeViewModel.incomeList.first?.avgTaxPaid ?? 0.0) : (incomeViewModel.incomeList.first?.avgAmount ?? 0.0)
                }
                
                incomeChartDataList.reverse()
            } else {
                if(groupByType) {
                    await incomeViewModel.getIncomeListByGroup(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear, groupBy: "Type")
                } else if(groupByTag) {
                    await incomeViewModel.getIncomeListByGroup(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear, groupBy: "Tag")
                } else if(groupByYear) {
                    await incomeViewModel.getIncomeListByGroup(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear, groupBy: "Year")
                } else if(groupByFinancialYear) {
                    await incomeViewModel.getIncomeListByGroup(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear, groupBy: "Financial Year")
                }
                for income in incomeViewModel.incomeListByGroup {
                    incomeListByGroup.updateValue(income.value.map {
                        $0.cumulativeAmount
                    }.first!, forKey: income.key)
                }
            }
        }
    }
    
    private func getValue(income: IncomeCalculation) -> Double {
        if(showTotal) {
            if(cumulativeView) {
                return income.cumulativeAmount + income.cumulativeTaxPaid
            } else if(averageView ){
                return income.avgAmount + income.avgTaxPaid
            } else {
                return income.amount + income.taxpaid
            }
        } else {
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
}
