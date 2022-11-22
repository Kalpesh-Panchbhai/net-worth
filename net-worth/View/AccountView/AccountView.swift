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
    
    private var notificationController = NotificationController()
    
    @State var searchAccountName: String = ""
    
    @State var isOpen: Bool = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(searchResults) { account in
                    NavigationLink(destination: AccountDetailsNavigationLinkView(uuid: account.sysid!), label: {
                        HStack{
                            VStack {
                                Text(account.accountname!)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(account.accounttype!).font(.system(size: 10))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            Spacer()
                            Text("\(String(format: "%.4f", account.currentbalance))")
                        }
                        .padding()
                    })
                }
                .onDelete(perform: deleteAccount)
            }
            .toolbar {
                if !accounts.isEmpty {
                    ToolbarItem(placement: .navigationBarLeading) {
                        EditButton()
                    }
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
                ToolbarItem(placement: .bottomBar){
                    let balance = accountController.getAccountTotalBalance()
                    HStack {
                        Text("Total Balance \(balance.withCommas())").foregroundColor(.blue).font(.title)
                    }
                }
            }
            .navigationTitle("Accounts")
            .searchable(text: $searchAccountName) {
                ForEach(searchResults, id: \.self) { result in
                    Text("Are you looking for \(result.accountname!)?").searchCompletion(result.accountname!)
                }
            }
        }
    }
    
    var searchResults: [Account] {
        accounts.filter { account in
            if(searchAccountName.isEmpty) {
                return true
            } else {
                return account.accountname!.lowercased().contains(searchAccountName.lowercased())
            }
        }
    }
    
    private func deleteAccount(offsets: IndexSet) {
        withAnimation {
            offsets.map {
                let acc = accounts[$0]
                if(acc.paymentReminder) {
                    notificationController.removeNotification(id: acc.sysid!)
                }
                return acc
            }.forEach(viewContext.delete)
            
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
