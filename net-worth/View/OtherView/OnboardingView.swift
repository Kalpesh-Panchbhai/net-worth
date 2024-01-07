//
//  OnboardingView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 08/02/23.
//

import SwiftUI

struct OnboardingView: View {
    
    var settingsController = SettingsController()
    var notificationController = NotificationController()
    var currencyList = CurrencyList().currencyList
    let transition: AnyTransition = .asymmetric(
        insertion: .move(edge: .trailing),
        removal: .move(edge: .leading))
    
    @State var onboardingState: Int = 0
    @State var currenySelected: Currency = Currency(code: "INR", symbol: "₹", name: "Indian rupee")
    @State var filterCurrencyList = CurrencyList().currencyList
    @State var isAuthenticationRequired: Bool = false
    @State var allNotification: Bool = false
    @State var mutualFundNotification: Bool = false
    @State var equityNotification: Bool = false
    @State var etfNotification: Bool = false
    @State var cryptoCurrencyNotification: Bool = false
    @State var futureNotification: Bool = false
    @State var optionNotification: Bool = false
    @State var creditCardNotification: Bool = false
    @State var loanNotification: Bool = false
    @State var otherNotification: Bool = false
    @State var alertTitle: String = ""
    @State var showAlert: Bool = false
    
    @AppStorage("onboardingCompleted") var onboardingCompleted = false
    
    @StateObject var fileViewModel = FileViewModel()
    
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
                case 2:
                    enableFaceID
                        .transition(transition)
                case 3:
                    enableNotification
                        .transition(transition)
                case 4:
                    loadingDataView
                        .onAppear() {
                            Task.init {
                                await fileViewModel.loadData()
                            }
                        }
                        .transition(transition)
                default:
                    MainScreenView()
                }
            }
            if(onboardingState <= 3 || (onboardingState == 4 && fileViewModel.dataLoadingCompleted)) {
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
    
    private func loadData() -> Bool {
        return true
    }
}

// MARK: COMPONENTS
extension OnboardingView {
    
