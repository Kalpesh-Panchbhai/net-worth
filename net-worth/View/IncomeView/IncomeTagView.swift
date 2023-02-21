//
//  IncomeTagView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 21/02/23.
//

import SwiftUI

struct IncomeTagView: View {
    
    @ObservedObject var incomeViewModel = IncomeViewModel()
    
    private var incomeController = IncomeController()
    
    var body: some View {
        List {
            ForEach(incomeViewModel.incomeTagList, id: \.self) { item in
                VStack(alignment: .leading) {
                    Text(item.name)
                    Text(item.isdefault ? "DEFAULT" : "")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
                .contextMenu {
                    if(!item.isdefault) {
                        Button(action: {
                            incomeController.makeOtherIncomeTagNonDefault(documentID: item.id!)
                            var updatedIncomeTag = item
                            updatedIncomeTag.isdefault = true
                            incomeController.updateIncomeTag(tag: updatedIncomeTag)
                            Task.init {
                                incomeViewModel.incomeTagList = [IncomeTag]()
                                await incomeViewModel.getIncomeTagList()
                            }
                        }, label: {
                            Text("Make default")
                        })
                    }
                }
            }
        }
        .onAppear {
            Task.init {
                await incomeViewModel.getIncomeTagList()
            }
        }
    }
}
