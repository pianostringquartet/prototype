//
//  GraphActions.swift
//  prototype
//
//  Created by cjc on 12/21/20.
//

import Foundation
import SwiftUI
import ReSwift

// For when user interacts with graph part of UI


/* ----------------------------------------------------------------
 Graph Actions
 ---------------------------------------------------------------- */


struct NodeDeletedAction: Action {
    let id: Int // the node deleted
}

struct NodeCreatedAction: Action {
//    let nodeType: NodeType
    
    // MUST HAVE ONE OF THESE AT LEAST
    
    // if uppercase or concat or optionPicker...
    var operation: Operation? = nil
    
    var portValue: PortValue? = nil
    
    
//    let id: Int // the node deleted
    
    
    
//    let
}


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

struct PlusButtonTappedAction: Action {
    let newValue: Bool
}



/* ----------------------------------------------------------------
 Handlers: (State, Action, Effects) -> State
 ---------------------------------------------------------------- */


/* ----------------------------------------------------------------
 Handlers: Graph actions
 ---------------------------------------------------------------- */


func handlePlusButtonTappedAction(state: AppState, action: PlusButtonTappedAction) -> AppState {
    var state = state
    log("state.shouldBlur was: \(state.shouldBlur)")
//    state.shouldBlur.toggle()
    state.shouldBlur = action.newValue
    log("state.shouldBlur is now: \(state.shouldBlur)")
    return state
}



func handleNodeCreatedAction(state: AppState, action: NodeCreatedAction) -> AppState {
    
    log("handleNodeCreatedAction")
    var state = state
    
    
    
    //
    let newNodeId: Int = nextNodeId(nodes: state.nodeModels)
    
    let defaultNewNode: NodeModel = stringValNode(id: newNodeId, value: "new node...")
    
    // HARDCODE the node to be added
//    let newNode: NodeModel = stringValNode(id: newNodeId, value: "ciao")
    var newNode: NodeModel
    
    if action.operation != nil {
        switch action.operation {
            case .concat:
                newNode = concatNodeModel(id: newNodeId)
            default:
                log("on some other case...")
                newNode = defaultNewNode
        }
    }
    else if action.portValue != nil {
        switch action.portValue! {
            case .string(let x):
                newNode = stringValNode(id: newNodeId, value: x)
            case .color(let x):
                newNode = colorValNode(id: newNodeId, value: x)
            default:
                log("some other port value cases...")
                newNode = defaultNewNode
        }
    }
    else {
        log("no matches at all?")
        newNode = defaultNewNode
    }
    
    state.nodeModels.append(newNode)
    state.shouldBlur = false
    
    return state
}


func handleNodeDeleted(state: AppState, action: NodeDeletedAction) -> AppState {
    log("handleNodeDeleted called")
    
    var state = state
    
    // have the id of the node deleted
    // steps:
    // 1. remove node itself
    //      (if node is viznode, also remove any associated intrxn val nodes)
    // 2. remove any edges that reference the node as origin or target

    
//    state.nodeModels.removeAll(where: { $0.id == action.id })
    
    // get rid of node itself
    state.nodeModels.removeAll(where: {$0.id == action.id})
    
    // get rid of any interaction val nodes that are for interactions for the deleted node
    state.nodeModels.removeAll(where: {
                                $0.nodeType == .valNode
                                    && $0.interactionModel != nil
                                    && $0.interactionModel!.forNodeId == action.id
    })
    
    
    
    state.edges.removeAll(where: { $0.from.nodeId == action.id || $0.to.nodeId == action.id})
    
    state = recalculateGraph(state: state)
    
    return state
}



// don't want to use PortModel.value, because the value could be outdated later?
// ... using PM for ActivePort should be okay, because value is most recent?
func handlePortTappedAction(state: AppState, action: PortTappedAction) -> AppState {
    log("handling portTappedAction")
    log("action.port.id: \(action.port.id)")
    log("state.activePM: \(state.activePM)")
    
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
        
        // for typography color text layer ONLY, the toPort nodeId is wrong
        let toPort: PortIdentifier = PortIdentifier(nodeId: action.port.nodeId,
                                                    portId: action.port.id,
                                                    isInput: action.port.portType == PortType.input)
        
        let newEdge: PortEdge = PortEdge(from: fromPort, to: toPort)
        let edgeAlreadyExists = state.edges.contains(newEdge)
        let flowValue: PortValue = state.activePM!.value
            
        
        
        if edgeAlreadyExists { // will remove edge and update ports
            log("handlePortTappedAction: edge already exists; will remove it")
            
            
            // if we remove an edge,
            state = removeEdgeAndUpdateNodes(state: state, newEdge: newEdge)
        }
        
        else { // ie edge does not already exist; will add it and update ports
            log("handlePortTappedAction: edge does not exist; will add it")
            
            state = addEdgeAndUpdateNodes(state: state, newEdge: newEdge, flowValue: flowValue, toPort: toPort)
        }
    }
    
    log("returning final state...")
    
    state = recalculateGraph(state: state)
    
    return state
}

// stuff we do anytime we add or remove an edge


func removeEdgeAndUpdateNodes(state: AppState, newEdge: PortEdge) -> AppState {
    log("removeEdgeAndUpdateNodes: edge exists; will remove it")
    
    var state = state
    
    state.edges.removeAll(where: { (edge: PortEdge) -> Bool in
        edge == newEdge
    })
    
    // Origami nodes' inputs do not change a connecting edge is removed
    return state
}


func addEdgeAndUpdateNodes(state: AppState, newEdge: PortEdge, flowValue: PortValue, toPort: PortIdentifier) -> AppState { // ie edge does not already exist; will add it and update ports

    log("addEdgeAndUpdateNodes: edge does not exist; will add it: newEdge: \(newEdge)")
    
    var state = state
    
    // add the new edge
    state.edges.append(newEdge)
    
    // update
    // an edge is always `output -> input` and `output` never changes
    
    // update the port
    // update the node model to use the new port
    // update the state to use the new node model
    
    // later?: look up the value in state rather than taking it from the action
    let updatedNode: NodeModel = updateNodePortAndPreviewModel(state: state, port: toPort, newValue: flowValue)
    
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
        let updatedNode2: NodeModel = updateNodePortAndPreviewModel(
            state: state,
            port: PortIdentifier(nodeId: outputPM.nodeId, portId: outputPM.id, isInput: false),
            newValue: calculatedValue)
//            newValue: operation(flowValue))
        
        let updatedNodes2: [NodeModel] = replace(ts: state.nodeModels, t: updatedNode2)
        
        state.nodeModels = updatedNodes2
    }
    
    return state // we added the edges and updated
}


