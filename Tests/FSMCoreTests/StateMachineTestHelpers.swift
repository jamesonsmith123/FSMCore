import Testing
@testable import FSMCore

// MARK: - Test Helper Utilities
struct StateMachineTestHelper {
    
    /// Creates a simple state machine for testing purposes
    @MainActor
    static func createSimpleTestMachine<S: FSMState, E: FSMEvent>(
        initialState: S,
        transitions: [StateTransition<S, E>],
        onStateChange: ((S, S) -> Void)? = nil
    ) -> StateMachine<S, E> {
        let config = StateMachineConfig<S, E>(
            initialState: initialState,
            transitions: transitions,
            onStateChange: onStateChange
        )
        return StateMachine(config: config)
    }
    
    /// Executes a sequence of events and returns the resulting states
    @MainActor
    static func executeEventSequence<S: FSMState, E: FSMEvent>(
        stateMachine: StateMachine<S, E>,
        events: [E]
    ) -> [S] {
        var states: [S] = [stateMachine.currentState]
        
        for event in events {
            stateMachine.send(event)
            states.append(stateMachine.currentState)
        }
        
        return states
    }
    
    /// Verifies a state machine follows an expected state sequence for given events
    @MainActor
    static func verifyStateSequence<S: FSMState, E: FSMEvent>(
        stateMachine: StateMachine<S, E>,
        events: [E],
        expectedStates: [S],
        file: String = #file, line: Int = #line
    ) {
        let actualStates = executeEventSequence(stateMachine: stateMachine, events: events)
        
        if actualStates != expectedStates {
            Issue.record("""
                State sequence mismatch:
                Expected: \(expectedStates)
                Actual: \(actualStates)
                Events: \(events)
                """)
        }
    }
    
    /// Creates a mock state machine with logging capabilities using a reference type for the log
    @MainActor
    static func createLoggingStateMachine<S: FSMState, E: FSMEvent>(
        initialState: S,
        transitions: [StateTransition<S, E>],
        logger: MockLogger
    ) -> StateMachine<S, E> {
        let config = StateMachineConfig<S, E>(
            initialState: initialState,
            transitions: transitions,
            onStateChange: { previous, current in
                logger.log("\(previous) -> \(current)")
            }
        )
        return StateMachine(config: config)
    }
}

// MARK: - Common Test State and Event Definitions
enum LinearFlowState: String, FSMState, CaseIterable {
    case step1, step2, step3, completed
    var description: String { rawValue }
}

enum LinearFlowEvent: String, FSMEvent {
    case next, previous, reset
    var type: String { rawValue }
}

enum LoadingState: String, FSMState, CaseIterable {
    case idle, loading, success, error
    var description: String { rawValue }
}

enum LoadingEvent: String, FSMEvent {
    case start, succeed, fail, reset, retry
    var type: String { rawValue }
}

enum FormState: String, FSMState, CaseIterable {
    case editing, submitting, success, error
    var description: String { rawValue }
}

enum FormEvent: String, FSMEvent {
    case submit, succeed, fail, reset
    var type: String { rawValue }
}

// MARK: - Test State Machines for Common Patterns
extension StateMachineTestHelper {
    
    /// Creates a linear flow state machine (step1 -> step2 -> step3 -> completed)
    @MainActor
    static func createLinearFlowMachine() -> StateMachine<LinearFlowState, LinearFlowEvent> {
        let config = StateMachineConfig<LinearFlowState, LinearFlowEvent>(
            initialState: .step1,
            transitions: [
                StateTransition(from: .step1, event: .next, to: .step2),
                StateTransition(from: .step2, event: .next, to: .step3),
                StateTransition(from: .step3, event: .next, to: .completed),
                StateTransition(from: .step2, event: .previous, to: .step1),
                StateTransition(from: .step3, event: .previous, to: .step2),
                StateTransition(from: .completed, event: .reset, to: .step1)
            ]
        )
        return StateMachine(config: config)
    }
    