    private var bottomView: some View {
        Text(onboardingState == 4 ? "FINISHED" : "NEXT")
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
            HStack {
                Image("net-worth-icon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .frame(height: 100)
            }
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
        NavigationView {
            ZStack {
                RadialGradient(gradient: Gradient(colors: [Color(#colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1)), Color(#colorLiteral(red: 0.3647058904, green: 0.06666667014, blue: 0.9686274529, alpha: 1))]),
                               center: .topLeading,
                               startRadius: 5,
                               endRadius: UIScreen.main.bounds.height)
                .ignoresSafeArea()
                VStack(spacing: 40) {
                    Spacer()
                    Text("Select Default Currency")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    DefaultCurrencyPicker(currenySelected: $currenySelected)
                        .foregroundColor(.white)
                    Spacer()
                    Spacer()
                }
                .multilineTextAlignment(.center)
                .padding(30)
            }
        }
    }
    
    private var loadingDataView: some View {
        NavigationView {
            ZStack {
                RadialGradient(gradient: Gradient(colors: [Color(#colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1)), Color(#colorLiteral(red: 0.3647058904, green: 0.06666667014, blue: 0.9686274529, alpha: 1))]),
                               center: .topLeading,
                               startRadius: 5,
                               endRadius: UIScreen.main.bounds.height)
                .ignoresSafeArea()
                VStack(spacing: 40) {
                    if(!fileViewModel.dataLoadingCompleted) {
                        Text("Please wait while we load the best experience for you!")
                        ProgressView().tint(Color.theme.primaryText)
                    } else {
                        Text("Setup completed! Please click on Finished to start using it!")
                    }
                }
                .multilineTextAlignment(.center)
                .padding(30)
            }
        }
    }
    
    private var enableFaceID: some View {
        VStack(spacing: 40) {
            Spacer()
            Text("Setup Face ID")
                .font(.largeTitle)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Toggle(isOn: $isAuthenticationRequired, label: {
                Label("Require Face ID", systemImage: "faceid")
            }).onChange(of: isAuthenticationRequired) { newValue in
                settingsController.setAuthentication(newValue: newValue)
            }
            Spacer()
            Spacer()
        }
        .multilineTextAlignment(.center)
        .padding(30)
    }
    
    private var notifications: some View {
        VStack {
            Toggle(isOn: $mutualFundNotification, label: {
                Text("Mutual Funds")
            }).onChange(of: mutualFundNotification) { newValue in
                allNotification = (mutualFundNotification && equityNotification && etfNotification && cryptoCurrencyNotification && futureNotification && optionNotification && creditCardNotification && loanNotification && otherNotification)
                notificationController.setNotification(newValue: newValue, accountType: "MUTUALFUND")
            }
            
            Toggle(isOn: $equityNotification, label: {
                Text("Equity")
            }).onChange(of: equityNotification) { newValue in
                allNotification = (mutualFundNotification && equityNotification && etfNotification && cryptoCurrencyNotification && futureNotification && optionNotification && creditCardNotification && loanNotification && otherNotification)
                notificationController.setNotification(newValue: newValue, accountType: "EQUITY")
            }
            
            Toggle(isOn: $etfNotification, label: {
                Text("ETF")
            }).onChange(of: etfNotification) { newValue in
                allNotification = (mutualFundNotification && equityNotification && etfNotification && cryptoCurrencyNotification && futureNotification && optionNotification && creditCardNotification && loanNotification && otherNotification)
                notificationController.setNotification(newValue: newValue, accountType: "ETF")
            }
            
            Toggle(isOn: $cryptoCurrencyNotification, label: {
                Text("Cryptocurrency")
            }).onChange(of: cryptoCurrencyNotification) { newValue in
                allNotification = (mutualFundNotification && equityNotification && etfNotification && cryptoCurrencyNotification && futureNotification && optionNotification && creditCardNotification && loanNotification && otherNotification)
                notificationController.setNotification(newValue: newValue, accountType: "CRYPTOCURRENCY")
            }
            
            Toggle(isOn: $futureNotification, label: {
                Text("Future")
            })
            .onChange(of: futureNotification) { newValue in
                allNotification = (mutualFundNotification && equityNotification && etfNotification && cryptoCurrencyNotification && futureNotification && optionNotification && creditCardNotification && loanNotification && otherNotification)
                notificationController.setNotification(newValue: newValue, accountType: "FUTURE")
            }
            
            Toggle(isOn: $optionNotification, label: {
                Text("Option")
            }).onChange(of: optionNotification) { newValue in
                allNotification = (mutualFundNotification && equityNotification && etfNotification && cryptoCurrencyNotification && futureNotification && optionNotification && creditCardNotification && loanNotification && otherNotification)
                notificationController.setNotification(newValue: newValue, accountType: "OPTION")
            }
            
            Toggle(isOn: $creditCardNotification, label: {
                Text(ConstantUtils.creditCardAccountType)
            }).onChange(of: creditCardNotification) { newValue in
                allNotification = (mutualFundNotification && equityNotification && etfNotification && cryptoCurrencyNotification && futureNotification && optionNotification && creditCardNotification && loanNotification && otherNotification)
                notificationController.setNotification(newValue: newValue, accountType: ConstantUtils.creditCardAccountType)
            }
            
            Toggle(isOn: $loanNotification, label: {
                Text(ConstantUtils.loanAccountType)
            })
            .onChange(of: loanNotification) { newValue in
                allNotification = (mutualFundNotification && equityNotification && etfNotification && cryptoCurrencyNotification && futureNotification && optionNotification && creditCardNotification && loanNotification && otherNotification)
                notificationController.setNotification(newValue: newValue, accountType: ConstantUtils.loanAccountType)
            }
            
            Toggle(isOn: $otherNotification, label: {
                Text(ConstantUtils.otherAccountType)
            })
            .onChange(of: otherNotification) { newValue in
                allNotification = (mutualFundNotification && equityNotification && etfNotification && cryptoCurrencyNotification && futureNotification && optionNotification && creditCardNotification && loanNotification && otherNotification)
                notificationController.setNotification(newValue: newValue, accountType: ConstantUtils.otherAccountType)
            }
        }
    }
    
    private var enableNotification: some View {
        VStack() {
            Text("Setup Notifications")
                .font(.largeTitle)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Toggle(isOn: $allNotification, label: {
                Text("All")
            }).onChange(of: allNotification) { newValue in
                mutualFundNotification = newValue
                equityNotification = newValue
                etfNotification = newValue
                cryptoCurrencyNotification = newValue
                futureNotification = newValue
                optionNotification = newValue
                creditCardNotification = newValue
                loanNotification = newValue
                otherNotification = newValue
                notificationController.setNotification(newValue: newValue, accountType: "MUTUALFUND")
                notificationController.setNotification(newValue: newValue, accountType: "EQUITY")
                notificationController.setNotification(newValue: newValue, accountType: "ETF")
                notificationController.setNotification(newValue: newValue, accountType: "CRYPTOCURRENCY")
                notificationController.setNotification(newValue: newValue, accountType: "FUTURE")
                notificationController.setNotification(newValue: newValue, accountType: "OPTION")
                notificationController.setNotification(newValue: newValue, accountType: ConstantUtils.creditCardAccountType)
                notificationController.setNotification(newValue: newValue, accountType: ConstantUtils.loanAccountType)
                notificationController.setNotification(newValue: newValue, accountType: ConstantUtils.otherAccountType)
            }
            
            notifications
        }
        .multilineTextAlignment(.center)
        .padding(30)
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
        
        if onboardingState == 4 {
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
