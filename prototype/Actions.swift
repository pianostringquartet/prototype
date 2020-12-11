//
//  Actions.swift
//  prototype
//
//  Created by cjc on 12/10/20.
//

import Foundation
import ReSwift
import SwiftUI


// ACTIONS AND HANDLERS


/* ----------------------------------------------------------------
 Actions
 ---------------------------------------------------------------- */


struct PortTappedAction: Action {
    let port: PortModel // contains portId, nodeId, portValue etc.
}



// later need to update this when adding back graph stuff
struct PortEdgeCreated: Action {
//    let to: (nodeId, portId)
//    let from: (nodeId, portId)
    let fromNode: Int
    let fromPort: Int
    
    let toNode: Int
    let toPort: Int
}


// a port was tapped;
// if NOT exists activePort/connectingPort,
//  then make this port the activePort
// else:
//  create an edge between this port and the existing activePort
struct PortTapped: Action {
    let port: PortIdentifier
//    let isInput: Bool
}



struct NodeMovedAction: Action {
    let graphId: Int
    let position: CGSize
    let node: Node
}

struct NodeCommittedAction: Action {
    let graphId: Int
    let position: CGSize
    let node: Node
}

struct NodeDeletedAction: Action {
    let graphId: Int
    let nodeId: Int
}

struct GraphDeletedAction: Action {
    let graphId: Int
}

struct EdgeAddedAction: Action {
    let graphId: Int
    let from: Int
    let to: Int
}

struct EdgeRemovedAction: Action {
    let graphId: Int
    let from: Int
    let to: Int
}


/* ----------------------------------------------------------------
 Handlers: (State, Action, Effects) -> State
 ---------------------------------------------------------------- */


// don't want to use PortModel.value, because the value could be outdated later?
// ... using PM for ActivePort should be okay, because value is most recent?
func handlePortTappedAction(state: AppState, action: PortTappedAction) -> AppState {
    log("handling portTappedAction... state.activePort: \(state.activePM)")
    
    var state: AppState = state // for easier mutation within function
    
    
    // if there's no active port, or this port is the active port,
    // we're just editing active port, not adding or removing edges
    if state.activePM == nil {
        log("setting new activePM: \(action.port)")
        state.activePM = action.port
        return state
    }
    else if state.activePM == action.port {
        log("turning off activePM")
        state.activePM = nil
        return state
    }
    
    // otherwise, we're adding or removing edges
    
    
    // disallowed edges
    else if (state.activePM!.nodeId == action.port.nodeId) || (state.activePM!.portType == PortType.input && action.port.portType == PortType.input ) {
        log("tried to create illegal edge")
        // ie not allowed: edge within a node or edge btwn two inputs
        return state // ie edge would be inside the node; not allowed
    }
    
    // will add or remove an edge
    else {
        log("will add or remove edge")
        // DO NOT want to capture old Port Values
        
        let fromPort: PortIdentifier = PortIdentifier(nodeId: state.activePM!.nodeId,
                                                      portId: state.activePM!.id,
                                                      isInput: state.activePM!.portType == PortType.input)
        
        let toPort: PortIdentifier = PortIdentifier(nodeId: action.port.nodeId,
                                                    portId: action.port.id,
                                                    isInput: action.port.portType == PortType.input)
        
        
        let newEdge: PortEdge = PortEdge(from: fromPort,
                                           to: toPort)
        let edgeAlreadyExists = state.edges.contains(newEdge)
        
        // better?: select these from state?
//        let fromValue: String = state.activePM!.value
        
        
        // CANNOT USE THE VALUE HERE, because e.g. the value will be the value of the tapped port, which might be an output
//        let toValue: String = action.port.value
//        let toValue: String = getPV(nodeModels: state.nodeModels, nodeId: toPort.nodeId, portId: toPort.portId)
        
        // ASSUMES: we always create edges from Output -> Input
        // ie the prev node's Output will always be the value flowing into the next node's Input
        let flowValue: String = state.activePM!.value
        
        
        if edgeAlreadyExists { // will remove edge and update ports
            log("handlePortTappedAction: edge already exists; will remove it")
            
            // prev: was updating calc-node, removing old node and adding updated node
            
            return removeEdgeAndUpdateNodes(state: state, newEdge: newEdge)
            
            
        }
        
        else { // ie edge does not already exist; will add it and update ports
            log("handlePortTappedAction: edge does not exist; will add it")
            
            return addEdgeAndUpdateNodes(state: state, newEdge: newEdge, flowValue: flowValue, toPort: toPort)
            
            // add the new edge
//            state.edges.append(newEdge)
//
//            // update
//            // an edge is always `output -> input` and `output` never changes
//
//            // update the port
//            // update the node model to use the new port
//            // update the state to use the new node model
//
//            // later?: look up the value in state rather than taking it from the action
//            let updatedNode: NodeModel = updateNodePortModel(state: state, port: toPort, newValue: flowValue)
//
//            let updatedNodes: [NodeModel] = replace(ts: state.nodeModels, t: updatedNode)
//
//            state.nodeModels = updatedNodes
//
//            // if input-port's node was an calc-node,
//            // we also update the output-port
//            // ASSUME: calc-node has SINGLE output port
//
//            let nodeType: NodeType = getNodeTypeForPort(nodeModels: state.nodeModels, nodeId: toPort.nodeId, portId: toPort.portId)
//
//            if nodeType == .calcNode {
//                log("will update a calcNode's output too")
//
//                // later?: customize operation etc.
//                let operation = { (s: String) -> String in s.uppercased() }
//
//                // don't know a priori the PortIdent for the output
//                let outputPM: PortModel = getOutputPortModel(nodeModels: state.nodeModels, nodeId: toPort.nodeId)
//
//                // node model with updated output
//                let updatedNode2: NodeModel = updateNodePortModel(
//                    state: state,
//                    port: PortIdentifier(nodeId: outputPM.nodeId, portId: outputPM.id, isInput: false),
//                    newValue: operation(flowValue))
//
//                let updatedNodes2: [NodeModel] = replace(ts: state.nodeModels, t: updatedNode2)
//
//                state.nodeModels = updatedNodes2
//            }
//
//            state.activePM = nil
//            return state // we added the edges and updated
        }
    }
    
    log("returning final state...")
    return state
}

