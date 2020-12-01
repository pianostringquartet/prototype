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
    let dispatch: Dispatch
    
    init(graphId: Int,
         nodes: [Node], connections: [Connection],
         dispatch: @escaping Dispatch) {
        self.graphId = graphId
        self.nodes = nodes
        self.connections = connections
        self.dispatch = dispatch
    }

    var body: some View {
        log("GraphEditorView body called")
        VStack { // HACK: bottom right corner alignment
            HStack {
                Button("< Back") {
                    dispatch(GoToGraphSelectionScreenAction())
                }
                Spacer()
                Text("Graph \(graphId)")
                Spacer()
            }.padding()
            
            
            Spacer()
            HStack {
                Spacer()
                ZStack {
                    ForEach(nodes, id: \.id) { (node: Node) in
                        Ball(connectingNode: $connectingNode,
                             node: node,
                             graphId: graphId,
                             connections: connections,
                             dispatch: dispatch)
                    }.padding(.trailing, 30).padding(.bottom, 30)
                }
            }
        }
        .offset(x: localPosition.width, y: localPosition.height)
        
        // Pinch to zoom
        // TODO: set limit to how far out / in we can zoom
        .contentShape(Rectangle()) // make container
        .scaleEffect(finalAmount + currentAmount)
        .gesture(
            MagnificationGesture()
                .onChanged { amount in
                    log("onChanged called")
                    self.currentAmount = amount - 1
                }
                .onEnded { amount in
                    log("onEnded called")
                    self.finalAmount += self.currentAmount
                    self.currentAmount = 0
                }
        )
        
        
        // the frame width 100 etc. is too small 
//        .frame(
////            width: 100 * magnifyBy,
////               height: 100 * magnifyBy,
//            width: 500 * magnifyBy,
//               height: 500 * magnifyBy,
//               alignment: .center)
//        .gesture(magnification)
        
        
        
        // Drag around:
//        .offset(x: localPosition.width, y: localPosition.height)
        
        // DEBUG: onEnded called but onChanged never called
        .gesture(DragGesture()
                    .onChanged {
                        
                        log("drag onChanged called")
                        log("localPosition: \(localPosition)")
                        log("localPreviousPosition: \(localPreviousPosition)")
                        log("value: \($0)")
                        self.localPosition = updatePosition(value: $0, position: self.localPreviousPosition)
                    }
                    .onEnded {
                        log("drag onEnded called")
                        log("localPosition: \(localPosition)")
                        log("localPreviousPosition: \(localPreviousPosition)")
                        log("value: \($0)")
                    
                        self.localPosition = updatePosition(value: $0, position: self.localPreviousPosition)
                        
                        self.localPreviousPosition = self.localPosition
                    }
        )
        
        
        
        .backgroundPreferenceValue(BallPreferenceKey.self) { (preferences: [BallPreferenceData]) in
            if connections.count >= 1 {
                let graphPreferences = preferences.filter( { (pref: BallPreferenceData) -> Bool in pref.graphId == graphId })
                GeometryReader { (geometry: GeometryProxy) in
                    ForEach(connections, content: { (connection: Connection) in
                        // Find each conn node's ball pref data
                        let to: BallPreferenceData? = graphPreferences.first(where: { (pref: BallPreferenceData) -> Bool in pref.nodeId == connection.to
                        })
                        let from: BallPreferenceData? = graphPreferences.first(where: { (pref: BallPreferenceData) -> Bool in pref.nodeId == connection.from
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
    
    var body: some View {
        let dispatcher: Dispatch = { state.dispatch($0) }
        return VStack {
            switch state.current.currentScreen {
                
                case Screens.graphEditing:
                    GraphEditorView(graphId: state.current.currentGraphId!,
                                    nodes: state.current.nodes.filter({ $0.graphId == state.current.currentGraphId!
                                     }),
                                     connections: state.current.connections.filter({
                                        $0.graphId == state.current.currentGraphId!
                                     }),
                                     dispatch: dispatcher
                    ).transition(.asymmetric(insertion: AnyTransition.opacity.combined(with: .slide),
                                             removal: AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                    )
                    
                
                    
                case Screens.graphSelection:
                    GraphSelectionView(graphs: state.current.graphs,
                                       nodes: state.current.nodes,
                                       connections: state.current.connections,
                                       dispatch: dispatcher
                    ).transition(.asymmetric(insertion: AnyTransition.opacity.combined(with: .slide),
                                             removal: AnyTransition.opacity.animation(.easeInOut(duration: 0.2))))
            }
        }
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
