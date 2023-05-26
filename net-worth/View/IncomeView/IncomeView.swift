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
    
    @StateObject var incomeViewModel: IncomeViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                if(incomeViewModel.incomeList.isEmpty && incomeViewModel.incomeListLoaded) {
                    // MARK: Empty View
                    ZStack {
                        Color.navyBlue.ignoresSafeArea()
                        HStack {
                            Text("Click on")
                            Image(systemName: "plus")
                            Text("Icon to add new Income.")
                        }
                        .foregroundColor(Color.lightBlue)
                        .bold()
                    }
                }  else if (!incomeViewModel.incomeListLoaded) {
                    // MARK: Loading View
                    ZStack {
                        Color.navyBlue.ignoresSafeArea()
                        ProgressView().tint(Color.lightBlue)
                    }
                } else {
                    ZStack {
                        Color.navyBlue.ignoresSafeArea()
                        VStack {
                            // MARK: Total Amount View
                            VStack {
                                incomeTotalAmount
                            }
                            .shadow(color: Color.navyBlue, radius: 3)
                            Divider()
                            // MARK: List View
                            VStack {
                                List {
                                    ForEach(incomeViewModel.incomeList, id: \.self) { income in
                                        NavigationLink(destination: {
                                            IncomeDetailView(income: income)
                                                .toolbarRole(.editor)
                                        }, label: {
                                            IncomeRowView(income: income)
                                        })
                                        .contextMenu {
                                            Label(income.id!, systemImage: "info.square")
                                        }
                                    }
                                    .onDelete(perform: deleteIncome)
                                    .listRowBackground(Color.white)
                                    .foregroundColor(Color.navyBlue)
                                }
                                // MARK: List View Scroll Indicator
                                .scrollIndicators(ScrollIndicatorVisibility.hidden)
                                // MARK: List View Refreshable
                                .refreshable {
                                    updateData()
                                }
                                // MARK: Chart Sheet View
                                .sheet(isPresented: $isChartViewOpen) {
                                    IncomeChartView()
                                        .presentationDetents([.medium])
                                }
                                .listStyle(.insetGrouped)
                                .toolbar {
                                    // MARK: Chart ToolbarItem
                                    ToolbarItem(placement: .navigationBarLeading) {
                                        Button(action: {
                                            self.isChartViewOpen.toggle()
                                        }, label: {
                                            Label("Income Chart", systemImage: "chart.line.uptrend.xyaxis")
                                                .foregroundColor(Color.lightBlue)
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
                                        }, label: {
                                            Image(systemName: "ellipsis")
                                                .foregroundColor(Color.lightBlue)
                                                .bold()
                                        })
                                        .font(.system(size: 14).bold())
                                    }
                                }
                                .background(Color.navyBlue)
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
                            .foregroundColor(Color.lightBlue)
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
                                .foregroundColor(Color.lightBlue)
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
            Text("Total: \(SettingsController().getDefaultCurrency().code) \(incomeViewModel.incomeTotalAmount.withCommas(decimalPlace: 2))")
                .foregroundColor(Color.navyBlue)
                .bold()
        }
        .padding(6)
        .frame(width: 360, height: 50)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.navyBlue.opacity(0.3),radius: 10, x: 0, y: 5)
        .padding(.horizontal)
    }
    
    private func deleteIncome(offsets: IndexSet) {
        var id = ""
        withAnimation {
            offsets.map {
                id = incomeViewModel.incomeList[$0].id ?? ""
            }.forEach {
                Task.init {
                    await incomeController.deleteIncome(income: id)
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
            await incomeViewModel.getIncomeList(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear)
        }
    }
}
