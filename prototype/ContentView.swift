//
//  ContentView.swift
//  prototype
//
//  Created by cjc on 11/1/20.
//

import SwiftUI
import AVFoundation
import ReSwift


/* ----------------------------------------------------------------
 GRAPH EDITING VIEW
 ---------------------------------------------------------------- */

struct GraphEditorView: View {
    
    // zooming
    @State private var currentAmount: CGFloat = 0
    @State private var finalAmount: CGFloat = 1
    
    // dragging
    @State private var localPosition: CGSize = CGSize.zero
    @State private var localPreviousPosition: CGSize = CGSize.zero
    
    // particular node to which we are adding/removing connections
    @State public var connectingNode: Int? = nil // not persisted

    let graphId: Int
    let nodes: [Node]
    let connections: [Connection]
    let portConnections: [PortConnection]
    let dispatch: Dispatch
    
    let state: AppState
    
    init(graphId: Int,
         nodes: [Node],
         connections: [Connection],
         portConnections: [PortConnection],
         dispatch: @escaping Dispatch,
         state: AppState) {
        self.graphId = graphId
        self.nodes = nodes
        self.connections = connections
        self.portConnections = portConnections
        self.dispatch = dispatch
        self.state = state
    }

    var body: some View {
        log("GraphEditorView body called")
        
        HStack (spacing: 50) {
    
            // left
            VStack {
                Text("Value nodes")
                ForEach(state.valNodes, id: \.id) { (valNode: ValNode) in
                    ValNodeView(title: "Val. Node", valNode: valNode, dispatch: dispatch, state: state)
                }
            }
            
            // middle
            VStack {
                Text("Calc nodes")
                ForEach(state.calcNodes, id: \.id) { (calcNode: CalcNode) in
                    CalcNodeView(title: "Calc Node", calcNode: calcNode, dispatch: dispatch, state: state)
                }
            }
            
            // right
            VStack {
                Text("Viz nodes")
                ForEach(state.vizNodes, id: \.id) { (vizNode: VizNode) in
                    VizNodeView(title: "Viz. Node", vizNode: vizNode, dispatch: dispatch, state: state)
                }
            }
            
  // manually hardcode what you want / need here

                    // keep the logic of the nodes, adding removing etc.
//                    ForEach(nodes, id: \.id) { (node: Node) in
//                        Ball(connectingNode: $connectingNode,
//                             node: node,
//                             graphId: graphId,
//                             connections: connections,
//                             dispatch: dispatch)
//                    }
                }
        .padding(.trailing, 30).padding(.bottom, 30)
//            }
//        }
        
        
        .offset(x: localPosition.width, y: localPosition.height)
        .frame(idealWidth: 500, idealHeight: 500)
        
        // Pinch to zoom
        // TODO: set limit to how far out / in we can zoom
        .contentShape(Rectangle()) // make container
//        .scaleEffect(finalAmount + currentAmount)
//        .gesture(
//            MagnificationGesture()
//                .onChanged { amount in
//                    log("onChanged called")
//                    self.currentAmount = amount - 1
//                }
//                .onEnded { amount in
//                    log("onEnded called")
//                    self.finalAmount += self.currentAmount
//                    self.currentAmount = 0
//                }
//        )
  
        .backgroundPreferenceValue(PortPreferenceKey.self) { (preferences: [PortPreferenceData]) in
//            if connections.count >= 1 {
            if state.edges.count >= 1 {
                let graphPreferences = preferences
                // no graphId right now
//                    .filter( { (pref: PortPreferenceData) -> Bool in pref.graphId == graphId })
                GeometryReader { (geometry: GeometryProxy) in
                    ForEach(state.edges, content: { (portEdge: PortEdge) in
                        // Find each conn node's ball pref data
                        
                        // find the pref data for this port (its node id and port id)
                        let to: PortPreferenceData? = graphPreferences.first(where: { (pref: PortPreferenceData) -> Bool in
                            pref.portId == portEdge.to.portId &&
                                pref.nodeId == portEdge.to.nodeId
                            
                        })
                        
                        let from: PortPreferenceData? = graphPreferences.first(where: { (pref: PortPreferenceData) -> Bool in
//                            pref.portId == portConnection.from
                            pref.portId == portEdge.from.portId &&
                                pref.nodeId == portEdge.from.nodeId
                        })
                        
                        // TODO: handle this properly;
                        // all connections should be deletions
                        if to != nil && from != nil {
                            line(from: geometry[to!.center], to: geometry[from!.center])
                        }
                        else {
                            log("Encountered a nil while trying to draw an edge.")
                            log("to: \(to)")
                            log("from: \(from)")
                        }
                        
//                        line(from: geometry[to!.center], to: geometry[from!.center])
                    })
                }
            }
        } // backgroundPreferenceValue
        
        
        // created HARDCODED CONNECTIONS FOR NOW
//        .backgroundPreferenceValue(PortPreferenceKey.self) { (preferences: [PortPreferenceData]) in
////            if connections.count >= 1 {
//            if portConnections.count >= 1 {
//                let graphPreferences = preferences
//                // no graphId right now
////                    .filter( { (pref: PortPreferenceData) -> Bool in pref.graphId == graphId })
//                GeometryReader { (geometry: GeometryProxy) in
//                    ForEach(portConnections, content: { (portConnection: PortConnection) in
//                        // Find each conn node's ball pref data
//                        let to: PortPreferenceData? = graphPreferences.first(where: { (pref: PortPreferenceData) -> Bool in pref.portId == portConnection.to
//                        })
//                        let from: PortPreferenceData? = graphPreferences.first(where: { (pref: PortPreferenceData) -> Bool in pref.portId == portConnection.from
//                        })
//
//                        // TODO: handle this properly;
//                        // all connections should be deletions
//                        if to != nil && from != nil {
//                            line(from: geometry[to!.center], to: geometry[from!.center])
//                        }
//                        else {
//                            log("Encountered a nil while trying to draw an edge.")
//                            log("to: \(to)")
//                            log("from: \(from)")
//                        }
//
////                        line(from: geometry[to!.center], to: geometry[from!.center])
//                    })
//                }
//            }
//        } // backgroundPreferenceValue

        
        
        
        
        
        // Drag around:
//        .offset(x: localPosition.width, y: localPosition.height)
        
        // DEBUG: onEnded called but onChanged never called
        
        // TEMPORARILY TURNING THIS OFF
//        .gesture(DragGesture()
//                    .onChanged {
//
//                        log("drag onChanged called")
//                        log("localPosition: \(localPosition)")
//                        log("localPreviousPosition: \(localPreviousPosition)")
//                        log("value: \($0)")
//                        self.localPosition = updatePosition(value: $0, position: self.localPreviousPosition)
//                    }
//                    .onEnded {
//                        log("drag onEnded called")
//                        log("localPosition: \(localPosition)")
//                        log("localPreviousPosition: \(localPreviousPosition)")
//                        log("value: \($0)")
//
//                        self.localPosition = updatePosition(value: $0, position: self.localPreviousPosition)
//
//                        self.localPreviousPosition = self.localPosition
//                    }
//        )
//
        
        
//        .backgroundPreferenceValue(BallPreferenceKey.self) { (preferences: [BallPreferenceData]) in
//            if connections.count >= 1 {
//                let graphPreferences = preferences.filter( { (pref: BallPreferenceData) -> Bool in pref.graphId == graphId })
//                GeometryReader { (geometry: GeometryProxy) in
//                    ForEach(connections, content: { (connection: Connection) in
//                        // Find each conn node's ball pref data
//                        let to: BallPreferenceData? = graphPreferences.first(where: { (pref: BallPreferenceData) -> Bool in pref.nodeId == connection.to
//                        })
//                        let from: BallPreferenceData? = graphPreferences.first(where: { (pref: BallPreferenceData) -> Bool in pref.nodeId == connection.from
//                        })
//
//                        // TODO: handle this properly;
//                        // all connections should be deletions
//                        if to != nil && from != nil {
//                            line(from: geometry[to!.center], to: geometry[from!.center])
//                        }
//                        else {
//                            log("Encountered a nil while trying to draw an edge.")
//                            log("to: \(to)")
//                            log("from: \(from)")
//                        }
//
////                        line(from: geometry[to!.center], to: geometry[from!.center])
//                    })
//                }
//            }
//        } // backgroundPreferenceValue

           
        
        
    }
}


