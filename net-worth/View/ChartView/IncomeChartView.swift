//
//  NewIncomeChartView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 26/04/23.
//

import SwiftUI
import Charts

struct IncomeChartView: View {
    
    @ObservedObject var incomeViewModel = IncomeViewModel()
    
    @State var currentActiveIncome: Income?
    @State var plotWidth: CGFloat = 0
    
    @State var filterIncomeTag = ""
    @State var filterIncomeType = ""
    @State var filterYear = ""
    @State var filterFinancialYear = ""
    
    @State var cumulativeView = false
    @State var taxPaidView = false
    
    var body: some View {
        NavigationStack {
            VStack {
                VStack(alignment: .leading,spacing: 12) {
                    HStack {
                        if(!(filterIncomeType.isEmpty && filterIncomeTag.isEmpty && filterYear.isEmpty && filterFinancialYear.isEmpty)) {
                            Text(getAppliedFilter())
                                .fontWeight(.semibold)
                        }
                    }
                    
                    let totalAmount = incomeViewModel.incomeList.reduce(0.0) { partialResult, item in
                        item.amount + partialResult
                    }
                    
                    let totalTaxPaid = incomeViewModel.incomeList.reduce(0.0) { partialResult, item in
                        item.taxpaid + partialResult
                    }
                    
                    HStack {
                        if(taxPaidView) {
                            Text(totalTaxPaid.stringFormat)
                                .font(.title3.bold())
                        } else {
                            Text(totalAmount.stringFormat)
                                .font(.title3.bold())
                        }
                        Spacer()
                        Button("Cumulative") {
                            self.cumulativeView.toggle()
                            Task.init {
                                await incomeViewModel.getIncomeList(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear)
                                for(index,_) in incomeViewModel.incomeList.enumerated() {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.01) {
                                        withAnimation(.interactiveSpring(response: 0.8, dampingFraction: 0.8, blendDuration: 0.8)) {
                                            incomeViewModel.incomeList[incomeViewModel.incomeList.count - 1 - index].animate = true
                                        }
                                    }
                                }
                            }
                        }.buttonStyle(.borderedProminent)
                            .tint(self.cumulativeView ? .green : .blue)
                            .font(.system(size: 13))
                        Button("Tax Paid") {
                            self.taxPaidView.toggle()
                            Task.init {
                                await incomeViewModel.getIncomeList(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear)
                                for(index,_) in incomeViewModel.incomeList.enumerated() {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.01) {
                                        withAnimation(.interactiveSpring(response: 0.8, dampingFraction: 0.8, blendDuration: 0.8)) {
                                            incomeViewModel.incomeList[incomeViewModel.incomeList.count - 1 - index].animate = true
                                        }
                                    }
                                }
                            }
                        }.buttonStyle(.borderedProminent)
                            .tint(self.taxPaidView ? .green : .blue)
                            .font(.system(size: 13))
                    }
                    
                    AnimatedChart()
                    
                }
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.black.shadow(.drop(radius: 2)))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding()
            .navigationTitle("Income Charts")
            .toolbar {
                if !incomeViewModel.incomeList.isEmpty {
                    ToolbarItem(placement: .navigationBarLeading) {
                        if(!filterIncomeType.isEmpty || !filterIncomeTag.isEmpty || !filterYear.isEmpty || !filterFinancialYear.isEmpty) {
                            Button(action: {
                                filterIncomeType = ""
                                filterIncomeTag = ""
                                filterYear = ""
                                filterFinancialYear = ""
                                Task.init {
                                    await incomeViewModel.getIncomeList(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear)
                                    for(index,_) in incomeViewModel.incomeList.enumerated() {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.01) {
                                            withAnimation(.interactiveSpring(response: 0.8, dampingFraction: 0.8, blendDuration: 0.8)) {
                                                incomeViewModel.incomeList[incomeViewModel.incomeList.count - 1 - index].animate = true
                                            }
                                        }
                                    }
                                }
                            }, label: {
                                Text("Clear")
                            })
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu(content: {
                            Menu(content: {
                                if(incomeViewModel.incomeTypeList.count > 0) {
                                    Menu(content: {
                                        ForEach(incomeViewModel.incomeTypeList, id: \.self) { item in
                                            Button(action: {
                                                filterIncomeType = item.name
                                                Task.init {
                                                    await incomeViewModel.getIncomeList(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear)
                                                    for(index,_) in incomeViewModel.incomeList.enumerated() {
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.01) {
                                                            withAnimation(.interactiveSpring(response: 0.8, dampingFraction: 0.8, blendDuration: 0.8)) {
                                                                incomeViewModel.incomeList[incomeViewModel.incomeList.count - 1 - index].animate = true
                                                            }
                                                        }
                                                    }
                                                }
                                            }, label: {
                                                Text(item.name)
                                            })
                                        }
                                    }, label: {
                                        Label("Income Type", systemImage: "tray.and.arrow.down")
                                    })
                                }
                                
                                if(incomeViewModel.incomeTagList.count > 0) {
                                    Menu(content: {
                                        ForEach(incomeViewModel.incomeTagList, id: \.self) { item in
                                            Button(action: {
                                                filterIncomeTag = item.name
                                                Task.init {
                                                    await incomeViewModel.getIncomeList(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear)
                                                    for(index,_) in incomeViewModel.incomeList.enumerated() {
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.01) {
                                                            withAnimation(.interactiveSpring(response: 0.8, dampingFraction: 0.8, blendDuration: 0.8)) {
                                                                incomeViewModel.incomeList[incomeViewModel.incomeList.count - 1 - index].animate = true
                                                            }
                                                        }
                                                    }
                                                }
                                            }, label: {
                                                Text(item.name)
                                            })
                                        }
                                    }, label: {
                                        Label("Income Tag", systemImage: "tag.square")
                                    })
                                }
                                
                                if(incomeViewModel.incomeYearList.count > 0) {
                                    Menu(content: {
                                        ForEach(incomeViewModel.incomeYearList, id: \.self) { item in
                                            Button(action: {
                                                filterYear = item
                                                filterFinancialYear = ""
                                                Task.init {
                                                    await incomeViewModel.getIncomeList(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear)
                                                    for(index,_) in incomeViewModel.incomeList.enumerated() {
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.01) {
                                                            withAnimation(.interactiveSpring(response: 0.8, dampingFraction: 0.8, blendDuration: 0.8)) {
                                                                incomeViewModel.incomeList[incomeViewModel.incomeList.count - 1 - index].animate = true
                                                            }
                                                        }
                                                    }
                                                }
                                            }, label: {
                                                Text(item)
                                            })
                                        }
                                    }, label: {
                                        Label("Year", systemImage: "calendar.badge.clock")
                                    })
                                }
                                
                                if(incomeViewModel.incomeFinancialYearList.count > 0) {
                                    Menu(content: {
                                        ForEach(incomeViewModel.incomeFinancialYearList, id: \.self) { item in
                                            Button(action: {
                                                filterYear = ""
                                                filterFinancialYear = item
                                                Task.init {
                                                    await incomeViewModel.getIncomeList(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear)
                                                    for(index,_) in incomeViewModel.incomeList.enumerated() {
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.01) {
                                                            withAnimation(.interactiveSpring(response: 0.8, dampingFraction: 0.8, blendDuration: 0.8)) {
                                                                incomeViewModel.incomeList[incomeViewModel.incomeList.count - 1 - index].animate = true
                                                            }
                                                        }
                                                    }
                                                }
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
                        })
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func AnimatedChart() -> some View {
        Chart {
            ForEach(incomeViewModel.incomeList, id: \.id) { income in
                // MARK: Line Graph
                LineMark(
                    x: .value("Time", income.creditedOn),
                    y: .value("Amount",income.animate ? (cumulativeView ? (taxPaidView ? income.cumulativeTaxPaid : income.cumulativeAmount) : (taxPaidView ? income.taxpaid : income.amount)) : 0.0)
                )
                .foregroundStyle(Color.blue.gradient)
                .interpolationMethod(.catmullRom)
                
                AreaMark(
                    x: .value("Time", income.creditedOn),
                    y: .value("Amount",income.animate ? (cumulativeView ? (taxPaidView ? income.cumulativeTaxPaid : income.cumulativeAmount) : (taxPaidView ? income.taxpaid : income.amount)) : 0.0)
                )
                .foregroundStyle(Color.blue.opacity(0.1).gradient)
                .interpolationMethod(.catmullRom)
                
                if let currentActiveIncome, currentActiveIncome.id == income.id {
                    RuleMark(x: .value("Time", currentActiveIncome.creditedOn))
                        .lineStyle(.init(lineWidth: 2, miterLimit: 2, dash: [2], dashPhase: 5))
                        .offset(x: (plotWidth / CGFloat(incomeViewModel.incomeList.count)) / 2)
                        .annotation(position: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Views")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                if(taxPaidView) {
                                    Text(currentActiveIncome.taxpaid.stringFormat)
                                        .font(.title3.bold())
                                        .foregroundColor(.gray)
                                } else {
                                    Text(currentActiveIncome.amount.stringFormat)
                                        .font(.title3.bold())
                                        .foregroundColor(.gray)
                                }
                                Text(currentActiveIncome.tag)
                                    .font(.title3.bold())
                                    .foregroundColor(.gray)
                                Text(currentActiveIncome.creditedOn.getDateAndFormat())
                                    .font(.title3.bold())
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(.white.shadow(.drop(radius: 2)))
                            }
                        }
                }
            }
        }
        // MARK: Customizing Y-AXIS Length
        .chartYScale(domain: 0...(getMaxYScale() * 1.5))
        // MARK: Gesture to Highlight Current Bar
        .chartOverlay(content: { proxy in
            GeometryReader { innerProxy in
                Rectangle()
                    .fill(.clear).contentShape(Rectangle())
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                // MARK: Getting Current Location
                                let location = value.location
                                
                                if let date: Date = proxy.value(atX: location.x) {
                                    let calendar = Calendar.current
                                    let selectedDate = calendar.dateComponents([.day, .month, .year], from: date)
                                    if let currentIncome = incomeViewModel.incomeList.first(where: { income in
                                        calendar.dateComponents([.day, .month, .year], from: income.creditedOn) == selectedDate
                                    }) {
                                        self.currentActiveIncome = currentIncome
                                        self.plotWidth = proxy.plotAreaSize.width
                                    }
                                }
                            }.onEnded { value in
                                self.currentActiveIncome = nil
                            }
                    )
            }
        })
        .frame(height: 250)
        .onAppear {
            Task.init {
                await incomeViewModel.getIncomeList(incomeType: filterIncomeType, incomeTag: filterIncomeTag, year: filterYear, financialYear: filterFinancialYear)
                await incomeViewModel.getIncomeTagList()
                await incomeViewModel.getIncomeTypeList()
                await incomeViewModel.getIncomeYearList()
                await incomeViewModel.getIncomeFinancialYearList()
                for(index,_) in incomeViewModel.incomeList.enumerated() {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.01) {
                        withAnimation(.interactiveSpring(response: 0.8, dampingFraction: 0.8, blendDuration: 0.8)) {
                            incomeViewModel.incomeList[incomeViewModel.incomeList.count - 1 - index].animate = true
                        }
                    }
                }
            }
        }
    }
    
    func getAppliedFilter() -> String {
        var returnString = ""
        var filterAlreadyApplied = false
        if(!filterIncomeType.isEmpty) {
            returnString = "Applied Filter: " + filterIncomeType
            filterAlreadyApplied = true
        }
        if(!filterIncomeTag.isEmpty) {
            if(filterAlreadyApplied) {
                returnString = returnString + "," + filterIncomeTag
            } else {
                returnString = "Applied Filter: " + filterIncomeTag
                filterAlreadyApplied = true
            }
        }
        if(!filterYear.isEmpty) {
            if(filterAlreadyApplied) {
                returnString = returnString + "," + filterYear
            } else {
                returnString = "Applied Filter: " + filterYear
                filterAlreadyApplied = true
            }
        }
        if(!filterFinancialYear.isEmpty) {
            if(filterAlreadyApplied) {
                returnString = returnString + "," + filterFinancialYear
            } else {
                returnString = "Applied Filter: " + filterFinancialYear
            }
        }
        return returnString
    }
    
    func getMaxYScale() -> Double {
        var max = 0.0
        if(cumulativeView && !taxPaidView) {
            max = incomeViewModel.incomeList.first?.cumulativeAmount ?? 0.0
        } else if(!cumulativeView && !taxPaidView) {
            max = incomeViewModel.incomeList.max { item1, item2 in
                item2.amount > item1.amount
            }?.amount ?? 0.0
        } else if(cumulativeView && taxPaidView) {
            max = incomeViewModel.incomeList.first?.cumulativeTaxPaid ?? 0.0
        } else {
            max = incomeViewModel.incomeList.max { item1, item2 in
                item2.taxpaid > item1.taxpaid
            }?.taxpaid ?? 0.0
        }
        return max
    }
}
