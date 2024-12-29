//
//  IncomeView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 14/11/22.
//

import SwiftUI

struct IncomeView: View {
    
    var incomeController = IncomeController()
    
    // MARK: View Open Variables
    @State var isNewIncomeViewOpen: Bool = false
    @State var isChartViewOpen: Bool = false
    
    // MARK: List Filter Variables
    @State var filterIncomeType = [String]()
    @State var filterIncomeTag = [String]()
    @State var filterYear = [String]()
    @State var filterFinancialYear = [String]()
    
    @State var groupByType = false
    @State var groupByTag = false
    @State var groupByYear = false
    @State var groupByFinancialYear = false
    
    @State var showCumulative = false
    @State var showAverage = false
    
    @EnvironmentObject var incomeViewModel: IncomeViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.theme.background.ignoresSafeArea()
                VStack {
                    // MARK: Total Amount View
                    incomeTotalAmount
                    Divider()
                    HStack {
                        if(isFilterDataAvailable()) {
                            Menu(content: {
                                // MARK: Income Type Menu
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
                                                self.incomeViewModel.selectedIncomeTypeList = filterIncomeType
                                                updateData()
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
                                // MARK: Income Tag Menu
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
                                                self.incomeViewModel.selectedIncomeTagList = filterIncomeTag
                                                updateData()
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
                                // MARK: Income Year Menu
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
                                                self.incomeViewModel.selectedYearList = filterYear
                                                self.incomeViewModel.selectedFinancialYearList = filterFinancialYear
                                                updateData()
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
                                // MARK: Income Financial Year Menu
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
                                                filterYear = [String]()
                                                self.incomeViewModel.selectedFinancialYearList = filterFinancialYear
                                                self.incomeViewModel.selectedYearList = filterYear
                                                updateData()
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
                                Image(systemName: isFilterApplied() ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            })
                            .font(.system(size: 14).bold())
                            
                            Menu(content: {
                                
                                Button(action: {
                                    self.groupByType.toggle()
                                    if(groupByType) {
                                        self.groupByTag = false
                                        self.groupByYear = false
                                        self.groupByFinancialYear = false
                                        self.incomeViewModel.groupView = true
                                        self.incomeViewModel.selectedGroupBy = "Type"
                                        Task.init {
                                            await incomeViewModel.getIncomeListByGroup(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear, groupBy: "Type")
                                        }
                                    } else {
                                        if(!(groupByType || groupByTag || groupByYear || groupByFinancialYear)) {
                                            Task.init {
                                                await incomeViewModel.getIncomeList(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear)
                                            }
                                        }
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
                                        self.incomeViewModel.groupView = true
                                        self.incomeViewModel.selectedGroupBy = "Tag"
                                        Task.init {
                                            await incomeViewModel.getIncomeListByGroup(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear, groupBy: "Tag")
                                        }
                                    } else {
                                        if(!(groupByType || groupByTag || groupByYear || groupByFinancialYear)) {
                                            Task.init {
                                                await incomeViewModel.getIncomeList(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear)
                                            }
                                        }
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
                                        self.groupByType = false
                                        self.groupByTag = false
                                        self.groupByFinancialYear = false
                                        self.incomeViewModel.groupView = true
                                        self.incomeViewModel.selectedGroupBy = "Year"
                                        Task.init {
                                            await incomeViewModel.getIncomeListByGroup(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear, groupBy: "Year")
                                        }
                                    } else {
                                        if(!(groupByType || groupByTag || groupByYear || groupByFinancialYear)) {
                                            Task.init {
                                                await incomeViewModel.getIncomeList(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear)
                                            }
                                        }
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
                                        self.groupByType = false
                                        self.groupByTag = false
                                        self.groupByYear = false
                                        self.incomeViewModel.groupView = true
                                        self.incomeViewModel.selectedGroupBy = "Financial Year"
                                        Task.init {
                                            await incomeViewModel.getIncomeListByGroup(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear, groupBy: "Financial Year")
                                        }
                                    } else {
                                        if(!(groupByType || groupByTag || groupByYear || groupByFinancialYear)) {
                                            Task.init {
                                                await incomeViewModel.getIncomeList(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear)
                                            }
                                        }
                                    }
                                }, label: {
                                    if(groupByFinancialYear) {
                                        Label("Financial Year", systemImage: ConstantUtils.checkmarkImageName)
                                    } else {
                                        Text("Financial Year")
                                    }
                                })
                                
                            }, label: {
                                Image(systemName: isGroupApplied() ? "rectangle.3.group.fill" : "rectangle.3.group")
                            })
                            .font(.system(size: 14).bold())
                            
                            Spacer()
                            
                            Menu(content: {
                                
                                Button(action: {
                                    self.showCumulative.toggle()
                                    if(showCumulative) {
                                        self.showAverage = false
                                    }
                                }, label: {
                                    if(showCumulative) {
                                        Label("Show Cumulative", systemImage: ConstantUtils.checkmarkImageName)
                                    } else {
                                        Text("Show Cumulative")
                                    }
                                })
                                
                                Button(action: {
                                    self.showAverage.toggle()
                                    if(showAverage) {
                                        self.showCumulative = false
                                    }
                                }, label: {
                                    if(showAverage) {
                                        Label("Show Average", systemImage: ConstantUtils.checkmarkImageName)
                                    } else {
                                        Text("Show Average")
                                    }
                                })
                                
                            }, label: {
                                Image(systemName: ConstantUtils.menuImageName)
                            })
                            .font(.system(size: 14).bold())
                        }
                        
                        if(isFilterApplied()) {
                            Button(action: {
                                filterIncomeType = [String]()
                                filterIncomeTag = [String]()
                                filterYear = [String]()
                                filterFinancialYear = [String]()
                                updateData()
                            }, label: {
                                Text("Reset")
                                    .foregroundColor(Color.theme.primaryText)
                            })
                            .font(.system(size: 14).bold())
                        }
                    }.padding([.leading, .trailing], 20)
                    if(incomeViewModel.incomeList.isEmpty && incomeViewModel.incomeListLoaded) {
                        // MARK: Empty View
                        EmptyView(name: "Income")
                    }  else if (!incomeViewModel.incomeListLoaded) {
                        // MARK: Loading View
                        LoadingView()
                    } else {
                        // MARK: List View
                        List {
                            if(groupByType || groupByTag || groupByYear || groupByFinancialYear) {
                                ForEach(incomeViewModel.incomeListByGroup.sorted(by: { (groupByYear || groupByFinancialYear) ? $0.key > $1.key : $0.key < $1.key}), id: \.key) { key, value in
                                    Section(key) {
                                        ForEach(value, id: \.self) { income in
                                            NavigationLink(destination: {
                                                IncomeDetailView(income: income)
                                                    .toolbarRole(.editor)
                                            }, label: {
                                                IncomeRowView(income: income, groupBy: groupByTag ? "Tag" : (groupByType ? "Type" : ""), showCumulative: showCumulative, showAverage: showAverage)
                                            })
                                        }
                                        .onDelete(perform: deleteIncome)
                                        .listRowBackground(Color.theme.foreground)
                                        .foregroundColor(Color.theme.primaryText)
                                    }
                                }
                            } else {
                                ForEach(incomeViewModel.incomeList, id: \.self) { income in
                                    NavigationLink(destination: {
                                        IncomeDetailView(income: income)
                                            .toolbarRole(.editor)
                                    }, label: {
                                        IncomeRowView(income: income, showCumulative: showCumulative, showAverage: showAverage)
                                    })
                                }
                                .onDelete(perform: deleteIncome)
                                .listRowBackground(Color.theme.foreground)
                                .foregroundColor(Color.theme.primaryText)
                            }
                        }
                        .listStyle(SidebarListStyle())
                        // MARK: List View Scroll Indicator
                        .scrollIndicators(ScrollIndicatorVisibility.hidden)
                        // MARK: List View Refreshable
                        .refreshable {
                            updateData(refreshData: true)
                        }
                        .background(Color.theme.background)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .toolbar {
                // MARK: Chart ToolbarItem
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        self.isChartViewOpen.toggle()
                    }, label: {
                        ZStack {
                            Circle()
                                .frame(width: 25, height: 25)
                                .foregroundColor(ColorTheme().foreground)
                            Image(systemName: ConstantUtils.chartImageName)
                                .foregroundColor(Color.theme.primaryText)
                                .font(.system(size: 12))
                        }
                    })
                    .font(.system(size: 14))
                }
                
                // MARK: New Income ToolbarItem
                ToolbarItem {
                    Button(action: {
                        self.isNewIncomeViewOpen.toggle()
                    }, label: {
                        ZStack {
                            Circle()
                                .frame(width: 25, height: 25)
                                .foregroundColor(ColorTheme().green)
                            Image(systemName: ConstantUtils.plusImageName)
                                .foregroundColor(Color.theme.background)
                                .font(.system(size: 12))
                        }
                    })
                    .font(.system(size: 14))
                }
            }
            // MARK: Chart Sheet View
            .sheet(isPresented: $isChartViewOpen) {
                IncomeChartView()
            }
            // MARK: New Income Sheet View
            .sheet(isPresented: $isNewIncomeViewOpen, onDismiss: {
                Task.init {
                    updateData()
                    await incomeViewModel.getIncomeYearList()
                    await incomeViewModel.getIncomeFinancialYearList()
                }
            }, content: {
                NewIncomeView()
                    .presentationDetents([.large])
            })
            .navigationTitle("Incomes")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var incomeTotalAmount: some View {
        VStack {
            HStack {
                Text("Total Income:")
                Spacer()
                Text(SettingsController().getDefaultCurrency().code)
                    .foregroundColor(Color.theme.primaryText)
                Text(incomeViewModel.incomeTotalAmount.withCommas(decimalPlace: 2))
                    .foregroundColor(Color.theme.primaryText)
                    .bold()
                Text("(\(incomePercent(incomeViewModel: incomeViewModel).withCommas(decimalPlace: 2))%)")
                        .font(.system(size: 10))
                        .italic()
            }
            HStack {
                Text("Total Tax Paid:")
                Spacer()
                Text(SettingsController().getDefaultCurrency().code)
                    .foregroundColor(Color.theme.primaryText)
                Text(incomeViewModel.incomeTaxPaidAmount.withCommas(decimalPlace: 2))
                    .foregroundColor(Color.theme.primaryText)
                    .bold()
                Text("(\(taxPaidPercent(incomeViewModel: incomeViewModel).withCommas(decimalPlace: 2))%)")
                        .font(.system(size: 9))
                        .italic()
            }
            HStack {
                Text("Total:")
                Spacer()
                Text(SettingsController().getDefaultCurrency().code)
                    .foregroundColor(Color.theme.primaryText)
                Text("\(addIncomeAndTaxPaid(incomeViewModel: incomeViewModel).withCommas(decimalPlace: 2))")
                    .foregroundColor(Color.theme.primaryText)
                    .bold()
                Text("(100%)")
                    .font(.system(size: 8))
                    .italic()
            }
        }
        .padding(15)
        .frame(width: 360, height: 80)
        .background(Color.theme.foreground)
        .cornerRadius(10)
    }
    
