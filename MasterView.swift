//
//  MasterView.swift
//  TrailBlazer
//
//  Created by Neelay Singhvi on 4/3/23.
//

import SwiftUI


struct MasterView: View {
    var view: ViewPath
    @EnvironmentObject private var masterViewModel : MasterViewModel
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            switch masterViewModel.currView {
                case .LogInView:
                    LogInView()
                case .SearchView:
                    SearchView()
                case .SignUpView:
                    SignUpView()
                case .ProfileView:
                    ProfileView()
            }
            
            Spacer()
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image("HomeIcon")
                }
                Spacer()
                Button {
                    masterViewModel.currView = .SearchView
                } label: {
                    Image("SearchIcon")
                }
                Spacer()
                Button {
                    masterViewModel.currView = .ProfileView
                } label: {
                    Image("ProfileIcon")
                }
            }.padding(.horizontal)
        }
        .onAppear {
            masterViewModel.currView = view
        }
        .onReceive(masterViewModel.$currView) { newVal in
            print(newVal)
        }
    }
}

struct MasterView_Previews: PreviewProvider {
    static var previews: some View {
        MasterView(view: .LogInView)
    }
}
