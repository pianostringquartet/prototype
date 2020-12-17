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


// a port was tapped;
// if NOT exists activePort/connectingPort,
//  then make this port the activePort
// else:
//  create an edge between this port and the existing activePort
//struct PortTapped: Action {
//    let port: PortIdentifier
////    let isInput: Bool
//}
//

//
//struct NodeMovedAction: Action {
//    let graphId: Int
//    let position: CGSize
//    let node: Node
//}
//
//struct NodeCommittedAction: Action {
//    let graphId: Int
//    let position: CGSize
//    let node: Node
//}
//
//struct NodeDeletedAction: Action {
//    let graphId: Int
//    let nodeId: Int
//}
//
//struct GraphDeletedAction: Action {
//    let graphId: Int
//}
//
//struct EdgeAddedAction: Action {
//    let graphId: Int
//    let from: Int
//    let to: Int
//}
//
//struct EdgeRemovedAction: Action {
//    let graphId: Int
//    let from: Int
//    let to: Int
//}





/* ----------------------------------------------------------------
 Handlers: (State, Action, Effects) -> State
 ---------------------------------------------------------------- */

// ALL OF THIS IS HARDCODED RIGHT NOW TO USE THE SPECIFIC `valNode3`
func handleTextTappedMiniviewAction(state: AppState, textTapped: TextTappedMiniviewAction) -> AppState {
    
    log("handleTextTappedMiniviewAction called")
    log("doing NOTHING")
    return state
    
//
//
//    var state = state
//
//    let pi: PortIdentifier = PortIdentifier(nodeId: valNodeId3, portId: 1, isInput: false)
//
//    // with a fn like getPortModel... with just the portid and nodeid, you would not know the type
//    // of the port's value
//
//    let pm: PortModel = getPortModel(nodeModels: state.nodeModels, nodeId: valNodeId3, portId: 1)
//
//    // e.g. toggle boolean value
////    let newValue: String = pm.value == "false" ? "true" : "false"
//
//    // should not be hardcoded? ... basically, want to toggle the value
//
//    // this is not good -- doing all this downcasting...
//    let newValue: BoolPV = (pm.value as! BoolPV).value == false ? BoolPV(true) : BoolPV(false)
//
//
//    log("handleTextTappedMiniviewAction newValue: \(newValue)")
//
//    let updatedNode: NodeModel = updateNodePortModel(state: state, port: pi, newValue: newValue)
//
//    let updatedNodes: [NodeModel] = replace(ts: state.nodeModels, t: updatedNode)
//
//    state.nodeModels = updatedNodes
//    state = recalculateGraph(state: state)
//
//    return state
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
        
        let toPort: PortIdentifier = PortIdentifier(nodeId: action.port.nodeId,
                                                    portId: action.port.id,
                                                    isInput: action.port.portType == PortType.input)
        
        
        let newEdge: PortEdge = PortEdge(from: fromPort,
                                           to: toPort)
        let edgeAlreadyExists = state.edges.contains(newEdge)
        
//        let flowValue: String = state.activePM!.value
        
        // the value that will flow could be a bool OR a string
        // ... so the flowValue should just be PV
//        let flowValue: PV = state.activePM!.value
        let flowValue: MPV = state.activePM!.value
            
        
        
        if edgeAlreadyExists { // will remove edge and update ports
            log("handlePortTappedAction: edge already exists; will remove it")
            
            // prev: was updating calc-node, removing old node and adding updated node
            
//            return removeEdgeAndUpdateNodes(state: state, newEdge: newEdge)
            
            state = removeEdgeAndUpdateNodes(state: state, newEdge: newEdge)
        }
        
        else { // ie edge does not already exist; will add it and update ports
            log("handlePortTappedAction: edge does not exist; will add it")
            
//            return addEdgeAndUpdateNodes(state: state, newEdge: newEdge, flowValue: flowValue, toPort: toPort)
            state = addEdgeAndUpdateNodes(state: state, newEdge: newEdge, flowValue: flowValue, toPort: toPort)
        }
    }
    
    
    log("returning final state...")
    
    // only return final state here
    //
    
    // THINGS WE HAVE TO DO ANYTIME AN EDGE WAS ADDED OR REMOVED
    
    // since we've removed an edge, we need to flow the values
