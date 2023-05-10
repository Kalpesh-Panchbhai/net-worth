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
    
    @State private var otherIndex = -1
    @State private var activeIndex: Int = -1
    
    var slices: [PieSliceData] {
        let sum = values.reduce(0, +)
        var endDeg: Double = 0
        var tempSlices: [PieSliceData] = []
        
        for (i, value) in values.enumerated() {
            let degrees: Double = value * 360 / sum
            if(endDeg >= 314 && endDeg != 360) {
                tempSlices.append(PieSliceData(startAngle: Angle(degrees: endDeg), endAngle: Angle(degrees: 360), text: String(format: "%.0f%%", ((360 - endDeg) / 360) * 100), color: self.colors[i]))
                break
            } else {
                tempSlices.append(PieSliceData(startAngle: Angle(degrees: endDeg), endAngle: Angle(degrees: endDeg + degrees), text: String(format: "%.0f%%", value * 100 / sum), color: self.colors[i]))
            }
            endDeg += degrees
        }
        return tempSlices
    }
    
    public init(values:[Double], names: [String], formatter: @escaping (Double) -> String, colors: [Color] = [Color.blue, Color.green, Color.orange], backgroundColor: Color = Color(red: 21 / 255, green: 24 / 255, blue: 30 / 255, opacity: 1.0), widthFraction: CGFloat = 0.75, innerRadiusFraction: CGFloat = 0.60){
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
                ZStack{
                    ForEach(0..<self.values.count, id: \.self){ i in
                        PieSliceView(pieSliceData: (i < self.slices.count ? self.slices[i] : self.slices[self.slices.count - 1]))
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
                                        if(i == slices.count - 1) {
                                            self.activeIndex = -2
                                            self.otherIndex = i
                                        } else {
                                            self.activeIndex = i
                                        }
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
                    
                    VStack {
                        Text(self.activeIndex == -1 ? "Total" : self.activeIndex == -2 ? "Other" : names[self.activeIndex])
                            .font(.title)
                            .foregroundColor(Color.gray)
                        Text(self.formatter(self.activeIndex == -1 ? values.reduce(0, +) : self.activeIndex == -2 ? getOtherTotal() : values[self.activeIndex]))
                            .font(.title)
                    }
                    
                }
                PieChartRows(colors: self.colors, names: self.names, values: self.values.map { self.formatter($0) }, percents: self.values.map { String(format: "%.0f%%", $0 * 100 / self.values.reduce(0, +)) })
            }
            .background(self.backgroundColor)
            .foregroundColor(Color.white)
        }
    }
    
    private func getOtherTotal() -> Double {
        var otherTotal = 0.0
        for i in 0..<values.count {
            if i >= otherIndex {
                otherTotal += values[i]
            }
        }
        return otherTotal
    }
}

struct PieChartRows: View {
    var colors: [Color]
    var names: [String]
    var values: [String]
    var percents: [String]
    
    var body: some View {
        VStack{
            ScrollView(.vertical) {
                ForEach(0..<self.values.count, id: \.self){ i in
                    HStack {
                        RoundedRectangle(cornerRadius: 5.0)
                            .fill(self.colors[i])
                            .frame(width: 20, height: 20)
                        Text(self.names[i])
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text((Double(self.values[i])?.withCommas(decimalPlace: 2))!)
                            Text(self.percents[i])
                                .foregroundColor(Color.gray)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}