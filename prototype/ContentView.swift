//
//  ContentView.swift
//  prototype
//
//  Created by cjc on 11/1/20.
//

import SwiftUI
import AVFoundation

import ReSwift

// MARK: ReSwift Example Setup

//struct AppState: StateType {
//    var counter: Int = 0
//}

struct AppState: StateType, Codable {
    var counter: Int = 0
    
    func persist() {
    }
    
}

struct CounterActionIncrease: Action {}
struct CounterActionDecrease: Action {}

func counterReducer(action: Action, state: AppState?) -> AppState {
    var state = state ?? AppState()

    switch action {
    case _ as CounterActionIncrease:
        state.counter += 1
    case _ as CounterActionDecrease:
        state.counter -= 1
    default:
        break
    }

    return state
}

let mainStore = Store<AppState>(
    reducer: counterReducer,
    state: nil
)

// MARK: ContentView

struct ContentView: View {
    
    // MARK: Private Properties
    
    @ObservedObject private var state = ObservableState(store: mainStore)

    // MARK: Body
    
    var body: some View {
        VStack {
            Text(String(state.current.counter))
            Button(action: state.dispatch(CounterActionIncrease())) {
                Text("Increase")
            }
            Button(action: state.dispatch(CounterActionDecrease())) {
                Text("Decrease")
            }
        }
    }
}

// MARK: ObservableState

public class ObservableState<T>: ObservableObject where T: StateType {

    // MARK: Public properties
    
    @Published public var current: T
    
    // MARK: Private properties
    
    private var store: Store<T>
    
    // MARK: Lifecycle
    
    public init(store: Store<T>) {
        self.store = store
        self.current = store.state
        
        store.subscribe(self)
    }
    
    deinit {
        store.unsubscribe(self)
    }
    
    // MARK: Public methods
    
    public func dispatch(_ action: Action) {
        store.dispatch(action)
    }
    
    public func dispatch(_ action: Action) -> () -> Void {
        {
            self.store.dispatch(action)
        }
    }
}

extension ObservableState: StoreSubscriber {
    
    // MARK: - <StoreSubscriber>
    
    public func newState(state: T) {
        DispatchQueue.main.async {
            self.current = state
        }
    }
}

///* ----------------------------------------------------------------
// PREVIEW
// ---------------------------------------------------------------- */
//
//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
//


// 2019, but not necessarily also SwiftUI?
// https://github.com/ReSwift/ReSwift/issues/110#issuecomment-497318214

class ReduxPersist: NSObject, StoreSubscriber {
    static let shared = ReduxPersist()
    var timer: Timer?

    override init() {
        super.init()
        mainStore.subscribe(self) { subcription in
//        store.subscribe(self) { subcription in
            subcription.select { state in state }
        }
    }
    
    func newState(state: StateType?) {
        print("ReduxPersist --> new State")
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.persistStore), userInfo: nil, repeats: false);
    }
    
    @objc func persistStore() {
//        store.state.persist()
        
        // the method persist() is just an implementation of Codable for each StateType in my project.
        mainStore.state.persist()
    }
}
