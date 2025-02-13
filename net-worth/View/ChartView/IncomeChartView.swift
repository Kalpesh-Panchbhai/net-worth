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
    
    @State var currentActiveIncome: IncomeRestModel?
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
    
    @EnvironmentObject var incomeViewModel: IncomeViewModel
    
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        NavigationStack {
            HStack(alignment: .top) {
                VStack(alignment: .center) {
                    let totalIncomeAmount = incomeViewModel.incomeList.reduce(0.0) { partialResult, item in
                        item.amount + partialResult
                    }
                    
                    let totalTaxPaid = incomeViewModel.incomeList.reduce(0.0) { partialResult, item in
                        item.taxPaid + partialResult
                    }
                    
                    let totalAmount = totalIncomeAmount + totalTaxPaid
                    
                    HStack {
                        if(showTotal) {
                            Text(totalAmount.stringFormat)
                                .foregroundColor(Color.theme.primaryText)
                                .font(.system(size: 15).bold())
                        } else {
                            if(taxPaidView) {
                                Text(totalTaxPaid.stringFormat)
                                    .foregroundColor(Color.theme.primaryText)
                                    .font(.system(size: 15).bold())
                            } else {
                                Text(totalIncomeAmount.stringFormat)
                                    .foregroundColor(Color.theme.primaryText)
                                    .font(.system(size: 15).bold())
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
                    .frame(maxWidth: .infinity, maxHeight: 10)
                    .padding(15)
                    .background(Color.theme.foreground)
                    .cornerRadius(10)
                    HStack {
                        if(groupByType || groupByTag || groupByYear || groupByFinancialYear) {
                            BarLollipopGroupChartView(chartDataList: incomeListByGroup)
                        } else {
                            if(cumulativeView || averageView) {
                                SingleLineLollipopChartView(chartDataList: incomeChartDataList, isColorChart: false)
                            } else {
                                BarLollipopChartView(chartDataList: incomeChartDataList, average: incomeAvg, isAverageChart: true)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(15)
                    .background(Color.theme.foreground)
                    .cornerRadius(10)
                    Spacer()
                }
                Spacer()
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
                                                    Label(item.name, systemImage: ConstantUtils.checkmarkImageName)
                                                } else {
                                                    Text(item.name)
                                                }
                                            })
                                        }
                                    }, label: {
                                        Label("Income Type", systemImage: "tray.and.arrow.down")
                                        Text(filterIncomeType.joined(separator: ","))
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
                                                    Label(item.name, systemImage: ConstantUtils.checkmarkImageName)
                                                } else {
                                                    Text(item.name)
                                                }
                                            })
                                        }
                                    }, label: {
                                        Label("Income Tag", systemImage: "tag.square")
                                        Text(filterIncomeTag.joined(separator: ","))
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
                                                    Label(item, systemImage: ConstantUtils.checkmarkImageName)
                                                } else {
                                                    Text(item)
                                                }
                                            })
                                        }
                                    }, label: {
                                        Label("Year", systemImage: "calendar.circle")
                                        Text(filterYear.joined(separator: ","))
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
                                                    Label(item, systemImage: ConstantUtils.checkmarkImageName)
                                                } else {
                                                    Text(item)
                                                }
                                            })
                                        }
                                    }, label: {
                                        Label("Financial Year", systemImage: "calendar.circle")
                                        Text(filterFinancialYear.joined(separator: ","))
                                    })
                                }
                                
                            }, label: {
                                Label("Filter by", systemImage: "line.3.horizontal.decrease.circle")
                                Text(getData())
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
                                        Label("Income Type", systemImage: ConstantUtils.checkmarkImageName)
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
                                        Label("Income Tag", systemImage: ConstantUtils.checkmarkImageName)
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
                                        Label("Year", systemImage: ConstantUtils.checkmarkImageName)
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
                                        Label("Financial Year", systemImage: ConstantUtils.checkmarkImageName)
                                    } else {
                                        Text("Financial Year")
                                    }
                                })
                            }, label: {
                                Label("Group by", systemImage: "rectangle.3.group")
                                if(groupByType) {
                                    Text("Income Type")
                                } else if(groupByTag) {
                                    Text("Income Tag")
                                } else if(groupByYear) {
                                    Text("Year")
                                } else if(groupByFinancialYear) {
                                    Text("Financial Year")
                                }
                            })
                            
                            Toggle("Show Total", isOn: $showTotal)
                                .onChange(of: showTotal, perform: { _ in
                                    self.taxPaidView = false
                                    updateChartData()
                                })
                        }, label: {
                            ZStack {
                                Circle()
                                    .frame(width: 25, height: 25)
                                    .foregroundColor(ColorTheme().green)
                                Image(systemName: ConstantUtils.menuImageName)
                                    .foregroundColor(Color.theme.background)
                                    .font(.system(size: 12))
                            }
                        })
                        .font(.system(size: 14))
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
                
//                for income in incomeViewModel.incomeList.reversed() {
//                    incomeChartDataList.append(ChartData(date: income.creditedDate.removeTimeStamp(), value: getValue(income: income)))
//                }
                
                if(showTotal) {
                    incomeAvg = (incomeViewModel.incomeList.first?.avgAmount ?? 0.0) + (incomeViewModel.incomeList.first?.avgTaxPaid ?? 0.0)
                } else {
                    incomeAvg = taxPaidView ? (incomeViewModel.incomeList.first?.avgTaxPaid ?? 0.0) : (incomeViewModel.incomeList.first?.avgAmount ?? 0.0)
                }
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
                for income in incomeViewModel.incomeListByGroup.reversed() {
                    if(showTotal) {
                        incomeListByGroup.updateValue(income.value.map {
                            $0.cumulativeAmount + $0.cumulativeTaxPaid
                        }.first!, forKey: income.key)
                    } else {
                        incomeListByGroup.updateValue(income.value.map {
                            $0.cumulativeAmount
                        }.first!, forKey: income.key)
                    }
                }
            }
        }
    }
    
    private func getValue(income: IncomeRestModel) -> Double {
        if(showTotal) {
            if(cumulativeView) {
                return income.cumulativeAmount + income.cumulativeTaxPaid
            } else if(averageView ){
                return income.avgAmount + income.avgTaxPaid
            } else {
                return income.amount + income.taxPaid
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
                        return income.taxPaid
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
    
    private func getData() -> String {
        var returnString = ""
        if(!filterIncomeType.isEmpty) {
            returnString = "Income Type"
        }
        if(!filterIncomeTag.isEmpty) {
            if(returnString.isEmpty) {
                returnString = "Income Tag"
            } else {
                returnString = returnString + ",Income Tag"
            }
        }
        if(!filterYear.isEmpty) {
            if(returnString.isEmpty) {
                returnString = "Year"
            } else {
                returnString = returnString + ",Year"
            }
        }
        if(!filterFinancialYear.isEmpty) {
            if(returnString.isEmpty) {
                returnString = "Financial Year"
            } else {
                returnString = returnString + ",Financial Year"
            }
        }
        return returnString
    }
}
