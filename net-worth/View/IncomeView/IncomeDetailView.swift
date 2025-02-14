//
//  IncomeDetailView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 25/04/23.
//

import SwiftUI

struct IncomeDetailView: View {
    
    @State var income: IncomeRestModel
    
    @State var modifyViewOpen = false
    
    @EnvironmentObject var incomeViewModel: IncomeViewModel
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        Form {
            Section("Income detail") {
                HStack {
                    Text("Income Tag")
                    Spacer()
                    Text(income.incomeTag.name)
                }
                
                HStack {
                    Text("Income Type")
                    Spacer()
                    Text(income.incomeType.name)
                }
                
                HStack {
                    Text("Amount")
                    Spacer()
                    Text(income.currency + " \(income.amount.withCommas(decimalPlace: 2))")
                }
                
                HStack {
                    Text("Tax Paid")
                    Spacer()
                    Text(income.currency + " \(income.taxPaid.withCommas(decimalPlace: 2))")
                }
                
                HStack {
                    Text("Credited Date")
                    Spacer()
                    Text(income.creditedDate.toFullDateFormat().getDateAndFormat())
                }
                
            }
            .listRowBackground(Color.theme.foreground)
            .foregroundColor(Color.theme.primaryText)
        }
        .toolbar {
            ToolbarItem(content: {
                Button(action: {
                    self.modifyViewOpen = true
                }, label: {
                    ZStack {
                        Circle()
                            .frame(width: 25, height: 25)
                            .foregroundColor(ColorTheme().green)
                        Image(systemName: ConstantUtils.newTransactionImageName)
                            .foregroundColor(Color.theme.background)
                            .font(.system(size: 12))
                    }
                })
                .font(.system(size: 14))
            })
        }
        .background(Color.theme.background)
        .scrollContentBackground(.hidden)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
            leading: Button(action: {
                self.presentationMode.wrappedValue.dismiss()
            }, label: {
                Image(systemName: ConstantUtils.backbuttonImageName)
                    .foregroundColor(Color.theme.primaryText)
            })
            .font(.system(size: 14).bold())
        )
        .sheet(isPresented: $modifyViewOpen, onDismiss: {
            if(incomeViewModel.groupView) {
                incomeViewModel.incomeListByGroup.forEach {
                    let filterIncome = $0.value.filter { data in
                        data.id == income.id
                    }.first ?? IncomeRestModel()
                    if(!filterIncome.currency.isEmpty) {
                        self.income = filterIncome
                    }
                }
            } else {
                Task.init {
                    self.income = incomeViewModel.incomeList.filter { data in
                        data.id == income.id
                    }.first!
                }
            }
        }, content: {
            UpdateIncomeView(income: income)
        })
    }
}
