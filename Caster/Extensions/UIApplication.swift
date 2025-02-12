//
//  UIApplication.swift
//  Caster
//
//  Created by Andy Stewart on 9/18/24.
//

import Foundation
import SwiftUI

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
