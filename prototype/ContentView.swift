//
//  ContentView.swift
//  prototype
//
//  Created by cjc on 11/1/20.
//

import UIKit
import SwiftUI
import AVFoundation
import ReSwift
import Combine
import Foundation


/* ----------------------------------------------------------------
 ReSwift + SwiftUI: taken from ReSwiftUI-StoreSubscriber
 https://github.com/ReSwift/ReSwift/issues/455#issuecomment-714791966
 ---------------------------------------------------------------- */

protocol HasName {
    var name: String { get }
}

struct ChangeName: Action {
    let to: String
}

func nameReducer(action: Action, state: String?) -> String {
    switch action {
    case let action as ChangeName:
        return action.to
    default:
        return state ?? ""
    }
}

struct StoreSubscriber<State, Content: View>: View {
    let content: (State, @escaping DispatchFunction) -> Content

    @EnvironmentObject var store: AnyObservableStore

    init(@ViewBuilder content: @escaping (State, @escaping DispatchFunction) -> Content) {
        self.content = content
    }

    var body: some View {
        content(store.state() as! State, store.dispatch)
    }
}

struct ContentView: View {
    var body: some View {
        StoreSubscriber { (state: HasName, dispatch: @escaping DispatchFunction) in
            VStack {
                Text(state.name)
                TextField("Name", text: Binding(
                    get: { state.name },
                    set: { dispatch(ChangeName(to: $0)) }
                ))
            }
        }
    }
}

struct ContentView_Previews : PreviewProvider {
    private struct MockState: StateType, HasName {
        var name: String = "mock"
    }

    private static func mockReducer(action: Action, state: MockState?) -> MockState {
        return MockState(
            name: nameReducer(action: action, state: state?.name)
        )
    }

    // injects store into environment
    static var previews: some View {
        ContentView()
            .environmentObject(
                AnyObservableStore(store: ObservableStore(reducer: mockReducer, state: MockState()))
        )
    }
}


/* ----------------------------------------------------------------
 From ReSwiftUI-StoreSubscriber's SceneDelegate
 https://github.com/ReSwift/ReSwift/issues/455#issuecomment-714791966
 ---------------------------------------------------------------- */

protocol ObservableStoreType: DispatchingStoreType, ObservableObject {

    associatedtype State: StateType

    /// The current state stored in the store.
    var state: State! { get }
}

class ObservableStore<State: StateType>: Store<State>, ObservableStoreType {

    override func _defaultDispatch(action: Action) {
        objectWillChange.send()
        super._defaultDispatch(action: action)
    }
}


class AnyObservableStore: ObservableObject {
    let state: () -> Any?
    let dispatch: (Action) -> Void

    var disposeBag: [AnyCancellable] = []

    init<State>(store: ObservableStore<State>) {
        state = { store.state as Any? }
        dispatch = store.dispatch

        disposeBag.append(
            store.objectWillChange.sink { [unowned self] in
                self.objectWillChange.send()
            }
        )
    }
}

struct AppState: StateType, Equatable, HasName {
    var name: String
}

func appReducer(action: Action, state: AppState?) -> AppState {
    return AppState(
        name: nameReducer(action: action, state: state?.name)
    )
}

