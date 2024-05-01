//
//  NavigationGesture.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 11/05/23.
//

import Foundation
import SwiftUI

extension UINavigationController: UIGestureRecognizerDelegate {
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}
