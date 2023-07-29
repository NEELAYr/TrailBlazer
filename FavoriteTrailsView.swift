//
//  FavoriteTrailsView.swift
//  TrailBlazer
//
//  Created by Neelay Singhvi on 4/22/23.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct Trail: Identifiable {
    var id: String
    var name: String
    var desc: String
    var diff: String
    var rating: String
    var thumbnail: String
    var length: String
    var lat: String
    var lng: String
}

struct FavoriteTrailsView: View {
    @State private var trails: [Trail] = []
    
    @State private var showingAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var showingProgressBar: Bool = false
    @State private var showingProgressView = false
    @State private var uploadSuccess = false
    @State private var isFavorite = false
    
    @EnvironmentObject private var masterViewModel : MasterViewModel

    var body: some View {
        List(trails) { trail in
            NavigationLink(destination: TrailDetailView(trailName: trail.name, trailDesc: trail.desc, trailDiff: trail.diff, trailRating: trail.rating, trailThumbnail: trail.thumbnail, trailLength: trail.length, trailID: trail.id, lat: trail.lat, lng: trail.lng, alreadyAdded: true)) {
                VStack(alignment: .leading) {
                    Text(trail.name).bold()
                }
            }
        }
        .navigationTitle("Favorite Trails").bold()
        .onAppear(perform: loadData)
    }
    
    private func loadData() {
        guard let userId = Auth.auth().currentUser?.uid else {
            showAlert(title: "Session Expired", message: "Please login again to continue.")
            isFavorite = false
            return
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection("trails").document(userId)
        let trailCollection = userRef.collection("trailData")
        
        trailCollection.getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                trails = querySnapshot?.documents.compactMap { document in
                    let data = document.data()
                    return Trail(
                        id: data["id"] as? String ?? "",
                        name: data["name"] as? String ?? "",
                        desc: data["desc"] as? String ?? "",
                        diff: data["diff"] as? String ?? "",
                        rating: data["rating"] as? String ?? "",
                        thumbnail: data["thumbnail"] as? String ?? "",
                        length: data["length"] as? String ?? "",
                        lat: data["lat"] as? String ?? "",
                        lng: data["lng"] as? String ?? ""
                    )
                } ?? []
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        showingAlert = true
        alertTitle = title
        alertMessage = message
        showingProgressBar = false
    }
}