/* ----------------------------------------------------------------
 GRAPH SELECTION VIEW
 ---------------------------------------------------------------- */

struct GraphSelectionView: View {
    let graphs: [Graph]
    let nodes: [Node]
    let connections: [Connection]
    let dispatch: Dispatch
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Button("Create new graph") {
                dispatch(GoToNewGraphAction())
            }
            List {
                ForEach(graphs, id: \.id) { (graph: Graph) in
                    Button("Graph \(graph.graphId)") {
                        dispatch(GoToGraphAction(graphId: graph.graphId))
                    }
                }.onDelete { (indexSet: IndexSet) in
                    for idx in indexSet {
                        dispatch(GraphDeletedAction(graphId: graphs[idx].graphId))
                    }
                }
            }
        }.padding()
    }
}


/* ----------------------------------------------------------------
 Content View
 ---------------------------------------------------------------- */


// Initialize redux store
let mainStore = Store<AppState>(
    reducer: reducer,
//    state: nil
    state: hwState
)


let valNodeOutput = PortValue(id: 1, nodeId: 1, label: "String value", value: "hello")
let valNode = ValNode(id: 1, outputs: [valNodeOutput])


//let calcNodeInput = PortValue(id: 2, nodeId: 2, label: "String value", value: "hello")
//let calcNodeOutput = PortValue(id: 3, nodeId: 2, label: "String value", value: "HELLO")
// ie start out empty
let calcNodeInput = PortValue(id: 2, nodeId: 2, label: "String value", value: "x1")
let calcNodeOutput = PortValue(id: 3, nodeId: 2, label: "String value", value: "x2")
let calcNode: CalcNode = CalcNode(
    id: 2,
    inputs: [calcNodeInput],
    outputs: [calcNodeOutput],
    operation: "uppercase"
//    operation: { (s: String) -> String in s.uppercased() }
)

