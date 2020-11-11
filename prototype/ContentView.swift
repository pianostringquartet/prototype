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
        log("GraphEditorView: body")
        log("GraphEditorView: nodes: \(nodes)")
        log("GraphEditorView: graphId: \(graphId)")
        VStack { // HACK: bottom right corner alignment
//            HStack {
//                Button("< Back") {
//                    dispatch(GoToGraphSelectionScreenAction())
//                }
//                Spacer()
//                Text("Graph \(graphId)")
//                Spacer()
//            }.padding()
            
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
        
//        https://stackoverflow.com/questions/63838185/swiftui-onappear-ondisappear-not-working-in-xcode-11-7-11e801a-ios-13-7
        .onAppear {
            log("graph editor .onAppear called")
            // no handler yet...
            // should check if graphId already exists; if not, create new graph (id of ) of one node ('plus ball')
            dispatch(SetupGraphAction(graphId: graphId))
        }
        .onDisappear {
            log("graph editor .onDisappear called")
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

struct XGraphSelectionView: View {
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
                        Text("Graph \(graph.graphId)").onTapGesture {
                            dispatch(GoToGraphAction(graphId: graph.graphId))
                        }
                    }
            }
        }.padding()
    }
}

struct GraphSelectionView: View {

//    let graphs: [Graph]
//    let nodes: [Node]
//    let connections: [Connection]
//    let activeGraph: Int?
//    let dispatch: Dispatch
//
    
    var graphs: [Graph]
    var nodes: [Node]
    var connections: [Connection]
    var activeGraph: Int?
    var dispatch: Dispatch
    
    
    // maybe this @State var doesn't get updated when we re-render?
//    @State private var hasActiveGraph: Bool
//    var hasActiveGraph: Bool
        
    @State private var hasActiveGraph: Int? = nil
    
//    init(graphs: [Graph],
//        nodes: [Node],
//        connections: [Connection],
//        activeGraph: Int?,
//        dispatch: @escaping Dispatch
//    ) {
//
//        // activeGraph was Optional(1), but hasActiveGraph stayed 0?
//        log("activeGraph != nil: \(activeGraph != nil)")
//
////        self.hasActiveGraph = activeGraph != nil
//
//        // this won't quite work
////        self._hasActiveGraph = State.init(initialValue: activeGraph != nil ? 1 : 0)
////        self._hasActiveGraph = State.init(initialValue: activeGraph != nil)
////
//
//        self.graphs = graphs
//        self.nodes = nodes
//        self.connections = connections
//        self.activeGraph = activeGraph
//        self.dispatch = dispatch
//    }
    
