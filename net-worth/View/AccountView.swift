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
        sortDescriptors: [NSSortDescriptor(keyPath: \Account.timestamp, ascending: true)],
        animation: .default)
    private var accounts: FetchedResults<Account>
    
    private var accountController = AccountController()
    
    @State var accountName: String = ""
    
    @State var isOpen: Bool = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(accounts) { account in
                    NavigationLink(destination: AccountDetailsView(uuid: account.sysid!), label: {
                        HStack{
                            VStack {
                                Text(account.accountname!)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(account.accounttype!).font(.system(size: 10))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            Spacer()
                            Text("\(String(format: "%.2f", account.currentbalance))")
                        }
                    })
                }
                .onDelete(perform: deleteAccount)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: {
                        self.isOpen = true
                    }, label: {
                        Label("Add Item", systemImage: "plus")
                    }).sheet(isPresented: $isOpen, content: {
                        NewAccountView()
                    })
                }
            }
            .toolbar {
                ToolbarItem(placement: .bottomBar){
                    let balance = accountController.getAccountTotalBalance()
                    HStack {
                        TextField("Total Balance \(String(format: "%.2f", balance))", text: $accountName).disabled(true).foregroundColor(.red).font(.title2)
                    }
                }
            }
            .navigationTitle("Accounts")
        }
    }
    
    private func deleteAccount(offsets: IndexSet) {
        withAnimation {
            offsets.map { accounts[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        AccountView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
