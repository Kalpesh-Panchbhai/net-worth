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
    
    @State var searchAccountName: String = ""
    
    @State var isOpen: Bool = false
    
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
                            Text("\(account.currentbalance.withCommas())")
                        }
                        .padding()
                    })
                }
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
                            }) {
                                Text("Done")
                            }
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if(editMode == .inactive) {
                        Button(action: {
                            self.isOpen = true
                        }, label: {
                            Label("Add Item", systemImage: "plus")
                        }).sheet(isPresented: $isOpen, content: {
                            NewAccountView()
                        })
                    }
                    else {
                        Button(action: {
                            for id in selection {
                                accountController.deleteAccount(account: id)
                            }
                            editMode = .inactive
                        }, label: {
                            Label("Add Item", systemImage: "trash")
                        })
                    }
                }
                ToolbarItem(placement: .bottomBar){
                    let balance = accountController.getAccountTotalBalance()
                    HStack {
                        Text("Total Balance \(balance.withCommas())").foregroundColor(.blue).font(.title2)
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
        AccountView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
