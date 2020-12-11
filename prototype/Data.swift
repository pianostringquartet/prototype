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


// need `String` and string vals for it to be codable?
// and need codable to be serializable?
enum NodeType: String, Codable {
    case valNode = "valNode"
    case calcNode = "calcNode"
    case vizNode = "vizNode"
}



// for CREATING BRAND NEW (CALC) NODE MODEL
func uppercaseNodeModel(id: Int) -> NodeModel {
    // a calc node whose operation is Uppercase
    
    // autogenerate node id too?
    
    let operation: Operation = Operation.uppercase
    
    let input: PortModel = PortModel(id: 1, nodeId: id, portType: PortType.input, label: "input: String", value: "")

    let output: PortModel = PortModel(id: 2, nodeId: id, portType: PortType.output, label: "output: String", value: "")
    
    return NodeModel(id: id, nodeType: .calcNode, ports: [input, output], operation: operation)
}


func concatNodeModel(id: Int) -> NodeModel {
    // a calc node whose operation is Uppercase
    
    // autogenerate node id too?
    
    let operation: Operation = Operation.concat
    
    
    // MUST have at least two inputs;
    // ideally, should allow as many as desired
    
    let input: PortModel = PortModel(id: 1, nodeId: id, portType: PortType.input, label: "input: String", value: "")
    
    let input2: PortModel = PortModel(id: 2, nodeId: id, portType: PortType.input, label: "input: String", value: "")

    let output: PortModel = PortModel(id: 3, nodeId: id, portType: PortType.output, label: "output: String", value: "")
    
    return NodeModel(id: id, nodeType: .calcNode, ports: [input, input2, output], operation: operation)
}






struct NodeModel: Identifiable, Codable {
    
    let id: Int // nodeId
    
    let nodeType: NodeType
    
    // how to enforce e.g. that a valNode has only outputs?
    // how about through specific constructors?
    // eg NodeModel.calcNode(inputs, output)
    // and .calcNode constructor sets nodeType = calcNode etc.
    // ... but you'd still have an outputs field...
    
    //
//    let inputs: [PortValue]
//    let outputs: [PortValue]
    
    // better?:
    // right... should be PortModel (not just PortValue)
    // can determine inputs vs. outputs by sorting ports by PortType
    let ports: [PortModel]
    
    
    // only for calc Nodes
//    let operation: Operation?
//    let operation: Operation? = nil
    var operation: Operation? = nil
    
    func update(id: Int? = nil, nodeType: NodeType? = nil, ports: [PortModel]? = nil, operation: Operation? = nil) -> NodeModel {
        return NodeModel(id: id ?? self.id,
                         nodeType: nodeType ?? self.nodeType,
                         ports: ports ?? self.ports,
                         operation: operation ?? self.operation
        )
    }
    
    
    
}



enum PortType: String, Codable {
    case input = "input"
    case output = "output"
}

// combo of PortIdentifier, PortValue, Cell
// common to all types of nodes
// anywhere you use PortIdentifier, you can use PortModel
struct PortModel: Identifiable, Codable, Equatable {
    let id: Int
    let nodeId: Int
    // later: `let graphId: Int`
    
    let portType: PortType // input or output
     
    let label: String // port label
    
    // later?: use cellId to retrieve port's Cell (ie value), update in one place, display in many
//    ...unsure how useful if we think about it like "input port of calc-node should have same value as output port of val-node"
//    let cellId: Cell
    
    // later, should be "of type T"
//    let value: String // port value
    
    let value: String // port value
    
    let defaultValue: String = ""
    
    func update(id: Int? = nil, nodeId: Int? = nil, portType: PortType? = nil, label: String? = nil, value: String? = nil) -> PortModel {
        
        return PortModel(id: id ?? self.id,
                         nodeId: nodeId ?? self.nodeId,
                         portType: portType ?? self.portType,
                         label: label ?? self.label,
                         value: value ?? self.value)
    }
    
    
    
//    func update(id: Int = self.id, nodeId: Int = self.nodeId, portType: PortType = self.portType, label: String = self.label, value: String = self.value) -> PortModel {
//        return PortModel(id: id,
//                         nodeId: nodeId,
//                         portType: portType,
//                         label: label,
//                         value: value)
//    }
    
}




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




