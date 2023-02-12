//
//  AccountCardListExpendableButton.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 10/02/23.
//

import SwiftUI

struct AccountCardListExpendableButton: View {
    
    @State var isNewTransactionViewOpen = false
    
    @ObservedObject var accountViewModel: AccountViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            
            Button(action: {
                self.isNewTransactionViewOpen.toggle()
            }) {
                Image(systemName: "plus")
                    .resizable()
                    .frame(width: 25, height: 25)
                    .padding(18)
            }
            .background(.blue)
            .foregroundColor(.white)
            .clipShape(Circle())
        }
        .halfSheet(showSheet: $isNewTransactionViewOpen) {
            NewAccountView(accountType: "None", accountViewModel: accountViewModel)
        }
        .animation(.spring(), value: true)
    }
}
