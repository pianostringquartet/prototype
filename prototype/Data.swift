//
//  Data.swift
//  prototype
//
//  Created by cjc on 11/8/20.
//

import Foundation
import SwiftUI
import ReSwift



/* ----------------------------------------------------------------
 ReSwift data: AppState, routes etc.
 ---------------------------------------------------------------- */

enum Screens: String, Codable {
    case graphSelection = "Select a graph"
    case graphEditing = "Edit a graph"
}

struct AppState: StateType, Codable {
    var graphs: [Graph] = []
    var nodes: [Node] = []
    var connections: [Connection] = []
    
    // start on the graphSelection screen if no persisted state etc.
    var currentScreen: Screens = Screens.graphSelection
    
    // the id of the graph we're currently editing
    var currentGraphId: Int? = nil
}


/* ----------------------------------------------------------------
 Domain
 ---------------------------------------------------------------- */

struct Fun: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var count: Int = 0
}

struct Connection: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var graphId: Int
    var from: Int
    var to: Int
    
    static func ==(lhs: Connection, rhs: Connection) -> Bool {
        // Edgeless connection:
        return lhs.graphId == rhs.graphId && (lhs.from == rhs.from && lhs.to == rhs.to || lhs.from == rhs.to && lhs.to == rhs.from)
    }
}

struct Graph: Identifiable, Codable {
    var id: UUID = UUID()
    var graphId: Int
}


struct Node: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var graphId: Int
    var info: UUID = UUID()
    var isAnchored: Bool
    var nodeId: Int
    
    var position: CGSize = .zero
    var radius: Int = 40 // start out at 40
}


/* ----------------------------------------------------------------
 SwiftUI Preference Data: passing data up from children to parent view
 ---------------------------------------------------------------- */

// Datatype for preference data
struct BallPreferenceData: Identifiable {
    let id = UUID()
    let viewIdx: Int
    let center: Anchor<CGPoint>
    let graphId: Int
    let nodeId: Int
}

// Preference key for preference data
struct BallPreferenceKey: PreferenceKey {
    typealias Value = [BallPreferenceData]
    
    static var defaultValue: [BallPreferenceData] = []
    
    static func reduce(value: inout [BallPreferenceData], nextValue: () -> [BallPreferenceData]) {
        value.append(contentsOf: nextValue())
    }
}
