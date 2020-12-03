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

func leftPorts(nodeId: Int, id1: Int, id2: Int) -> [Port] {
 return [
    Port(id: id1, label: "L \(id1)", isInput: true, nodeId: nodeId),
    Port(id: id2, label: "L \(id2)", isInput: true, nodeId: nodeId),
 ]
}

func rightPorts(nodeId: Int, id1: Int, id2: Int) -> [Port] {
 return [
    Port(id: id1, label: "R \(id1)", isInput: false, nodeId: nodeId),
    Port(id: id2, label: "R \(id2)", isInput: false, nodeId: nodeId),
 ]
}


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
    
    init(graphId: Int,
         nodes: [Node],
         connections: [Connection],
         portConnections: [PortConnection],
         dispatch: @escaping Dispatch) {
        self.graphId = graphId
        self.nodes = nodes
        self.connections = connections
        self.portConnections = portConnections
        self.dispatch = dispatch
    }

    var body: some View {
        log("GraphEditorView body called")
        HStack {
            
            Box2(title: "Box 1", color: .green,
                 leftPorts: leftPorts(nodeId: 1, id1: 1, id2: 2),
                 rightPorts: rightPorts(nodeId: 1, id1: 3, id2: 4))
            
            Box2(title: "Box 2", color:  .orange,
                 leftPorts: leftPorts(nodeId: 2, id1: 5, id2: 6),
                 rightPorts: rightPorts(nodeId: 2, id1: 7, id2: 8))
            
            Box2(title: "Box 3", color:  .blue,
                 leftPorts: leftPorts(nodeId: 3, id1: 9, id2: 10),
                 rightPorts: rightPorts(nodeId: 3, id1: 11, id2: 12))
            

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
        
        // created HARDCODED CONNECTIONS FOR NOW
        .backgroundPreferenceValue(PortPreferenceKey.self) { (preferences: [PortPreferenceData]) in
//            if connections.count >= 1 {
            if portConnections.count >= 1 {
                let graphPreferences = preferences
                // no graphId right now
//                    .filter( { (pref: PortPreferenceData) -> Bool in pref.graphId == graphId })
                GeometryReader { (geometry: GeometryProxy) in
                    ForEach(portConnections, content: { (portConnection: PortConnection) in
                        // Find each conn node's ball pref data
                        let to: PortPreferenceData? = graphPreferences.first(where: { (pref: PortPreferenceData) -> Bool in pref.portId == portConnection.to
                        })
                        let from: PortPreferenceData? = graphPreferences.first(where: { (pref: PortPreferenceData) -> Bool in pref.portId == portConnection.from
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
    state: nil
)

struct ContentView: View {

    @ObservedObject private var state = ObservableState(store: mainStore)

    // zooming
//    @State private var currentAmount: CGFloat = 0
//    @State private var finalAmount: CGFloat = 1
    
    
    // fake port connections for now
    let portConnections = [
        
        // output only
        PortConnection(from: 3, to: 5),
        
        // input and output
        PortConnection(from: 7, to: 9),
        PortConnection(from: 8, to: 9),
//
//        // input only
//        PortConnection(from: <#T##Int#>, to: <#T##Int#>),
        // ^^^ implicitly already created by other connections
//
        

    ]
    
    
    var body: some View {
        let dispatcher: Dispatch = { state.dispatch($0) }
        
        
        return GraphEditorView(graphId: 1, //state.current.currentGraphId!,
                               nodes: [],
                                connections: [],
                                portConnections: portConnections,
                                dispatch: dispatcher
               ).transition(.asymmetric(insertion: AnyTransition.opacity.combined(with: .slide),
                                        removal: AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
               )
        
//        return VStack {
//
//
//            switch state.current.currentScreen {
//
//                case Screens.graphEditing:
//                    GraphEditorView(graphId: state.current.currentGraphId!,
//                                    nodes: state.current.nodes.filter({ $0.graphId == state.current.currentGraphId!
//                                     }),
//                                     connections: state.current.connections.filter({
//                                        $0.graphId == state.current.currentGraphId!
//                                     }),
//                                     dispatch: dispatcher
//                    ).transition(.asymmetric(insertion: AnyTransition.opacity.combined(with: .slide),
//                                             removal: AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
//                    )
//
//
//
//                case Screens.graphSelection:
//                    GraphSelectionView(graphs: state.current.graphs,
//                                       nodes: state.current.nodes,
//                                       connections: state.current.connections,
//                                       dispatch: dispatcher
//                    ).transition(.asymmetric(insertion: AnyTransition.opacity.combined(with: .slide),
//                                             removal: AnyTransition.opacity.animation(.easeInOut(duration: 0.2))))
//            }
//        }
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
