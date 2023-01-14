//
//  SwiftUIView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 14/01/23.
//

import SwiftUI

struct SwiftUIView: View {
    
    var stickyHeaderView: some View {
        RoundedRectangle(cornerRadius: 25.0, style: .continuous)
            .fill(Color.gray)
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .overlay(
                Text("Section")
                    .foregroundColor(Color.white)
                    .font(.largeTitle)
            )
    }
    
    var card: some View {
        ZStack {
            Color.black
            Text("Kalpesh")
            Text("Kalpesh1")
        }
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView(.vertical) {
                LazyVStack(spacing: 20, pinnedViews: [.sectionHeaders]) {
                    ForEach(0..<10) { index in
                        Section(header: stickyHeaderView) {
                            ScrollView(.horizontal) {
                                LazyHStack(spacing: 20) {
                                    ForEach(0..<10) { index in
                                        card
                                            .frame(width: 200, height: 150)
                                            .shadow(color: .white, radius: 10)
                                            .padding()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIView()
    }
}
