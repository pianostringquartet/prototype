//
//  Redux.swift
//  prototype
//
//  Created by cjc on 11/8/20.
//

import SwiftUI
import Foundation
import ReSwift


/* ----------------------------------------------------------------
 Adapting ReSwift for SwiftUI
 ---------------------------------------------------------------- */

typealias Dispatch = (Action) -> Void

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
//        log("ObservableState init called")
        self.store = store
        self.current = store.state
        
        // here we might also want to retrieve
        
        store.subscribe(self)
    }
    
    // might want to saved UD state here?
    deinit {
//        log("ObservableState deinit called")
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
//        log("ObservableState: StoreSubscriber: newState called")
        DispatchQueue.main.async {
            self.current = state
        }
    }
}
