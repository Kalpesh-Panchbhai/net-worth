//
//  SingleLineLollipop.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 03/06/23.
//

import SwiftUI
import Charts

struct SingleLineLollipopChartView: View {
    
    var chartDataList: [ChartData]
    var accountTransactionList: [AccountTransactionRestModel] = [AccountTransactionRestModel]()
    var isPercentageChart: Bool = false
    var isColorChart: Bool = true
    
    var showMessage: Bool
    var isAccount: Bool
    
    @State private var lineWidth = 2.0
    @State private var selectedElement: ChartData?
    
    var body: some View {
        ZStack {
            Chart {
                ForEach(chartDataList, id: \.self) { data in
                    LineMark(
                        x: .value("Date", data.date),
                        y: .value("Value", data.value),
                        series: .value("Type", "Value")
                    )
                    .accessibilityLabel(data.date.formatted(date: .complete, time: .omitted))
                    .accessibilityValue("\(data.value)")
                    .lineStyle(StrokeStyle(lineWidth: lineWidth))
                    .foregroundStyle(getChartColor().gradient)
                    .interpolationMethod(.catmullRom)
                    
                    if(isAccount) {
                        LineMark(
                            x: .value("Date", data.date),
                            y: .value("Value", data.invested),
                            series: .value("Type", "Invested")
                        )
                        .accessibilityLabel(data.date.formatted(date: .complete, time: .omitted))
                        .accessibilityValue("\(data.invested)")
                        .lineStyle(StrokeStyle(lineWidth: lineWidth))
                        .foregroundStyle(getChartColor().gradient)
                        .interpolationMethod(.catmullRom)
                    }
                    if(isTransactionDate(date: data.date.localToLocalStringFull())) {
                        PointMark(
                            x: .value("Date", data.date),
                            y: .value("Value", data.value)
                        )
                        .annotation(position: .overlay, alignment: .center) {
                            ZStack {
                                Circle()
                                    .fill(getTransactionDateCircleColor(date: data.date.localToLocalStringFull()).opacity(1))
                                    .frame(width: 13, height: 13)
                            }
                        }
                        .symbolSize(0)
                    }
                    AreaMark(
                        x: .value("Date", data.date),
                        y: .value("Value", data.value)
                    )
                    .foregroundStyle(Gradient(colors: [getChartColor().opacity(0.05), .clear]))
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartYScale(domain: getMinValue()...getMaxValue())
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisGridLine(centered: true, stroke: StrokeStyle(lineWidth: 0.1, dash: [0]))
                        .foregroundStyle(Color.theme.primaryText)
                    AxisTick(stroke: StrokeStyle(lineWidth: 1))
                        .foregroundStyle(Color.theme.primaryText)
                    AxisValueLabel()
                        .foregroundStyle(Color.theme.primaryText)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic) { value in
                    AxisGridLine(centered: true, stroke: StrokeStyle(lineWidth: 0.1, dash: [0]))
                        .foregroundStyle(Color.theme.primaryText)
                    AxisTick(stroke: StrokeStyle(lineWidth: 1))
                        .foregroundStyle(Color.theme.primaryText)
                    AxisValueLabel {
                        if(isPercentageChart) {
                            Text("\(CommonController.abbreviateAxisValue(string: CommonController.parseAxisValue(value: value) ?? ""))%")
                        } else {
                            Text("\(CommonController.abbreviateAxisValue(string: CommonController.parseAxisValue(value: value) ?? ""))")
                        }
                    }
                    .foregroundStyle(Color.theme.primaryText)
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle().fill(.clear).contentShape(Rectangle())
                        .gesture(
                            SpatialTapGesture()
                                .onEnded { value in
                                    let element = findElement(location: value.location, proxy: proxy, geometry: geo)
                                    if selectedElement?.date == element?.date {
                                        selectedElement = nil
                                    } else {
                                        selectedElement = element
                                    }
                                }
                                .exclusively(
                                    before: DragGesture()
                                        .onChanged { value in
                                            selectedElement = findElement(location: value.location, proxy: proxy, geometry: geo)
                                        }
                                )
                        )
                }
            }
            .chartBackground { proxy in
                ZStack(alignment: .topLeading) {
                    GeometryReader { geo in
                        if let selectedElement {
                            let dateInterval = Calendar.current.dateInterval(of: .day, for: selectedElement.date)!
                            let startPositionX1 = proxy.position(forX: dateInterval.start) ?? 0
                            let startPositionY1 = proxy.position(forY: selectedElement.value) ?? 0
                            let startPositionY2 = proxy.position(forY: selectedElement.invested) ?? 0
                            
                            let lineX = startPositionX1 + geo[proxy.plotFrame!].origin.x
                            let lineY1 = startPositionY1 + geo[proxy.plotFrame!].origin.y
                            let lineY2 = startPositionY2 + geo[proxy.plotFrame!].origin.y
                            
                            let lineHeight = geo[proxy.plotFrame!].maxY
                            let boxWidth: CGFloat = 200
                            let boxOffset = max(0, min(geo.size.width - boxWidth, lineX - boxWidth / 2))
                            
                            Rectangle()
                                .fill(getChartColor())
                                .frame(width: 2, height: lineHeight)
                                .position(x: lineX, y: lineHeight / 2)
                            
                            Circle()
                                .strokeBorder(Color.theme.primaryText, lineWidth: 3)
                                .background(Circle().fill(getChartColor()))
                                .frame(width: 12, height: 12)
                                .position(x: lineX, y: lineY1)
                            
                            if(isAccount) {
                                Circle()
                                    .strokeBorder(Color.theme.primaryText, lineWidth: 3)
                                    .background(Circle().fill(getChartColor()))
                                    .frame(width: 12, height: 12)
                                    .position(x: lineX, y: lineY2)
                            }
                            
                            VStack(alignment: .center) {
                                Text("\(selectedElement.date, format: .dateTime.year().month().day())")
                                    .font(.system(size: 10).bold())
                                    .foregroundColor(Color.theme.background)
                                if(isPercentageChart) {
                                    if(isAccount) {
                                        HStack {
                                            VStack {
                                                Text("Current: \(selectedElement.value.withCommas(decimalPlace: 2))%")
                                                    .font(.system(size: 12).bold())
                                                    .foregroundColor(Color.theme.background)
                                                Text("Invested: \(selectedElement.invested.withCommas(decimalPlace: 2))%")
                                                    .font(.system(size: 12).bold())
                                                    .foregroundColor(Color.theme.background)
                                            }
                                            VStack {
                                                Text(getPercentageChange())
                                                    .font(.system(size: 12).bold())
                                                    .foregroundColor(getGrowthColor())
                                            }
                                        }
                                    } else {
                                        Text("\(selectedElement.value.withCommas(decimalPlace: 2))%")
                                            .font(.system(size: 12).bold())
                                            .foregroundColor(Color.theme.background)
                                    }
                                } else {
                                    if(isAccount) {
                                        HStack {
                                            VStack {
                                                Text("Current: \(selectedElement.value.withCommas(decimalPlace: 2))")
                                                    .font(.system(size: 12).bold())
                                                    .foregroundColor(Color.theme.background)
                                                Text("Invested: \(selectedElement.invested.withCommas(decimalPlace: 2))")
                                                    .font(.system(size: 12).bold())
                                                    .foregroundColor(Color.theme.background)
                                            }
                                            VStack {
                                                Text(getPercentageChange())
                                                    .font(.system(size: 12).bold())
                                                    .foregroundColor(getGrowthColor())
                                            }
                                        }
                                    } else {
                                        Text("\(selectedElement.value.withCommas(decimalPlace: 2))")
                                            .font(.system(size: 12).bold())
                                            .foregroundColor(Color.theme.background)
                                    }
                                }
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityHidden(false)
                            .frame(width: boxWidth, alignment: .center)
                            .background {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.theme.primaryText)
                                }
                                .padding(.horizontal, -8)
                                .padding(.vertical, -4)
                            }
                            .offset(x: boxOffset)
                            .shadow(radius: 5)
                        }
                    }
                }
            }
            .frame(maxHeight: .infinity)
            
            if showMessage {
                if !chartDataList.isEmpty {
                    withAnimation {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.theme.primaryText.opacity(0.8))
                            .frame(width: 100, height: 60)
                            .overlay(
                                Text(getChangedPercentage())
                                    .font(.headline.bold())
                                    .foregroundColor(getChangedPercentage().hasPrefix("-") ? Color.theme.red : Color.theme.green)
                                )
                            .transition(.opacity)
                    }
                }
            }
        }
    }
        
    private func getChangedPercentage() -> String {
        return CommonController.getGrowthPercentage(previousBalance: chartDataList[0].value, currentBalance: chartDataList[chartDataList.count - 1].value)
    }
    
    private func findElement(location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) -> ChartData? {
        let relativeXPosition = location.x - geometry[proxy.plotFrame!].origin.x
        if let date = proxy.value(atX: relativeXPosition) as Date? {
            
            var minDistance: TimeInterval = .infinity
            var index: Int? = nil
            for salesDataIndex in chartDataList.indices {
                let nthSalesDataDistance = chartDataList[salesDataIndex].date.distance(to: date)
                if abs(nthSalesDataDistance) < minDistance {
                    minDistance = abs(nthSalesDataDistance)
                    index = salesDataIndex
                }
            }
            if let index {
                return chartDataList[index]
            }
        }
        return nil
    }
    
    private func getMinValue() -> Double {
        return (chartDataList.map {
            return $0.value < $0.invested ? $0.value : $0.invested
        }.min() ?? 0.0) > 0.0 ? ((chartDataList.map {
            return $0.value < $0.invested ? $0.value : $0.invested
        }.min() ?? 0.0) * 0.95) : ((chartDataList.map {
            return $0.value < $0.invested ? $0.value : $0.invested
        }.min() ?? 0.0)) * 1.05
    }
    
    private func getMaxValue() -> Double {
        return (chartDataList.map {
            return $0.value > $0.invested ? $0.value : $0.invested
        }.max() ?? 0.0) > 0.0 ? ((chartDataList.map {
            return $0.value > $0.invested ? $0.value : $0.invested
        }.max() ?? 0.0) * 1.05) : ((chartDataList.map {
            return $0.value > $0.invested ? $0.value : $0.invested
        }.max() ?? 0.0)) * 0.95
    }
    
    private func isPositiveValue() -> Bool {
        !chartDataList.isEmpty && (((chartDataList.first?.value.distance(to: chartDataList.last!.value))!) >= 0)
    }
    
    private func getChartColor() -> Color {
        isColorChart ? (isPositiveValue() ? Color.theme.green : Color.theme.red) : Color.theme.primaryText
    }
    
    private func isTransactionDate(date: String) -> Bool {
        return accountTransactionList.filter {
            return $0.transactionDate.elementsEqual(date)
        }.count > 0
    }
    
    private func getTransactionDateCircleColor(date: String) -> Color {
        let accountTransactionFilteredList = accountTransactionList.filter {
            return $0.transactionDate <= date
        }
        return (accountTransactionFilteredList.count > 1 ? (accountTransactionFilteredList[0].value >= accountTransactionFilteredList[1].value ? Color.theme.green : Color.theme.red) : Color.theme.green)
    }
    
    private func getPercentageChange() -> String {
        return CommonController.getGrowthPercentage(previousBalance: selectedElement?.invested ?? 0.0, currentBalance: selectedElement?.value ?? 0.0)
    }
    
    public func getGrowthColor() -> Color {
        let value = CommonController.getGrowthPercentageInDouble(previousBalance: selectedElement?.invested ?? 0.0, currentBalance: selectedElement?.value ?? 0.0)
        return value >= 0 ? Color.theme.green : Color.theme.red
    }
}
