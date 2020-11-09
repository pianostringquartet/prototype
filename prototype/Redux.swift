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

public class ObservableState<T>: ObservableObject where T: StateType {

    @Published public var current: T
    
    private var store: Store<T>
    
    public init(store: Store<T>) {
        self.store = store
        self.current = store.state
        store.subscribe(self)
    }
    
    deinit {
        store.unsubscribe(self)
    }
    
    
    public func dispatch(_ action: Action) {
        store.dispatch(action)
    }
    
    public func dispatch(_ action: Action) -> () -> Void {
        return {
            self.store.dispatch(action)
        }
    }
}

extension ObservableState: StoreSubscriber {
    
    public func newState(state: T) {
        DispatchQueue.main.async {
            self.current = state
        }
    }
}
