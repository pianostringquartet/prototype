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
                     nodeId: nextNodeId(nodes: nodesForGraph(graphId: nodeCommitted.graphId,
                                                             nodes: state.nodes))
                )
            )
            
        case let nodeDeleted as NodeDeletedAction:
            state.nodes.removeAll(where: { $0.graphId == nodeDeleted.graphId && $0.nodeId == nodeDeleted.nodeId })
            state.connections.removeAll(where: {
                                            $0.graphId == nodeDeleted.graphId &&
                                                ($0.to == nodeDeleted.nodeId || $0.from == nodeDeleted.nodeId) })
    
            
//        // EDGES
//
////        case let edgeAdded as EdgeAddedAction:
////            state.connections.append(Connection(graphId: edgeAdded.graphId, from: edgeAdded.from, to: edgeAdded.to))
////
////        case let edgeRemoved as EdgeRemovedAction:
////            state.connections.removeAll(where: {(conn: Connection) -> Bool in
////                conn.graphId == edgeRemoved.graphId && (conn.from == edgeRemoved.from && conn.to == edgeRemoved.to || conn.from == edgeRemoved.to && conn.to == edgeRemoved.from)
////            })
//
        default:
            break
    }


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
