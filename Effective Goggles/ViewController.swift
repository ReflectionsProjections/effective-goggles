//
//  ViewController.swift
//  Effective Goggles
//
//  Created by Yasha Mostofi on 9/12/18.
//  Copyright © 2018 Yasha Mostofi. All rights reserved.
//

import UIKit
import SafariServices

class ViewController: BaseViewController {
    var loginSession: SFAuthenticationSession?

    @IBAction func loginButtonAction(_ sender: Any) {
        oauthLogin()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        EventManager.sharedinstance.getEvents()
        performSegue(withIdentifier: "ShowScanner", sender: self)
    }

    func oauthLogin() {
        guard let url = URL(string: "https://api.reflectionsprojections.org/auth/google/?redirect_uri=https://reflectionsprojections.org/auth?isMobile=true") else { fatalError() }
        print("URL::\(url)")
        loginSession = SFAuthenticationSession(url: url, callbackURLScheme: "hackillinois://") { [weak self] (url, error) in
            if let url = url,
                let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
                let queryItems = components.queryItems,
                let token = queryItems.first(where: { $0.name == "token" })?.value,
                token.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
                print("Token: \(token)")
                // DispatchQueue.main.async {
                //  self?.populateUserData(loginMethod: .github, token: token, sender: loginSelectionViewController)
                // }
            }
            
            if let error = error {
                if (error as? SFAuthenticationError)?.code == SFAuthenticationError.canceledLogin {
                    // do nothing
                } else {
                    let alert = UIAlertController(title: "Authentication Failed", message: nil, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    self?.present(alert, animated: true, completion: nil)
                }
            }
        }
        loginSession?.start()
    }

}

