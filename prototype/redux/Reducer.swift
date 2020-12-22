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


func reducer(action: Action, state: AppState?) -> AppState {
    
    log("reducer called")
    
    var defaultState: AppState = AppState()
    if let persistedState = pullState() {
        defaultState = persistedState
    }
    
    var state = state ?? defaultState
    
    switch action {
        
        // GRAPH ACTIONS
        
        case let portTapped as PortTappedAction:
            state = handlePortTappedAction(state: state, action: portTapped)
//            log("newState from PortTappedAction: \(newState)")
//            state = newState
        
        
        case let nodeDeleted as NodeDeletedAction:
            state = handleNodeDeleted(state: state, action: nodeDeleted)
        
        case let nodeCreated as NodeCreatedAction:
            state = handleNodeCreatedAction(state: state, action: nodeCreated)
        
        
        // PREVIEW ACTIONS
        
        case let textTapped as TextTappedMiniviewAction:
            state = handleTextTappedMiniviewAction(state: state, textTapped: textTapped)
//            log("newState from TextTappedMiniviewAction: \(newState)")
//            state = newState
        
        case let textMoved as TextMovedMiniviewAction:
            state = handleTextMovedMiniviewAction(state: state, textMoved: textMoved)

            
            
            // we have the p
            
        default:
            break
    }
    
//    let nm: NodeModel = state.nodeModels.first(where: {$0.id == 7} )!
//    let ports = nm.ports.sorted(by: ascending)
//    log("node 7: ports[2].value: \(ports[2].value)")
//    log("node 7: nm.previewModel!.position: \(nm.previewModel!.position)")
    

    
    // persist state to UserDefaults
    saveState(state: state)
    return state
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
