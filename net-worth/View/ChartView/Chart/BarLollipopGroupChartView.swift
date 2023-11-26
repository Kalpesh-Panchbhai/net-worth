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
        .frame(height: 400)
    }

}