    /// Creates a loading state machine (idle -> loading -> success/error)
    @MainActor
    static func createLoadingMachine() -> StateMachine<LoadingState, LoadingEvent> {
        let config = StateMachineConfig<LoadingState, LoadingEvent>(
            initialState: .idle,
            transitions: [
                StateTransition(from: .idle, event: .start, to: .loading),
                StateTransition(from: .loading, event: .succeed, to: .success),
                StateTransition(from: .loading, event: .fail, to: .error),
                StateTransition(from: .success, event: .reset, to: .idle),
                StateTransition(from: .error, event: .reset, to: .idle),
                StateTransition(from: .error, event: .retry, to: .loading)
            ]
        )
        return StateMachine(config: config)
    }
    
    /// Creates a form state machine with validation
    @MainActor
    static func createFormMachine(isValid: @escaping () -> Bool) -> StateMachine<FormState, FormEvent> {
        let config = StateMachineConfig<FormState, FormEvent>(
            initialState: .editing,
            transitions: [
                StateTransition(
                    from: .editing,
                    event: .submit,
                    to: .submitting,
                    guard: { _, _ in isValid() }
                ),
                StateTransition(from: .submitting, event: .succeed, to: .success),
                StateTransition(from: .submitting, event: .fail, to: .error),
                StateTransition(from: .success, event: .reset, to: .editing),
                StateTransition(from: .error, event: .reset, to: .editing)
            ]
        )
        return StateMachine(config: config)
    }
}

// MARK: - Test Assertion Helpers
extension StateMachine {
    
    /// Asserts that the current state matches the expected state
    func assertCurrentState(_ expectedState: S) {
        if currentState != expectedState {
            Issue.record("Expected state \(expectedState), but current state is \(currentState)")
        }
    }
    
    /// Asserts that a transition with the given event is possible
    func assertCanTransition(with event: E) {
        if !canTransition(with: event) {
            Issue.record("Expected to be able to transition with event \(event) from state \(currentState)")
        }
    }
    
    /// Asserts that a transition with the given event is not possible
    func assertCannotTransition(with event: E) {
        if canTransition(with: event) {
            Issue.record("Expected to NOT be able to transition with event \(event) from state \(currentState)")
        }
    }
    
    /// Asserts that the progress matches the expected value (with tolerance)
    func assertProgress(_ expectedProgress: Double, tolerance: Double = 0.001) {
        let actualProgress = getProgress()
        if abs(actualProgress - expectedProgress) > tolerance {
            Issue.record("Expected progress \(expectedProgress), but got \(actualProgress)")
        }
    }
}

// MARK: - Mock Objects for Testing
@MainActor
class MockStateChangeObserver<S: FSMState> {
    private(set) var stateChanges: [(from: S, to: S)] = []
    
    var onStateChange: (S, S) -> Void {
        return { [weak self] from, to in
            self?.stateChanges.append((from: from, to: to))
        }
    }
    
    func reset() {
        stateChanges.removeAll()
    }
    
    var changeCount: Int {
        stateChanges.count
    }
    
    var lastChange: (from: S, to: S)? {
        stateChanges.last
    }
}

class MockActionExecutor {
    private(set) var executedActions: [String] = []
    
    func createAction(name: String) -> (Any, Any) -> Void {
        return { [weak self] _, _ in
            self?.executedActions.append(name)
        }
    }
    
    func reset() {
        executedActions.removeAll()
    }
    
    var executionCount: Int {
        executedActions.count
    }
    
    var lastAction: String? {
        executedActions.last
    }
}

class MockGuardCondition {
    var shouldAllow: Bool = true
    private(set) var evaluationCount: Int = 0
    
    var guardFunction: (Any, Any) -> Bool {
        return { [weak self] _, _ in
            self?.evaluationCount += 1
            return self?.shouldAllow ?? true
        }
    }
    
    func reset() {
        evaluationCount = 0
        shouldAllow = true
    }
}

class MockLogger {
    private(set) var logs: [String] = []
    
    func log(_ message: String) {
        logs.append(message)
    }
    
    func reset() {
        logs.removeAll()
    }
    
    var isEmpty: Bool {
        logs.isEmpty
    }
} 