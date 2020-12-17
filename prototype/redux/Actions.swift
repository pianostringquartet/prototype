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
 Miniviewer Actions
 ---------------------------------------------------------------- */

// should change color in redux state, which flow to
struct TextTappedMiniviewAction: Action {
}


struct TextMovedMiniviewAction: Action {
    let textLayerId: Int // the specific TextLayer that was moved
    let newPosition: CGFloat
    let oldPosition: CGFloat
}


/* ----------------------------------------------------------------
 Graph Actions
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



/* ----------------------------------------------------------------
 Handlers: (State, Action, Effects) -> State
 ---------------------------------------------------------------- */

// ALL OF THIS IS HARDCODED RIGHT NOW TO USE THE SPECIFIC `valNode3`
func handleTextTappedMiniviewAction(state: AppState, textTapped: TextTappedMiniviewAction) -> AppState {
    
    log("handleTextTappedMiniviewAction called")

    //    log("doing NOTHING")
//    return state
    
    
    var state = state

    
    // HARDCODED -- the port-identifier for the `press` interaction node
    let pi: PortIdentifier = PortIdentifier(nodeId: valNodeId3, portId: 1, isInput: false)

    // retrieving the port from state
    let pm: PortModel = getPortModel(nodeModels: state.nodeModels, nodeId: valNodeId3, portId: 1)
    
    if case .bool(let x) = pm.value {
        let newValue: PortValue = .bool(toggleBool(x))
        
        log("handleTextTappedMiniviewAction newValue: \(newValue)")
        let updatedNode: NodeModel = updateNodePortModel(state: state, port: pi, newValue: newValue)
        let updatedNodes: [NodeModel] = replace(ts: state.nodeModels, t: updatedNode)
        state.nodeModels = updatedNodes
        state = recalculateGraph(state: state)
    }
    
    
    return state
}


// don't want to use PortModel.value, because the value could be outdated later?
// ... using PM for ActivePort should be okay, because value is most recent?
func handlePortTappedAction(state: AppState, action: PortTappedAction) -> AppState {
    log("handling portTappedAction... state.activePM: \(state.activePM)")
    
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
func recalculateGraph(state: AppState) -> AppState {
    var state = state
    
    state = flowValues(state: state, nodes: state.nodeModels, edges: state.edges)
    
    state = selfConsistency(state: state,
                            nodes: state.nodeModels.filter({ (n: NodeModel) -> Bool in
                                n.nodeType == .calcNode }))
    
    // need to reflow again because selfConsistency may have changed a node's inputs and outputs
    state = flowValues(state: state, nodes: state.nodeModels, edges: state.edges)
    
    state.activePM = nil
    
    return state
}



func isBasePreviewElement(pe: PreviewElement) -> Bool {
    log("isBasePreviewElement called")
    switch pe {
        case .text:
            return true
        case .typographyColor:
            return false
    }
}



// for some reason, when if baseVn.previewElement! etc. is added,
// we get "Function declares an opaque return type, but the return statements in its body do not have matching underlying types"
//func generateMiniview(state: AppState, dispatch: @escaping Dispatch) -> some View {

// `some View` is a specific view-type;
// instead, use `AnyView` since the view-type returned is dynamic
func generateMiniview(state: AppState, dispatch: @escaping Dispatch) -> AnyView {
    log("generateMiniview called")
    
    // state would contain these values?
    // iterate through vizModels/uiElems in state,
    // iterate through the (input) PortModels of the VizNodes;
    // these inputs contain eg. `Typography Text`, `Typography Color`
    
    let vns: [NodeModel] = state.nodeModels.filter { $0.nodeType == .vizNode }
    log("generateMiniview: vns: \(vns)")
    
    
//    let baseVn: NodeModel = vns.first { isBasePreviewElement(pe: $0.previewElement!) }!
    
    let baseVn: NodeModel = vns.first { (nm: NodeModel) -> Bool in
        log("baseVn: nm.previewElement: \(nm.previewElement)")
        return isBasePreviewElement(pe: nm.previewElement!)
    }!
    
    let modifierVn: NodeModel = vns.first { (nm: NodeModel) -> Bool in
        log("modifierVn: nm.previewElement: \(nm.previewElement)")
        return !isBasePreviewElement(pe: nm.previewElement!)
    }!
        
//        NodeModel = vns.first { !isBasePreviewElement(pe: $0.previewElement!) }!
    
    // ui base vs ui modifier
    // ui base = eg Text, Image
    // ui modifier = eg TypographyColor
    // grab every VizNode base
//    let miniviewBase = switch baseVn.previewElement! {
//        case .text:
//            return Text(baseVn.ports.first!.value)
//        case .typographyColor:
//            return nil
//    }
    
    // retrieve the correct base UI...
    if baseVn.previewElement! == .text {
        
        let display: String = getDisplayablePortValue(mpv: baseVn.ports.first!.value)
        
        let text = Text(display)
            .font(.largeTitle)
            .gesture(DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            log("onChanged inside generateMiniview")
                            dispatch(TextTappedMiniviewAction())
                            
                        }
                        .onEnded { _ in
                            log("onEnded inside generateMiniview")
                            dispatch(TextTappedMiniviewAction())
                            
                        }
            )

        // add any potential modifiers...
        if modifierVn.previewElement! == .typographyColor {
            
            if case .color(let x) = modifierVn.ports.first!.value {
                return AnyView(text.foregroundColor(colorFromString(x)).padding())
//                return AnyView(text.foregroundColor(x.color).padding())
            }
        }

        return AnyView(text.padding())
    }
    else {
        let defaultView = Text("No base UI found...").padding()
        return AnyView(defaultView)
    }
    
    
    // how do you identify the 'base' view (e.g. `Text`) vs a modifier (e.g. `TypographyColor`)?
    // how do you know which modifiers go with which bases, and in which order?
    // eg what if you have two different `TextLayers` in the graph, and want each to be a different color?

    // some modifiers obviously only apply to Text (e.g. TypographyColor)
    // other modifiers obviously only apply to Image
        
    // FOR NOW?: assume one Base (Text) and one modifier (Color)
  
}


