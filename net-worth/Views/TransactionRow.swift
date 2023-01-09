//
//  TransactionRow.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 07/01/23.
//

import SwiftUI

struct TransactionRow: View {
    var body: some View {
        HStack {
            Image("visaIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 30, height: 30)
                .padding(5)
            VStack(alignment: .leading) {
                Text("Dribble")
                    .font(.headline)
                Text("12 Nov 2020  11:08")
                    .font(.caption)
                    .foregroundColor(Color(.secondaryLabel))
            }
            Spacer()
            Text("-$60.0")
                .font(.headline)
        }
        .padding(8)
    }
}

struct TransactionRow_Previews: PreviewProvider {
    static var previews: some View {
        TransactionRow()
    }
}
