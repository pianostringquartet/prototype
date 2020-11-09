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

//enum Screens: String, Codable {
enum Screens: String, Codable {
    case graphSelection = "Select a graph"
    case graphEditing = "Edit a graph"
}

//struct Screen: Codable {
//    let screen: Screens
//}

//enum RoutingDestination: String {
//  case menu = "MenuTableViewController"
//  case categories = "CategoriesTableViewController"
//  case game = "GameViewController"
//}

struct AppState: StateType, Codable {
//    var counter: Int = 0
//    var counter: Int = 5
    var fun: Fun = Fun(name: "Molly Bloom")
    var muchFun: [Fun] = [Fun(name: "James Joyce"), Fun(name: "Marcel Proust")]
    
    // These start out empty
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

// needs equatable as well, and .connectionId?
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

// add nodes? ... but then I have to be updating the Graph everytime?
struct Graph: Identifiable, Codable {
    var id: UUID = UUID()
    var graphId: Int
    // var nodeCount?
}

// should add a constructor like ".plusBall"
struct Node: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var graphId: Int
    var info: UUID = UUID()
    var isAnchored: Bool // = true // nodes start out anchored
    var nodeId: Int // = 1 // if creating the first node
    
    // can I start out like this ?
    var position: CGSize = .zero
//    var positionX: CGFloat
//    var positionX: CGFloat
    
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
    
    // need to add, for particular graph!
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