    private func deleteIncome(offsets: IndexSet) {
        var deletedIncome = Income()
        withAnimation {
            offsets.map {
                deletedIncome = incomeViewModel.incomeList[$0]
            }.forEach {
                Task.init {
                    await incomeController.deleteIncome(income: deletedIncome)
                    updateData(refreshData: true)
                }
            }
        }
    }
    
    private func updateData(refreshData: Bool = false) {
        Task.init {
            if(refreshData) {
                await incomeViewModel.getIncomeList()
            }
            await incomeViewModel.getIncomeYearList()
            await incomeViewModel.getIncomeFinancialYearList()
            await incomeViewModel.getTotalBalance(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear)
            await incomeViewModel.getTotalTaxPaid(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear)
            if(groupByTag || groupByType || groupByYear || groupByFinancialYear) {
                if(groupByTag) {
                    await incomeViewModel.getIncomeListByGroup(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear, groupBy: "Tag")
                } else if(groupByType) {
                    await incomeViewModel.getIncomeListByGroup(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear, groupBy: "Type")
                } else if(groupByYear) {
                    await incomeViewModel.getIncomeListByGroup(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear, groupBy: "Year")
                } else if(groupByFinancialYear) {
                    await incomeViewModel.getIncomeListByGroup(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear, groupBy: "Financial Year")
                }
            } else {
                await incomeViewModel.getIncomeList(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear)
            }
        }
    }
    
