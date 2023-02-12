//
//  NewAccountCardView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 12/02/23.
//

import SwiftUI

struct NewAccountCardView: View {
    
    var body: some View {
        ZStack {
            Color.green
            Image(systemName: "plus")
                .foregroundColor(.white)
                .font(.system(size: 20))
        }
        .frame(width: 50, height: 50)
        .cornerRadius(10)
    }
}
