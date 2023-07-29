//
//  Trails.swift
//  TrailBlazer
//
//  Created by Neelay Singhvi on 4/21/23.
//

import Foundation

struct Trails: Identifiable {
    var id: String
    var name: String
    var lat: String
    var lng: String
    var desc: String
    var diff: String
    var rating: String
    var thumbnail: String
    var length: String
    
    init() {
        id = ""
        name = ""
        lat = ""
        lng = ""
        desc = ""
        diff = ""
        rating = ""
        thumbnail = ""
        length = ""
    }
    
    // initializer used when parsing data received from firestore
    init(id: String, data: [String: Any]) {
        self.id = id
        self.name = data["name"] as! String
        self.lat = data["lat"] as! String
        self.lng = data["lng"] as! String
        self.desc = data["desc"] as! String
        self.diff = data["diff"] as! String
        self.rating = data["rating"] as! String
        self.thumbnail = data["thumbnail"] as! String
        self.length = data["length"] as! String
    }
    
    // utility function used when uploading a new contact to firestore
    func toDict() -> [String: Any] {
        [
            "id": id,
            "name": name,
            "lat": lat,
            "lng": lng,
            "desc": desc,
            "diff": diff,
            "rating": rating,
            "thumbnail": thumbnail,
            "length": length
        ]
    }
}