//let vizNodeInput = Input(id: 3, nodeId: 3, value: "HELLO")
//let vizNodeInput = PortValue(id: 4, nodeId: 3, label: "String value", value: "HELLO")
let vizNodeInput = PortValue(id: 4, nodeId: 3, label: "String value", value: "x3")
let vizNode = VizNode(id: 3, inputs: [vizNodeInput])


let hwState = AppState(graphs: [],
                       nodes: [],
                       connections: [],
                       currentScreen: Screens.graphEditing,
                       currentGraphId: 1,
                       // might want each of these to be a map {:nodeId nodeType}
                       // instead of just a list?
                       valNodes: [valNode],
                       calcNodes: [calcNode],
                       vizNodes: [vizNode])




struct ContentView: View {

    @ObservedObject private var state = ObservableState(store: mainStore)

    // fake port connections for now
    let portConnections: [PortConnection] = [
        // output only
//        PortConnection(from: 1, to: 2),
        // input and output
//        PortConnection(from: 3, to: 4   ),
    ]

    var body: some View {
        let dispatcher: Dispatch = { state.dispatch($0) }
        
        return GraphEditorView(graphId: 1, //state.current.currentGraphId!,
                               nodes: state.current.nodes,
                               connections: state.current.connections,
                                portConnections: portConnections,
                                dispatch: dispatcher,
                                // careful -- is this updated enough?
                                state: state.current
               )
    }
}


/* ----------------------------------------------------------------
 PREVIEW
 ---------------------------------------------------------------- */

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