    // like a special window onto a @State var, where we can do callbacks when getting and setting
//    func customBinding() -> Binding<Int?> {
//        let binding = Binding<Int?>(get: {
//            log("customBinding GET called: \(self.hasActiveGraph)")
//            return self.hasActiveGraph
////            return activeGraph != nil ? 1 : 0
//        }, set: {
////            print("Table \(String(describing: $0)) chosen")
//            // this is presumably the value it will be set to
//            log("customBinding SET called: \($0)")
//
//            // this will force a re-rendering?
////            dispatch(GoToNewGraphAction(graphId: 1))
//            if $0 == 1 {
//                log("will dispatch 'go to new graph' action for graph: \(graphs.count + 1)")
//                dispatch(GoToNewGraphAction(graphId: graphs.count + 1))
//            }
//
//            return self.hasActiveGraph = $0
//        })
//        log("about to return binding: \(binding)")
//        return binding
//    }
        
    
    var body: some View {
//        log("GraphSelectionView: body: timesCalled: \(timesCalled)")
        log("GraphSelectionView: body")
        log("GraphSelectionView: graphs: \(graphs)")
        log("GraphSelectionView: nodes: \(nodes)")
        log("GraphSelectionView: activeGraph: \(activeGraph)")
        log("GraphSelectionView: hasActiveGraph: \(hasActiveGraph)")
        return NavigationView {
            VStack(spacing: 30) {
                let newGraphId: Int = activeGraph == nil ? graphs.count + 1 : activeGraph!
                List {
                    // This view needs to have the data that will be created in the redux handler
                    // do I provide that data here -- or will the state be re-rendered
                    // what I think happens:
                    NavigationLink(
                        "Create a new graph with id \(newGraphId)",
                        destination: GraphEditorView(graphId: newGraphId,
                                                     nodes: nodesForGraph(graphId: newGraphId, nodes: nodes),
                                                     connections: connectionsForGraph(graphId: newGraphId, connections: connections),
                                                     dispatch: dispatch),
                        tag: 1,
                        selection:
                            Binding<Int?>.init(
                                get: { () -> Int? in
                                    log("INLINE customBinding GET called: \(self.hasActiveGraph)")
                                    return self.hasActiveGraph
                                },
                                set: {
                                    log("INLINE customBinding SET called: \($0)")
                                    if $0 == 1 {
//                                        log("will dispatch 'go to new graph' action for graph: \(graphs.count + 1)")
//                                        dispatch(GoToNewGraphAction(graphId: graphs.count + 1))
//                                        dispatch(NewGraphCreatedAction())
                                        log("would have dispatched NewGraphCreatedAction....")
                                    }
                                    return self.hasActiveGraph = $0
                                }))
                    ForEach(graphs, id: \.id) { (graph: Graph) in
                        NavigationLink(destination: GraphEditorView(graphId: graph.graphId,
                                                                    nodes: nodesForGraph(graphId: graph.graphId, nodes: nodes),
                                                                    connections: connectionsForGraph(graphId: graph.graphId, connections: connections),
                                                                    dispatch: dispatch)
                        ) {
                            Text("Graph \(graph.graphId)").onTapGesture {
                                log("NavLink existing graph: \(graph.graphId)")
                                dispatch(GoToGraphAction(graphId: graph.graphId))
                            }
                        }
                    }
                }
            }.navigationBarTitle(Text("Graphs"), displayMode: .inline)
        } // NavigationView
        .navigationViewStyle(StackNavigationViewStyle())
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

//struct ContentView: View {
//
//    @ObservedObject private var state = ObservableState(store: mainStore)
//
//    var body: some View {
//        log("ContentView: body")
//        log("ContentView: state.current.graphs: \(state.current.graphs)")
//        log("ContentView: state.current.nodes: \(state.current.nodes)")
//        log("ContentView: state.current.currentGraphId: \(state.current.currentGraphId)")
//
//        let s = state.current
//        let graphs = s.graphs
//        let nodes = s.nodes
//        let connections = s.connections
//        let dispatch: Dispatch = { state.dispatch($0) }
//
//        return NavigationView {
//            VStack(spacing: 30) {
//                let newGraphId: Int = graphs.count + 1
//                List {
//                    // This view needs to have the data that will be created in the redux handler
//                    // do I provide that data here -- or will the state be re-rendered
//                    // what I think happens:
//                    NavigationLink(
//                        "Create a new graph with id \(newGraphId)",
//                        destination: GraphEditorView(graphId: newGraphId,
//                                                                // this should work, because this navlink won't be activated until
//                                                                // the hasActiveGraph is mutated
////                                                                nodes: nodesForGraph(graphId: newGraphId, nodes: nodes),
////                                                                connections: [],
//                                                                nodes: [
//                                                                    Node(graphId: newGraphId, isAnchored: false, nodeId: 1),
//                                                                    Node(graphId: newGraphId, isAnchored: false, nodeId: 2),
//                                                                    // plus ball
//                                                                    Node(graphId: newGraphId, isAnchored: true, nodeId: 3),
//                                                                ],
//                                                                connections: [
//                                                                    Connection(graphId: newGraphId, from: 1, to: 2)
//                                                                ],
//                                                                dispatch: dispatch),
////                        isActive: $hasActiveGraph
//
////                        isActive: State.init(initialValue: hasActiveGraph)
//
//
//                        tag: 1,
//                        selection: $hasActiveGraph // self.customBinding() //$hasActiveGraph
//                    )
//                    .onTapGesture {
//                            log("NavLink new graph TAPPED: \(newGraphId)")
//                        self.hasActiveGraph = 1
//                    }
//
////                    {
////                        // can't combine this if using `isActive` rather than `tag`, `selection` etc.
////                        // but need someway to do a callback
////                        Text("Create a new graph").onTapGesture {
////                                    log("NavLink new graph: \(newGraphId)")
////                                    dispatch(GoToNewGraphAction(graphId: newGraphId))
////        //                            self.action = 1
////                                    // do I have to mutate this directly?
////                                    // yes -- apparently -- and it goes there immediately,
////                                    // without generating the new nodes
////        //                            self.hasActiveGraph = 1
////                                }
////                    }
//
//                    ForEach(graphs, id: \.id) { (graph: Graph) in
//                        NavigationLink(destination: GraphEditorView(graphId: graph.graphId,
//                                                                    nodes: nodesForGraph(graphId: graph.graphId, nodes: nodes),
//                                                                    connections: connectionsForGraph(graphId: graph.graphId, connections: connections),
//                                                                    dispatch: dispatch)
//                        ) {
//                            Text("Graph \(graph.graphId)").onTapGesture {
//                                log("NavLink existing graph: \(graph.graphId)")
//                                dispatch(GoToGraphAction(graphId: graph.graphId))
//                            }
//                        }
//                    }
//                }
//            }.navigationBarTitle(Text("Graphs"), displayMode: .inline)
//        } // NavigationView
//        .navigationViewStyle(StackNavigationViewStyle())
//
//
//    }
//}


struct ContentView: View {

    @ObservedObject private var state = ObservableState(store: mainStore)

    var body: some View {
        log("ContentView: body")
        log("ContentView: state.current.graphs: \(state.current.graphs)")
        log("ContentView: state.current.nodes: \(state.current.nodes)")
        log("ContentView: state.current.currentGraphId: \(state.current.currentGraphId)")


        GraphSelectionView(graphs: state.current.graphs,
                           nodes: state.current.nodes,
                           connections: state.current.connections,
                           activeGraph: state.current.currentGraphId,
                           dispatch: { (action: Action) in state.dispatch(action) })
//        return VStack {
//            switch state.current.currentScreen {
//
//                case Screens.graphEditing:
//                    GraphEditorView(graphId: state.current.currentGraphId!,
//                                     nodes: state.current.nodes.filter({ (n: Node) -> Bool in n.graphId == state.current.currentGraphId!
//                                     }),
//                                     connections: state.current.connections.filter( {
//                                        (conn: Connection) -> Bool in conn.graphId == state.current.currentGraphId!
//                                     }),
//                                     dispatch: { (action: Action) in state.dispatch(action) })
//
//                case Screens.graphSelection:
//                    GraphSelectionView(graphs: state.current.graphs,
//                                       nodes: state.current.nodes,
//                                       connections: state.current.connections,
//                                       dispatch: { (action: Action) in state.dispatch(action) })
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
