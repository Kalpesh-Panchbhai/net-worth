//
//  CustomButton.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 29/01/23.
//

import SwiftUI

struct CustomButton: View {
    var body: some View {
        Button(action: {}) {
            HStack {
                Spacer()
                Text("Login")
                    .foregroundColor(.white)
                Spacer()
            }
        }
        .padding()
        .background(.black)
        .cornerRadius(10)
        .padding()
    }
}

struct CustomButton_Previews: PreviewProvider {
    static var previews: some View {
        CustomButton()
    }
}
