//
//  BarLollipopGroupChartView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 25/11/23.
//

import SwiftUI
import Charts

struct BarLollipopGroupChartView: View {
    
    var chartDataList: [String: Double]
    
    @State private var lineWidth = 2.0
    @State private var selectedElement: GroupChartData?
    
    var body: some View {
        Chart {
            ForEach(chartDataList.sorted(by: >), id: \.key) { key, value in
                BarMark(
                    x: .value("Date", key),
                    y: .value("Value", value),
                    width: .fixed(10)
                )
                .accessibilityValue("\(value)")
                .foregroundStyle(Color.theme.primaryText.gradient)
            }
            
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisGridLine(centered: true, stroke: StrokeStyle(lineWidth: 0.1, dash: [0]))
                    .foregroundStyle(Color.theme.primaryText)
                AxisTick(stroke: StrokeStyle(lineWidth: 1))
                    .foregroundStyle(Color.theme.primaryText)
                AxisValueLabel ()
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
                    Text("\(CommonController.abbreviateAxisValue(string: CommonController.parseAxisValue(value: value) ?? ""))")
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
                                if selectedElement?.groupType == element?.groupType {
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
                        let startPositionX1 = proxy.position(forX: selectedElement.groupType) ?? 0
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
                            Text(selectedElement.groupType)
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
    
    private func findElement(location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) -> GroupChartData? {
        let relativeXPosition = location.x - geometry[proxy.plotAreaFrame].origin.x
        if let selectedGroup = proxy.value(atX: relativeXPosition) as String? {
            return GroupChartData(groupType: selectedGroup, value: chartDataList[selectedGroup] ?? 0.0)
        }
        return nil
    }
    
}
