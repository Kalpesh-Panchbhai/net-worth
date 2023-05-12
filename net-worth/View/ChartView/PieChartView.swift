//
//  PieChartView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 09/05/23.
//

import SwiftUI

public struct PieChartView: View {
    public let values: [Double]
    public let names: [String]
    public let formatter: (Double) -> String
    
    public var colors: [Color]
    public var backgroundColor: Color
    
    public var widthFraction: CGFloat
    public var innerRadiusFraction: CGFloat
    
    @State private var activeIndex: Int = -1
    
    var slices: [PieSliceData] {
        let sum = values.reduce(0, +)
        var endDeg: Double = 0
        var tempSlices: [PieSliceData] = []
        
        for (i, value) in values.enumerated() {
            let degrees: Double = value * 360 / sum
            tempSlices.append(PieSliceData(startAngle: Angle(degrees: endDeg), endAngle: Angle(degrees: endDeg + degrees), text: String(format: "%.2f%%", value * 100 / sum), color: self.colors[i]))
            endDeg += degrees
        }
        return tempSlices
    }
    
    public init(values:[Double], names: [String], formatter: @escaping (Double) -> String, colors: [Color] = [Color.blue, Color.green, Color.orange], backgroundColor: Color = Color(red: 21 / 255, green: 24 / 255, blue: 30 / 255, opacity: 1.0), widthFraction: CGFloat = 0.5, innerRadiusFraction: CGFloat = 0.00){
        self.values = values
        self.names = names
        self.formatter = formatter
        
        self.colors = colors
        self.backgroundColor = backgroundColor
        self.widthFraction = widthFraction
        self.innerRadiusFraction = innerRadiusFraction
    }
    
    public var body: some View {
        GeometryReader { geometry in
            VStack{
                if(self.values.count > 0) {
                    ZStack{
                        ForEach(0..<self.values.count, id: \.self){ i in
                            PieSliceView(pieSliceData: self.slices[i])
                                .scaleEffect(self.activeIndex == i ? 1.03 : 1)
                                .animation(Animation.spring(), value: self.activeIndex == i ? 1.03 : 1)
                        }
                        .frame(width: widthFraction * geometry.size.width, height: widthFraction * geometry.size.width)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let radius = 0.5 * widthFraction * geometry.size.width
                                    let diff = CGPoint(x: value.location.x - radius, y: radius - value.location.y)
                                    let dist = pow(pow(diff.x, 2.0) + pow(diff.y, 2.0), 0.5)
                                    if (dist > radius || dist < radius * innerRadiusFraction) {
                                        self.activeIndex = -1
                                        return
                                    }
                                    var radians = Double(atan2(diff.x, diff.y))
                                    if (radians < 0) {
                                        radians = 2 * Double.pi + radians
                                    }
                                    
                                    for (i, slice) in slices.enumerated() {
                                        if (radians < slice.endAngle.radians) {
                                            self.activeIndex = i
                                            break
                                        }
                                    }
                                }
                                .onEnded { value in
                                    self.activeIndex = -1
                                }
                        )
                        Circle()
                            .fill(self.backgroundColor)
                            .frame(width: widthFraction * geometry.size.width * innerRadiusFraction, height: widthFraction * geometry.size.width * innerRadiusFraction)
                    }
                    .frame(height: 200)
                    Divider()
                }
                VStack {
                    Text(getAccountName())
                        .font(.system(size: 14))
                        .foregroundColor(Color.navyBlue)
                    Text(getAccountAmount())
                        .font(.system(size: 14))
                        .foregroundColor(Color.navyBlue)
                }
                Divider()
                PieChartRows(colors: self.colors, names: self.names, values: self.values.map { self.formatter($0) }, percents: self.values.map { String(format: "%.2f%%", $0 * 100 / self.values.reduce(0, +)) })
            }
            .background(self.backgroundColor)
            .foregroundColor(Color.white)
        }
    }
    
    private func getAccountName() -> String {
        return self.activeIndex == -1 ? "Total" : names[self.activeIndex]
    }
    
    private func getAccountAmount() -> String {
        if(self.activeIndex == -1) {
            let totalAmount = values.reduce(0, +)
            return totalAmount == 0 ? (totalAmount.withCommas(decimalPlace: 2) + " (0%)") : (totalAmount.withCommas(decimalPlace: 2) + " (100%)")
        } else {
            let totalAmount = values[self.activeIndex].withCommas(decimalPlace: 2)
            let percentage = ((values[self.activeIndex] * 100) / values.reduce(0, +)).withCommas(decimalPlace: 2)
            return totalAmount + " (" + percentage + "%)"
        }
    }
}

struct PieChartRows: View {
    var colors: [Color]
    var names: [String]
    var values: [String]
    var percents: [String]
    
    var body: some View {
        VStack{
            ScrollView(.vertical, showsIndicators: false) {
                ForEach(0..<self.values.count, id: \.self){ i in
                    HStack {
                        RoundedRectangle(cornerRadius: 5.0)
                            .fill(self.colors[i])
                            .frame(width: 20, height: 20)
                            .font(.system(size: 14))
                        Text(self.names[i])
                            .foregroundColor(Color.navyBlue)
                            .font(.system(size: 14))
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text((Double(self.values[i])?.withCommas(decimalPlace: 2))!)
                                .foregroundColor(Color.navyBlue)
                                .font(.system(size: 14))
                            Text(self.percents[i])
                                .foregroundColor(Color.navyBlue)
                                .font(.system(size: 14))
                        }
                    }
                    .padding(.horizontal)
                    Divider()
                }
            }
        }
    }
}
