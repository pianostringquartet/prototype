//
//  Helpers.swift
//  prototype
//
//  Created by cjc on 12/15/20.
//

import Foundation
import ReSwift
import SwiftUI


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


// can instead be method on MPV type?
func getDisplayablePortValue(mpv: PortValue) -> String {
    switch mpv {
        case .string(let x):
            return x
        case .bool(let x):
            return x.description
        case .color(let x):
            // what IS a description for a color?
            return x.description
//            return x.color.description
        case .int(let x):
            return x.description
    }
}


// does this output/input port have an edge coming out of / into it?
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
//    let isDesiredNode = { (nm: NodeModel) -> Bool in nm.id == nodeId}
    let isDesiredPort = { (pm: PortModel) -> Bool in pm.id == portId }
    
    let nodeModel: NodeModel = nodeModels.first { (nm: NodeModel) -> Bool in
        nm.id == nodeId && nm.ports.contains(where: isDesiredPort)
    }!
    
    return nodeModel.nodeType
}


// useful for retrieving values too
// can be used for getting either input- OR output- ports, as long as you have the nodeId and portId
func getPortModel(nodeModels: [NodeModel], nodeId: Int, portId: Int) -> PortModel {
    log("getPortModel called")

    let isDesiredNode = { (nm: NodeModel) -> Bool in nm.id == nodeId}
    let isDesiredPort = { (pm: PortModel) -> Bool in pm.id == portId }
    
    let node: NodeModel = nodeModels.first(where: isDesiredNode)!
    return node.ports.first(where: isDesiredPort)!
}



// difference: don't have portID, just nodeID
// ASSUMES there's only one output on a node
func getOutputPortModel(nodeModels: [NodeModel], nodeId: Int) -> PortModel {
    log("getOutputPortModel called")

    let isDesiredNode = { (nm: NodeModel) -> Bool in nm.id == nodeId}
    let isOutputPort = { (pm: PortModel) -> Bool in pm.portType == .output }
    
    let node: NodeModel = nodeModels.first(where: isDesiredNode)!
    
    return node.ports.first(where: isOutputPort)!
}



// returns a NodeModel with the port-specific PortModel.value updated to use newValue
func updateNodePortModel(state: AppState,
                         port: PortIdentifier,
//                         newValue: String) -> NodeModel {
                         // now have to use some PV
//                         newValue: PV) -> NodeModel {
                         newValue: PortValue) -> NodeModel {
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
    
    let updatedNode: NodeModel = oldNode.update(ports: updatedPorts)
    
    return updatedNode
}


func updateNodeOutputPortModel(state: AppState,
                         port: PortIdentifier,
                         newValue: PortValue) -> NodeModel {
    log("updateNodeOutputPortModel called")
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
    
    // .update is a Dart-style .copy method
    let updatedPort = oldPort.update(value: newValue)
    log("updateNodeOutputPortModel: updatedPort: \(updatedPort)")
    
    let updatedPorts: [PortModel] = replace(ts: oldNode.ports, t: updatedPort)
    
    let updatedNode: NodeModel = oldNode.update(ports: updatedPorts)
    
    return updatedNode
}

