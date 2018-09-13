//
//  BaseViewController.swift
//  Effective Goggles
//
//  Created by Yasha Mostofi on 9/13/18.
//  Copyright © 2018 Yasha Mostofi. All rights reserved.
//

import Foundation
import UIKit

class BaseViewController: UIViewController {
    var login_session = ""
    
    func displayAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okayAction = UIAlertAction(title: "Okay", style: .default)
        alert.addAction(okayAction)
        DispatchQueue.main.async { [weak self] in
            self?.present(alert, animated: true) {
            }
        }
    }
}
