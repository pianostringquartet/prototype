//
//  Reducer.swift
//  prototype
//
//  Created by cjc on 11/8/20.
//

import Foundation
import SwiftUI
import ReSwift


/* ----------------------------------------------------------------
 Reducer
 ---------------------------------------------------------------- */


// preferably -- this should be more general?
// or, at least one hardcoded action per miniviewer Interactin type?
// e.g. MiniviewTextTapped, MiniviewTextLongPressed
func handleTextTappedMiniviewAction(state: AppState, textTapped: TextTappedMiniviewAction) -> AppState {
    
    log("handleTextTappedMiniviewAction called")
    
    var state = state
    
    // where is the 'Green' value stored?
    // it's in the Node 6 typography color (input) PORT
    // ... so you have to change that value
    
    let vns: [NodeModel] = state.nodeModels.filter { $0.nodeType == .vizNode }
    
//    let color: Color = modifierVn.ports.first!.value == "Green" ? Color.purple : Color.green
    let modifierVn: NodeModel = vns.first { (nm: NodeModel) -> Bool in
        log("handleTextTappedMiniviewAction: nm.previewElement: \(nm.previewElement)")
        return !isBasePreviewElement(pe: nm.previewElement!)
    }!
    
    // HARDCODED...
    let pi: PortIdentifier = PortIdentifier(nodeId: vizNodeId2, portId: 1, isInput: true)
        
    let newValue: String = modifierVn.ports.first!.value == "Green" ? "Purple" : "Green"
    log("handleTextTappedMiniviewAction newValue: \(newValue)")
    
    let updatedNode: NodeModel = updateNodePortModel(state: state, port: pi, newValue: newValue)
    
    let updatedNodes: [NodeModel] = replace(ts: state.nodeModels, t: updatedNode)
    
    state.nodeModels = updatedNodes
    
//    let updatedPortModel: PortModel =

    
    return state
}


func reducer(action: Action, state: AppState?) -> AppState {
    var defaultState: AppState = AppState()
    if let persistedState = pullState() {
        defaultState = persistedState
    }
    
    var state = state ?? defaultState
    
    switch action {
        
        case let portTapped as PortTappedAction:
            var newState = handlePortTappedAction(state: state, action: portTapped)
            log("newState from PortTappedAction: \(newState)")
            state = newState
        
        case let textTapped as TextTappedMiniviewAction:
            var newState = handleTextTappedMiniviewAction(state: state, textTapped: textTapped)
            log("newState from TextTappedMiniviewAction: \(newState)")
            state = newState
            
        default:
            break
    }

    // 
    

    // persist state to UserDefaults
    saveState(state: state)
    return state
}


/* ----------------------------------------------------------------
 State/domain helpers
 ---------------------------------------------------------------- */


func nodesForGraph(graphId: Int, nodes: [Node]) -> [Node] {
    return nodes.filter({ (n: Node) -> Bool in n.graphId == graphId
    })
}

func connectionsForGraph(graphId: Int, connections: [Connection]) -> [Connection] {
    return connections.filter({ (conn: Connection) -> Bool in conn.graphId == graphId
    })
}

func nextNodeId(nodes: [Node]) -> Int {
    return nodes.isEmpty ?
        1 :
        nodes.max(by: {(n1: Node, n2: Node) -> Bool in n1.nodeId < n2.nodeId})!.nodeId + 1
    
}

func nextGraphId(graphs: [Graph]) -> Int {
    return graphs.isEmpty ? 1 :
        graphs.max(by: {(g1: Graph, g2: Graph) -> Bool in g1.graphId < g2.graphId})!.graphId + 1
}


/* ----------------------------------------------------------------
 Persisting state via UserDefaults
 ---------------------------------------------------------------- */

let savedDataKey = "SavedData"

func saveState(state: AppState) -> () {
    if let encoded = try? JSONEncoder().encode(state) {
        UserDefaults.standard.set(encoded, forKey: savedDataKey)
    }
}

func pullState() -> AppState? {
    if let data = UserDefaults.standard.data(forKey: savedDataKey) {
        if let decodedState = try? JSONDecoder().decode(AppState.self, from: data) {
          return decodedState
        }
    }
    return nil
}
