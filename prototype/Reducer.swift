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

//func handlePortTapped(portTapped: PortTapped, state: AppState) -> AppState {
//    log("handling portTapped... state.activePort: \(state.activePort)")
//
//    if state.activePort == nil {
//        log("setting new activePort: \(portTapped.port)")
//        state.activePort = portTapped.port
//    }
//    else if state.activePort == portTapped.port {
//        log("turning off activePort")
//        state.activePort = nil
//    }
//    else {
//        // if ports are not in same node,
//        // and if an edge does not already exist,
//        // create a new edge between the ports
//
//        // if edge already exists, then remove it
//
//        let isEdgeInsideNode = state.activePort!.nodeId == portTapped.port.nodeId
//
//
//        let newEdge: PortEdge = PortEdge(from: state.activePort!,
//                                         to: portTapped.port)
//        let edgeAlreadyExists = state.edges.contains(newEdge)
//
//
//
//        if isEdgeInsideNode {
//            log("attempted to create an edge inside a node!")
//        }
//        else if edgeAlreadyExists {
//            log("edge already exists; will remove it")
//
////                    state.edges.re
//
//            state.activePort = nil
//        }
//        else if !edgeAlreadyExists {
//
//            log("will create a new edge")
//            // create a connection between the activePort and tappedPort,
//            // and reset activePort
//            log("state.edges was: \(state.edges)")
//
////                    let newEdge: PortEdge = PortEdge(from: state.activePort!,
////                                                     to: portTapped.port)
//
//            state.edges.append(newEdge)
//            log("state.edges is now: \(state.edges)")
//
//
//            state.activePort = nil
//        }
//
//        // ie we always set activePort `nil` after adding or removing an edge?
//        state.activePort = nil
//
//    }
//}