// probably shares some overlap with addEdgeAndUpdateNodes,
// in the updating nodes part
// NOTE: flowValue is more like 'default value'
func removeEdgeAndUpdateNodes(state: AppState, newEdge: PortEdge, flowValue: String = "") -> AppState {
    log("removeEdgeAndUpdateNodes: edge exists; will remove it")
    
    var state = state
    
    state.edges.removeAll(where: { (edge: PortEdge) -> Bool in
        edge == newEdge
    })
    
    // WHEN EDGE REMOVED, want to reset the port values of the CalcNode
    
    // NOTE: newEdge is the edge we just removed;
    // can reuse it's vals here
//                    let fromPortIdentifier: PortIdentifier = newEdge.from
    let toPortIdentifier: PortIdentifier = newEdge.to

    let updatedNode: NodeModel = updateNodePortModel(state: state, port: toPortIdentifier, newValue: flowValue)
    
    let updatedNodes: [NodeModel] = replace(ts: state.nodeModels, t: updatedNode)
    
    state.nodeModels = updatedNodes
        
    let nodeType: NodeType = getNodeTypeForPort(nodeModels: state.nodeModels, nodeId: toPortIdentifier.nodeId, portId: toPortIdentifier.portId)
    
    if nodeType == .calcNode {
        log("removeEdgeAndUpdateNodes: will update a calcNode's output too")
        
        // don't know a priori the PortIdent for the output
        let outputPM: PortModel = getOutputPortModel(nodeModels: state.nodeModels, nodeId: toPortIdentifier.nodeId)
        
        // node model with updated output
        let updatedNode2: NodeModel = updateNodePortModel(
            state: state,
            port: PortIdentifier(nodeId: outputPM.nodeId, portId: outputPM.id, isInput: false),
            newValue: flowValue) // NO OPERATION
        
        let updatedNodes2: [NodeModel] = replace(ts: state.nodeModels, t: updatedNode2)
        
        state.nodeModels = updatedNodes2
    }
    
    
    // since we've removed an edge, we need to flow the values
    state = flowValues(state: state, nodes: state.nodeModels, edges: state.edges)
    
    state.activePM = nil
    
    
    return state
}


