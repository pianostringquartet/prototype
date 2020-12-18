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
        
        case let portTapped as PortTappedAction:
            state = handlePortTappedAction(state: state, action: portTapped)
//            log("newState from PortTappedAction: \(newState)")
//            state = newState
        
        case let textTapped as TextTappedMiniviewAction:
            state = handleTextTappedMiniviewAction(state: state, textTapped: textTapped)
//            log("newState from TextTappedMiniviewAction: \(newState)")
//            state = newState
        
        case let textMoved as TextMovedMiniviewAction:
            state = handleTextMovedMiniviewAction(state: state, textMoved: textMoved)
            
        default:
            break
    }

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
