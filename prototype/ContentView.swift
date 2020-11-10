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
                        line(from: geometry[to!.center], to: geometry[from!.center])
                    })
                }
            }
        }
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
                dispatch(GoToNewGraphAction(graphId: graphs.count + 1))
            }
            List {
                ForEach(graphs, id: \.id) { (graph: Graph) in
                    Button("Graph \(graph.graphId)") {
                        dispatch(GoToGraphAction(graphId: graph.graphId))
                    }
                }.onDelete { (indexSet: IndexSet) in
                    for idx in indexSet {
                        log("onDelete: graphs[idx] was: \(graphs[idx])")
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

    var body: some View {
        return VStack {
            switch state.current.currentScreen {
                
                case Screens.graphEditing:
                    GraphEditorView(graphId: state.current.currentGraphId!,
                                     nodes: state.current.nodes.filter({ (n: Node) -> Bool in n.graphId == state.current.currentGraphId!
                                     }),
                                     connections: state.current.connections.filter( {
                                        (conn: Connection) -> Bool in conn.graphId == state.current.currentGraphId!
                                     }),
                                     dispatch: { (action: Action) in state.dispatch(action) }
                    ).transition(.asymmetric(insertion: AnyTransition.opacity.combined(with: .slide),
                                             removal: AnyTransition.opacity.animation(.easeInOut(duration: 0.2))))
                
                case Screens.graphSelection:
                    GraphSelectionView(graphs: state.current.graphs,
                                       nodes: state.current.nodes,
                                       connections: state.current.connections,
                                       dispatch: { (action: Action) in state.dispatch(action) }
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
