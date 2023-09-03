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
    
    @State var showTaxPaidData = false
    @State var hideZeroAmount = true
    
    @State var groupByType = false
    @State var groupByTag = false
    @State var groupByYear = false
    @State var groupByFinancialYear = false
    
    @StateObject var incomeViewModel: IncomeViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.theme.background.ignoresSafeArea()
                VStack {
                    // MARK: Total Amount View
                    if(showTaxPaidData) {
                        incomeTotalTaxPaid
                    } else {
                        incomeTotalAmount
                    }
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
                                                    Label(item, systemImage: "checkmark")
                                                } else {
                                                    Text(item)
                                                }
                                            })
                                        }
                                    }, label: {
                                        Label("Financial year", systemImage: filterFinancialYear.isEmpty ? "calendar.circle" : "\(filterFinancialYear.count).circle")
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
                                        Label("Income Tag", systemImage: "checkmark")
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
                                        Label("Year", systemImage: "checkmark")
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
                                        Label("Financial Year", systemImage: "checkmark")
                                    } else {
                                        Text("Financial Year")
                                    }
                                })
                                
                            }, label: {
                                Image(systemName: isGroupApplied() ? "rectangle.3.group.fill" : "rectangle.3.group")
                            })
                            .font(.system(size: 14).bold())
                        }
                        Spacer()
                        
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
                                            if((hideZeroAmount && ((!income.taxpaid.isZero && showTaxPaidData) || (!income.amount.isZero && !showTaxPaidData)) || !hideZeroAmount)) {
                                                NavigationLink(destination: {
                                                    IncomeDetailView(income: income, incomeViewModel: incomeViewModel)
                                                        .toolbarRole(.editor)
                                                }, label: {
                                                    IncomeRowView(income: income, groupBy: groupByTag ? "Tag" : (groupByType ? "Type" : ""), showTaxPaid: $showTaxPaidData)
                                                })
                                                .contextMenu {
                                                    Label(income.id!, systemImage: "info.square")
                                                }
                                            }
                                        }
                                        .onDelete(perform: deleteIncome)
                                        .listRowBackground(Color.theme.foreground)
                                        .foregroundColor(Color.theme.primaryText)
                                    }
                                }
                            } else {
                                ForEach(incomeViewModel.incomeList, id: \.self) { income in
                                    if((hideZeroAmount && ((!income.taxpaid.isZero && showTaxPaidData) || (!income.amount.isZero && !showTaxPaidData)) || !hideZeroAmount)) {
                                        NavigationLink(destination: {
                                            IncomeDetailView(income: income, incomeViewModel: incomeViewModel)
                                                .toolbarRole(.editor)
                                        }, label: {
                                            IncomeRowView(income: income, showTaxPaid: $showTaxPaidData)
                                        })
                                        .contextMenu {
                                            Label(income.id!, systemImage: "info.square")
                                        }
                                    }
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
                            updateData()
                        }
                        // MARK: Chart Sheet View
                        .sheet(isPresented: $isChartViewOpen) {
                            IncomeChartView()
                        }
                        .toolbar {
                            // MARK: Chart ToolbarItem
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button(action: {
                                    self.isChartViewOpen.toggle()
                                }, label: {
                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                        .foregroundColor(Color.theme.primaryText)
                                        .bold()
                                })
                                .font(.system(size: 14).bold())
                            }
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Menu(content: {
                                    // MARK: Show Tax View
                                    Toggle(isOn: $showTaxPaidData, label: {
                                        Label("Show Tax View", systemImage: "indianrupeesign.square")
                                    })
                                    
                                    // MARK: Hide Zero Balance
                                    Toggle(isOn: $hideZeroAmount, label: {
                                        Label("Hide Zero amount", systemImage: "0.square")
                                    })
                                }, label: {
                                    Image(systemName: "ellipsis")
                                        .foregroundColor(Color.theme.primaryText)
                                        .bold()
                                })
                                .font(.system(size: 14).bold())
                            }
                        }
                        .background(Color.theme.background)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .toolbar {
                // MARK: New Income ToolbarItem
                ToolbarItem {
                    Button(action: {
                        self.isNewIncomeViewOpen.toggle()
                    }, label: {
                        Image(systemName: "plus")
                            .foregroundColor(Color.theme.primaryText)
                            .bold()
                    })
                    .font(.system(size: 14).bold())
                }
            }
            // MARK: New Income Sheet View
            .sheet(isPresented: $isNewIncomeViewOpen, onDismiss: {
                Task.init {
                    updateData()
                    
                    await incomeViewModel.getIncomeTagList()
                    await incomeViewModel.getIncomeTypeList()
                    await incomeViewModel.getIncomeYearList()
                    await incomeViewModel.getIncomeFinancialYearList()
                }
            }, content: {
                NewIncomeView(incomeViewModel: incomeViewModel)
                    .presentationDetents([.medium, .large])
            })
            .navigationTitle("Incomes")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var incomeTotalAmount: some View {
        HStack {
            Text("Total Income: \(SettingsController().getDefaultCurrency().code) \(incomeViewModel.incomeTotalAmount.withCommas(decimalPlace: 2))")
                .foregroundColor(Color.theme.primaryText)
                .bold()
        }
        .padding(6)
        .frame(width: 300, height: 50)
        .background(Color.theme.foreground)
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    private var incomeTotalTaxPaid: some View {
        HStack {
            Text("Total Tax Paid: \(SettingsController().getDefaultCurrency().code) \(incomeViewModel.incomeTaxPaidAmount.withCommas(decimalPlace: 2))")
                .foregroundColor(Color.theme.primaryText)
                .bold()
        }
        .padding(6)
        .frame(width: 300, height: 50)
        .background(Color.theme.foreground)
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    private func deleteIncome(offsets: IndexSet) {
        var id = ""
        withAnimation {
            offsets.map {
                id = incomeViewModel.incomeList[$0].id ?? ""
            }.forEach {
                Task.init {
                    await incomeController.deleteIncome(id: id)
                    updateData()
                    await incomeViewModel.getIncomeYearList()
                    await incomeViewModel.getIncomeFinancialYearList()
                }
            }
        }
    }
    
    private func updateData() {
        Task.init {
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
}
