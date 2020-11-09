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

struct GoToGraphAction: Action {
    let graphId: Int
}

struct GoToNewGraphAction: Action {
    let graphId: Int // the id for the newly created graph
}

struct GoToScreen: Action {
    let screen: Screens
}

struct GoToGraphSelectionScreenAction: Action {}


/* ----------------------------------------------------------------
 Reducer
 ---------------------------------------------------------------- */

func reducer(action: Action, state: AppState?) -> AppState {
    var defaultState: AppState = AppState()
    if let persistedState = pullState() {
        defaultState = persistedState
    }
    
    var state = state ?? defaultState
    
    switch action {
        
        // NODES
        
        case let nodeMoved as NodeMovedAction:
            // remove the old node and insert and updated one:
            state.nodes.removeAll(where: {
                (n: Node) in n.nodeId == nodeMoved.node.nodeId && n.graphId == nodeMoved.graphId
            })
            state.nodes.append(Node(graphId: nodeMoved.graphId,
                                    isAnchored: false, // unanchored
                                    nodeId: nodeMoved.node.nodeId,
                                    // use the updated position
                                    position: nodeMoved.position))
            
        case let nodeCommitted as NodeCommittedAction:
            // remove the old node and insert and updated one:
            state.nodes.removeAll(where: {
                (n: Node) in n.nodeId == nodeCommitted.node.nodeId && n.graphId == nodeCommitted.graphId
            })
            state.nodes.append(Node(graphId: nodeCommitted.graphId,
                                    isAnchored: false, // unanchored
                                    nodeId: nodeCommitted.node.nodeId,
                                    // use the updated position
                                    position: nodeCommitted.position))
            
            // create the new node ie plus ball
            state.nodes.append(
                Node(graphId: nodeCommitted.graphId,
                     isAnchored: true,
                     nodeId: nodesForGraph(graphId: nodeCommitted.graphId,
                                           nodes: state.nodes).count + 1))
            
            
        // EDGES
            
        case let edgeAdded as EdgeAddedAction:
            state.connections.append(Connection(graphId: edgeAdded.graphId, from: edgeAdded.from, to: edgeAdded.to))
            
        case let edgeRemoved as EdgeRemovedAction:
            state.connections.removeAll(where: {(conn: Connection) -> Bool in
                conn.graphId == edgeRemoved.graphId && (conn.from == edgeRemoved.from && conn.to == edgeRemoved.to || conn.from == edgeRemoved.to && conn.to == edgeRemoved.from)
            })
            
        
        // NAVIGATION
            
        case let newGraph as GoToNewGraphAction:
            // create new graph
            state.graphs.append(Graph(graphId: newGraph.graphId))
            state.nodes.append(Node(graphId: newGraph.graphId, isAnchored: true, nodeId: 1))
            
            // set as active graph
            state.currentGraphId = newGraph.graphId
            
            // route to graph edit screen:
            state.currentScreen = Screens.graphEditing
            
        case let goToGraph as GoToGraphAction:
            state.currentGraphId = goToGraph.graphId
            state.currentScreen = Screens.graphEditing
            
        case let goToSelection as GoToGraphSelectionScreenAction:
            state.currentGraphId = nil
            state.currentScreen = Screens.graphSelection
            
        default:
            break
    }


    // persist state to UserDefaults
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
    if let encoded = try? JSONEncoder().encode(state) {
        UserDefaults.standard.set(encoded, forKey: "SavedData")
    }
}

func pullState() -> AppState? {
    if let data = UserDefaults.standard.data(forKey: "SavedData") {
        if let decodedState = try? JSONDecoder().decode(AppState.self, from: data) {
          return decodedState
        }
    }
    return nil
}
