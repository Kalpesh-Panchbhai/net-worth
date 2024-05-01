//
//  ProgressView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 09/06/23.
//

import SwiftUI

struct LoadingView: View {
    
    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()
            ProgressView().tint(Color.theme.primaryText)
        }
    }
}
