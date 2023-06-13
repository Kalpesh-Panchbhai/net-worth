//
//  BarLollipopChartView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 12/06/23.
//

import SwiftUI
import Charts

struct BarLollipopChartView: View {
    
    var chartDataList: [ChartData]
    var average: Double = 0.0
    var isAverageChart: Bool = false
    var isPercentageChart: Bool = false
    
    @State private var lineWidth = 2.0
    @State private var selectedElement: ChartData?
    
    var body: some View {
        Chart {
            ForEach(chartDataList, id: \.self) { data in
                BarMark(
                    x: .value("Date", data.date),
                    y: .value("Value", data.value),
                    width: .fixed(2)
                )
                .accessibilityLabel(data.date.formatted(date: .complete, time: .omitted))
                .accessibilityValue("\(data.value)")
                .foregroundStyle(Color.theme.primaryText.gradient)
            }
            
            if(isAverageChart) {
                if(average >= 0) {
                    RuleMark(y: .value("Value", average))
                        .foregroundStyle(Color.theme.green)
                        .annotation(alignment: .leading, content: {
                            Text("Average")
                                .font(.system(size: 10))
                                .foregroundColor(Color.theme.green)
                        })
                        .annotation(position: .bottom, alignment: .leading, content: {
                            Text(average.withCommas(decimalPlace: 2))
                                .font(.system(size: 10))
                                .foregroundColor(Color.theme.green)
                        })
                } else {
                    RuleMark(y: .value("Value", average))
                        .foregroundStyle(Color.theme.red)
                        .annotation(alignment: .leading, content: {
                            Text("Average")
                                .font(.system(size: 10))
                                .foregroundColor(Color.theme.red)
                        })
                        .annotation(position: .bottom, alignment: .leading, content: {
                            Text(average.withCommas(decimalPlace: 2))
                                .font(.system(size: 10))
                                .foregroundColor(Color.theme.red)
                        })
                }
            }
        }
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
                                    // If tapping the same element, clear the selection.
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
                        
                        let lineX = startPositionX1 + geo[proxy.plotAreaFrame].origin.x
                        let lineY = startPositionY1 + geo[proxy.plotAreaFrame].origin.y
                        
                        let lineHeight = geo[proxy.plotAreaFrame].maxY
                        let boxWidth: CGFloat = 100
                        let boxOffset = max(0, min(geo.size.width - boxWidth, lineX - boxWidth / 2))
                        
                        Rectangle()
                            .fill(Color.theme.green)
                            .frame(width: 2, height: lineHeight)
                            .position(x: lineX, y: lineHeight / 2)
                        
                        Circle()
                            .strokeBorder(Color.theme.primaryText, lineWidth: 3)
                            .background(Circle().fill(Color.theme.green))
                            .frame(width: 12, height: 12)
                            .position(x: lineX, y: lineY)
                        
                        VStack(alignment: .center) {
                            Text("\(selectedElement.date, format: .dateTime.year().month().day())")
                                .font(.system(size: 10).bold())
                                .foregroundColor(Color.theme.background)
                            Text("\(selectedElement.value.withCommas(decimalPlace: 2))")
                                .font(.system(size: 12).bold())
                                .foregroundColor(Color.theme.background)
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
                    }
                }
            }
        }
        .frame(height: 400)
    }
    
    private func findElement(location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) -> ChartData? {
        let relativeXPosition = location.x - geometry[proxy.plotAreaFrame].origin.x
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
}
