//
//  EmptyView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 09/06/23.
//

import SwiftUI

struct EmptyView: View {
    
    let name: String
    
    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()
            HStack {
                Text("Click on")
                Image(systemName: "plus")
                Text("Icon to add new " + name + ".")
            }
            .foregroundColor(Color.theme.primaryText)
            .bold()
        }
    }
}
