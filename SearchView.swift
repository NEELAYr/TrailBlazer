//
//  SearchView.swift
//  TrailBlazer
//
//  Created by Neelay Singhvi on 4/3/23.
//

import SwiftUI
import MapKit

struct trailDetails
{
    let id: Int
    let name: String
    let url: String
    let description: String
    let length: Double
    let lat: String
    let lon: String
    let difficulty: String
    let rating: Double?
    let thumbnail: String?
}

struct Location: Identifiable {
    let id = UUID()
    var name: String
    var coordinate: CLLocationCoordinate2D
}

struct SearchView: View {
    @State private var searchText: String = ""
    @State private var lat: String = ""
    @State private var lng: String = ""
    @State private var resultArr: [[String]] = []
    @State private var emptyResult: String = ""
    @State private var showingProgressBar: Bool = false
    
    private static let defaultLocation = CLLocationCoordinate2D(
        latitude: 33.4255,
        longitude: -111.9400
    )
    
    @State private var region = MKCoordinateRegion(
        center: defaultLocation,
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    // state property that stores marker locations in current map region
    @State private var markers = [
        Location(name: "Jaipur", coordinate: defaultLocation)
    ]
    
    var body: some View {
        VStack {
            Text("Search View").bold().font(.largeTitle)
            searchBar
            Spacer()
            Spacer()
            if searchText.isEmpty {
                EmptyView()
            } else { List {
                    if resultArr.isEmpty {
                        Text(emptyResult).bold()
                    } else {
                        ForEach(resultArr.prefix(10), id: \.self) { val in
                            NavigationLink(destination: TrailDetailView(trailName: val[0], trailDesc: val[1], trailDiff: val[2], trailRating: val[3], trailThumbnail: val[4], trailLength: val[5], trailID: val[8], lat: val[6], lng: val[7], alreadyAdded: false)) {
                                VStack(alignment: .leading) {
                                    Text(val[0]).bold()
                                    HStack {
                                        Image("ReviewIcon")
                                        Text(val[3])
                                        Spacer()
                                        Image("PathIcon")
                                        Text(val[5])
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            forwardGeocoding(searchText)
        }
        .onChange(of: searchText) { _ in
            forwardGeocoding(searchText)
            emptyResult = String()
            resultArr = []
        }
        .overlay {
            if showingProgressBar {
                ProgressView()
            }
        }
        .padding()
    }
    
    private func getTrailsInfo() {
        let headers = [
            "X-RapidAPI-Key": "5ba2115bf0mshc2132c76363256fp168dfejsn8c4fd7e48c39",
            "X-RapidAPI-Host": "trailapi-trailapi.p.rapidapi.com"
        ]

        let request = NSMutableURLRequest(url: NSURL(string: "https://trailapi-trailapi.p.rapidapi.com/trails/explore/?lat=\(lat)&lon=\(lng)")! as URL,
                                                cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers

        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            if (error != nil) {
                print(error ?? "Some error")
            }
            var _: NSError?
            
            do {
                let decodedData = try JSONSerialization.jsonObject(with: data ?? Data(), options: []) as? [String: Any]
                
                if(decodedData?["results"] as! Int == 0) {
                    emptyResult = "No Trail Data Found"
                }
                DispatchQueue.main.async {
                    let data = decodedData!["data"] as! [[String: Any]]
                    let trailDetails = parseJson(data: data)
                    for i in trailDetails {
                        let rating = String(i.rating!)
                        let id = String(i.id)
                        let length = resolveLength(length: i.length)
                        let l = String(length)
                        self.resultArr.append([i.name, i.description, i.difficulty, rating, i.thumbnail ?? "Placeholder", l, i.lat, i.lon, id])
                    }
                }
                showingProgressBar = false
            } catch {
                print("error: \(error)")
            }
        })

        dataTask.resume()
    }
    
    func parseJson(data: [[String: Any]]) -> [trailDetails] {
        data.map { trailInfo in
            trailDetails(
                id: trailInfo["id"] as! Int,
                name: trailInfo["name"] as! String,
                url: trailInfo["url"] as! String,
                description: trailInfo["description"] as! String,
                length: resolveLength(length: trailInfo["length"]!),
                lat: trailInfo["lat"] as! String,
                lon: trailInfo["lon"] as! String,
                difficulty: trailInfo["difficulty"] as! String,
                rating: trailInfo["rating"] as? Double,
                thumbnail: trailInfo["thumbnail"] as? String
            )
        }
    }
    
    func resolveLength(length: Any) -> Double {
        switch length {
        case let val as Double:
            return val
        default:
            return Double(length as! String)!
        }
    }
    
    func forwardGeocoding(_ addressStr: String)
    {
        _ = CLGeocoder();
        let addressString = addressStr
        CLGeocoder().geocodeAddressString(addressString, completionHandler:
                                            {(placemarks, error) in
            
            if error != nil {
                print("Geocode failed: \(error!.localizedDescription)")
            } else if placemarks!.count > 0 {
                let placemark = placemarks![0]
                let location = placemark.location
                let coords = location!.coordinate
                print(coords.latitude)
                print(coords.longitude)
                lat = String(format: "%.2f", coords.latitude)
                lng = String(format: "%.2f", coords.longitude)

                DispatchQueue.main.async
                {
                    region.center = coords
                    self.markers[0].name = placemark.locality ?? "Jaipur"
                    markers[0].coordinate = coords
                }
            }
        })
    }
    
    private var searchBar: some View {
        HStack {
            Button {
                getTrailsInfo()
                showingProgressBar = true
            } label: {
                Image(systemName: "location.magnifyingglass")
                    .resizable()
                    .foregroundColor(.black)
                    .frame(width: 24, height: 24)
                    .padding(.trailing, 12)
            }
            TextField("Search trails!", text: $searchText)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 8)
                .foregroundColor(.white)
        }
        .padding()
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SearchView()
        }
    }
}