//    state = flowValues(state: state, nodes: state.nodeModels, edges: state.edges)
//
//    state = selfConsistency(state: state,
//                            nodes: state.nodeModels.filter({ (n: NodeModel) -> Bool in
//                                n.nodeType == .calcNode }))
//
//    // need to reflow again because selfConsistency may have changed a node's inputs and outputs
//    state = flowValues(state: state, nodes: state.nodeModels, edges: state.edges)
//
//
//    state.activePM = nil
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

// generate a miniview View from the viz nodes in the most updated graph
// AppState needs to be able to contain a SwiftUI View

// if we assume state can't hold

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
    
//    // retrieve the correct base UI...

    if baseVn.previewElement! == .text {

//        let text: some View = Text(baseVn.ports.first!.value) // defaults to empty string?
//        let text = Text(baseVn.ports.first!.value) // defaults to empty string?
        
//        let display: String = (baseVn.ports.first!.value as! StringPV).value
        let display: String = "hardcoded TextLayer"
        
        let text = Text(display) // defaults to empty string?
            .font(.largeTitle)
            
            // long press
//            .gesture(LongPressGesture()
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

//            .onTapGesture(count: 1) {
//                log("onTapGesture inside generateMiniview")
//                dispatch(TextTappedMiniviewAction())
//            }

        // add any potential modifiers...
        if modifierVn.previewElement! == .typographyColor {

//            let color: Color = modifierVn.ports.first!.value == "Green" ? Color.green : Color.purple
//            var color: Color
            var color: Color = Color.red
//            switch modifierVn.ports.first!.value {
//            switch (modifierVn.ports.first!.value as! StringPV).value {
//                case "Green":
//                    color = Color.green
//                case "Purple":
//                    color = Color.purple
//                default:
//                    color = Color.red
//            }
//

//            return text.foregroundColor(color).padding()
            return AnyView(text.foregroundColor(color).padding())
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
    
    
//    return TouchableText(text: text, color: color, dispatch: dispatch).padding()
}


// you have to be able


// probably shares some overlap with addEdgeAndUpdateNodes,
// in the updating nodes part
// NOTE: flowValue is more like 'default value'


//func removeEdgeAndUpdateNodes(state: AppState, newEdge: PortEdge, flowValue: String = "") -> AppState {
//func removeEdgeAndUpdateNodes(state: AppState, newEdge: PortEdge) -> AppState {

// SHOULD IMPLEMENT defaultValue on each PortValue type
func removeEdgeAndUpdateNodes(state: AppState,
                              newEdge: PortEdge,
//                              flowValue: PV = StringPV("default...")) -> AppState {
                              flowValue: MPV = MPV.StringMPV("default...")) -> AppState {
    log("removeEdgeAndUpdateNodes: edge exists; will remove it")
    
    var state = state
    
    state.edges.removeAll(where: { (edge: PortEdge) -> Bool in
        edge == newEdge
    })
    
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
    
    
//    // since we've removed an edge, we need to flow the values
//    state = flowValues(state: state, nodes: state.nodeModels, edges: state.edges)
//
//    state = selfConsistency(state: state,
//                            nodes: state.nodeModels.filter({ (n: NodeModel) -> Bool in
//                                n.nodeType == .calcNode }))
//
//    // need to reflow again because selfConsistency may have changed a node's inputs and outputs
//    state = flowValues(state: state, nodes: state.nodeModels, edges: state.edges)
//
//
//    state.activePM = nil
    
    
    return state
}


//func addEdgeAndUpdateNodes(state: AppState, newEdge: PortEdge, flowValue: String, toPort: PortIdentifier) -> AppState { // ie edge does not already exist; will add it and update ports
//func addEdgeAndUpdateNodes(state: AppState, newEdge: PortEdge, flowValue: PV, toPort: PortIdentifier) -> AppState { // ie edge does not already exist; will add it and update ports
func addEdgeAndUpdateNodes(state: AppState, newEdge: PortEdge, flowValue: MPV, toPort: PortIdentifier) -> AppState { // ie edge does not already exist; will add it and update ports

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
func calculateValue(nm: NodeModel, op: Operation, flowValue: MPV) -> MPV {
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
            log("doing nothing!")
            return MPV.StringMPV("implement me...")
//
//            // will always have at least 2 inputs;
//            // though their values may be empty-strings etc.
//
////            let s1: String = inputs[0].value
////            let s2: String = inputs[1].value
////            let s1: String = (inputs[0].value as! StringPV).value
////            let s2: String = (inputs[1].value as! StringPV).value
//
////            let s1: String = (inputs[0].value as! MPV.StringMPV).value
////            let s2: String = (inputs[1].value as! MPV.StringMPV).value
//
//            let s1: String = (inputs[0].value).value as! String
//            let s2: String = (inputs[1].value as! MPV.StringMPV).value
//
//
//            if (s1 == "") || (s2 == "") {
////                return "" // ie don't calculate yet
//                log("will not concat...")
////                return StringPV("")
//                return MPV.StringMPV("")
//            }
//            else {
////                log("...will return: \(inputs[0].value + inputs[1].value)")
//                log("will concat...")
//                //                return MPV.StringMPV(s1 + s2)
//                return MPV.StringMPV(s1 + s2)
////                return inputs[0].value + inputs[1].value
//            }
//
////            log("...will return: \(inputs[0].value + inputs[1].value)")
////            return inputs[0].value + inputs[1].value
//
//        case .uppercase:
////            log("matched on .uppercase, will return: \(inputs[0].value.uppercased())")
//            log("matched on .uppercase")
////            return inputs[0].value.uppercased()
////            return StringPV((inputs[0].value as! StringPV).value.uppercased())
//            return MPV.StringMPV((inputs[0].value as! MPV.StringMPV).value.uppercased())
//
//
//
        case .optionPicker:
            log("matched on .optionPicker")
            log("doing nothing...")
            return MPV.StringMPV("Purple")
            
//            // ie flip the value
//            log("inputs: \(inputs)")
////            let boolPort = inputs[0].value
////            let boolPort: Bool = (inputs[0].value as! BoolPV).value
//            let boolPort: Bool = (inputs[0].value as! MPV.BoolMPV).value
//            log("boolPort: \(boolPort)")
////            let calculatedColor: String = boolPort == "true" ? inputs[1].value : inputs[2].value
//
//            // technically, you know this can be BoolPV;
//            // but the type of inputs[1].value is not known by the compiler...
////            let calculatedColor: PV = boolPort ? inputs[1].value : inputs[2].value
//            let calculatedColor: MPV = boolPort ? inputs[1].value : inputs[2].value
//            log("calculatedColor: \(calculatedColor)")
//            return calculatedColor
        
        case .uppercase:
            log("revised: matched on .uppercase")
            return MPV.StringMPV("UPPERCASE CALLED")
//            switch inputs.first!.value {
//                case <#pattern#>:
//                    <#code#>
//                default:
//                    <#code#>
//            }
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
    
//    let node: NodeModel = nodes.first!
    
    nodes.forEach { (node: NodeModel) in
        
        log("selfConsistency: node.id \(node.id), node type \(node.nodeType)")
        
        // we only recalculate the value if there's an operation / it's a calcNode
        if node.operation != nil && node.nodeType == .calcNode {
            
            let inputs: [PortModel] = node.ports.filter { $0.portType == .input && $0.nodeId == node.id }
            
            // assumes single output; output port modl for just this node
            let output: PortModel = node.ports.first { $0.portType == .output && $0.nodeId == node.id }!
            
            // `inputs[0].value` is just some simple default value
//            let newOutputValue: String = calculateValue(nm: node, op: node.operation!, flowValue: inputs[0].value)
            let newOutputValue: MPV = calculateValue(nm: node, op: node.operation!, flowValue: inputs[0].value)
            
            let updatedNode2: NodeModel = updateNodePortModel(
                state: state,
                port: PortIdentifier(nodeId: output.nodeId, portId: output.id, isInput: false),
                newValue: newOutputValue)
    //            newValue: operation(flowValue))
            
            let updatedNodes2: [NodeModel] = replace(ts: state.nodeModels, t: updatedNode2)
            
            state.nodeModels = updatedNodes2
            
            
        } else {
            log("selfConsistency: encountered a non-calc node?!: \(node)")
        }
        
    }
    
    
    
    // gr
//    the input port models for just this node
    
    
    
    
    
    return state
}


