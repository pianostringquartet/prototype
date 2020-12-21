//
//  GraphHelpers.swift
//  prototype
//
//  Created by cjc on 12/21/20.
//

import Foundation
import SwiftUI
import ReSwift


// Helpers primarily for the graph in redux state



// ASSUMES: nodeType is .calcNode, and CALLED AFTER WE'VE UPDATED NODE'S INPUTS
func calculateValue(nm: NodeModel, op: Operation, flowValue: PortValue) -> PortValue {
    log("calculateValue called")
    
    // this node's inputs
    let inputs = nm.ports.filter { (pm: PortModel) -> Bool in
        pm.portType == .input
    }.sorted(by: ascending)
    
    // the specific operation tells you how many inputs to look for
    
    switch op {
        case .identity:
            return flowValue
        
        // TODO: should be a reduce option; can take arbitrarily many inputs
        case .concat:
            log("matched on .concat")
            
            switch (inputs[0].value, inputs[1].value) {
                case (.string(let s1), .string(let s2)):
                    if (s1 == "") || (s2 == "") {
                        log("will not concat...")
                        return PortValue.string("")
                    }
                    else {
                        log("will concat...")
                        return PortValue.string(s1 + s2)
                    }
                default:
                    return PortValue.string("")
            }
            
            
        case .uppercase:
            log("matched on .uppercase")
            switch inputs[0].value {
                case .string(let x):
                    return .string(x.uppercased())
                default:
                    return .string("")
            }
            

        // .optionPickers need to be generalized --
        // e.g. for Ints, Colors, Strings, etc. -- not just any
        // optionPicker should be of type MPV (PortValue)
        case .optionPicker:
            log("matched on .optionPicker")
//            return MPV.StringMPV("Purple")
            switch inputs[0].value {
                case .bool(let x):
//                    return .string(x == true ? "Green" : "Purple")
                    return .color(x == true ? trueColorString : falseColorString)
//                    return .color(x == true ? trueColor2 : falseColor2)
                default:
                    log(".optionPicker default...")
//                    return .string("Purple")
//                    return .color(falseColor)
//                    return .color(falseColor2)
                    return .color(falseColorString)
            }
    }
}

//

// make the values 'flow' across the graph
// Origami does this whenever an output changes (though currently you and origami change `output` at different times


// don't update ALL data, just the edges after the startPoint
// probably a better implementation?



func flowValues(state: AppState, nodes: [NodeModel], edges: [PortEdge]) -> AppState {
    log("flowValues called")
    
    var state = state
    
    edges.forEach { (edge: PortEdge) in
        
        log("flowValues: edge: \(edge)")
        
        let origin: PortIdentifier = edge.from
        let originPM: PortModel = getPortModel(nodeModels: nodes, nodeId: origin.nodeId, portId: origin.portId)
        
        
        let target: PortIdentifier = edge.to
        let targetPM: PortModel = getPortModel(nodeModels: nodes, nodeId: target.nodeId, portId: target.portId)
        
        // update target to use origin's value
        let updatedNode: NodeModel = updateNodePortModel(state: state, port: target, newValue: originPM.value)
        let updatedNodes: [NodeModel] = replace(ts: state.nodeModels, t: updatedNode)
        
        state.nodeModels = updatedNodes
    }
    
    return state
}


// self-consistency
// iterate through every node make sure output is consistent with operation(inputs)
// ie rerun calculateValue
// BETTER?: nodes should only be calcNodes
func selfConsistency(state: AppState, nodes: [NodeModel]) -> AppState {
    log("selfConsistency called")
    
    var state = state
        
    nodes.forEach { (node: NodeModel) in
        
        log("selfConsistency: node.id \(node.id), node type \(node.nodeType)")
        
        // we only recalculate the value if there's an operation / it's a calcNode
        if node.operation != nil && node.nodeType == .calcNode {
            
            let inputs: [PortModel] = node.ports.filter { $0.portType == .input && $0.nodeId == node.id }
            
            // assumes single output; output port model for just this node
            let output: PortModel = node.ports.first { $0.portType == .output && $0.nodeId == node.id }!
            
            // `inputs[0].value` is just some simple default value
            let newOutputValue: PortValue = calculateValue(nm: node, op: node.operation!, flowValue: inputs[0].value)
            
            let updatedNode2: NodeModel = updateNodePortModel(
                state: state,
                port: PortIdentifier(nodeId: output.nodeId, portId: output.id, isInput: false),
                newValue: newOutputValue)
    
            let updatedNodes2: [NodeModel] = replace(ts: state.nodeModels, t: updatedNode2)
            
            state.nodeModels = updatedNodes2
            
        } else {
            log("selfConsistency: encountered a non-calc node?!: \(node)")
        }
        
    }
    
    return state
}

