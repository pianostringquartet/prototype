//
//  Helpers.swift
//  prototype
//
//  Created by cjc on 12/15/20.
//

import Foundation
import ReSwift
import SwiftUI


let ascending = { (pm1: PortModel, pm2: PortModel) -> Bool in
    pm1.id < pm2.id
}

let ascendingNodes = { (nm1: NodeModel, nm2: NodeModel) -> Bool in nm1.id < nm2.id }

func toggleBool(_ bool: Bool) -> Bool {
    return bool ? false : true
}

func colorFromString(_ s: String) -> Color {
    switch s {
        case greenColorString:
            return Color.green
        case purpleColorString:
            return Color.purple
        default:
            log("colorFromString default...")
            return Color.gray
    }
}


func getDisplayablePortValue(mpv: PortValue) -> String {
    switch mpv {
        case .string(let x):
            return x
        case .bool(let x):
            return x.description
        case .color(let x):
            return x.description
        case .int(let x):
            return x.description
        case .position(let x):
            return "(x \(x.width), y \(x.height))"
    }
}



func hasEdge(edges: [PortEdge], pm: PortModel, isInput: Bool) -> Bool {
    edges.contains { (edge: PortEdge) -> Bool in
        
        let pmIdentifier: PortIdentifier = PortIdentifier(nodeId: pm.nodeId,
                                                          portId: pm.id,
                                                          // irrelevant...
                                                          isInput: isInput)
        return (edge.from == pmIdentifier || edge.to == pmIdentifier)
    }
}


func getNodeTypeForPort(nodeModels: [NodeModel], nodeId: Int, portId: Int) -> NodeType {
    let isDesiredPort = { (pm: PortModel) -> Bool in pm.id == portId }
    
    let nodeModel: NodeModel = nodeModels.first { (nm: NodeModel) -> Bool in
        nm.id == nodeId && nm.ports.contains(where: isDesiredPort)
    }!
    
    return nodeModel.nodeType
}


func isInteractionValNodeForVizNode(vizNodeId: Int, node: NodeModel) -> Bool {
    return node.nodeType == .valNode
        && node.interactionModel != nil
        && node.interactionModel!.forNodeId == vizNodeId
}

// given a nodeId for a viz layer,
// return the interaction val node for that model
// ... we're interested in a specific interaction too

// ASSUMES a given viz node has a SINGLE associated val interaction node
func getInteractionNode(nodes: [NodeModel], vizNodeId: Int
//                        previewInteraction: PreviewInteraction
) -> NodeModel {
    
    return nodes.first {
        $0.nodeType == .valNode
        && $0.interactionModel != nil
        && $0.interactionModel!.forNodeId == vizNodeId
    }!
    
}

// useful for retrieving values too
// can be used for getting either input- OR output- ports, as long as you have the nodeId and portId
func getPortModel(nodeModels: [NodeModel], nodeId: Int, portId: Int) -> PortModel {
    log("getPortModel called")
    log("nodeId \(nodeId), portId \(portId)")

    let isDesiredNode = { (nm: NodeModel) -> Bool in nm.id == nodeId}
    let isDesiredPort = { (pm: PortModel) -> Bool in pm.id == portId }
    
    let node: NodeModel = nodeModels.first(where: isDesiredNode)!
    return node.ports.first(where: isDesiredPort)!
}



// difference: don't have portID, just nodeID
// ASSUMES there's only one output on a node
func getOutputPortModel(nodeModels: [NodeModel], nodeId: Int) -> PortModel {
    log("getOutputPortModel called")
    log("nodeId \(nodeId)")

    let isDesiredNode = { (nm: NodeModel) -> Bool in nm.id == nodeId}
    let isOutputPort = { (pm: PortModel) -> Bool in pm.portType == .output }
    
    let node: NodeModel = nodeModels.first(where: isDesiredNode)!
    
    return node.ports.first(where: isOutputPort)!
}


func updateNodePortAndPreviewModel(state: AppState, port: PortIdentifier, newValue: PortValue) -> NodeModel {
    log("updateNodePortModel called")
    log("port: \(port)")
    log("newValue: \(newValue)")

    let isDesiredNode = { (nm: NodeModel) -> Bool in nm.id == port.nodeId}
    
    // Find the old port
    // 1. find the desired node
    // 2. then find the node's port

    // ie must be able to find the node
    let oldNode: NodeModel = state.nodeModels.first(where: isDesiredNode)!
    
    let oldPort: PortModel = getPortModel(nodeModels: state.nodeModels,
                                          nodeId: port.nodeId,
                                          portId: port.portId)
    
    
    // Update the old port
    let updatedPort = oldPort.update(value: newValue)
    
    log("updateNodePortModel: updatedPort: \(updatedPort)")
    
    let updatedPorts: [PortModel] = replace(ts: oldNode.ports, t: updatedPort)
    
    // ports updated
    let updatedNode: NodeModel = oldNode.update(ports: updatedPorts)
        
    // preview mode
    if oldNode.nodeType == .vizNode {
        log("we have a viz node...")
        
        if case .position(let x) = newValue {
            log("... and a position value")
            let updatedPM: PreviewModel = oldNode.previewModel!.updatePosition(position: x)
            let updatedNode2: NodeModel = updatedNode.update(previewModel: updatedPM)
            return updatedNode2
        }
    }
    
    return updatedNode
}


func recalculateGraph(state: AppState) -> AppState {
    var state = state
    
    state = flowValues(state: state, nodes: state.nodeModels, edges: state.edges)
    
    // if there are no calc nodes, then skip this step
    
    let calcNodes = state.nodeModels.filter({ (n: NodeModel) -> Bool in
                                                n.nodeType == .calcNode })
    if !calcNodes.isEmpty {
        log("there are calc nodes, so will call selfConsistency")
        state = selfConsistency(state: state, nodes: calcNodes)
    }
    
    // need to reflow again because selfConsistency may have changed a node's inputs and outputs
    state = flowValues(state: state, nodes: state.nodeModels, edges: state.edges)
    
    state.activePM = nil
    
    return state
}

