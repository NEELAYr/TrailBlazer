//
//  TrailDetailView.swift
//  TrailBlazer
//
//  Created by Neelay Singhvi on 4/19/23.
//

import SwiftUI
import MapKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct TrailDetailView: View {
    var trailName:String
    var trailDesc:String
    var trailDiff: String
    var trailRating: String
    var trailThumbnail: String
    var trailLength: String
    var trailID: String
    var lat: String
    var lng: String
    var alreadyAdded: Bool
    
    
    @State private var trails = Trails()
    @State private var showingAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var showingProgressBar: Bool = false
    @State private var showingProgressView = false
    @State private var uploadSuccess = false
    @State private var isFavorite = false
    
    private static var defaultLocation = CLLocationCoordinate2D()
    
    // state property that represents the current map region
    @State private var region = MKCoordinateRegion()
    // state property that stores marker locations in current map region
    @State private var markers = [
        Location(name: "Jaipur", coordinate: defaultLocation)
    ]
    
    init(trailName: String, trailDesc: String, trailDiff: String, trailRating: String, trailThumbnail: String, trailLength: String, trailID: String, lat: String, lng: String, alreadyAdded: Bool) {
            self.trailName = trailName
            self.trailDesc = trailDesc
            self.trailDiff = trailDiff
            self.trailRating = trailRating
            self.trailThumbnail = trailThumbnail
            self.trailLength = trailLength
            self.trailID = trailID
            self.lat = lat
            self.lng = lng
            self.alreadyAdded = alreadyAdded
            
        TrailDetailView.defaultLocation = CLLocationCoordinate2D(
                latitude: Double(lat) ?? 33.4255,
                longitude: Double(lng) ?? -111.9400
            )
            
            _region = State(initialValue: MKCoordinateRegion(
                center: TrailDetailView.defaultLocation,
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            ))
        }
    
    var body: some View {
        ScrollView {
            Text(trailName).bold().font(.largeTitle)
            VStack {
                HStack {
                    AsyncImage(url: URL(string: trailThumbnail)) { image in
                        image
                            .resizable()
                            .frame(width: 300, height: 250)
                    } placeholder: {
                        Image("BikeTrail")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 300, height: 250)
                    }
                }
            }
            .frame(width: 300, height: 250)
            .padding(5)
            Text("Description: ").bold().frame(alignment: .center)
            Text(trailDesc).padding(10)
            Spacer()
            HStack {
                Text("Difficulty: ").bold().frame(alignment: .center)
                Text(trailDiff).padding(10)
            }
            ZStack(alignment: .bottom) {
                Map(coordinateRegion: $region,
                    interactionModes: .all,
                    annotationItems: markers
                ){ location in
                    MapMarker(coordinate: location.coordinate)
                }
                searchBar
            }.frame(width: 300, height: 250)
            Button {
                let trailNameForQuery = trailName.replacingOccurrences(of: " ", with: "+")
                let urlString = "http://maps.apple.com/?q=\(trailNameForQuery)"
                if let url = URL(string: urlString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Image("DirectionsButton")
            }
            .padding()
        }
        .toolbar {
            ToolbarItem (placement: .navigationBarTrailing) {
                Button {
                    isFavorite.toggle()
                    if isFavorite {
                        uploadTrail()
                    } else {
                        deleteTrail()
                    }
                } label: {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                }
            }
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK", role: .cancel) {
                showingAlert = false
            }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            if let userId = Auth.auth().currentUser?.uid {
                let db = Firestore.firestore()
                let userRef = db.collection("trails").document(userId)
                let trailCollection = userRef.collection("trailData")
                trailCollection.whereField("id", isEqualTo: trailID).getDocuments { (querySnapshot, error) in
                    if let error = error {
                        print("Error getting documents: \(error)")
                    } else {
                        if let documents = querySnapshot?.documents, !documents.isEmpty {
                            // Trail exists in user's favorite list
                            isFavorite = true
                        }
                    }
                }
            }
        }
        .onAppear {
            if alreadyAdded {
                isFavorite.toggle()
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            Button ("") {
                let searchRequest = MKLocalSearch.Request()
                searchRequest.naturalLanguageQuery = trailName
                searchRequest.region = region
                
                MKLocalSearch(request: searchRequest).start { response, error in
                    guard let response = response else {
                        print("Error: \(error?.localizedDescription ?? "Unknown error").")
                        return
                    }
                    region = response.boundingRegion
                    markers = response.mapItems.map { item in
                        Location(
                            name: item.name ?? "",
                            coordinate: item.placemark.coordinate
                        )
                    }
                }
            }
        }
        .padding()
    }
    
    private func showAlert(title: String, message: String) {
        showingAlert = true
        alertTitle = title
        alertMessage = message
        showingProgressBar = false
    }
    
    private func uploadTrail() {
        let db = Firestore.firestore()
        guard let userId = Auth.auth().currentUser?.uid else {
            showAlert(title: "Session Expired", message: "Please login again to continue.")
            isFavorite = false
            return
        }
        let userRef = db.collection("trails").document(userId)
        
        let trailCollection = userRef.collection("trailData")
        
        trails.length = trailLength
        trails.thumbnail = trailThumbnail
        trails.rating = trailRating
        trails.diff = trailDiff
        trails.desc = trailDesc
        trails.lng = lng
        trails.lat = lat
        trails.name = trailName
        trails.id = trailID
        
        let newTrail = trails.toDict()
        trailCollection.addDocument(data: newTrail) { error in
            if let error {
                showAlert(title: "Network Error", message: error.localizedDescription)
                showingProgressBar = false
                return
            }
            showAlert(title: "Upload Success", message: "Trail successfully added to the database")
            showingProgressBar = false
            uploadSuccess = true
            isFavorite = true
        }
    }
    
    private func deleteTrail() {
        let db = Firestore.firestore()
        guard let userId = Auth.auth().currentUser?.uid else {
            showAlert(title: "Session Expired", message: "Please login again to continue.")
            isFavorite = true
            return
        }
        let userRef = db.collection("trails").document(userId)
        let trailCollection = userRef.collection("trailData")

        trailCollection.whereField("id", isEqualTo: trailID).getDocuments { (querySnapshot, error) in
            if let error = error {
                showAlert(title: "Network Error", message: error.localizedDescription)
                showingProgressBar = false
                isFavorite = true
                return
            }

            for document in querySnapshot!.documents {
                document.reference.delete { error in
                    if let error = error {
                        showAlert(title: "Network Error", message: error.localizedDescription)
                        showingProgressBar = false
                        isFavorite = true
                        return
                    }
                    showAlert(title: "Deletion Success", message: "Trail successfully removed from the database")
                    showingProgressBar = false
                    uploadSuccess = false
                    isFavorite = false
                }
            }
        }
    }

}

struct TrailDetailView_Previews: PreviewProvider {
    static var previews: some View {
        TrailDetailView(trailName: "Hayden Butte", trailDesc: "Very nice trail it is", trailDiff: "Advanced", trailRating: "5.0", trailThumbnail: "", trailLength: "0", trailID: "1", lat: "", lng: "", alreadyAdded: false)
    }
}
