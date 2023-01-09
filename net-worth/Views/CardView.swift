//
//  CardView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 07/01/23.
//

import SwiftUI

struct CardView: View {

    @State var isSelected: Bool = false
    @State var account: Account

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Spacer()
                Image("visaIcon") // logo
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 35, height: 15)
                    .foregroundColor(isSelected ? .white : .black)
                    .padding()
            }
            Spacer()
            Text(account.accountname!)
                .foregroundColor(isSelected ? .white : .black)
                .font(.caption)
                .padding(.bottom, 5)
            HStack(alignment: .center) {
                Text(account.currency!)
                    .foregroundColor(isSelected ? .white : .black)
                    .font(.caption)
                Text("\(account.currentbalance)")
                    .foregroundColor(isSelected ? .white : .black)
                    .font(.headline)
                    .fontWeight(.heavy)
            }
            .padding(.bottom)
            Spacer()
            Text("**** **** **** 3022")
                .foregroundColor(isSelected ? .white : .black)
                .font(.caption)
                .padding(.bottom)
        }
        .frame(width: 130, height: 150)
        .padding(8)
        .background(Color(isSelected ? #colorLiteral(red: 0.3097526431, green: 0.3843510449, blue: 0.7528470159, alpha: 1) : .white))
        .cornerRadius(20)
    }

}

//struct CardView_Previews: PreviewProvider {
//    static var previews: some View {
//        CardView()
//    }
//}
