import Foundation
import SwiftUI

// MARK: - Core State Machine Protocol
protocol State: Hashable, CaseIterable {
    var description: String { get }
}

protocol Event: Hashable {
    var type: String { get }
}

// MARK: - State Transition
struct StateTransition<S: State, E: Event> {
    let from: S
    let event: E
    let to: S
    let guardCondition: ((S, E) -> Bool)?
    let action: ((S, E) -> Void)?
    
    init(from: S, event: E, to: S, guard guardCondition: ((S, E) -> Bool)? = nil, action: ((S, E) -> Void)? = nil) {
        self.from = from
        self.event = event
        self.to = to
        self.guardCondition = guardCondition
        self.action = action
    }
}

// MARK: - State Machine Configuration
struct StateMachineConfig<S: State, E: Event> {
    let initialState: S
    let transitions: [StateTransition<S, E>]
    let onStateChange: ((S, S) -> Void)?
    
    init(initialState: S, transitions: [StateTransition<S, E>], onStateChange: ((S, S) -> Void)? = nil) {
        self.initialState = initialState
        self.transitions = transitions
        self.onStateChange = onStateChange
    }
}

// MARK: - State Machine
@MainActor
class StateMachine<S: State, E: Event>: ObservableObject {
    @Published private(set) var currentState: S
    private let config: StateMachineConfig<S, E>
    private var transitionMap: [S: [E: StateTransition<S, E>]] = [:]
    
    init(config: StateMachineConfig<S, E>) {
        self.config = config
        self.currentState = config.initialState
        buildTransitionMap()
    }
    
    private func buildTransitionMap() {
        for transition in config.transitions {
            if transitionMap[transition.from] == nil {
                transitionMap[transition.from] = [:]
            }
            transitionMap[transition.from]?[transition.event] = transition
        }
    }
    
    func send(_ event: E) {
        guard let transition = transitionMap[currentState]?[event] else {
            print("No transition found for state: \(currentState) with event: \(event)")
            return
        }
        
        // Check guard condition
        if let guardCondition = transition.guardCondition, !guardCondition(currentState, event) {
            print("Guard condition failed for transition from \(currentState) to \(transition.to)")
            return
        }
        
        let previousState = currentState
        
        // Execute action before state change
        transition.action?(currentState, event)
        
        // Change state
        currentState = transition.to
        
        // Call state change callback
        config.onStateChange?(previousState, currentState)
        
        print("State transition: \(previousState) -> \(currentState) via \(event)")
    }
    
    func canTransition(with event: E) -> Bool {
        guard let transition = transitionMap[currentState]?[event] else {
            return false
        }
        
        if let guardCondition = transition.guardCondition {
            return guardCondition(currentState, event)
        }
        
        return true
    }
    
    func getAvailableTransitions() -> [E] {
        return Array(transitionMap[currentState]?.keys ?? [:].keys)
    }
    
    func getProgress() -> Double {
        let allStates = Array(S.allCases)
        guard let currentIndex = allStates.firstIndex(of: currentState) else { return 0 }
        return Double(currentIndex) / Double(max(1, allStates.count - 1))
    }
} 