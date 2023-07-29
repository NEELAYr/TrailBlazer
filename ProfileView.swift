//
//  ProfileView.swift
//  TrailBlazer
//
//  Created by Neelay Singhvi on 4/3/23.
//

import SwiftUI

import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct ProfileView: View {
    
    @State private var userLoggedIn = false
    @State private var showingAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var showingProgressBar: Bool = false
    @State private var deleteAcc: Bool = false
    @AppStorage("email") private var email: String = ""
    
    @State private var pInfo = [Person]()
    @EnvironmentObject private var masterViewModel : MasterViewModel
    
    
    var body: some View {
        ScrollView {
            VStack {
                if pInfo.isEmpty {
                    Text("LOGIN TO SEE YOUR PROFILE").bold()
                }
            ForEach(pInfo) { info in
                if (info.email == email) {
                    VStack {
                        Text("User Profile").bold().font(.title)
                        Spacer()
                        Spacer()
                        HStack {
                            Circle()
                                .foregroundColor(.white)
                                .frame(width: 162)
                                .overlay {
                                    AsyncImage(url: URL(string: info.imageURL)) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 162)
                                            .clipShape(Circle())
                                    } placeholder: {
                                        Image("ProfilePicPlaceholder")
                                    }
                                }
                                .shadow(radius: 4)
                                .padding()
                        }
                        Spacer()
                        HStack {
                            Text("\(info.firstName) \(info.lastName)").bold()
                        }
                        Group {
                            Spacer()
                            Spacer()
                            Text("Email: \(info.email)").bold()
                            Spacer()
                            Spacer()
                            Text("Age: \(info.age)").bold()
                            Spacer()
                            Spacer()
                        }
                        Spacer()
                        VStack {
                            NavigationLink(destination: FavoriteTrailsView()){
                                Image("FavoriteButton")
                            }
                            Spacer()
                            Spacer()
                            Spacer()
                            Spacer()
                            HStack {
                                Button {
                                    do {
                                        try Auth.auth().signOut()
                                        masterViewModel.currView = .LogInView
                                    } catch let error {
                                        showingAlert = true
                                        alertTitle = "Error Signing Out"
                                        alertMessage = error.localizedDescription
                                    }
                                } label: {
                                    Image("SignOutButton")
                                }
                                Button {
                                    showAlert(title: "Delete Account", message: "Are you sure you want to delete your account.")
                                } label: {
                                    Image("DeleteAccountButton")
                                }
                            }
                        }
                    }
                }
            }
                Spacer()
                Spacer()
                Spacer()
            }
        }
        .task {
            await ifLoggedIn()
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("YES", role: .cancel) {
                showingAlert = false
                deleteAccount()
            }
            Button("NO", role: .destructive) {
                showingAlert = false
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func ifLoggedIn() async {
        let db = Firestore.firestore()
        
        guard Auth.auth().currentUser != nil else {
            // if no user found, then ask the user to login again
            return
        }
        
        guard let snapshot = try? await db.collection("userInfo").getDocuments() else {
            return
        }
        pInfo = snapshot.documents.map {
            Person(id: $0.documentID, data: $0.data())
        }
    }
    
    private func showAlert(title: String, message: String) {
        showingAlert = true
        alertTitle = title
        alertMessage = message
        showingProgressBar = false
    }
    
    private func deleteAccount() {
        let user = Auth.auth().currentUser
        
        // Delete user data from Firestore
        let db = Firestore.firestore()
        let userRef = db.collection("userInfo").document(user!.uid)
        userRef.delete()
        
        // Delete user's favorite trails from Firestore
        let trailRef = db.collection("trails").document(user!.uid)
        trailRef.delete()
        
        // Delete user account from Firebase Authentication
        user?.delete { error in
            if let error = error {
                print("Error deleting user: \(error.localizedDescription)")
            } else {
                // User account deleted.
                masterViewModel.currView = .SignUpView
            }
        }
    }
}


struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProfileView()
        }
    }
}
