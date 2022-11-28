//
//  ContentView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 09/11/22.
//

import SwiftUI
import CoreData

struct AccountView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Account.accountname, ascending: true)],
        animation: .default)
    private var accounts: FetchedResults<Account>
    
    private var accountController = AccountController()
    
    private var mutualFundController = MutualFundController()
    
    @State var searchAccountName: String = ""
    
    @State var isOpen: Bool = false
    
    @State var isAllSelected: Bool = false
    
    var searchResults: [Account] {
        accounts.filter { account in
            if(searchAccountName.isEmpty) {
                return true
            } else {
                return account.accountname!.lowercased().contains(searchAccountName.lowercased())
            }
        }
    }
    
    @State var selection = Set<Account>()
    
    @State var editMode = EditMode.inactive
    
    var body: some View {
        NavigationView {
            List(selection: $selection) {
                ForEach(searchResults, id: \.self) { account in
                    NavigationLink(destination: AccountDetailsNavigationLinkView(uuid: account.sysid!), label: {
                        HStack{
                            VStack {
                                Text(account.accountname!)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(account.accounttype!).font(.system(size: 10))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            Spacer()
                            if(account.accounttype == "Mutual Fund") {
                                let mutualFund = mutualFundController.getMutualFund(name: account.accountname!)
                                Text("\((account.totalshare * mutualFund.rate).withCommas())")
                            } else {
                                Text("\(account.currentbalance.withCommas())")
                            }
                        }
                        .padding()
                    })
                    .swipeActions {
                        Button{
                            accountController.deleteAccount(account: account)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .tint(.red)
                    }
                }
            }
            .refreshable {
                mutualFundController.fetch()
            }
            .environment(\.editMode, self.$editMode)
            .listStyle(.inset)
            .toolbar {
                if !accounts.isEmpty {
                    ToolbarItem(placement: .navigationBarLeading) {
                        if(editMode == .inactive) {
                            Button(action: {
                                self.editMode = .active
                                self.selection = Set<Account>()
                            }) {
                                Text("Edit")
                            }
                        }
                        else {
                            Button(action: {
                                self.editMode = .inactive
                                self.selection = Set<Account>()
                                isAllSelected =  false
                            }) {
                                Text("Done")
                            }
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if(editMode == .inactive) {
                        Button(action: {
                            self.isOpen.toggle()
                        }, label: {
                            Label("Add Item", systemImage: "plus")
                        }).sheet(isPresented: $isOpen, content: {
                            NewAccountView()
                        })
                    }
                    else {
                        Button(action: {
                            for accountSelected in selection {
                                accountController.deleteAccount(account: accountSelected)
                            }
                            editMode = .inactive
                        }, label: {
                            Label("Add Item", systemImage: "trash")
                        }).disabled(selection.count == 0)
                    }
                }
                ToolbarItem(placement: .bottomBar){
                    if(editMode == .inactive) {
                        let balance = accountController.getAccountTotalBalance()
                        HStack {
                            Text("Total Balance \(balance.withCommas())").foregroundColor(.blue).font(.title2)
                        }
                    }else {
                        if(!isAllSelected && searchResults.count != selection.count) {
                            Button("Select all", action: {
                                searchResults.forEach { (acc) in
                                    self.selection.insert(acc)
                                }
                                isAllSelected = true
                            })
                        }else {
                            Button("Deselect all", action: {
                                self.selection.removeAll()
                                isAllSelected = false
                            })
                        }
                    }
                }
            }
            .navigationTitle("Accounts")
            .searchable(text: $searchAccountName) {
                ForEach(searchResults, id: \.self) { result in
                    Text("\(result.accountname!)").searchCompletion(result.accountname!)
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        AccountView()
    }
}
