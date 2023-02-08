//
//  OnboardingView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 08/02/23.
//

import SwiftUI

struct OnboardingView: View {
    
    @AppStorage("onboardingCompleted") var onboardingCompleted = false
    let transition: AnyTransition = .asymmetric(
        insertion: .move(edge: .trailing),
        removal: .move(edge: .leading))
    @State var onboardingState: Int = 0
    @State private var currenySelected: Currency = Currency()
    @State private var filterCurrencyList = CurrencyList().currencyList
    private var currencyList = CurrencyList().currencyList
    
    private var settingsController = SettingsController()

    @State var alertTitle: String = ""
    @State var showAlert: Bool = false
    
    var body: some View {
        ZStack {
            
            RadialGradient(gradient: Gradient(colors: [Color(#colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1)), Color(#colorLiteral(red: 0.3647058904, green: 0.06666667014, blue: 0.9686274529, alpha: 1))]),
                           center: .topLeading,
                           startRadius: 5,
                           endRadius: UIScreen.main.bounds.height)
            .ignoresSafeArea()
            
            ZStack {
                switch onboardingState {
                case 0:
                    welcomeSection
                        .transition(transition)
                case 1:
                    selectDefaultCurrencySection
                        .transition(transition)
                default:
                    MainScreenView()
                }
            }
            if(onboardingState <= 1) {
                VStack {
                    Spacer()
                    bottomView
                }
                .padding(30)
            }
        }
        .alert(isPresented: $showAlert, content: {
            return Alert(title: Text(alertTitle))
        })
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}

// MARK: COMPONENTS
extension OnboardingView {
    
    private var bottomView: some View {
        Text(onboardingState == 1 ? "FINISHED" : "NEXT")
            .font(.headline)
            .foregroundColor(.purple)
            .frame(height: 55)
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(10)
            .onTapGesture {
                handleNextButtonPressed()
            }
    }
    
    private var welcomeSection: some View {
        VStack(spacing: 40) {
            Spacer()
            Image(systemName: "heart.text.square.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .foregroundColor(.white)
            Text("Net Worth")
                .font(.largeTitle)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .overlay(
                    Capsule(style: .continuous)
                        .frame(height: 3)
                        .offset(y: 5)
                        .foregroundColor(.white)
                    , alignment: .bottom
                )
            Text("Welcome to Net worth!")
                .fontWeight(.medium)
                .foregroundColor(.white)
            Spacer()
            Spacer()
        }
        .multilineTextAlignment(.center)
        .padding(30)
    }
    
    private var selectDefaultCurrencySection: some View {
        VStack(spacing: 40) {
            Spacer()
            Text("Select Default Currency")
                .font(.largeTitle)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            defaultCurrencyPicker
            Spacer()
            Spacer()
        }
        .multilineTextAlignment(.center)
        .padding(30)
    }
    
    var defaultCurrencyPicker: some View {
        
        Picker(selection: $currenySelected, label: Text("Select a default currency"), content: {
            Text("Select a default currency").tag(Currency())
            ForEach(filterCurrencyList, id: \.self) { (data) in
                defaultCurrencyPickerRightVersionView(currency: data)
                    .tag(data)
            }
        })
        .edgesIgnoringSafeArea(.all)
        .onChange(of: currenySelected) { (data) in
            settingsController.setDefaultCurrency(newValue: data)
        }
        .pickerStyle(.menu)
    }
}

// MARK: FUNCTIONS
extension OnboardingView {
    
    func handleNextButtonPressed() {
        
        switch onboardingState {
        case 1:
            guard !currenySelected.code.isEmpty else {
                showAlert(title: "Please select a default currency")
                return
            }
        default:
            break
        }
        
        if onboardingState == 1 {
            signIn()
        } else {
            withAnimation(.spring()) {
                onboardingState += 1
            }
        }
    }
    
    func signIn() {
        UserDefaults.standard.set(true, forKey: "onboardingCompleted")
    }
    
    func showAlert(title: String) {
        alertTitle = title
        showAlert.toggle()
    }
}
