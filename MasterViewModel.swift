//
//  MasterViewModel.swift
//  TrailBlazer
//
//  Created by Neelay Singhvi on 4/17/23.
//

import SwiftUI

enum ViewPath: Int {
    case LogInView
    case SignUpView
    case SearchView
    case ProfileView
}


class MasterViewModel: ObservableObject {
    @Published var currView: ViewPath = .ProfileView
}
