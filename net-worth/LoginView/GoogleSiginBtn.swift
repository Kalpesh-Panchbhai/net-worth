//
//  GoogleSiginBtn.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 29/01/23.
//

import SwiftUI

struct GoogleSiginBtn: View {
    var action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            HStack {
                Image("google")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 25, height: 25)
                    .frame(height: 45)
                
                Text("Sign in with Google")
                    .font(.callout)
                    .lineLimit(1)
            }
            .foregroundColor(.black)
            .padding(.horizontal,15)
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.white)
            }
        }
//        .frame(width: .infinity, height: 50)
    }
}

struct GoogleSiginBtn_Previews: PreviewProvider {
    static var previews: some View {
        GoogleSiginBtn(action: {})
    }
}
