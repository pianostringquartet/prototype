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


// MARK: - NODES

enum NodeType: String, Codable {
    case valNode, calcNode, vizNode
}


func isValNode(nm: NodeModel) -> Bool {
    return nm.nodeType == .valNode
}

func isValInteractionNode(nm: NodeModel) -> Bool {
    return nm.nodeType == .valNode && nm.previewInteraction != nil
}

func isCalcNode(nm: NodeModel) -> Bool {
    return nm.nodeType == .calcNode && nm.operation != nil
}

func isVizNode(nm: NodeModel) -> Bool {
    return nm.nodeType == .vizNode && nm.previewElement != nil
}


// better?: use enum or subclasses for val vs calc vs viz node
// See Bear Notes on how to subclass this
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
    case input, output
}


// Temporary: wrapper type
struct Color2: Equatable, Codable {
    var r: Double = 0.0
    var g: Double = 0.0
    var b: Double = 0.0
    var opacity: Double = 1.0

    var color: Color {
        return Color(red: r, green: g, blue: b, opacity: opacity)

    }
}


enum PortValue: Equatable, Codable {
    
    case string(String)
    case bool(Bool)
    case color(String)
//    case color(Color)
//    case color(Color2)
    case int(Int)
    
    enum CodingKeys: CodingKey {
        case string, bool, color, int
    }
    
    func encode(to encoder: Encoder) throws {
        log("PortValue encode called")
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
            case .string(let value):
                log("PortValue encoder: .string")
                try container.encode(value, forKey: .string)
            case .bool(let value):
                log("PortValue encoder: .bool")
                try container.encode(value, forKey: .bool)
            case .color(let value):
                log("PortValue encoder: .color")
                try container.encode(value, forKey: .color)
            case .int(let value):
                log("PortValue encoder: .int")
                try container.encode(value, forKey: .int)
                
        }
        // don't need to return anything?
    } // encode
    
    
    init(from decoder: Decoder) throws {
//        log("PortValue: init(from decoder: Decoder) called")
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        if let value = try? values.decode(String.self, forKey: .string) {
            log("PortValue decoder: .string")
            self = .string(value)
            return
        } else if let value = try? values.decode(Bool.self, forKey: .bool) {
            log("PortValue decoder: .bool")
            self = .bool(value)
            return
        } else if let value = try? values.decode(Int.self, forKey: .int) {
            log("PortValue decoder: .int")
            self = .int(value)
            return
        } else {
            log("... may try to decode Color...")
//            if let value = try? values.decode(Color.self, forKey: .color) {
//            if let value = try? values.decode(Color2.self, forKey: .color) {
            if let value = try? values.decode(String.self, forKey: .color) {
                log("PortValue decoder: .color")
                self = .color(value)
                return
            }
            else {
                log("will throw fatal decoding error...")
                throw fatalError("decoding MPV failed...")
            }
        }
    }
        
            
//        } else if let value = try? values.decode(Color.self, forKey: .color) {
//            log("PortValue decoder: .color")
//            self = .color(value)
//            return
////        } else if let value = try? values.decode(Int.self, forKey: .int) {
////            self = .int(value)
////            return
//        } else {
////            throw EncodingError.dataCorrupted // not found?
//            throw fatalError("decoding MPV failed...")
//        }
        
//    }
}


struct PortModel: Identifiable, Codable, Equatable {
    
    let id: Int
    let nodeId: Int
    // later: `let graphId: Int`
    
    let portType: PortType // input or output
     
    let label: String // port label

    // alternatively, use `var` since these can be changed during use? 
    let value: PortValue
    
    let defaultValue: PortValue // not needed?
        
