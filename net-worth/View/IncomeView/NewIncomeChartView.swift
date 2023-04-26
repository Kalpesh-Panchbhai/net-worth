//
//  NewIncomeChartView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 26/04/23.
//

import SwiftUI
import Charts

struct NewIncomeChartView: View {
    
    @ObservedObject var incomeViewModel = IncomeViewModel()
    
    @State var currentActiveIncome: Income?
    @State var plotWidth: CGFloat = 0
    
    @State var filterIncomeTag = ""
    @State var filterIncomeType = ""
    @State var filterYear = ""
    @State var filterFinancialYear = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                VStack(alignment: .leading,spacing: 12) {
                    HStack {
                        Text("Views")
                            .fontWeight(.semibold)
                    }
                    
                    let totalValue = incomeViewModel.incomeList.reduce(0.0) { partialResult, item in
                        item.amount + partialResult
                    }
                    
                    Text(totalValue.stringFormat)
                        .font(.largeTitle.bold())
                    
                    AnimatedChart()
                    
                }
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.black.shadow(.drop(radius: 2)))
                }
                
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
                        for(index,_) in incomeViewModel.incomeList.enumerated() {
                            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.01) {
                                withAnimation(.interactiveSpring(response: 0.8, dampingFraction: 0.8, blendDuration: 0.8)) {
                                    incomeViewModel.incomeList[incomeViewModel.incomeList.count - 1 - index].animate = true
                                }
                            }
                        }
                    }
                }
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
                        for(index,_) in incomeViewModel.incomeList.enumerated() {
                            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.01) {
                                withAnimation(.interactiveSpring(response: 0.8, dampingFraction: 0.8, blendDuration: 0.8)) {
                                    incomeViewModel.incomeList[incomeViewModel.incomeList.count - 1 - index].animate = true
                                }
                            }
                        }
                    }
                }
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
                        for(index,_) in incomeViewModel.incomeList.enumerated() {
                            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.01) {
                                withAnimation(.interactiveSpring(response: 0.8, dampingFraction: 0.8, blendDuration: 0.8)) {
                                    incomeViewModel.incomeList[incomeViewModel.incomeList.count - 1 - index].animate = true
                                }
                            }
                        }
                    }
                }
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
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding()
            .navigationTitle("Swift Charts")
        }
    }
    
    @ViewBuilder
    func AnimatedChart() -> some View {
        let max = incomeViewModel.incomeList.max { item1, item2 in
            item2.amount > item1.amount
        }?.amount ?? 0.0
        Chart {
            ForEach(incomeViewModel.incomeList, id: \.id) { income in
                // MARK: Line Graph
                LineMark(
                    x: .value("Time", income.creditedOn),
                    y: .value("Amount",income.animate ? income.amount : 0.0)
                )
                .foregroundStyle(Color.blue.gradient)
                .interpolationMethod(.catmullRom)
                
                AreaMark(
                    x: .value("Time", income.creditedOn),
                    y: .value("Amount",income.animate ? income.amount : 0.0)
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
                                
                                Text(currentActiveIncome.amount.stringFormat)
                                    .font(.title3.bold())
                                    .foregroundColor(.gray)
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
        .chartYScale(domain: 0...(max * 1.5))
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
}
