//
//  TransactionsHeader.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 07/01/23.
//

import SwiftUI

struct TransactionsHeader: View {
    var body: some View {
        HStack {
            Text("Send to money")
                .font(.headline)
            Spacer()
            Image(systemName: "plus.circle.fill")
                .resizable()
                .foregroundColor(Color(#colorLiteral(red: 0.3097526431, green: 0.3843510449, blue: 0.7528470159, alpha: 1)))
                .frame(width: 30, height: 30)
            Text("Add recipient")
                .font(.headline)
        }
        .padding(20)
        .padding(.bottom, 40)
        .foregroundColor(.white)
        .background(Color(#colorLiteral(red: 0.1019468382, green: 0.1058915928, blue: 0.1333118379, alpha: 1)))
        .cornerRadius(20)
    }
}

struct TransactionsHeader_Previews: PreviewProvider {
    static var previews: some View {
        TransactionsHeader()
    }
}