func removeEdgeAndUpdateNodes(state: AppState,
                              newEdge: PortEdge
//                              ,
//                              flowValue: PortValue = .string("default...")
//                              flowValue: PortValue
) -> AppState {
    log("removeEdgeAndUpdateNodes: edge exists; will remove it")
    
    var state = state
    
    state.edges.removeAll(where: { (edge: PortEdge) -> Bool in
        edge == newEdge
    })
    
    // Origami nodes' inputs do not change a connecting edge is removed
    
//    let toPortIdentifier: PortIdentifier = newEdge.to
//
//    let updatedNode: NodeModel = updateNodePortModel(state: state, port: toPortIdentifier, newValue: flowValue)
//
//    let updatedNodes: [NodeModel] = replace(ts: state.nodeModels, t: updatedNode)
//
//    state.nodeModels = updatedNodes
//
//    let nodeType: NodeType = getNodeTypeForPort(nodeModels: state.nodeModels, nodeId: toPortIdentifier.nodeId, portId: toPortIdentifier.portId)
//
//    if nodeType == .calcNode {
//        log("removeEdgeAndUpdateNodes: will update a calcNode's output too")
//
//        // don't know a priori the PortIdent for the output
//        let outputPM: PortModel = getOutputPortModel(nodeModels: state.nodeModels, nodeId: toPortIdentifier.nodeId)
//
//        // node model with updated output
//        let updatedNode2: NodeModel = updateNodePortModel(
//            state: state,
//            port: PortIdentifier(nodeId: outputPM.nodeId, portId: outputPM.id, isInput: false),
//            newValue: flowValue) // NO OPERATION
//
//        let updatedNodes2: [NodeModel] = replace(ts: state.nodeModels, t: updatedNode2)
//
//        state.nodeModels = updatedNodes2
//    }
    

    
    return state
}


//func addEdgeAndUpdateNodes(state: AppState, newEdge: PortEdge, flowValue: String, toPort: PortIdentifier) -> AppState { // ie edge does not already exist; will add it and update ports
//func addEdgeAndUpdateNodes(state: AppState, newEdge: PortEdge, flowValue: PV, toPort: PortIdentifier) -> AppState { // ie edge does not already exist; will add it and update ports
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
//    state = flowValues(state: state, nodes: state.nodeModels, edges: state.edges)
//
//    state = selfConsistency(state: state,
//                            nodes: state.nodeModels.filter({ (n: NodeModel) -> Bool in
//                                n.nodeType == .calcNode }))
//    state = flowValues(state: state, nodes: state.nodeModels, edges: state.edges)
//
//
//    state.activePM = nil
    return state // we added the edges and updated
}


// ASSUMES: nodeType is .calcNode, and CALLED AFTER WE'VE UPDATED NODE'S INPUTS
//func calculateValue(nm: NodeModel, op: Operation, flowValue: String) -> String {
//func calculateValue(nm: NodeModel, op: Operation, flowValue: PV) -> PV {
func calculateValue(nm: NodeModel, op: Operation, flowValue: PortValue) -> PortValue {
    log("calculateValue called")
    
    let ascending = { (pm1: PortModel, pm2: PortModel) -> Bool in
        pm1.id < pm2.id
    }
    
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
