//
//  SettingsView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 14/11/22.
//

import SwiftUI
import Firebase
import GoogleSignIn

struct SettingsView: View {
    
    var currencyList = CurrencyList().currencyList
    
    var settingsController = SettingsController()
    var notificationController = NotificationController()
    
    @State var filterCurrencyList = CurrencyList().currencyList
    @State var profilePhoto = UIImage()
    @State var isAuthenticationRequired: Bool
    @State var logout =  false
    @State var isPresentingDataAndAccountDeletionConfirmation = false
    @State var isPresentingLogoutConfirm = false
    @State var isPresentingUpdateChartDataConfirm = false
    
    @State var currenySelected: Currency
    @State var defaultIncomeType = IncomeType()
    @State var defaultIncomeTag = IncomeTag()
    
    @StateObject var incomeViewModel: IncomeViewModel
    
    var body: some View {
        NavigationView(){
            List{
                // MARK: Profile Detail View
                Section() {
                    VStack() {
                        Image(uiImage: profilePhoto)
                            .clipShape(Circle())
                            .frame(width: 100, height: 100)
                        
                        Text(Auth.auth().currentUser?.displayName ?? "")
                            .font(.system(size: 25))
                            .bold()
                            .foregroundColor(Color.theme.primaryText)
                        Text(Auth.auth().currentUser?.email ?? "")
                            .font(.system(size: 15))
                            .foregroundColor(Color.theme.primaryText)
                        
                    }
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .frame(height: 180)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
                
                Section() {
                    // MARK: Authentication Required toggle
                    Toggle(isOn: $isAuthenticationRequired, label: {
                        Label("Require Face ID", systemImage: "faceid")
                    }).onChange(of: isAuthenticationRequired) { newValue in
                        settingsController.setAuthentication(newValue: newValue)
                    }
                    .foregroundColor(Color.theme.primaryText)
                    .listRowBackground(Color.theme.foreground)
                    
                    // MARK: Notification View Link
                    NavigationLink(destination: {
                        NotificationsView()
                    }, label: {
                        Label("Notifications", systemImage: "play.square")
                    })
                    .foregroundColor(Color.theme.primaryText)
                    .listRowBackground(Color.theme.foreground)
                    
                    // MARK: Default Currency Picker
                    DefaultCurrencyPicker(currenySelected: $currenySelected)
                        .foregroundColor(Color.theme.primaryText)
                        .listRowBackground(Color.theme.foreground)
                    
                    // MARK: Income Type View
                    NavigationLink(destination: {
                        IncomeTypeView(incomeViewModel: incomeViewModel)
                    }, label: {
                        Label(title: {
                            HStack {
                                Text("Income Type")
                                Spacer()
                                Text(defaultIncomeType.name)
                            }
                        }, icon: {
                            Image(systemName: "tray.and.arrow.down")
                        })
                    })
                    .foregroundColor(Color.theme.primaryText)
                    .listRowBackground(Color.theme.foreground)
                    
                    // MARK: Income Tag View
                    NavigationLink(destination: {
                        IncomeTagView(incomeViewModel: incomeViewModel)
                    }, label: {
                        Label(title: {
                            HStack {
                                Text("Income Tag")
                                Spacer()
                                Text(defaultIncomeTag.name)
                            }
                        }, icon: {
                            Image(systemName: "tag.square")
                        })
                    })
                    .foregroundColor(Color.theme.primaryText)
                    .listRowBackground(Color.theme.foreground)
                    
                    // MARK: Backup View
                    NavigationLink(destination: {
                        BackupView()
                    }, label: {
                        Label("Backup", systemImage: "folder")
                    })
                    .foregroundColor(Color.theme.primaryText)
                    .listRowBackground(Color.theme.foreground)
                }
                
                Section() {
                    // MARK: Delete Account & Data
                    Button(action: {
                        isPresentingDataAndAccountDeletionConfirmation.toggle()
                    }, label: {
                        Label("Delete Account & Data", systemImage: "xmark.bin")
                            .foregroundColor(Color.theme.red)
                            .listRowBackground(Color.theme.foreground)
                    }).confirmationDialog("Are you sure?",
                                          isPresented: $isPresentingDataAndAccountDeletionConfirmation) {
                        Button("Delete all data and account?", role: .destructive) {
                            Task.init {
                                await deleteAccountAndData()
                            }
                        }
                    }
                    
                    // MARK: Logout
                    Button(action: {
                        isPresentingLogoutConfirm.toggle()
                    }, label: {
                        Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(Color.theme.primaryText)
                            .listRowBackground(Color.theme.foreground)
                    }).confirmationDialog("Are you sure?",
                                          isPresented: $isPresentingLogoutConfirm) {
                        Button("Logout?", role: .destructive) {
                            logoutUser()
                        }
                    }
                }
                
                // MARK: Application Version
                let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
                let buildVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
                Label("Version " + (appVersion ?? "") + " Build(" + (buildVersion ?? "Unknown Build Version)") + ")", systemImage: "gear.badge.checkmark")
                    .foregroundColor(Color.theme.primaryText)
                    .listRowBackground(Color.theme.foreground)
                
                // MARK: Chart last updated
                Button(action: {
                    isPresentingUpdateChartDataConfirm.toggle()
                }, label: {
                    let dateTime = UserDefaults.standard.string(forKey: "chartLastUpdated") ?? ""
                    Label("Date Time: " + dateTime, systemImage: "gear.badge.checkmark")
                        .foregroundColor(Color.theme.primaryText)
                        .listRowBackground(Color.theme.foreground)
                }).confirmationDialog("Are you sure?",
                                      isPresented: $isPresentingUpdateChartDataConfirm) {
                    Button("Do you want to update chart data?", role: .destructive) {
                        Task.init {
                            await ApplicationData.loadData(fetchLatest: true)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .listStyle(.insetGrouped)
            .background(Color.theme.background)
            .scrollContentBackground(.hidden)
            .foregroundColor(Color.theme.primaryText)
        }
        .onAppear {
            Task.init {
                profilePhoto = await fetchProfilePhoto()
                self.defaultIncomeType = await IncomeTypeController().getIncomeTypeList().filter({
                    $0.isdefault
                }).first ?? IncomeType()
                self.defaultIncomeTag = await IncomeTagController().getIncomeTagList().filter({
                    $0.isdefault
                }).first ?? IncomeTag()
            }
        }
        .fullScreenCover(isPresented: $logout, content: {
            LoginScreen()
        })
    }
    
    private func fetchProfilePhoto() async -> UIImage {
        do {
            let (data, _) = try await URLSession.shared.data(from: (Auth.auth().currentUser?.photoURL)!)
            if let image = UIImage(data: data) {
                return image
            }
        } catch {
            print(error)
        }
        return UIImage()
    }
    
    private func logoutUser() {
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            defaults.removeObject(forKey: key)
        }
        settingsController.setAuthentication(newValue: false)
        ApplicationData.clear()
    }
    
    private func deleteAccountAndData() async {
        await UserController().deleteUser()
        logoutUser()
    }
}
