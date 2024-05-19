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
        if(name.elementsEqual("Chart")) {
            ZStack {
                Color.theme.background.ignoresSafeArea()
                HStack {
                    Text("Click on")
                    Image(systemName: ConstantUtils.menuImageName)
                    Text("icon to see chart data.")
                }
                .foregroundColor(Color.theme.primaryText)
                .bold()
            }
        } else {
            ZStack {
                Color.theme.background.ignoresSafeArea()
                HStack {
                    Text("Click on")
                    Image(systemName: ConstantUtils.plusImageName)
                    Text("icon to add new " + name + ".")
                }
                .foregroundColor(Color.theme.primaryText)
                .bold()
            }
        }
    }
}
