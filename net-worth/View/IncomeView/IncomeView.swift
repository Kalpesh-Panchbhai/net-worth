//
//  IncomeView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 14/11/22.
//

import SwiftUI
import CoreData

struct IncomeView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Income.creditedon, ascending: true)],
        animation: .default)
    private var incomes: FetchedResults<Income>
    
    @State var isOpen: Bool = false
    
    private var incomeController = IncomeController()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(incomes) { income in
                    HStack{
                        VStack {
                            Text(income.incometype!)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Spacer()
                            Text("\(income.creditedon!, formatter: dateFormatter)").font(.system(size: 10))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        Text("\(String(format: "%.2f", income.amount))")
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .onDelete(perform: deleteIncome)
            }
            .listStyle(.inset)
            .toolbar {
                if !incomes.isEmpty {
                    ToolbarItem(placement: .navigationBarLeading) {
                        EditButton()
                    }
                }
                ToolbarItem {
                    Button(action: {
                        self.isOpen = true
                    }, label: {
                        Label("Add Income", systemImage: "plus")
                    }).sheet(isPresented: $isOpen, content: {
                        NewIncomeView()
                    })
                }
                ToolbarItem(placement: .bottomBar){
                    let balance = incomeController.getTotalBalance()
                    HStack {
                        Text("Total Income \(balance.withCommas(decimalPlace: 2))").foregroundColor(.blue).font(.title2)
                    }
                }
            }
            .navigationTitle("Income")
        }
    }
    
    private func deleteIncome(offsets: IndexSet) {
        withAnimation {
            offsets.map { incomes[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}

struct IncomeView_Previews: PreviewProvider {
    static var previews: some View {
        IncomeView()
    }
}
