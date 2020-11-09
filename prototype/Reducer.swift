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
 Actions
 ---------------------------------------------------------------- */

struct CounterActionIncrease: Action {}
struct CounterActionDecrease: Action {}

// when ball has been dragged:
// - create new ball
// - increment nodeCount -- ah, don't need this anymore at all, right?
// just: create new ball, rerender that graph
struct NodeCommittedAction: Action {
    let graphId: Int
    
    // position of the original node which has now been committed
    let position: CGSize
//    let nodeId: Int
    let node: Node
}

// now, when user touches one ball and then another,
// we can do all that calculation logic (save vs. remove) in here
struct EdgeAttemptedAction: Action {
    let graphId: Int
    let connectingNode: Int
    let clickedNode: Int
}

/* ----------------------------------------------------------------
 Reducer
 ---------------------------------------------------------------- */

func counterReducer(action: Action, state: AppState?) -> AppState {
    log("counterReducer called")
    log("counterReducer: action: \(action)")
    
    var defaultState: AppState = AppState()
    
    if let persistedState = pullState() {
        log("there was persistedState: \(persistedState)")
        defaultState = persistedState
    }
    
//    var state = state ?? AppState()
    var state = state ?? defaultState
    
    log("state before reducers: \(state)")

    switch action {
    case _ as CounterActionIncrease:
//        state.counter += 1
        state.fun.count += 1
    case _ as CounterActionDecrease:
//        state.counter -= 1
        state.fun.count -= 1
//    case _ as NodeCommittedAction:
        
        // need to both update the given node's position,
        // AND create a new node
    case let nodeCommitted as NodeCommittedAction:
        log("handling NodeCommittedAction: action: \(action)")
        log("handling NodeCommittedAction: nodeCommitted: \(nodeCommitted)")
        
        // updating the original node's position
        //
        
//        state.nodes.removeAll(where: <#T##(Node) throws -> Bool#>)
        
        // remove the original node...
        log("state.nodes.count before removal: \(state.nodes.count)")
        state.nodes.removeAll(where: {
            (n: Node) in n.nodeId == nodeCommitted.node.nodeId && n.graphId == nodeCommitted.graphId
        })
        log("state.nodes.count after removal: \(state.nodes.count)")
        // ... and the updated version:
        
        state.nodes.append(Node(graphId: nodeCommitted.graphId,
                                isAnchored: false, // unanchored
                                nodeId: nodeCommitted.node.nodeId,
                                // use the updated position
                                position: nodeCommitted.position))
        log("state.nodes.count after first append: \(state.nodes.count)")
        
        
//        ... and finally, create the new node ie plus ball
        state.nodes.append(Node(graphId: nodeCommitted.graphId,
                                nodeId: state.nodes.count + 1))
        log("state.nodes.count after second append: \(state.nodes.count)")
        
    default:
        break
    }

    log("about to return state in reducer: state: \(state)")
    saveState(state: state)
    return state
}


/* ----------------------------------------------------------------
 Persisting state via UserDefaults
 ---------------------------------------------------------------- */

func saveState(state: AppState) -> () {
    log("saveState called")
    
    if let encoded = try? JSONEncoder().encode(state) {
        UserDefaults.standard.set(encoded, forKey: "SavedData")
        log("saved state...")
    }
    else {
        log("wasn't able to save state...")
    }
}

func pullState() -> AppState? {
    log("pullState() called")
    if let data = UserDefaults.standard.data(forKey: "SavedData") {
        if let decodedState = try? JSONDecoder().decode(AppState.self, from: data) {
            log("decodedState: \(decodedState)")
          return decodedState
        }
    }
    return nil
}
