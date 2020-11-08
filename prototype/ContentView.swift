//
//  ContentView.swift
//  prototype
//
//  Created by cjc on 11/1/20.
//

import SwiftUI
import AVFoundation

import ReSwift


// For debug printing from simulator
func log(_ log: String) -> EmptyView {
    print("** \(log)")
    return EmptyView()
}

// MARK: ReSwift Example Setup

//struct AppState: StateType {
//    var counter: Int = 0
//}

struct AppState: StateType, Codable {
//    var counter: Int = 0
//    var counter: Int = 5
    var fun: Fun = Fun(name: "Molly Bloom")
    var muchFun: [Fun] = [Fun(name: "James Joyce"), Fun(name: "Marcel Proust")]
    
//    func persist() {
//    }
    
}

struct CounterActionIncrease: Action {}
struct CounterActionDecrease: Action {}


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



// seems to be called first?
func counterReducer(action: Action, state: AppState?) -> AppState {
    log("counterReducer called")
    print("counterReducer printed")
    
    var defaultState: AppState = AppState()
    
    if let persistedState = pullState() {
        log("there was persistedState: \(persistedState)")
        defaultState = persistedState
    }
    
    
//    var state = state ?? AppState()
    
//    var state = state ?? AppState()
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
    default:
        break
    }

    log("about to return state in reducer: state: \(state)")
    saveState(state: state)
    return state
}


// here is where we declare the store
// we define it here, outside any view?
// ... where else to put this?
let mainStore = Store<AppState>(
    reducer: counterReducer,
    state: nil
)


struct MyCountView: View {
    
    var body: some View {
     return EmptyView()
    }
}

// MARK: ContentView

struct ContentView: View {
//struct XContentView: View {

    // MARK: Private Properties

    @ObservedObject private var state = ObservableState(store: mainStore)

    // MARK: Body

    var body: some View {
        log("redux ContentView: body")
        VStack {
            // We just directly grab the data from the state
            // ... can also pass this down later?
//            Text(String(state.current.counter))
            Text(String(state.current.fun.count))
            Button(action: state.dispatch(CounterActionIncrease())) {
                log("redux ContentView: dispatch increment")
                Text("Increase")
            }
            Button(action: state.dispatch(CounterActionDecrease())) {
                log("redux ContentView: dispatch decrement")
                Text("Decrease")
            }
            ForEach(state.current.muchFun, id: \.id) { (f: Fun) in
                Text("\(f.name) has \(f.count) books.")
            }
        }
    }
}




// MARK: ObservableState

public class ObservableState<T>: ObservableObject where T: StateType {

    // MARK: Public properties
    // ie access this from the outside like `state.current.counter`
    @Published public var current: T
    
    // MARK: Private properties
    
    private var store: Store<T>
    
    // MARK: Lifecycle
    
    // might want to retrieve UD state here?
    public init(store: Store<T>) {
        log("ObservableState init called")
        self.store = store
        self.current = store.state
        
        // here we might also want to retrieve
        
        store.subscribe(self)
    }
    
    // might want to saved UD state here?
    deinit {
        log("ObservableState deinit called")
        store.unsubscribe(self)
    }
    
    // MARK: Public methods
    
    public func dispatch(_ action: Action) {
        log("ObservableState dispatch 1 called")
        store.dispatch(action)
    }
    
    public func dispatch(_ action: Action) -> () -> Void {
        log("ObservableState dispatch 2 called")
        return {
//        {
            self.store.dispatch(action)
        }
    }
}

extension ObservableState: StoreSubscriber {
    
    // MARK: - <StoreSubscriber>
    
    public func newState(state: T) {
        log("ObservableState: StoreSubscriber: newState called")
        DispatchQueue.main.async {
            self.current = state
        }
    }
}

///* ----------------------------------------------------------------
// PREVIEW
// ---------------------------------------------------------------- */
//

// can build and run on simulator etc. WITHOUT THIS method
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


// class vs struct here?
class Prospect: Identifiable, Codable {
    var id = UUID()
    var name = "Anon"
    var emailAddress = ""
    var count = 0
    fileprivate(set) var isContacted = false
}

// State is also an ObservableObject
class Prospects: ObservableObject {
    @Published var people: [Prospect]
    
    init() {
        if let data = UserDefaults.standard.data(forKey: "SavedData") {
            if let decoded = try? JSONDecoder().decode([Prospect].self, from: data) {
                self.people = decoded
                return
            }
        }
        self.people = []
    }
    
    // writing to UserDefaults; called after Prospects is mutated
    func save() {
        // try to SAVE the data
        if let encoded = try? JSONEncoder().encode(people) {
            UserDefaults.standard.set(encoded, forKey: "SavedData")
        }
    }
    
    func toggle(_ prospect: Prospect) {
        objectWillChange.send()
        prospect.isContacted.toggle()
        // ie call save when we change a prospect
        save()
    }
    
}


struct Fun: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var count: Int = 0
}

struct FunContentView: View {
    
    @State private var fun: Fun
    
    init() {
        log("FunView: init")
        
        if let data = UserDefaults.standard.data(forKey: "SavedData") {
//            if let decoded = try? JSONDecoder().decode([Prospect].self, from: data) {
            if let decoded = try? JSONDecoder().decode(Fun.self, from: data) {
//                self.people = decoded
                self._fun = State.init(initialValue: decoded)
                return
            }
        }
        self._fun = State.init(initialValue: Fun(name: "Rebecca"))
    }
    
    func save() {
        log("FunView: save")
//        if let encoded = try? JSONEncoder().encode(people) {
        if let encoded = try? JSONEncoder().encode(fun) {
            UserDefaults.standard.set(encoded, forKey: "SavedData")
        }
    }
    
    var body: some View {
        log("FunView: body")
        Text("Fun Name: \(fun.name)")
        Text("Fun Count: \(fun.count)")
        Button("Fun Count!") {
            self.fun.count += 1
            save()
        }

    }
}



struct YContentView: View {
    
//    @State private var tapCount = 0
    // okay for simple cases, but not for decoding etc.?
    @State private var tapCount = UserDefaults.standard.integer(forKey: "Tap")


    var body: some View {
        Button("TapCount \(tapCount):") {
            // modify the count
            self.tapCount += 1
            // then update UserDefaults
            UserDefaults.standard.set(self.tapCount, forKey: "Tap")
            
            
            
            

            //            self.prospects.people.append(person)
//            self.prospects.save()
        }
    }
}

// user defaults
//struct ContentView: View {
//
////    @State private var tapCount = 0
//    @State private var tapCount = UserDefaults.standard.integer(forKey: "Tap")
//
//
//    var body: some View {
//        Button("Tap count: \(tapCount)") {
//            // modify the count
//            self.tapCount += 1
//
//            // then update UserDefaults
//            UserDefaults.standard.set(self.tapCount, forKey: "Tap")
//        }
//    }
//}