    func update(id: Int? = nil, nodeId: Int? = nil, portType: PortType? = nil, label: String? = nil, value: PortValue? = nil, defaultValue: PortValue? = nil) -> PortModel {
        
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
struct PortIdentifier: Codable, Equatable {
    let nodeId: Int
    let portId: Int
    
    let isInput: Bool // why do we need this?
}


// NodeId, PortId
typealias PortCoordinate = (Int, Int) // still use PortIdentifier for now?

// should be identifiable and equatable as well?
//struct PortCoordinate: Equatable, Codable {
//    let nodeId: Int
//    let portId: Int
//}

let pc: PortCoordinate = PortCoordinate(1, 2)
let pc2: PortCoordinate = (1, 2)



struct PortEdge: Identifiable, Codable, Equatable {

    // should be `let`? when is `id` ever changed?
    var id: UUID = UUID()
    
    let from: PortIdentifier // ie nodeId, portId
    let to: PortIdentifier
    
    static func ==(x: PortEdge, y: PortEdge) -> Bool {
        // Edgeless connection:
        return (x.from == y.from && x.to == y.to || x.from == y.to && x.to == y.from)
    }
}



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





// MARK: - MINIVIEWER MODELS

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


// MARK: - CALC NODE OPERATIONS

/* ----------------------------------------------------------------
 Calc-node operations
 ---------------------------------------------------------------- */

// a given node can have a serializable `operation: Operation`,
// and then the fn is retrieved via eg. `operations[operation]`


enum Operation: String, Codable {
    case uppercase, concat, optionPicker, identity
}

// doesn't this mapping just reproduce the switch/case mapping in `calculateValue`?
let operations: [Operation: Any] = [
    Operation.uppercase: { (s: String) -> String in s.uppercased() },
    Operation.concat: { (s1: String, s2: String) -> String in s1 + s2 },
//    Operation.identity: { (x: T) -> T in x } // T not in scope?
]


// MARK: - PREFERENCE DATA

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


// MARK: - HELPERS

/* ----------------------------------------------------------------
 Helpers
 ---------------------------------------------------------------- */


// val nodes have a single output
func stringValNode(id: Int, value: String, label: String = "output: String") -> NodeModel {
    
    let valNodeOutput: PortModel = PortModel(id: 1, nodeId: id, portType: PortType.output,
                                             label: label,
                                             value: PortValue.string(value),
                                             defaultValue: .string(value))

    return NodeModel(id: id, nodeType: NodeType.valNode, ports: [valNodeOutput])
}


func boolValNode(id: Int, value: Bool, label: String = "output: Bool") -> NodeModel {
    
    let valNodeOutput: PortModel = PortModel(id: 1, nodeId: id, portType: PortType.output,
                                             label: label,
                                             value: PortValue.bool(value),
                                             defaultValue: .bool(value))


    return NodeModel(id: valNodeId, nodeType: NodeType.valNode, ports: [valNodeOutput])
}

// viz nodes have only inputs (one or more)
func stringVizNode(id: Int, value: String, previewElement: PreviewElement, label: String) -> NodeModel {

    let vizNodeInput: PortModel = PortModel(id: 1, nodeId: id, portType: PortType.input, label: label, value: .string(value), defaultValue: .string(value))

    return NodeModel(id: id, nodeType: NodeType.vizNode, ports: [vizNodeInput], previewElement: previewElement)
}


func colorVizNode(id: Int, value: String, previewElement: PreviewElement, label: String) -> NodeModel {

    let vizNodeInput: PortModel = PortModel(id: 1, nodeId: id, portType: PortType.input, label: label, value: .color(value), defaultValue: .color(value))

    return NodeModel(id: id, nodeType: NodeType.vizNode, ports: [vizNodeInput], previewElement: previewElement)
}


// not used yet?
func boolVizNode(id: Int, value: Bool, previewElement: PreviewElement, label: String) -> NodeModel {

    let vizNodeInput: PortModel = PortModel(id: 1, nodeId: id, portType: PortType.input, label: label, value: .bool(value), defaultValue: .bool(value))

    return NodeModel(id: id, nodeType: NodeType.vizNode, ports: [vizNodeInput], previewElement: previewElement)
}




// for CREATING BRAND NEW (CALC) NODE MODEL
func uppercaseNodeModel(id: Int) -> NodeModel {
    
    let operation: Operation = Operation.uppercase
    
    let input: PortModel = PortModel(id: 1, nodeId: id, portType: PortType.input, label: "input: String", value: .string(""), defaultValue: .string(""))

    let output: PortModel = PortModel(id: 2, nodeId: id, portType: PortType.output, label: "output: String", value: .string(""), defaultValue: .string(""))
    
    return NodeModel(id: id, nodeType: .calcNode, ports: [input, output], operation: operation)
}


func concatNodeModel(id: Int) -> NodeModel {
    let operation: Operation = Operation.concat
        
    let input: PortModel = PortModel(id: 1, nodeId: id, portType: PortType.input, label: "input: String", value: PortValue.string(""), defaultValue: PortValue.string(""))
    let input2: PortModel = PortModel(id: 2, nodeId: id, portType: PortType.input, label: "input: String", value: PortValue.string(""), defaultValue: PortValue.string(""))
    let output: PortModel = PortModel(id: 3, nodeId: id, portType: PortType.output, label: "output: String", value: PortValue.string(""), defaultValue: PortValue.string(""))
    
    return NodeModel(id: id, nodeType: NodeType.calcNode, ports: [input, input2, output], operation: operation)
}

// need calcNode for Option picker
func optionPickerNodeModel(id: Int) -> NodeModel {
    
    // binaryOption picker; receives bool / 1-or-0
    let operation = Operation.optionPicker
    
    let input: PortModel = PortModel(id: 1, nodeId: id, portType: PortType.input, label: "Bool", value: PortValue.bool(false), defaultValue: PortValue.bool(false))
    
//    let input2: PortModel = PortModel(id: 2, nodeId: id, portType: PortType.input, label: "Color", value: PortValue.string("Green"), defaultValue: PortValue.string("Green"))
//    let input3: PortModel = PortModel(id: 3, nodeId: id, portType: PortType.input, label: "Color", value: PortValue.string("Purple"), defaultValue: PortValue.string("Pruple"))
//    let output: PortModel = PortModel(id: 4, nodeId: id, portType: PortType.output, label: "Color", value: PortValue.string("Purple"), defaultValue: PortValue.string("Purple"))
    
    let input2: PortModel = PortModel(id: 2, nodeId: id, portType: PortType.input, label: "Color", value: .color(trueColorString), defaultValue: .color(trueColorString))
    let input3: PortModel = PortModel(id: 3, nodeId: id, portType: PortType.input, label: "Color", value: .color(falseColorString), defaultValue: .color(falseColorString))
    let output: PortModel = PortModel(id: 4, nodeId: id, portType: PortType.output, label: "Color", value: .color(falseColorString), defaultValue: .color(falseColorString))
        
    return NodeModel(id: id, nodeType: NodeType.calcNode, ports: [input, input2, input3, output], operation: operation)

}

// need valNode for "Interaction" (only outputs)
func pressInteractionNodeModel(id: Int) -> NodeModel {
    
    let output: PortModel = PortModel(id: 1, nodeId: id, portType: .output, label: "Interaction", value: PortValue.bool(false), defaultValue: PortValue.bool(false))
    
    return NodeModel(id: id, nodeType: NodeType.valNode, ports: [output], previewInteraction: PreviewInteraction.press)
}

