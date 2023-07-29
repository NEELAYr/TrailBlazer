//
//  SignUpView.swift
//  TrailBlazer
//
//  Created by Neelay Singhvi on 4/3/23.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import PhotosUI
import FirebaseStorage

struct SignUpView: View {
    @State private var person = Person()
    
    @AppStorage("email") private var email: String = ""
    private let emailRegex = /^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/
    @State private var password: String = ""
    
    @State private var showingAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var showingProgressBar: Bool = false
    @State private var showingProgressView = false
    @State private var signUpSuccess = false

    
    @State private var pickerItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @EnvironmentObject private var masterViewModel : MasterViewModel
    
    var body: some View {
        ScrollView {
            Text("Create Account").bold().font(.largeTitle)
//            Spacer()
            HStack {
                Spacer()
                photoPickerView
                Spacer()
            }
//            Spacer()
            Group {
                HStack {
                    Text("First Name: ").bold().frame(width: 100, alignment: .leading)
                    TextField("Neelay", text: $person.firstName).textFieldStyle(.roundedBorder).autocorrectionDisabled(true)
                }
                HStack {
                    Text("Last Name: ").bold().frame(width: 100, alignment: .leading)
                    TextField("Singhvi", text: $person.lastName).textFieldStyle(.roundedBorder).autocorrectionDisabled(true)
                }
                HStack {
                    Text("Age: ").bold().frame(width: 100, alignment: .leading)
                    TextField("19", text: $person.age).textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                }
                HStack {
                    Text("Email: ").bold().frame(width: 100, alignment: .leading)
                    TextField("abc@gmail.com", text: $email).keyboardType(.emailAddress).textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                }
                HStack {
                    Text("Password: ").bold().frame(width: 100, alignment: .leading)
                    SecureField("Enter Password", text: $password).textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                }
            }.padding(7)
//            Spacer()
//            Spacer()
            Button {
                if isDetailValid() {
                    showingProgressBar = true
                    Task {
                        await signup()
                    }
                }
            } label: {
                Image("SignUpButton")
            }
//            Group {
//                Spacer()
//                Spacer()
//                Spacer()
//                Spacer()
//            }
        }
        .overlay {
            if showingProgressBar {
                ProgressView()
            }
        }
        .alert(alertTitle, isPresented: $showingAlert) { 
            Button("OK", role: .cancel) {
                showingAlert = false
                if signUpSuccess {
                    masterViewModel.currView = .ProfileView
                }
            }
        } message: {
            Text(alertMessage)
        }
        
        .onChange(of: pickerItem) { _ in
            Task {
                // if user has picked a new image,
                // - extract the data
                // - convert to UIImage
                // - set this UIImage to selectedImage
                if let data = try? await pickerItem?.loadTransferable(type: Data.self) {
                    if let uiImage = UIImage(data: data) {
                        selectedImage = uiImage
                        return
                    }
                }
            }
        }
    }
    
    private var photoPickerView: some View {
        ZStack {
            Circle()
                .foregroundColor(.white)
                .frame(width: 162)
                .shadow(radius: 2)
            
            if let selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 162)
                    .clipShape(Circle())
            } else {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Image("ProfilePicAdder")
                }
            }
        }
    }
    
    private func isDetailValid() -> Bool {
        // Case 1: first name should be filled
        if person.firstName.isEmpty {
            showAlert(
                title: "First Name Input Error",
                message: "First Name cannot be empty")
        }
        // Case 2: last name should be filled
        if person.lastName.isEmpty {
            showAlert(
                title: "Last Name Input Error",
                message: "Last Name cannot be empty")
        }
        // Case 3: age should be filled
        if person.age.isEmpty {
            showAlert(
                title: "Age Input Error",
                message: "Age cannot be empty")
        }
        // Case 4: age cannot be negative
        if Int(person.age) ?? 19 < 0 {
            showAlert(
                title: "Age Input Error",
                message: "Plase enter the correct age")
        }
        // Case 5: email shouldn't be empty
        if email.isEmpty {
            showAlert(
                title: "Email Input Error",
                message: "Email address cannot be empty"
            )
            return false
        }
        // Case 6: email should be in the correct format
        guard let _ = try? emailRegex.wholeMatch(in: email) else {
            showAlert(
                title: "Email Input Error",
                message: "\(email) is not a valid email address"
            )
            return false
        }
        // Case 7: password shouldn't be empty
        if password.isEmpty {
            showAlert(
                title: "Password Input Error",
                message: "Password cannot be empty"
            )
            return false
        }
        // Case 8: password length criteria should satisfy
        if password.count < 8 {
            showAlert(
                title: "Password Input Error",
                message: "Password length is too short (need something greater than 7)"
            )
            return false
        }
        return true
    }
    
    private func signup() async {
        do {
            // use Firebase auth library to sign-up a new user
            try await Auth.auth().createUser(withEmail: email, password: password)
            person.email = email
            uploadDataWImage()
            
        } catch let error {
            showAlert(
                title: "Sign-up Error",
                message: error.localizedDescription
            )
        }
    }
    
    private func uploadDataWImage() {
        guard
            let selectedImage,
            let imageData = selectedImage.jpegData(compressionQuality: 0.3)
        else {
            uploadData()
            return
        }
        
        // create unique name for the image
        person.imageRef = "\(UUID().uuidString)-\(Date().ISO8601Format()).jpg"
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let imageRef = storageRef.child(person.imageRef)
        
        // upload jpeg image data to cloud storage
        imageRef.putData(imageData) { metaData, error in
            if let error {
                showAlert(title: "Image Upload Error", message: error.localizedDescription)
                showingProgressBar = false
                return
            }
            imageRef.downloadURL { url, error in
                if let error {
                    showAlert(title: "Image Upload Error", message: error.localizedDescription)
                    showingProgressBar = false
                    return
                }
                guard let url else {
                    showingProgressBar = false
                    return
                }
                person.imageURL = url.absoluteString
                uploadData()
            }
        }
    }
    
    private func uploadData() {
        let db = Firestore.firestore()
        db.collection("userInfo").addDocument(data: person.toDict()) { error in
            if let error {
                showAlert(title: "Network Error", message: error.localizedDescription)
                showingProgressBar = false
                return
            }
            // when all the steps were successfully executed
            // show a success alert and reset the view to original state
            showAlert(title: "Upload Success", message: "User successfully added to the database")
            showingProgressBar = false
            signUpSuccess = true
            resetView()
        }
    }

    // utility function, prompts alert with provided title and message
    private func showAlert(title: String, message: String) {
        showingAlert = true
        alertTitle = title
        alertMessage = message
        showingProgressBar = false
    }
    
    private func resetView() {
        pickerItem = nil
        selectedImage = nil
        password = ""
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SignUpView()
        }
    }
}
