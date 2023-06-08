//
//  SwiftUIView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 08/06/23.
//

import SwiftUI

struct SwiftUIView: View {
    var body: some View {
//        List {
//            Color.theme.background
//            Color.theme.foreground
//            Color.theme.foreground2
//        }
        
        ZStack {
            Color.theme.foreground.ignoresSafeArea()
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.theme.foreground)
                .frame(width: 100, height: 100)
                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 5)
        }
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIView()
            .preferredColorScheme(.dark)
        
        SwiftUIView()
            .preferredColorScheme(.light)
    }
}
