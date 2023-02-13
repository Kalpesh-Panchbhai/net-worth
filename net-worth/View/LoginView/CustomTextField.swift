//
//  CustomTextField.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 29/01/23.
//

import SwiftUI

struct CustomTextfield: View {
    @Binding var text: String
    
    var body: some View {
        TextField("Username", text: $text)
            .padding(16)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke()
            )
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
    }
}

struct CustomTextfield_Previews: PreviewProvider {
    static var previews: some View {
        CustomTextfield(text: .constant(""))
    }
}
