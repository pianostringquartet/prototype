//
//  Data.swift
//  prototype
//
//  Created by cjc on 11/8/20.
//

import Foundation
import SwiftUI
import ReSwift


// data models not specific to graph or preview areas

/* ----------------------------------------------------------------
 Domain: representation common to graph and visualization view
 ---------------------------------------------------------------- */


// MARK: - REDUX MODELS

/* ----------------------------------------------------------------
 ReSwift data: AppState, screen, routes etc.
 ---------------------------------------------------------------- */

enum Screens: String, Codable {
    case graphSelection = "Select a graph"
    case graphEditing = "Edit a graph"
}


struct AppState: StateType, Codable {
    var nodeModels: [NodeModel] = []
    var activePM: PortModel? = nil
    var edges: [PortEdge] = []
}



