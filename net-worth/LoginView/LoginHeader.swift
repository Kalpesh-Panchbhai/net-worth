//
//  LoginHeader.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 29/01/23.
//

import SwiftUI

struct LoginHeader: View {
    var body: some View {
        VStack {
            Text("Net Worth")
                .font(.largeTitle)
                .fontWeight(.medium)
        }
    }
}

struct LoginHeader_Previews: PreviewProvider {
    static var previews: some View {
        LoginHeader()
    }
}