// ie one half og the
func addEdgeAndUpdateNodes(state: AppState, newEdge: PortEdge, flowValue: String, toPort: PortIdentifier) -> AppState { // ie edge does not already exist; will add it and update ports
    log("addEdgeAndUpdateNodes: edge does not exist; will add it")
    
    var state = state
    
    // add the new edge
    state.edges.append(newEdge)
    
    // update
    // an edge is always `output -> input` and `output` never changes
    
    // update the port
    // update the node model to use the new port
    // update the state to use the new node model
    
    // later?: look up the value in state rather than taking it from the action
    let updatedNode: NodeModel = updateNodePortModel(state: state, port: toPort, newValue: flowValue)
    
    let updatedNodes: [NodeModel] = replace(ts: state.nodeModels, t: updatedNode)
    
    state.nodeModels = updatedNodes
    
    // if input-port's node was an calc-node,
    // we also update the output-port
    // ASSUME: calc-node has SINGLE output port
    
    let nodeType: NodeType = getNodeTypeForPort(nodeModels: state.nodeModels, nodeId: toPort.nodeId, portId: toPort.portId)
    
    
    // UPDATING THE OUTPUT
    if nodeType == .calcNode {
        log("will update a calcNode's output too")
        
        // later?: customize operation etc.
//        let operation = { (s: String) -> String in s.uppercased() }
        
        let calculatedValue = calculateValue(
            nm: updatedNode, // should contain updated inputs...
            op: updatedNode.operation!, // REQUIRED
            flowValue: flowValue)
        // let calculatedValue = operation(flowValue)
        
        log("will use calculatedValue: \(calculatedValue)")
        
        
        // don't know a priori the PortIdent for the output
        let outputPM: PortModel = getOutputPortModel(nodeModels: state.nodeModels, nodeId: toPort.nodeId)
        
        // node model with updated output
        let updatedNode2: NodeModel = updateNodePortModel(
            state: state,
            port: PortIdentifier(nodeId: outputPM.nodeId, portId: outputPM.id, isInput: false),
            newValue: calculatedValue)
//            newValue: operation(flowValue))
        
        let updatedNodes2: [NodeModel] = replace(ts: state.nodeModels, t: updatedNode2)
        
        state.nodeModels = updatedNodes2
    }
    
    
    // since we've added an edge, we need to flow the values
    state = flowValues(state: state, nodes: state.nodeModels, edges: state.edges)
    
    
    
    state.activePM = nil
    return state // we added the edges and updated
}


