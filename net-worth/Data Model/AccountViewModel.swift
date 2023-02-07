//
//  AccountViewModel.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 05/02/23.
//

import Foundation
import FirebaseFirestore

class AccountViewModel: ObservableObject {
    
    @Published var accountList = [Account]()
    @Published var grouping: Grouping = .accountType
    @Published var accountTransactionList = [AccountTransaction]()
    
    var originalAccountList = [Account]()
    private var accountController = AccountController()
    
    enum Grouping: String, CaseIterable, Identifiable {
        case accountType = "Account Type"
        case currency = "Currency"
        var id: String {
            self.rawValue
        }
    }
    
    var groupedAccount: [String: [Account]] {
        switch grouping {
        case .accountType:
            return Dictionary(grouping: accountList) { $0.accountType }
        case .currency:
            return Dictionary(grouping: accountList) { $0.currency }
        }
    }
    
    var sectionHeaders: [String] {
        switch grouping {
        case .accountType:
            return Array(Set(accountList.map{$0.accountType})).sorted(by: <)
        case .currency:
            return Array(Set(accountList.map{$0.currency})).sorted(by: <)
        }
    }
    
    func sectionContent(key: String, searchKeyword: String) -> [Account] {
        let data = groupedAccount[key] ?? []
        if searchKeyword.isEmpty {
            return data
        } else {
            return data.filter { value in
                value.accountName.lowercased().contains(searchKeyword.lowercased()) || value.accountType.lowercased().contains(searchKeyword.lowercased())
            }
        }
        
    }
    
    func sortAccountList(orderBy: String) {
        if(orderBy.elementsEqual(ConstantUtils.accountKeyAccountName)) {
            accountList
                .sort(by: {
                    $0.accountName < $1.accountName
                })
        } else if(orderBy.elementsEqual(ConstantUtils.accountKeyCurrentBalance)) {
            accountList
                .sort(by: {
                    $0.currentBalance < $1.currentBalance
                })
        }
    }
    
    func filterAccountList(filter: String) {
        accountList = originalAccountList
            .filter { account in
                account.accountType.lowercased().elementsEqual(filter.lowercased())
            }
    }
    
    func resetAccountList() {
        accountList = originalAccountList
    }
    
    func getAccountList() async {
        do {
            let list = try await accountController.getAccountList()
            DispatchQueue.main.async {
                self.accountList = list
                self.originalAccountList = list
            }
        } catch {
            print(error)
        }
    }
    
    func getAccountTransactionList(id: String) {
        UserController()
            .getCurrentUserDocument()
            .collection(ConstantUtils.accountCollectionName)
            .document(id)
            .collection(ConstantUtils.accountTransactionCollectionName)
            .order(by: ConstantUtils.accountTransactionKeytimestamp, descending: true)
            .getDocuments { snapshot, error in
                if error == nil {
                    if let snapshot = snapshot {
                        self.accountTransactionList = snapshot.documents.map { doc in
                            return AccountTransaction(id: doc.documentID,
                                                      timestamp: (doc[ConstantUtils.accountTransactionKeytimestamp] as? Timestamp)?.dateValue() ?? Date(),
                                                      balanceChange: doc[ConstantUtils.accountTransactionKeyBalanceChange] as? Double ?? 0.0)
                        }
                    }
                } else {
                    
                }
                
            }
    }
}
