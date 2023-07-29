//
//  Person.swift
//  TrailBlazer
//
//  Created by Neelay Singhvi on 4/16/23.
//

import Foundation

struct Person: Identifiable {
    var id: String
    var firstName: String
    var lastName: String
    var age: String
    var email: String
    var imageRef: String        // name of image in cloud storage
    var imageURL: String        // location of image in cloud storage
    
    // initializer used while creating a new contact
    init() {
        id = ""
        firstName = ""
        lastName = ""
        age = ""
        email = ""
        imageRef = ""
        imageURL = ""
    }
    
    // initializer used when parsing data received from firestore
    init(id: String, data: [String: Any]) {
        self.id = id
        self.firstName = data["firstName"] as! String
        self.lastName = data["lastName"] as! String
        self.age = data["age"] as! String
        self.email = data["email"] as! String
        self.imageRef = (data["imageRef"] as? String) ?? ""
        self.imageURL = (data["imageURL"] as? String) ?? ""
    }
    
    // utility function used when uploading a new contact to firestore
    func toDict() -> [String: Any] {
        [
            "firstName": firstName,
            "lastName": lastName,
            "age": age,
            "email": email,
            "imageRef": imageRef,
            "imageURL": imageURL
        ]
    }
}
