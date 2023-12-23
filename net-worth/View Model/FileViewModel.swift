//
//  FileViewModel.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 22/12/23.
//

import Foundation

class FileViewModel: ObservableObject {
    
    @Published var dataLoadingCompleted = false
    
    public func loadData() async {
        await ApplicationData.loadData()
        self.dataLoadingCompleted = !ApplicationData.shared.dataLoading
    }
    
}