    private func isFilterApplied() -> Bool {
        return (!filterIncomeType.isEmpty || !filterIncomeTag.isEmpty || !filterYear.isEmpty || !filterFinancialYear.isEmpty)
    }
    
    private func isGroupApplied() -> Bool {
        return (groupByType || groupByTag || groupByYear || groupByFinancialYear)
    }
    
    private func isFilterDataAvailable() -> Bool {
        return incomeViewModel.incomeTypeList.count > 0 || incomeViewModel.incomeTagList.count > 0 || incomeViewModel.incomeYearList.count > 0 || incomeViewModel.incomeFinancialYearList.count > 0
    }
    
    private func addIncomeAndTaxPaid(incomeViewModel: IncomeViewModel) -> Double {
        return incomeViewModel.incomeTotalAmount + incomeViewModel.incomeTaxPaidAmount
    }
    
    private func incomePercent(incomeViewModel: IncomeViewModel) -> Double {
        return incomeViewModel.incomeTotalAmount / addIncomeAndTaxPaid(incomeViewModel: incomeViewModel) * 100
    }
    
    private func taxPaidPercent(incomeViewModel: IncomeViewModel) -> Double {
        return incomeViewModel.incomeTaxPaidAmount / addIncomeAndTaxPaid(incomeViewModel: incomeViewModel) * 100
    }
}
