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


// used for if node moved and
struct NodeMovedAction: Action {
    let graphId: Int
    let position: CGSize
    let node: Node
}

// when ball has been dragged:
// - create new ball
// - increment nodeCount -- ah, don't need this anymore at all, right?
// just: create new ball, rerender that graph
struct NodeCommittedAction: Action {
    let graphId: Int
    
    // the new position of the original node (now committed)
    let position: CGSize
    // the original node (now committed)
    let node: Node
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

// when a new graph is created, we make both a graph and a node
//struct GraphCreatedAction: Action {
//    let graphId: Int // the id for the newly created graph
//}

// sets a new active graph
struct GoToGraphAction: Action {
    let graphId: Int
}

struct GoToNewGraphAction: Action {
    let graphId: Int // the id for the newly created graph
}

struct GoToScreen: Action {
    let screen: Screens
}

// set activeGraph = nil and activeScreen = graphSelection
struct GoToGraphSelectionScreenAction: Action {
    
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


//    case let graphCreated as GraphCreatedAction:
//        log("handling graphCreated...")
//        log("state.graphs.count before addition: \(state.graphs.count)")
//        log("state.nodes.count before addition: \(state.nodes.count)")
//        // create new graph
//        state.graphs.append(Graph(graphId: graphCreated.graphId))
//
//        // create new node
//        state.nodes.append(Node(graphId: graphCreated.graphId))
//        log("state.graphs.count after addition: \(state.graphs.count)")
//        log("state.nodes.count after addition: \(state.nodes.count)")
        
    case let newGraph as GoToNewGraphAction:
        log("handling newGraph...")
        log("newGraph.graphId: \(newGraph.graphId)")
        
        // create new graph
        state.graphs.append(Graph(graphId: newGraph.graphId))
        
        // create new node
        // ... a brand new node FOR THIS GRAPH, the plus ball node
        state.nodes.append(Node(graphId: newGraph.graphId, isAnchored: true, nodeId: 1))
        
        log("state.graphs.count after addition: \(state.graphs.count)")
        log("state.nodes.count after addition: \(state.nodes.count)")
        
        // set as active graph
        state.currentGraphId = newGraph.graphId
        
        // route to graph edit screen:
        state.currentScreen = Screens.graphEditing
        
        
    case let goToGraph as GoToGraphAction:
        log("handling goToGraph...")
        state.currentGraphId = goToGraph.graphId
        // route to graph edit screen:
        state.currentScreen = Screens.graphEditing
        
    case let goToSelection as GoToGraphSelectionScreenAction:
        log("handling goToSelection...")
        state.currentGraphId = nil
        // route to graph edit screen:
        state.currentScreen = Screens.graphSelection
        
        
        
        
    case let edgeAdded as EdgeAddedAction:
        log("handling edgeAdded...")
        log("state.connections.count before addition: \(state.connections.count)")
        state.connections.append(Connection(graphId: edgeAdded.graphId, from: edgeAdded.from, to: edgeAdded.to))
        log("state.connections.count after addition: \(state.connections.count)")
        
    case let edgeRemoved as EdgeRemovedAction:
        log("handling edgeRemoved...")
        log("state.connections.count before removal: \(state.connections.count)")
        
        state.connections.removeAll(where: {(conn: Connection) -> Bool in
            conn.graphId == edgeRemoved.graphId && (conn.from == edgeRemoved.from && conn.to == edgeRemoved.to || conn.from == edgeRemoved.to && conn.to == edgeRemoved.from)
        })
        log("state.connections.count after removal: \(state.connections.count)")
        
        
    case let nodeMoved as NodeMovedAction:
        log("handling nodeMoved...")
        log("state.nodes.count before removal: \(state.nodes.count)")
        state.nodes.removeAll(where: {
            (n: Node) in n.nodeId == nodeMoved.node.nodeId && n.graphId == nodeMoved.graphId
        })
        log("state.nodes.count after removal: \(state.nodes.count)")
        // ... and the updated version:
        state.nodes.append(Node(graphId: nodeMoved.graphId,
                                isAnchored: false, // unanchored
                                nodeId: nodeMoved.node.nodeId,
                                // use the updated position
                                position: nodeMoved.position))
        log("state.nodes.count after first append: \(state.nodes.count)")
        
    case let nodeCommitted as NodeCommittedAction:
        // remove the original node...
        log("handling nodeCommitted...")
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
        state.nodes.append(
            Node(graphId: nodeCommitted.graphId,
                 isAnchored: true,
                                // can't say this -- because you have to go by GRAPH
                 nodeId: nodesForGraph(graphId: nodeCommitted.graphId,
                                       nodes: state.nodes).count + 1))

//                                nodeId: state.nodes.count + 1
//        ))
        log("state.nodes.count after second append: \(state.nodes.count)")
        
    default:
        break
    }

    log("about to return state in reducer: state: \(state)")
    saveState(state: state)
    return state
}

func nodesForGraph(graphId: Int, nodes: [Node]) -> [Node] {
    return nodes.filter({ (n: Node) -> Bool in n.graphId == graphId
    })
}

func connectionsForGraph(graphId: Int, connections: [Connection]) -> [Connection] {
    return connections.filter({ (conn: Connection) -> Bool in conn.graphId == graphId
    })
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