//
//// 'layer 1' node: output only
//struct ValNode: Identifiable, Codable {
//
//    let id: Int
////    let outputs: [Output]
//    let outputs: [PortValue]
//}
//
//
//// 'layer 2' node: input and output
////struct CalcNode: Identifiable, Codable {
//struct CalcNode: Identifiable, Codable {
//
//    let id: Int
////    let inputs: [Input]
//    let inputs: [PortValue]
////    let outputs: [Output]
////    let outputs: [PortValue]
//
//    // a calc node only has one output!
//    let output: PortValue
//
//    // functionality, e.g. str-concat or str-caps
//    // swift: how to indicate just a general function?
////    let operation: (Any) -> Any
//
//    // for now using:
//    // how to use this with Codable?
//    // if can't serialize the function,
//    // alternatively, could have a redux action for operation,
//    // and dispatch the
////    let operation: (String) -> String
//    // but redux actions are hardcoded and known;
//
//    // some redux action
//    // not serializable?
////    let operation: Action.Type
//
//    //
////    let operation: NodeDeletedAction.Type
//
//    // RIGHT NOW: unused and
//    let operation: String // and do Action.Type
//
//
//    // or define custom serializers?
//    // toString: Action.self or Action.type
//    // fromString: ... would need to match the string against a list of actions...
//
//    // can you set this aside for now?
//    // can you just hardcode something for now?
//
//
//
//}
//
//
//// 'layer 3' node: input only; UI elem only
//// what
//struct VizNode: Identifiable, Codable {
//
//    let id: Int
////    let inputs: [Input]
//    let inputs: [PortValue]
//
//
//
//}



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
//    var valNodes: [ValNode] = []
//    var calcNodes: [CalcNode] = []
//    var vizNodes: [VizNode] = []
    
    
    var nodeModels: [NodeModel] = []
    
    // ie the connectingPort
//    var activePort: PortIdentifier? = nil
    
    var activePM: PortModel? = nil
    
    var edges: [PortEdge] = []
}



/* ----------------------------------------------------------------
 Domain
 ---------------------------------------------------------------- */


// NodeId, PortId
//typealias PortCoordinate = (Int, Int) // still use PortIdentifier for now?
//typealias PortCoordinate = (Int, Int) // still use PortIdentifier for now?

// should be identifiable and equatable as well?
struct PortCoordinate: Equatable, Codable {
    let nodeId: Int
    let portId: Int
}


// PROBLEM: if you put port-values inside an edge, when will the edge be updated?
// ie old port-values will be trapped inside an edge;
// it's better to look those up based on

//struct PortEdge2: Identifiable, Codable, Equatable {
//    var id: UUID = UUID()
//
//    let from: PortCoordinate // ie nodeId, portId
//    let to: PortCoordinate
//
//
//    // are two edges the same?
//    static func ==(x: PortEdge2, y: PortEdge2) -> Bool {
//        // Edgeless connection:
//
////        let isSameNodeId: Bool = x.from.nodeId == y.from.nodeId && x.from.nodeId == y.from.nodeId
////
////        let isSame
////        let x1:
//        let res: Bool = (x.from == y.from && x.to == y.to) || (x.from == y.to && x.to == y.from)
//
////        log("PortEdge == res: \(res)")
//        print("PortEdge2 == res: \(res)")
//
//        // now compaing
//        return res
//    }
//}


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


//struct PortConnection: Identifiable, Codable, Equatable {
//    var id: UUID = UUID()
////    var graphId: Int
//
//    // from a port #, to a port #
//    var from: Int
//    var to: Int
//
//    // invariant: can only do input->output
//
//
//    // here, the edges SHOULD HAVE DIRECTIONS?
//    static func ==(lhs: PortConnection, rhs: PortConnection) -> Bool {
//        // Edgeless connection:
//        return (lhs.from == rhs.from && lhs.to == rhs.to || lhs.from == rhs.to && lhs.to == rhs.from)
//    }
//}

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
 Calc-node operations
 ---------------------------------------------------------------- */

// a given node can have a serializable `operation: Operation`,
// and then the fn is retrieved via eg. `operations[operation]`

enum Operation: String, Codable {
    case uppercase = "uppercase"
    case concat = "concat" // str concat
    case identity = "identity"
}

// doesn't this mapping just reproduce the switch/case mapping in `calculateValue`?
let operations: [Operation: Any] = [
    Operation.uppercase: { (s: String) -> String in s.uppercased() },
    Operation.concat: { (s1: String, s2: String) -> String in s1 + s2 },
//    Operation.identity: { (x: T) -> T in x } // T not in scope?
]


/* ----------------------------------------------------------------
 SwiftUI Preference Data: passing data up from children to parent view
 ---------------------------------------------------------------- */

// Datatype for preference data
struct PortPreferenceData: Identifiable {
    let id = UUID()
    let viewIdx: Int // not needed?
    let center: Anchor<CGPoint>
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

