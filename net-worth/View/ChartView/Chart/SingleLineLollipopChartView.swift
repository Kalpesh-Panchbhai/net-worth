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
    
    @State private var lineWidth = 2.0
    @State private var chartColor: Color = Color.navyBlue
    @State private var showSymbols = true
    @State private var selectedElement: ChartData?
    
    var body: some View {
        Chart {
            ForEach(chartDataList, id: \.self) { data in
                LineMark(
                    x: .value("Date", data.date),
                    y: .value("Value", data.value)
                )
                .accessibilityLabel(data.date.formatted(date: .complete, time: .omitted))
                .accessibilityValue("\(data.value)")
                .lineStyle(StrokeStyle(lineWidth: lineWidth))
                .foregroundStyle(chartColor.gradient)
                .interpolationMethod(.cardinal)
                
                AreaMark(
                    x: .value("Date", data.date),
                    y: .value("Value", data.value)
                )
                .foregroundStyle(Gradient(colors: [Color.navyBlue.opacity(0.3), .clear]))
                .interpolationMethod(.cardinal)
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisGridLine(centered: true, stroke: StrokeStyle(dash: [1]))
                    .foregroundStyle(Color.navyBlue)
                AxisTick(stroke: StrokeStyle(lineWidth: 1))
                    .foregroundStyle(Color.navyBlue)
                AxisValueLabel()
                    .foregroundStyle(Color.navyBlue)
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic) { value in
                AxisGridLine(centered: true, stroke: StrokeStyle(dash: [1]))
                    .foregroundStyle(Color.navyBlue)
                AxisTick(stroke: StrokeStyle(lineWidth: 1))
                    .foregroundStyle(Color.navyBlue)
                AxisValueLabel {
                    Text("\(CommonController.abbreviateAxisValue(string: CommonController.parseAxisValue(value: value) ?? ""))")
                }
                .foregroundStyle(Color.navyBlue)
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
                            .fill(Color.lightBlue)
                            .frame(width: 2, height: lineHeight)
                            .position(x: lineX, y: lineHeight / 2)
                        
                        Circle()
                            .fill(Color.lightBlue)
                            .frame(width: 8, height: 8)
                            .position(x: lineX, y: lineY)
                        
                        VStack(alignment: .center) {
                            Text("\(selectedElement.date, format: .dateTime.year().month().day())")
                                .font(.system(size: 10).bold())
                                .foregroundColor(Color.white)
                            Text("\(selectedElement.value, format: .number)")
                                .font(.system(size: 12).bold())
                                .foregroundColor(Color.white)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityHidden(false)
                        .frame(width: boxWidth, alignment: .center)
                        .background {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.navyBlue)
                            }
                            .padding(.horizontal, -8)
                            .padding(.vertical, -4)
                        }
                        .offset(x: boxOffset)
                    }
                }
            }
        }
        .chartXAxis(.automatic)
        .chartYAxis(.automatic)
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