// ASSUMES: nodeType is .calcNode, and CALLED AFTER WE'VE UPDATED NODE'S INPUTS
func calculateValue(nm: NodeModel, op: Operation, flowValue: String) -> String {
    log("calculateValue called")
    
    // we MUST have an operation
    
    // the actual function
//    let fn = operations[op]!
    
    // this node's inputs
    let inputs = nm.ports.filter { (pm: PortModel) -> Bool in
        pm.portType == .input
    }
    
    // the specific operation tells you how many inputs to look for
    
    switch op {
        case .identity:
            return flowValue
        
        // TODO: should be a reduce option; can take arbitrarily many inputs
        case .concat:
            log("matched on .concat")
            
            // will always have at least 2 inputs;
            // though their values may be empty-strings etc.
            
            let s1: String = inputs[0].value
            let s2: String = inputs[1].value
            if (s1 == "") || (s2 == "") {
                return "" // ie don't calculate yet
            }
            else {
                log("...will return: \(inputs[0].value + inputs[1].value)")
                return inputs[0].value + inputs[1].value
            }
            
//            log("...will return: \(inputs[0].value + inputs[1].value)")
//            return inputs[0].value + inputs[1].value
            
        case .uppercase:
            log("matched on .uppercase, will return: \(inputs[0].value.uppercased())")
            return inputs[0].value.uppercased()
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
    
    
    
    // for a given edge, set edge.target.portValue = edge.origin.portValue
    
//    let edge: PortEdge = edges.first!
    
    
//    let origin: PortIdentifier = edge.from
//    let originPM: PortModel = getPortModel(nodeModels: nodes, nodeId: origin.nodeId, portId: origin.portId)
//
//
//    let target: PortIdentifier = edge.to
//    let targetPM: PortModel = getPortModel(nodeModels: nodes, nodeId: target.nodeId, portId: target.portId)
//
//    // update target to use origin's value
//    let updatedNode: NodeModel = updateNodePortModel(state: state, port: target, newValue: originPM.value)
//    let updatedNodes: [NodeModel] = replace(ts: state.nodeModels, t: updatedNode)
//    state.nodeModels = updatedNodes
    
    return state
}



func getNodeTypeForPort(nodeModels: [NodeModel], nodeId: Int, portId: Int) -> NodeType {
    let isDesiredNode = { (nm: NodeModel) -> Bool in nm.id == nodeId}
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

    var node: NodeModel = nodeModels.first(where: isDesiredNode)!
    return node.ports.first(where: isDesiredPort)!
}



// difference: don't have portID, just nodeID
// ASSUMES there's only one output on a node
func getOutputPortModel(nodeModels: [NodeModel], nodeId: Int) -> PortModel {
    log("getOutputPortModel called")

    let isDesiredNode = { (nm: NodeModel) -> Bool in nm.id == nodeId}
    let isOutputPort = { (pm: PortModel) -> Bool in pm.portType == .output }
    
    var node: NodeModel = nodeModels.first(where: isDesiredNode)!
    
    return node.ports.first(where: isOutputPort)!
}



// returns a NodeModel with the port-specific PortModel.value updated to use newValue
func updateNodePortModel(state: AppState,
                         port: PortIdentifier,
                         newValue: String) -> NodeModel {
    log("updateNodePortModel called")
    log("newValue: \(newValue)")

    let isDesiredNode = { (nm: NodeModel) -> Bool in nm.id == port.nodeId}
    let isDesiredPort = { (pm: PortModel) -> Bool in pm.id == port.portId }
    
    // Find the old port
    // 1. find the desired node
    // 2. then find the node's port

    // ie must be able to find the node
    var oldNode: NodeModel = state.nodeModels.first(where: isDesiredNode)!
    
    var oldPort: PortModel = getPortModel(nodeModels: state.nodeModels,
                                          nodeId: port.nodeId,
                                          portId: port.portId)
    
    
    // Update the old port
    
    // .update is a Dart-style .copy method
    let updatedPort = oldPort.update(value: newValue)
    log("updateNodePortModel: updatedPort: \(updatedPort)")
    
//    return updatedPort
    
    
    let updatedPorts: [PortModel] = replace(ts: oldNode.ports, t: updatedPort)
    
    let updatedNode: NodeModel = oldNode.update(ports: updatedPorts)
    
    return updatedNode
}


func updateNodeOutputPortModel(state: AppState,
                         port: PortIdentifier,
                         newValue: String) -> NodeModel {
    log("updateNodeOutputPortModel called")
    log("newValue: \(newValue)")

    let isDesiredNode = { (nm: NodeModel) -> Bool in nm.id == port.nodeId}
    let isDesiredPort = { (pm: PortModel) -> Bool in pm.id == port.portId }
    
    // Find the old port
    // 1. find the desired node
    // 2. then find the node's port

    // ie must be able to find the node
    var oldNode: NodeModel = state.nodeModels.first(where: isDesiredNode)!
    
    var oldPort: PortModel = getPortModel(nodeModels: state.nodeModels,
                                          nodeId: port.nodeId,
                                          portId: port.portId)
    
    
    // Update the old port
    
    // .update is a Dart-style .copy method
    let updatedPort = oldPort.update(value: newValue)
    log("updateNodeOutputPortModel: updatedPort: \(updatedPort)")
    
//    return updatedPort
    
    
    let updatedPorts: [PortModel] = replace(ts: oldNode.ports, t: updatedPort)
    
    let updatedNode: NodeModel = oldNode.update(ports: updatedPorts)
    
    return updatedNode
}

// given a nodeId and portID, retrieve that port's value
//func getPV(nodeModels: [NodeModel], nodeId: Int, portId: Int) -> String {
//
//    nodeModels.
//}

// given a port identifier, get the port model

