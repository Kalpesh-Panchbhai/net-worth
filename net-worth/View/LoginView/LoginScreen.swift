//
//  LoginScreen.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 29/01/23.
//

import SwiftUI
import FirebaseAuth
import GoogleSignIn
import Firebase

struct LoginScreen: View {
    
    var body: some View {
        ZStack {
            RadialGradient(gradient: Gradient(colors: [Color(#colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1)), Color(#colorLiteral(red: 0.3647058904, green: 0.06666667014, blue: 0.9686274529, alpha: 1))]),
                           center: .topLeading,
                           startRadius: 5,
                           endRadius: UIScreen.main.bounds.height)
            .ignoresSafeArea()
            
            VStack {
                LoginHeader()
                
                HStack {
                    Image("net-worth-icon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .frame(height: 100)
                }
                
                GoogleSiginBtn {
                    // TODO: - Call the sign method here
                    guard let clientID = FirebaseApp.app()?.options.clientID else { return }

                    // Create Google Sign In configuration object.
                    let config = GIDConfiguration(clientID: clientID)
                    
                    GIDSignIn.sharedInstance.configuration = config

                    // Start the sign in flow!
                    GIDSignIn.sharedInstance.signIn(withPresenting: getRootViewController()) { user, error in
                        if error != nil {
                            return
                        }
                        
                        guard let authentication = user?.user, let idToken = authentication.idToken
                        else {
                          return
                        }

                        let credential = GoogleAuthProvider.credential(withIDToken: idToken.tokenString,
                                                                       accessToken: authentication.accessToken.tokenString)
                        
                        Auth.auth().signIn(with: credential) { authResult, error in
                            guard error == nil else {
                                return
                            }
                            
                            UserDefaults.standard.set(true, forKey: "signIn")
                            UserController().addCurrentUser()
                            Task.init {
                                await WatchController().addDefaultWatchList()
                            }
                        }
                    }
                }
            }
        }
    }
}
