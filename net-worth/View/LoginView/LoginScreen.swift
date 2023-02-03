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
    @State var username: String = ""
    @State var password: String = ""
    
    var body: some View {
        VStack {
            VStack {
                LoginHeader()
                
                HStack {
                    Image("net-worth-icon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .frame(height: 100)
                }
                .padding(.horizontal,100)
                .padding(.vertical,100)
                .background {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.black)
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
                            guard let userUID = Auth.auth().currentUser?.uid else { return }
                            UserDefaults.standard.set(userUID, forKey: "currentLoggedUserUID")
                        }
                    }

                } // GoogleSiginBtn
            } // VStack
            .padding(.top, 52)
            Spacer()
        }
    }
}


struct LoginScreen_Previews: PreviewProvider {
    static var previews: some View {
        LoginScreen()
    }
}
