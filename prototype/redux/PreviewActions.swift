//
//  PreviewActions.swift
//  prototype
//
//  Created by cjc on 12/21/20.
//

import Foundation
import SwiftUI
import ReSwift


// For when user interacts with preview-window part of UI


/* ----------------------------------------------------------------
 Preview Actions
 ---------------------------------------------------------------- */

// should change color in redux state, which flow to
struct TextTappedMiniviewAction: Action {
    // when a text layer is tapped, you're also tapped a text layer NODE
    let nodeId: Int // viz node that was tapped
}


// for dragging
struct TextMovedMiniviewAction: Action {
    let textLayerId: Int // the id of the specific TextLayer viz node that was moved
    let position: CGSize
    let previousPosition: CGSize
}


/* ----------------------------------------------------------------
 Handlers: Preview actions
 ---------------------------------------------------------------- */

func handleTextTappedMiniviewAction(state: AppState, textTapped: TextTappedMiniviewAction) -> AppState {
    
    log("handleTextTappedMiniviewAction called")
    log("textTapped.nodeId: \(textTapped.nodeId)")
    
    var state = state
        
    
    // CANNOT ASSUME that the interaction 
    let interactionNode: NodeModel = getInteractionNode(nodes: state.nodeModels,
                                                        vizNodeId: textTapped.nodeId //,
                                                        // `press`, since this is text TAPPED
//                                                        previewInteraction: PreviewInteraction.press
    )
    
    // still HARDCODED the portId -- assumes that `press` val nodes only have single port...
    let pi: PortIdentifier = PortIdentifier(nodeId: interactionNode.id, portId: 1, isInput: false)
    let pm: PortModel = getPortModel(nodeModels: state.nodeModels, nodeId: interactionNode.id, portId: 1)
    

    log("handleTextTappedMiniviewAction pm: \(pm)") // ought to be 3...
    
    if case .bool(let x) = pm.value {
        let newValue: PortValue = .bool(toggleBool(x))
        
        log("handleTextTappedMiniviewAction newValue: \(newValue)")
        let updatedNode: NodeModel = updateNodePortAndPreviewModel(state: state, port: pi, newValue: newValue)
        let updatedNodes: [NodeModel] = replace(ts: state.nodeModels, t: updatedNode)
        state.nodeModels = updatedNodes
        state = recalculateGraph(state: state)
    }
    
    
    return state
}


// previously you maintained local state in the node view, which updated immediately;
// and you had a 'node moved' action, which updated the node's position in state
// ie `Node` is now `NodeModel`; `Ball` is now `NodeView`

// now, position will be on previewModel
// so updating a position will mean finding and updating a specific previewModel (on a given viz node)


func handleTextMovedMiniviewAction(state: AppState, textMoved: TextMovedMiniviewAction) -> AppState {
    log("handleTextMovedMiniviewAction called")
    
    var state = state
    
    let textLayerId: Int = textMoved.textLayerId
    

    // UPDATE VIZ NODE'S PREVIEW MODEL
    
    // To actually move the ui-element, we need to update its corresponding layer 3 viz node's Preview Model
    var vizNode: NodeModel = state.nodeModels.first { $0.id == textLayerId }!

    let updatedPreviewModel: PreviewModel = vizNode.previewModel!.updatePosition(
        position: textMoved.position,
        previousPosition: textMoved.previousPosition)
    
    vizNode.previewModel = updatedPreviewModel
    
    let updatedNode = vizNode
    
    log("handleTextMovedMiniviewAction: updatedNode: \(updatedNode)")
    
    let updatedNodes: [NodeModel] = replace(ts: state.nodeModels, t: updatedNode)
    state.nodeModels = updatedNodes
    
    
    // updated the position etc., but now have to also update the interaction val-node
    
    /// ASSUMES looking for `.drag` interaction val node
    var interactionNode: NodeModel = getInteractionNode(nodes: state.nodeModels,
                                                        vizNodeId: textLayerId
                                                        //,
                                                        // `drag`, since this is text DRAGGED
//                                                        previewInteraction: PreviewInteraction.drag
    )
    
    // still HARDCODED the portId -- assumes that `drag` val nodes only have single port...
    let pi: PortIdentifier = PortIdentifier(nodeId: interactionNode.id, portId: 1, isInput: false)
    
    let pm: PortModel = getPortModel(nodeModels: state.nodeModels, nodeId: interactionNode.id, portId: 1)
    
    
    // UPDATE INTERACTION VAL-NODE'S POSITION PORT
    
    if case .position(let x) = pm.value {
        let newValue: PortValue = .position(textMoved.position)
        
        let updatedNode2: NodeModel = updateNodePortAndPreviewModel(state: state, port: pi, newValue: newValue)
        let updatedNodes2: [NodeModel] = replace(ts: state.nodeModels, t: updatedNode2)
        state.nodeModels = updatedNodes2
    }
    
    
    // finally, recalculate the graph
    state = recalculateGraph(state: state)
    
    
    return state
}
