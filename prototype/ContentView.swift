//
//  ContentView.swift
//  prototype
//
//  Created by cjc on 11/1/20.
//

import SwiftUI
import AVFoundation
import ReSwift

// Initialize redux store
let mainStore = Store<AppState>(
    reducer: counterReducer,
    state: nil
)

/* ----------------------------------------------------------------
 GRAPH EDITING VIEWS
 ---------------------------------------------------------------- */


// SHOULD ONLY RECEIVE NODES AND CONNECTIONS FOR GIVEN GRAPHID
struct GraphEditorChild: View {
//    @Environment(\.managedObjectContext) var moc

    // particular node to which we are adding/removing connections
    @State public var connectingNode: Int? = nil // not persisted

//    @State private var nodeCount: Int

    let graphId: Int
    let nodes: [Node]
    let connections: [Connection]
    let dispatch: Dispatch
    
    init(graphId: Int,
//         nodeCount: Int,
         nodes: [Node], connections: [Connection],
         dispatch: @escaping Dispatch) {
//        self._nodeCount = State.init(initialValue: nodeCount)
        self.graphId = graphId
        self.nodes = nodes
        self.connections = connections
        self.dispatch = dispatch
    }

    var body: some View {
        VStack { // HACK: bottom right corner alignment
            log("GraphEditorChild: nodes: \(nodes)")
            log("GraphEditorChild: connections: \(connections)")
            HStack {
                Button("< Back") {
                    log("graph edit screen back pressed")
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
 Content View
 ---------------------------------------------------------------- */

// has list of graphs, nodes etc.
// from here, user picks particular graphId
struct GraphSelectionView: View {

    let graphs: [Graph]
    let nodes: [Node]
    let connections: [Connection]
    let dispatch: Dispatch
    
    // TODO: Find a better approach to route to 'new screen'
    @State private var action: Int? = 0
    
    var body: some View {
        log("GraphSelectionView: nodes: \(nodes)")
        log("GraphSelectionView: connections: \(connections)")
        
        VStack(spacing: 20) {
            Spacer()
            Button("Create new graph") {
                log("create new graph button pressed")
                // needs to also change currentScreen and set a new currentGraph
//                dispatch(GraphCreatedAction(graphId: graphs.count + 1))
                dispatch(GoToNewGraphAction(graphId: graphs.count + 1))
            }
            
            List {
                ForEach(graphs, id: \.id) { (graph: Graph) in
//                        log("selected graph \(graph.graphId)")
//                    NavigationLink(destination:
//                                    GraphEditorChild(graphId: graph.graphId,
//                                                     nodes: nodes.filter({ (n: Node) -> Bool in
//                                                        n.graphId == graph.graphId
//                                                     }),
//                                                     connections: connections.filter({ (conn: Connection) -> Bool in
//                                                        conn.graphId == graph.graphId
//                                                     }),
//                                                     dispatch: dispatch)
//                    )
//                    {
                        Text("Graph \(graph.graphId)").onTapGesture {
                            log("picked graph \(graph.graphId)")
                            dispatch(GoToGraphAction(graphId: graph.graphId))
                        }
                    }
            }
           
        }.padding()
        
//        NavigationView {
//            VStack(spacing: 30) {
//                List {
//                    NavigationLink(destination:
//                                    GraphEditorChild(graphId: graphs.count + 1,
//
//                                                                 // new graphs have one 'plus ball' node
//                                                                 nodes: [Node(graphId: graphs.count + 1)],
//                                                                 // new graphs have no edges
//                                                                 connections: [],
//                                                                 dispatch: dispatch),
//                                   tag: 1, selection: $action)
//                    {
//                        Text("Create new graph").onTapGesture {
////                            self.graphCount += 1
//
//                            // Create first node for new graph
////                            let node = Node(context: self.moc)
////                            mutateNewNode(node: node,
////                                          nodeNumber: 1,
////                                          graphId: graphCount)
////
////                            // Create graph itself
////                            let graph = Graph(context: self.moc)
////                            graph.id = UUID()
////                            graph.graphId = Int32(graphCount)
//
////
////                            try? moc.save()
//
//                            // BUG?: sometimes CoreData mutation is not finished
//                            // before we call this and go to graph-edit screen?
//
//                            // could change this to be a state var, e.g. "go to X";
//                            // ... but then the user
//
//                            dispatch(GraphCreatedAction(graphId: graphs.count + 1))
//
//
//                            log("about to flip self.action")
//                            self.action = 1
//                            log("just flipped self.action")
//
//                        }
//                    }
//                    ForEach(graphs, id: \.id) { (graph: Graph) in
////                        log("selected graph \(graph.graphId)")
//                        NavigationLink(destination:
//                                        GraphEditorChild(graphId: graph.graphId,
//                                                         nodes: nodes.filter({ (n: Node) -> Bool in
//                                                            n.graphId == graph.graphId
//                                                         }),
//                                                         connections: connections.filter({ (conn: Connection) -> Bool in
//                                                            conn.graphId == graph.graphId
//                                                         }),
//                                                         dispatch: dispatch)
//                        ) {
//                            Text("Graph \(graph.graphId)")
//                        }
//                    }
//                }
//            }.navigationBarTitle(Text("Graphs"), displayMode: .inline)
//        } // NavigationView
//        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ContentView: View {
//struct XContentView: View {

    // MARK: Private Properties

    @ObservedObject private var state = ObservableState(store: mainStore)

    // MARK: Body

    
    var body: some View {
        log("redux ContentView: body")
        // just start with one
        log("state.current.currentScreen: \(state.current.currentScreen)")
        log("state.current.currentGraphId: \(state.current.currentGraphId)")
        log("state.current.graphs: \(state.current.graphs)")
        
        return VStack {
            switch state.current.currentScreen {
                case Screens.graphEditing:
                    log("routing to Screens.graphEditing")
                    
                    
                    // need, in state, a 'current graph' etc.
                    GraphEditorChild(graphId: state.current.currentGraphId!,
                                     //                                     nodes: state.current.nodes.isEmpty ? [Node(graphId: state.current.currentGraphId!)] : state.current.nodes,
                                     
                                     // only provide the nodes and connections for the active graph
                                     nodes: state.current.nodes.filter({ (n: Node) -> Bool in n.graphId == state.current.currentGraphId!
                                     }),
                                     connections: state.current.connections.filter( {
                                        (conn: Connection) -> Bool in conn.graphId == state.current.currentGraphId!
                                     })
                                     ,
                                     dispatch: { (action: Action) in state.dispatch(action) })
             
                    // this is what the state defaults to
                case Screens.graphSelection:
                    log("routing to Screens.graphSelection")
                    GraphSelectionView(graphs: state.current.graphs,
                                       nodes: state.current.nodes,
                                       connections: state.current.connections,
                                       dispatch: { (action: Action) in state.dispatch(action) })
                    
                default:
                    log("defaulting to GraphSelectionView")
                    GraphSelectionView(graphs: state.current.graphs,
                                       nodes: state.current.nodes,
                                       connections: state.current.connections,
                                       dispatch: { (action: Action) in state.dispatch(action) })
            }
        }
        
        
        
        // how to handle if no graphs yet?
//        GraphSelectionView(graphs: state.current.graphs,
//                           nodes: state.current.nodes,
//                           connections: state.current.connections,
//                           dispatch: { (action: Action) in state.dispatch(action) })
        
//        GraphEditorChild(graphId: tempGraphId, // hardcode
//                         nodeCount: state.current.nodes.count,
//                         nodes: state.current.nodes.isEmpty ? [Node(graphId: tempGraphId)] : state.current.nodes,
//                         connections: state.current.connections,
//                         dispatch: { (action: Action) in state.dispatch(action) })
//
        
        
        
//        VStack {
//            // We just directly grab the data from the state
//            // ... can also pass this down later?
////            Text(String(state.current.counter))
//            Text(String(state.current.fun.count))
//            Button(action: state.dispatch(CounterActionIncrease())) {
//                log("redux ContentView: dispatch increment")
//                Text("Increase")
//            }
//            Button(action: state.dispatch(CounterActionDecrease())) {
//                log("redux ContentView: dispatch decrement")
//                Text("Decrease")
//            }
//            ForEach(state.current.muchFun, id: \.id) { (f: Fun) in
//                AuthorView(f: f)
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
