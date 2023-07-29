//
//  LogInView.swift
//  TrailBlazer
//
//  Created by Neelay Singhvi on 4/3/23.
//

import SwiftUI
import FirebaseAuth

struct LogInView: View {

    @State private var password: String = ""
    @AppStorage("email") private var email: String = ""
    private let emailRegex = /^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/
    
    @State private var showingAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var showingProgressBar: Bool = false
    @State private var pushProfileView: Bool = false
    
    @EnvironmentObject private var masterViewModel : MasterViewModel
    
    var body: some View {
        VStack {
            Text("Log In View").bold().font(.largeTitle)
            Spacer()
            Group {
                Text("\n")  
                HStack {
                    Text("Email: ").bold().frame(width: 100, alignment: .leading)
                    TextField("abc@gmail.com", text: $email).keyboardType(.emailAddress).textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                }.padding()
                HStack {
                    Text("Password: ").bold().frame(width: 100, alignment: .leading)
                    SecureField("Password", text: $password).textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                }.padding()
            }
            Text("\n\n")
            Button {
                if isDetailValid() {
                    showingProgressBar = true
                    // create an asynchronous task to log the user in
                    Task {
                        await login()
                        showingProgressBar = false
                    }
                }
            } label: {
                Image("LogInButton")
            }
            Group {
                Spacer()
                Spacer()
                Spacer()
            }
        }
        .overlay {
            if showingProgressBar {
                ProgressView()
            }
        }
        // prompt appropriate alerts based on different errors
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK", role: .cancel) {
                showingAlert = false
                password = ""
            }
        } message: {
            Text(alertMessage)
        }
        
    }
    
    private func isDetailValid() -> Bool {
        // Case 1: email shouldn't be empty
        if email.isEmpty {
            showAlert(
                title: "Email Input Error",
                message: "Email address cannot be empty"
            )
            return false
        }
        // Case 2: email should be in the correct format (OPTIONAL)
        guard let _ = try? emailRegex.wholeMatch(in: email) else {
            showAlert(
                title: "Email Input Error",
                message: "\(email) is not a valid email address"
            )
            return false
        }
        // Case 3: password shouldn't be empty
        if password.isEmpty {
            showAlert(
                title: "Password Input Error",
                message: "Password cannot be empty"
            )
            return false
        }
        // Case 4: password length criteria should satisfy
        if password.count < 6 {
            showAlert(
                title: "Password Input Error",
                message: "Password length is too short (need something greater than 5)"
            )
            return false
        }
        return true
    }
    
    private func login() async {
        do {
            // use Firebase auth library to log-in the user
            try await Auth.auth().signIn(withEmail: email, password: password)
            masterViewModel.currView = .ProfileView
            password = ""
        } catch let error {
            showAlert(
                title: "Login Error",
                message: error.localizedDescription
            )
        }
    }
    
    private func showAlert(title: String, message: String) {
        showingAlert = true
        alertTitle = title
        alertMessage = message
        showingProgressBar = false
    }
}

struct LogInView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            LogInView()
        }
    }
}
