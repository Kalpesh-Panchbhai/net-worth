//
//  AccountDetailsView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 11/11/22.
//

import SwiftUI

struct AccountDetailsView: View {
    
    private var uuid: UUID
    
    private var accountController: AccountController
    
    private var account: Account
    
    init(uuid: UUID) {
        self.uuid = uuid
        self.accountController = AccountController()
        self.account = accountController.getAccount(uuid: uuid)
    }
    
    var body: some View {
        Text("Item at \(account.sysid!) \(account.timestamp!, formatter: accountFormatter) \(account.accounttype!) \(account.accountname!) \(String(account.paymentReminder)) \(account.currentbalance) \(account.paymentDate)")
    }
    
    private let accountFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter
    }()
}

struct AccountDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        AccountDetailsView(uuid: UUID())
    }
}
