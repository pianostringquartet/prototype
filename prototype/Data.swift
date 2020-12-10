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
 Domain: representation common to graph and visualization view
 ---------------------------------------------------------------- */

func identity<T>(x: T) -> T {
    return x
}

// a redux-state representation of calculation graph
struct StateGraph {
    
}

// basic unit of computation: inputs + a function
// both inputs and outputs ports are cells
// input-port cell = value + identity function
// output-port cell = value + non-identity function

// a cell might be reused / displayed in multiple UI contexts
struct Cell: Identifiable, Codable {
    
//struct Cell<A>: Identifiable, Codable {

    // a cell is tied to a specific port?
    
    var id: Int
    
//    let value: A
    let value: String
    
    // for now, no operation;
    // need e.g. either `let operation: (A) -> B`
    // or: `let operation: Action.type`
    
//    func result = operation(value)
    
}




// using strings for now?

// what kind of id should the outputs/inputs have?
// previously did a totally unique enumeration,
// but need to handle programmatically...

// a given 'Put' belongs to a node of a given type (Val vs Calc vs Viz)



// used to 'locate'/'specify' a specific port
// ports are unique by: graph + node + port id
// SKIPPING GRAPH ID FOR NOW
struct PortIdentifier: Codable, Equatable {
//    let graphId: Int
    let nodeId: Int
    let portId: Int
    let isInput: Bool
}

struct PortValue: Codable, Equatable {
    
    let id: Int // port id
    let nodeId: Int // id of node this port belongs to
    let label: String // port label
    
    // may need to use eg Cell for `value` instead?
    // because
    let value: String // port's value
    
    // alternatively?:
    // use cellId, and store the value in a Cell instead of `.value` here
    // bc: a Cell is usable across many ports
    // e.g. both a calcNode's output and a vizNode's input will use (display) the same value: uppercase('hello'),
    // but in redux state we only want to calculate and store `uppercase('hello')` one time and in one place
}





// 'layer 1' node: output only
struct ValNode: Identifiable, Codable {
    
    let id: Int
//    let outputs: [Output]
    let outputs: [PortValue]
}


// 'layer 2' node: input and output
//struct CalcNode: Identifiable, Codable {
struct CalcNode: Identifiable, Codable {

    let id: Int
//    let inputs: [Input]
    let inputs: [PortValue]
//    let outputs: [Output]
//    let outputs: [PortValue]
    
    // a calc node only has one output!
    let output: PortValue
    
    // functionality, e.g. str-concat or str-caps
    // swift: how to indicate just a general function?
//    let operation: (Any) -> Any
    
    // for now using:
    // how to use this with Codable?
    // if can't serialize the function,
    // alternatively, could have a redux action for operation,
    // and dispatch the
//    let operation: (String) -> String
    // but redux actions are hardcoded and known;
    
    // some redux action
    // not serializable?
//    let operation: Action.Type
    
    //
//    let operation: NodeDeletedAction.Type
    
    // RIGHT NOW: unused and
    let operation: String // and do Action.Type
    
    
    // or define custom serializers?
    // toString: Action.self or Action.type
    // fromString: ... would need to match the string against a list of actions...
    
    // can you set this aside for now?
    // can you just hardcode something for now?
    

    
}


// 'layer 3' node: input only; UI elem only
// what
struct VizNode: Identifiable, Codable {
    
    let id: Int
//    let inputs: [Input]
    let inputs: [PortValue]
    

    
}



/* ----------------------------------------------------------------
 ReSwift data: AppState, routes etc.
 ---------------------------------------------------------------- */

enum Screens: String, Codable {
    case graphSelection = "Select a graph"
    case graphEditing = "Edit a graph"
}

//struct AppState: StateType, Codable {
//    // for now, not worrying about graphs
//    var graphs: [Graph] = []
//
//    var nodes: [Node] = []
//    var connections: [Connection] = []
//
//    // start on the graphSelection screen if no persisted state etc.
//    var currentScreen: Screens = Screens.graphSelection
//
//    // the id of the graph we're currently editing
//    var currentGraphId: Int? = nil
//}


// for redux graph hello world
struct AppState: StateType, Codable {
    
    var graphs: [Graph] = []
    var nodes: [Node] = []
    var connections: [Connection] = []
    var currentScreen: Screens = Screens.graphSelection
    var currentGraphId: Int? = nil
    
    //
    var valNodes: [ValNode] = []
    var calcNodes: [CalcNode] = []
    var vizNodes: [VizNode] = []
    
    
    // ie the connectingPort
    var activePort: PortIdentifier? = nil
    
    var edges: [PortEdge] = []
    
}



/* ----------------------------------------------------------------
 Domain
 ---------------------------------------------------------------- */

struct PortEdge: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    
    let from: PortIdentifier // ie nodeId, portId
    let to: PortIdentifier
    
    
    // are two edges the same?
    static func ==(x: PortEdge, y: PortEdge) -> Bool {
        // Edgeless connection:
        
//        let isSameNodeId: Bool = x.from.nodeId == y.from.nodeId && x.from.nodeId == y.from.nodeId
//
//        let isSame
//        let x1:
        let res = (x.from == y.from && x.to == y.to || x.from == y.to && x.to == y.from)
        
//        log("PortEdge == res: \(res)")
        print("PortEdge == res: \(res)")
        
        // now compaing
        return res
    }
}


struct PortConnection: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
//    var graphId: Int
    
    // from a port #, to a port #
    var from: Int
    var to: Int
    
    // invariant: can only do input->output
    
    
    // here, the edges SHOULD HAVE DIRECTIONS?
    static func ==(lhs: PortConnection, rhs: PortConnection) -> Bool {
        // Edgeless connection:
        return (lhs.from == rhs.from && lhs.to == rhs.to || lhs.from == rhs.to && lhs.to == rhs.from)
    }
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
struct PortPreferenceData: Identifiable {
    let id = UUID()
    let viewIdx: Int // not needed?
    let center: Anchor<CGPoint>
//    let graphId: Int
    let nodeId: Int
    let portId: Int
}


// Preference key for preference data
struct PortPreferenceKey: PreferenceKey {
    typealias Value = [PortPreferenceData]
    
    static var defaultValue: [PortPreferenceData] = []
    
    static func reduce(value: inout [PortPreferenceData], nextValue: () -> [PortPreferenceData]) {
        value.append(contentsOf: nextValue())
    }
}



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

