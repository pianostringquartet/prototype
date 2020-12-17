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

//func identity<T>(x: T) -> T {
//    return x
//}



// need `String` and string vals for it to be codable?
// and need codable to be serializable?
//enum NodeType: String, Codable {
enum NodeType: String, Codable {
    case valNode, calcNode, vizNode
//    case valNode = "valNode"
//    case calcNode = "calcNode"
//    case vizNode = "vizNode"
}


// MARK: - NODES

// val nodes have a single output
func stringValNode(id: Int, value: String, label: String = "output: String") -> NodeModel {
    
    let valNodeOutput: PortModel = PortModel(id: 1, nodeId: id, portType: PortType.output,
                                             label: label,
                                             value: MPV.StringMPV(value),
                                             defaultValue: .StringMPV(value))

    return NodeModel(id: id, nodeType: NodeType.valNode, ports: [valNodeOutput])
}


func boolValNode(id: Int, value: Bool, label: String = "output: Bool") -> NodeModel {
    
    let valNodeOutput: PortModel = PortModel(id: 1, nodeId: id, portType: PortType.output,
                                             label: label,
                                             value: MPV.BoolMPV(value),
                                             defaultValue: .BoolMPV(value))


    return NodeModel(id: valNodeId, nodeType: NodeType.valNode, ports: [valNodeOutput])
}

// viz nodes have only inputs (one or more)
func stringVizNode(id: Int, value: String, previewElement: PreviewElement, label: String) -> NodeModel {

    let vizNodeInput: PortModel = PortModel(id: 1, nodeId: id, portType: PortType.input, label: label, value: MPV.StringMPV(value), defaultValue: .StringMPV(value))

    return NodeModel(id: id, nodeType: NodeType.vizNode, ports: [vizNodeInput], previewElement: previewElement)
}


// not used yet?
func boolVizNode(id: Int, value: Bool, previewElement: PreviewElement, label: String) -> NodeModel {

    let vizNodeInput: PortModel = PortModel(id: 1, nodeId: id, portType: PortType.input, label: label, value: MPV.BoolMPV(value), defaultValue: .BoolMPV(value))

    return NodeModel(id: id, nodeType: NodeType.vizNode, ports: [vizNodeInput], previewElement: previewElement)
}




// for CREATING BRAND NEW (CALC) NODE MODEL
func uppercaseNodeModel(id: Int) -> NodeModel {
    
    let operation: Operation = Operation.uppercase
    
    let input: PortModel = PortModel(id: 1, nodeId: id, portType: PortType.input, label: "input: String", value: MPV.StringMPV(""), defaultValue: MPV.StringMPV(""))

    let output: PortModel = PortModel(id: 2, nodeId: id, portType: PortType.output, label: "output: String", value: MPV.StringMPV(""), defaultValue: MPV.StringMPV(""))
    
    return NodeModel(id: id, nodeType: .calcNode, ports: [input, output], operation: operation)
}


func concatNodeModel(id: Int) -> NodeModel {
    let operation: Operation = Operation.concat
        
    let input: PortModel = PortModel(id: 1, nodeId: id, portType: PortType.input, label: "input: String", value: MPV.StringMPV(""), defaultValue: MPV.StringMPV(""))
    let input2: PortModel = PortModel(id: 2, nodeId: id, portType: PortType.input, label: "input: String", value: MPV.StringMPV(""), defaultValue: MPV.StringMPV(""))
    let output: PortModel = PortModel(id: 3, nodeId: id, portType: PortType.output, label: "output: String", value: MPV.StringMPV(""), defaultValue: MPV.StringMPV(""))
    
    return NodeModel(id: id, nodeType: NodeType.calcNode, ports: [input, input2, output], operation: operation)
}

// need calcNode for Option picker
func optionPickerNodeModel(id: Int) -> NodeModel {
    
    // binaryOption picker; receives bool / 1-or-0
    let operation = Operation.optionPicker
    
    let input: PortModel = PortModel(id: 1, nodeId: id, portType: PortType.input, label: "Bool", value: MPV.BoolMPV(false), defaultValue: MPV.BoolMPV(false))
    
    let input2: PortModel = PortModel(id: 2, nodeId: id, portType: PortType.input, label: "Color", value: MPV.StringMPV("Green"), defaultValue: MPV.StringMPV("Green"))
    let input3: PortModel = PortModel(id: 3, nodeId: id, portType: PortType.input, label: "Color", value: MPV.StringMPV("Purple"), defaultValue: MPV.StringMPV("Pruple"))
    let output: PortModel = PortModel(id: 4, nodeId: id, portType: PortType.output, label: "Color", value: MPV.StringMPV("Purple"), defaultValue: MPV.StringMPV("Purple"))
        
    return NodeModel(id: id, nodeType: NodeType.calcNode, ports: [input, input2, input3, output], operation: operation)

}

// need valNode for "Interaction" (only outputs)
func pressInteractionNodeModel(id: Int) -> NodeModel {
    
    let output: PortModel = PortModel(id: 1, nodeId: id, portType: .output, label: "Interaction", value: MPV.BoolMPV(false), defaultValue: MPV.BoolMPV(false))
    
    return NodeModel(id: id, nodeType: NodeType.valNode, ports: [output], previewInteraction: PreviewInteraction.press)
}



struct NodeModel: Identifiable, Codable {

    let id: Int // nodeId
    
    let nodeType: NodeType
    let ports: [PortModel]
    
    var operation: Operation? = nil // only for calc nodes
    