func reducer(action: Action, state: AppState?) -> AppState {
    var defaultState: AppState = AppState()
    if let persistedState = pullState() {
        defaultState = persistedState
    }
    
    var state = state ?? defaultState
    
    switch action {
        
        case let pta as PortTappedAction:
            var newState = handlePortTappedAction(state: state, action: pta)
            log("newState from PortTappedAction: \(newState)")
            state = newState
        
        
        case let portTapped as PortTapped:
//            return handlePortTapped(portTapped: portTapped, state: state)
            log("handling portTapped... state.activePort: \(state.activePort)")
            
            if state.activePort == nil {
                log("setting new activePort: \(portTapped.port)")
                state.activePort = portTapped.port
            }
            else if state.activePort == portTapped.port {
                log("turning off activePort")
                state.activePort = nil
            }
            else {
                // if ports are not in same node,
                // and if an edge does not already exist,
                // create a new edge between the ports
                
                // if edge already exists, then remove it
                
                let isEdgeInsideNode = state.activePort!.nodeId == portTapped.port.nodeId
                
                
                let newEdge: PortEdge = PortEdge(from: state.activePort!,
                                                 to: portTapped.port)
                let edgeAlreadyExists = state.edges.contains(newEdge)
                
                let isEdgeBetweenInputs = state.activePort!.isInput && portTapped.port.isInput
                
                if isEdgeInsideNode {
                    log("ILLEGAL: attempted to create an edge inside a node!")
                }
                
                // disallow connecting an input to another input;
                // only outputs can connect to
                
                else if isEdgeBetweenInputs {
                    log("ILLEGAL: attempted to create an edge between inputs!")
                }
                
                else if edgeAlreadyExists {
                    log("edge already exists; will remove it")
                    
                    
                    log("state.edges was: \(state.edges)")
                    state.edges.removeAll(where: { (edge: PortEdge) -> Bool in
                        edge == newEdge
                    })
                    log("state.edges is now: \(state.edges)")
                    
                    
                    
                    
                    // WHEN EDGE REMOVED, want to reset the port values of the CalcNode
                    
                    // NOTE: newEdge is the edge we just removed;
                    // can reuse it's vals here
//                    let fromPortIdentifier: PortIdentifier = newEdge.from
                    let toPortIdentifier: PortIdentifier = newEdge.to
                    
                    let updatedCalcNode: CalcNode = updateCalcNodeInput(state: state,
                                        port: toPortIdentifier,
                                        newValue: "default")
                    
                    state.calcNodes = updateCalcNodes(calcNodes: state.calcNodes, newCalcNode: updatedCalcNode)
                    
                    
                    let updatedCalcNode2: CalcNode = updateCalcNodeOutput(
                        state: state,
                        nodeId: toPortIdentifier.nodeId,
                        // note we use `fromPV.value`, since is supposed to be the
                        // updated calc node's input anyway
                        inputValue: "other",
                        operation: { $0 })
                    
                    state.calcNodes = updateCalcNodes(calcNodes: state.calcNodes, newCalcNode: updatedCalcNode2)
                    
                    
                    state.activePort = nil
                }
                
                // ADDING AN EDGE
                else if !edgeAlreadyExists {
                    
                    log("will create a new edge")
                    // create a connection between the activePort and tappedPort,
                    // and reset activePort
                    log("state.edges was: \(state.edges)")
                                        
                    state.edges.append(newEdge)
                    log("state.edges is now: \(state.edges)")
                    
                    
                    // LOGIC FOR UPDATING CALC NODE INPUTS
                    let fromPortIdentifier: PortIdentifier = newEdge.from
                    let toPortIdentifier: PortIdentifier = newEdge.to
                    
                    let fromPV: PortValue = getPortValue(state: state, pi: fromPortIdentifier)
                    let toPV: PortValue = getPortValue(state: state, pi: toPortIdentifier)
                    

                    // the toPV needs to be updated to reflect the fromPV;
                    // and then the updatd toPV needs to be put back into the CalcInputNode
                    
                    // using the edge.from's PortValue's value,
                    // we update the calc Node's input
                    let updatedCalcNode: CalcNode = updateCalcNodeInput(state: state,
                                        port: toPortIdentifier,
                                        newValue: fromPV.value)
                    
                    state.calcNodes = updateCalcNodes(calcNodes: state.calcNodes, newCalcNode: updatedCalcNode)
                    
                    
                    // both modifications are done to same CalcNode; but different ports
                    
                    // the Output port has been updated
                    let operation = {(s: String) -> String in s.uppercased()}
                    
                    let updatedCalcNode2: CalcNode = updateCalcNodeOutput(
                        state: state,
                        nodeId: toPV.nodeId,
                        // note we use `fromPV.value`, since is supposed to be the
                        // updated calc node's input anyway
                        inputValue: fromPV.value,
                        operation: operation)
                    
                    state.calcNodes = updateCalcNodes(calcNodes: state.calcNodes, newCalcNode: updatedCalcNode2)
                    
                
                    // do only at very, very end
                    state.activePort = nil
                }
                
                // ie we always set activePort `nil` after adding or removing an edge?
                state.activePort = nil
                
            }
                    
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



// given a port identifer, retrieve the port value
func getPortValue(state: AppState, pi: PortIdentifier) -> PortValue {
        
    // val vs calc vs viz node?
    let valNode: ValNode? = state.valNodes.first(where: { (vn: ValNode) -> Bool in
        vn.id == pi.nodeId
    })
    
    // valNodes only have outputs
    let valNodePV: PortValue? = valNode?.outputs.first(where: { (pv: PortValue) -> Bool in
        pv.nodeId == pi.nodeId && pv.id == pi.portId
    })
    
    if valNodePV != nil {
        log("found valNodePV: \(valNodePV!)")
        return valNodePV!
    }
    
    
    
    let calcNode: CalcNode? = state.calcNodes.first(where: { (cn: CalcNode) -> Bool in
        cn.id == pi.nodeId
    })
    
    let calcNodePV: PortValue? = calcNode?.inputs.first(where: { (pv: PortValue) -> Bool in
        pv.nodeId == pi.nodeId && pv.id == pi.portId
    })
    
    let calcNodeOutputPV: PortValue? = calcNode?.output
    
    
    if calcNodePV != nil {
        log("found calcNodePV: \(calcNodePV!)")
        return calcNodePV!
    }
    if calcNodeOutputPV != nil {
        log("found calcNodeOutputPV: \(calcNodeOutputPV!)")
        return calcNodeOutputPV!
    }
    
    
    
    
    let vizNode: VizNode? = state.vizNodes.first(where: { (viznode: VizNode) -> Bool in
        viznode.id == pi.nodeId
    })
    
    // vizNodes only have inputs
    let vizNodePV: PortValue? = vizNode?.inputs.first(where: { (pv: PortValue) -> Bool in
        pv.nodeId == pi.nodeId && pv.id == pi.portId
    })
    
    if vizNodePV != nil {
        log("found vizNodePV: \(vizNodePV!)")
        return vizNodePV!
    }
    
    log("ILLEGAL: unable to find PortValue for PortIdentifier \(pi)")
    
    return PortValue(id: 0, nodeId: 0, label: "FAKE LABEL", value: "FAKE VALUE")
    
}




func updateCalcNodes(calcNodes: [CalcNode], newCalcNode: CalcNode) -> [CalcNode] {
    
    
    var myCalcNodes = calcNodes
    
    log("updateCalcNodes: calcNodes AGAIN was: \(myCalcNodes)")
    
    myCalcNodes.removeAll { (cn: CalcNode) -> Bool in
        cn.id == newCalcNode.id
    }
    
    myCalcNodes.append(newCalcNode)
    // ^^^ this is adding and removing THE SAME CalcNode AGAIN... :-(
    
    log("updateCalcNodes: calcNodes AGAIN is now: \(myCalcNodes)")
    
    return myCalcNodes
    
    
}



// given a port identifier, retrieve the calc node's input-port
// where `port` is the specific port we know we want
// and `new value` is its value

// given a port identifier and a new value, return a new CalcNode with the new-value
// where `port` is the specific (input) port to update,
//
func updateCalcNodeInput(state: AppState, port: PortIdentifier, newValue: String) -> CalcNode {

    log("updateCalcNodeInput called")


    // the specific calcNode we're looking for
//    let calcNode: CalcNode = state.calcNodes.first(where: {$0.id == port.nodeId})!
    
    // DOES NOT WORK EG WHEN WE TRY TO DRAW EDGE TO VIZ NODE
    let calcNode: CalcNode = state.calcNodes.first(where: {$0.id == port.nodeId})!
    
    var calcNodeInputs: [PortValue] = calcNode.inputs

    func isDesiredPort(pv: PortValue) -> Bool {
        pv.nodeId == port.nodeId && pv.id == port.portId
    }

    let inputPortValue: PortValue = calcNode.inputs.first(where: isDesiredPort)!

    let updatedInputPortValue: PortValue = PortValue(id: inputPortValue.id,
                                                nodeId: inputPortValue.nodeId,
                                                label: inputPortValue.label,
                                                value: newValue)
    
    calcNodeInputs.removeAll(where: isDesiredPort)
    calcNodeInputs.append(updatedInputPortValue)
    
    log("updated calcNodeInputs: \(calcNodeInputs)")
    
    let updatedCalcNode: CalcNode = CalcNode(
        id: calcNode.id,
        inputs: calcNodeInputs,
        output: calcNode.output,
        operation: calcNode.operation)
    
    return updatedCalcNode
}




// where `port` identifies the CalcNode's Output Port
// `new value` is already operation(old

// ASSUME, for now,
func updateCalcNodeOutput(state: AppState, nodeId: Int, inputValue: String, operation: (String) -> String) -> CalcNode {

    log("updateCalcNodeOutput called")

    // the specific calcNode we're looking for
//    let calcNode: CalcNode = state.calcNodes.first(where: {$0.id == port.nodeId})!
    let calcNode: CalcNode = state.calcNodes.first(where: {$0.id == nodeId})!
    
//    var calcNodeOutput: PortValue = calcNode.output

    let outputPortValue: PortValue = calcNode.output

    
    let newValue: String = operation(inputValue)
    let updatedOutputPortValue: PortValue = PortValue(id: outputPortValue.id,
                                                nodeId: outputPortValue.nodeId,
                                                label: outputPortValue.label,
                                                value: newValue)
    
//    calcNodeOutputs.removeAll(where: isDesiredPort)
//    calcNodeOutputs.append(updatedOutputPortValue)
    
//    log("updated calcNodeOutputs: \(calcNodeOutputs)")
    
    let updatedCalcNode: CalcNode = CalcNode(
        id: calcNode.id,
        inputs: calcNode.inputs,
        output: updatedOutputPortValue,
        operation: calcNode.operation)
    
    return updatedCalcNode
}









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
