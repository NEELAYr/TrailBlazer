//
//  ContentView.swift
//  TrailBlazer
//
//  Created by Neelay Singhvi on 4/2/23.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    
    @AppStorage("isUserLoggedIn") var isUserLoggedIn = false
        
    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 0) {
                Text("Trail").bold().font(.largeTitle).foregroundColor(.white)
                Text("Blazer").bold().font(.largeTitle).foregroundColor(Colors.BlazerColor)
            }
            Spacer()
            if !isUserLoggedIn {
                HStack {
                    NavigationLink {
                        MasterView(view: .LogInView)
                    } label: {
                        Image("LogInButton")
                    }
                    NavigationLink {
                        MasterView(view: .SignUpView)
                    } label: {
                        Image("SignUpButton")
                    }
                }
            }
            HStack {
                NavigationLink {
                    MasterView(view: .SearchView)
                } label: {
                    Image("SearchButton")
                }
                NavigationLink {
                    MasterView(view: .ProfileView)
                } label: {
                    Image("ProfileButton")
                }
            }
            Spacer()
            Spacer()
            
        }
        .onAppear {
            isUserLoggedIn = Auth.auth().currentUser != nil
        }
        .background(background)
    }
    
    private var background: some View {
        Image("BackgroundImage")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
    }
}

struct ContentView_Previews: PreviewProvider {
    @StateObject static private var masterViewModel = MasterViewModel()
    static var previews: some View {
        NavigationView {
            ContentView()
        }.environmentObject(masterViewModel)
    }
}