    // assuming, for now, one previewElement per VizNode
    // ... if need to keep track of specifically-embodied PreviewElement,
    // can use the PreviewElement struct with the id instead?
    var previewElement: PreviewElement? = nil // only for viz-nodes
    
    var previewInteraction: PreviewInteraction? = nil // only for interaction val-nodes
    
    
    func update(id: Int? = nil, nodeType: NodeType? = nil, ports: [PortModel]? = nil, operation: Operation? = nil, previewElement: PreviewElement? = nil, previewInteraction: PreviewInteraction? = nil) -> NodeModel {
        return NodeModel(id: id ?? self.id,
                         nodeType: nodeType ?? self.nodeType,
                         ports: ports ?? self.ports,
                         operation: operation ?? self.operation,
                         previewElement: previewElement ?? self.previewElement,
                         previewInteraction: previewInteraction ?? self.previewInteraction
        )
    }
    
    
    
}



enum PortType: String, Codable {
    case input = "input"
    case output = "output"
}



// are these genuinely equatable?
// shouldn't I need to implement `==` method?
//enum MPV: Equatable, Codable {

// assoc-val enum has to be manually decoded etc.
// ... so we'll extend with Codable
enum MPV: Equatable, Codable {
    case StringMPV(String)
    case BoolMPV(Bool)
    
//    init(from decoder: Decoder) throws {
//        log("MPV init called")
//        fatalError("init(from:) has not been implemented")
//    }

    //
    enum CodingKeys: CodingKey {
        case StringMPV, BoolMPV
    }
    
    func encode(to encoder: Encoder) throws {
//        log("MPV encode called")
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
            case .StringMPV(let value):
                try container.encode(value, forKey: .StringMPV)
            case .BoolMPV(let value):
                try container.encode(value, forKey: .BoolMPV)
        }
        // don't need to return anything?
    } // encode
    
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        if let value = try? values.decode(String.self, forKey: .StringMPV) {
            self = .StringMPV(value)
            return
        } else if let value = try? values.decode(Bool.self, forKey: .BoolMPV) {
            self = .BoolMPV(value)
            return
        } else {
//            throw EncodingError.dataCorrupted // not found?
            throw fatalError("decoding MPV failed...")
        }
    }
}

struct PortModel: Identifiable, Codable, Equatable {
    
    let id: Int
    let nodeId: Int
    // later: `let graphId: Int`
    
    let portType: PortType // input or output
     
    let label: String // port label

    // alternatively, use `var` since these can be changed during use? 
    let value: MPV
    
    let defaultValue: MPV // not needed?
        
    func update(id: Int? = nil, nodeId: Int? = nil, portType: PortType? = nil, label: String? = nil, value: MPV? = nil, defaultValue: MPV? = nil) -> PortModel {
        
        return PortModel(id: id ?? self.id,
                         nodeId: nodeId ?? self.nodeId,
                         portType: portType ?? self.portType,
                         label: label ?? self.label,
                         value: value ?? self.value,
                         defaultValue: defaultValue ?? self.defaultValue
        )
    }
        
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
// AppState<View> not decodable...
struct AppState: StateType, Codable {
//struct AppState: StateType, Codable {

// AppState does not conform to decodable
//struct AppState<T: Codable & Equatable>: StateType, Codable {
        
    var nodeModels: [NodeModel] = []
    
    // ie the connectingPort
//    var activePort: PortIdentifier? = nil
    
//    var activePM<T: Codable & Equatable>: PortModel<T>? = nil

//    var activePM: PortModel<T>? = nil
    var activePM: PortModel? = nil
    
    var edges: [PortEdge] = []
    
    // right -- how would you serialize a view?
    // you can't store the View itself?
    // -- you have to reconstruct the view?
//    var miniview: View? = nil
}



/* ----------------------------------------------------------------
 Domain
 ---------------------------------------------------------------- */


// NodeId, PortId
//typealias PortCoordinate = (Int, Int) // still use PortIdentifier for now?

// should be identifiable and equatable as well?
struct PortCoordinate: Equatable, Codable {
    let nodeId: Int
    let portId: Int
}


struct PortEdge: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    
    let from: PortIdentifier // ie nodeId, portId
    let to: PortIdentifier
    
    
    // are two edges the same?
    static func ==(x: PortEdge, y: PortEdge) -> Bool {
        // Edgeless connection:
        let res = (x.from == y.from && x.to == y.to || x.from == y.to && x.to == y.from)
        print("PortEdge == res: \(res)")
        
        // now compaing
        return res
    }
}


/* ----------------------------------------------------------------
 `Viz-layer -> miniviewer` models
 ---------------------------------------------------------------- */

// string is user displayable?
// and then these get matched in a gigantic
enum PreviewElement: String, Codable {
    case text = "Text"
    case typographyColor = "Typography Color"
}

enum PreviewInteraction: String, Codable {
    case press = "Press"
}


/* ----------------------------------------------------------------
 Calc-node operations
 ---------------------------------------------------------------- */

// a given node can have a serializable `operation: Operation`,
// and then the fn is retrieved via eg. `operations[operation]`


enum Operation: String, Codable {
    case uppercase = "uppercase"
    case concat = "concat" // str concat
    case optionPicker = "optionPicker"
    case identity = "identity"
    
    // also?:
    
}

// doesn't this mapping just reproduce the switch/case mapping in `calculateValue`?
//let operations: [Operation: Any] = [
//    Operation.uppercase: { (s: String) -> String in s.uppercased() },
//    Operation.concat: { (s1: String, s2: String) -> String in s1 + s2 },
////    Operation.identity: { (x: T) -> T in x } // T not in scope?
//]


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
