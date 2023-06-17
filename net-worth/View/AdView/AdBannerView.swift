//
//  SwiftUIView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 17/06/23.
//

import SwiftUI
import GoogleMobileAds

struct AdBannerView: View {
    
    var body: some View {
        VStack {
            GADBannerViewController()
        }
    }
}

struct GADBannerViewController: UIViewControllerRepresentable {
    
    func makeUIViewController(context: Context) -> some UIViewController {
        let view = GADBannerView(adSize: GADAdSizeBanner)
        let viewController = UIViewController()
        let testID = "ca-app-pub-6010707433076438/7134696783"
        
        view.adUnitID = testID
        view.rootViewController = viewController
        
        viewController.view.addSubview(view)
        viewController.view.frame = CGRect(origin: .zero, size: GADAdSizeBanner.size)
        
        view.load(GADRequest())
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
}
