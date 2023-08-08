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
    @State var filterIncomeType = ""
    @State var filterIncomeTag = ""
    @State var filterYear = ""
    @State var filterFinancialYear = ""
    
    @State var showTaxPaidData = false
    @State var hideZeroAmount = true
    
    @State var groupByType = false
    @State var groupByTag = false
    @State var groupByYear = false
    
    @StateObject var incomeViewModel: IncomeViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                if(incomeViewModel.incomeList.isEmpty && incomeViewModel.incomeListLoaded) {
                    // MARK: Empty View
                    EmptyView(name: "Income")
                }  else if (!incomeViewModel.incomeListLoaded) {
                    // MARK: Loading View
                    LoadingView()
                } else {
                    ZStack {
                        Color.theme.background.ignoresSafeArea()
                        VStack {
                            // MARK: Total Amount View
                            VStack {
                                if(showTaxPaidData) {
                                    incomeTotalTaxPaid
                                } else {
                                    incomeTotalAmount
                                }
                            }
                            Divider()
                            // MARK: List View
                            VStack {
                                List {
                                    if(groupByType || groupByTag || groupByYear) {
                                        ForEach(incomeViewModel.incomeListByGroup.sorted(by: { groupByYear ? $0.key > $1.key : $0.key < $1.key}), id: \.key) { key, value in
                                            Section(key) {
                                                ForEach(value, id: \.self) { income in
                                                    if((hideZeroAmount && ((!income.taxpaid.isZero && showTaxPaidData) || (!income.amount.isZero && !showTaxPaidData)) || !hideZeroAmount)) {
                                                        NavigationLink(destination: {
                                                            IncomeDetailView(income: income)
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
                                                    IncomeDetailView(income: income)
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
                                .listStyle(.insetGrouped)
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
                                            Menu(content: {
                                                // MARK: Income Type Menu
                                                if(incomeViewModel.incomeTypeList.count > 0) {
                                                    Menu(content: {
                                                        ForEach(incomeViewModel.incomeTypeList, id: \.self) { item in
                                                            Button(action: {
                                                                filterIncomeType = item.name
                                                                updateData()
                                                            }, label: {
                                                                Text(item.name)
                                                            })
                                                        }
                                                    }, label: {
                                                        Label("Income Type", systemImage: "tray.and.arrow.down")
                                                    })
                                                }
                                                // MARK: Income Tag Menu
                                                if(incomeViewModel.incomeTagList.count > 0) {
                                                    Menu(content: {
                                                        ForEach(incomeViewModel.incomeTagList, id: \.self) { item in
                                                            Button(action: {
                                                                filterIncomeTag = item.name
                                                                updateData()
                                                            }, label: {
                                                                Text(item.name)
                                                            })
                                                        }
                                                    }, label: {
                                                        Label("Income Tag", systemImage: "tag.square")
                                                    })
                                                }
                                                // MARK: Income Year Menu
                                                if(incomeViewModel.incomeYearList.count > 0) {
                                                    Menu(content: {
                                                        ForEach(incomeViewModel.incomeYearList, id: \.self) { item in
                                                            Button(action: {
                                                                filterYear = item
                                                                filterFinancialYear = ""
                                                                updateData()
                                                            }, label: {
                                                                Text(item)
                                                            })
                                                        }
                                                    }, label: {
                                                        Label("Year", systemImage: "calendar.badge.clock")
                                                    })
                                                }
                                                // MARK: Income Financial Year Menu
                                                if(incomeViewModel.incomeFinancialYearList.count > 0) {
                                                    Menu(content: {
                                                        ForEach(incomeViewModel.incomeFinancialYearList, id: \.self) { item in
                                                            Button(action: {
                                                                filterYear = ""
                                                                filterFinancialYear = item
                                                                updateData()
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
                                            
                                            Menu(content: {
                                                Toggle(isOn: $groupByType, label: {
                                                    Label("Income Type", systemImage: "tray.and.arrow.down")
                                                })
                                                .onChange(of: groupByType, perform: { _ in
                                                    if(groupByType) {
                                                        self.groupByTag = false
                                                        self.groupByYear = false
                                                        Task.init {
                                                            await incomeViewModel.getIncomeListByGroup(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear, groupBy: "Type")
                                                        }
                                                    }
                                                    
                                                    if(!(groupByType || groupByTag || groupByYear)) {
                                                        Task.init {
                                                            await incomeViewModel.getIncomeList(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear)
                                                        }
                                                    }
                                                })
                                                
                                                Toggle(isOn: $groupByTag, label: {
                                                    Label("Income Tag", systemImage: "tag.square")
                                                })
                                                .onChange(of: groupByTag, perform: { _ in
                                                    if(groupByTag) {
                                                        self.groupByType = false
                                                        self.groupByYear = false
                                                        Task.init {
                                                            await incomeViewModel.getIncomeListByGroup(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear, groupBy: "Tag")
                                                        }
                                                    }
                                                    
                                                    if(!(groupByType || groupByTag || groupByYear)) {
                                                        Task.init {
                                                            await incomeViewModel.getIncomeList(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear)
                                                        }
                                                    }
                                                })
                                                
                                                Toggle(isOn: $groupByYear, label: {
                                                    Label("Year", systemImage: "calendar.badge.clock")
                                                })
                                                .onChange(of: groupByYear, perform: { _ in
                                                    if(groupByYear) {
                                                        self.groupByType = false
                                                        self.groupByTag = false
                                                        Task.init {
                                                            await incomeViewModel.getIncomeListByGroup(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear, groupBy: "Year")
                                                        }
                                                    }
                                                    
                                                    if(!(groupByType || groupByTag || groupByYear)) {
                                                        Task.init {
                                                            await incomeViewModel.getIncomeList(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear)
                                                        }
                                                    }
                                                })
                                                
                                            }, label: {
                                                Label("Group by", systemImage: "rectangle.3.group")
                                            })
                                            
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
                // MARK: Reset ToolbarItem
                ToolbarItem(placement: .navigationBarLeading) {
                    if(!filterIncomeType.isEmpty || !filterIncomeTag.isEmpty || !filterYear.isEmpty || !filterFinancialYear.isEmpty) {
                        Button(action: {
                            filterIncomeType = ""
                            filterIncomeTag = ""
                            filterYear = ""
                            filterFinancialYear = ""
                            updateData()
                        }, label: {
                            Text("Reset")
                                .foregroundColor(Color.theme.primaryText)
                                .bold()
                        })
                        .font(.system(size: 14).bold())
                    }
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
            if(groupByTag || groupByType) {
                if(groupByTag) {
                    await incomeViewModel.getIncomeListByGroup(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear, groupBy: "Tag")
                } else {
                    await incomeViewModel.getIncomeListByGroup(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear, groupBy: "Type")
                }
            } else {
                await incomeViewModel.getIncomeList(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear)
            }
        }
    }
}
