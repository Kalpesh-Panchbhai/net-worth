//
//  ChartView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 09/05/23.
//

import SwiftUI

struct ChartView: View {
    var body: some View {
        PieChartView(
            values: [1500, 500, 300],
            names: ["Rent", "Transport", "Education"],
            formatter: {value in String(format: "$%.2f", value)})
    }
}
