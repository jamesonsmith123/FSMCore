import Testing
@testable import FSMCore

// MARK: - Test State and Event Definitions
enum TestState: String, State, CaseIterable {
    case idle
    case loading
    case success
    case error
    
    var description: String { rawValue }
}

enum TestEvent: String, Event {
    case start
    case succeed
    case fail
    case reset
    
    var type: String { rawValue }
}

enum FlowState: String, State, CaseIterable {
    case step1
    case step2
    case step3
    case step4
    case completed
    
    var description: String { rawValue }
}

enum FlowEvent: String, Event {
    case next
    case previous
    case skip
    case reset
    
    var type: String { rawValue }
}

// MARK: - State Machine Core Tests
@Suite("StateMachine Core Functionality")
struct StateMachineTests {
    
    // MARK: - Basic State Machine Tests
    @Test("State machine initializes with correct initial state")
    func testInitialState() async {
        await MainActor.run {
            let config = StateMachineConfig<TestState, TestEvent>(
                initialState: .idle,
                transitions: []
            )
            let stateMachine = StateMachine(config: config)
            
            #expect(stateMachine.currentState == .idle)
        }
    }
    
    @Test("State machine can transition between valid states")
    func testValidTransition() async {
        await MainActor.run {
            let config = StateMachineConfig<TestState, TestEvent>(
                initialState: .idle,
                transitions: [
                    StateTransition(from: .idle, event: .start, to: .loading)
                ]
            )
            let stateMachine = StateMachine(config: config)
            
            stateMachine.send(.start)
            #expect(stateMachine.currentState == .loading)
        }
    }
    
    @Test("State machine ignores invalid transitions")
    func testInvalidTransition() async {
        await MainActor.run {
            let config = StateMachineConfig<TestState, TestEvent>(
                initialState: .idle,
                transitions: [
                    StateTransition(from: .idle, event: .start, to: .loading)
                ]
            )
            let stateMachine = StateMachine(config: config)
            
            // Try to send an event that doesn't have a valid transition
            stateMachine.send(.succeed)
            #expect(stateMachine.currentState == .idle) // Should remain in idle
        }
    }
    
    @Test("State machine handles multiple transitions correctly")
    func testMultipleTransitions() async {
        await MainActor.run {
            let config = StateMachineConfig<TestState, TestEvent>(
                initialState: .idle,
                transitions: [
                    StateTransition(from: .idle, event: .start, to: .loading),
                    StateTransition(from: .loading, event: .succeed, to: .success),
                    StateTransition(from: .loading, event: .fail, to: .error),
                    StateTransition(from: .success, event: .reset, to: .idle),
                    StateTransition(from: .error, event: .reset, to: .idle)
                ]
            )
            let stateMachine = StateMachine(config: config)
            
            // Test success path
            stateMachine.send(.start)
            #expect(stateMachine.currentState == .loading)
            
            stateMachine.send(.succeed)
            #expect(stateMachine.currentState == .success)
            
            stateMachine.send(.reset)
            #expect(stateMachine.currentState == .idle)
        }
    }
    
    @Test("State machine handles error path correctly")
    func testErrorPath() async {
        await MainActor.run {
            let config = StateMachineConfig<TestState, TestEvent>(
                initialState: .idle,
                transitions: [
                    StateTransition(from: .idle, event: .start, to: .loading),
                    StateTransition(from: .loading, event: .fail, to: .error),
                    StateTransition(from: .error, event: .reset, to: .idle)
                ]
            )
            let stateMachine = StateMachine(config: config)
            
            stateMachine.send(.start)
            #expect(stateMachine.currentState == .loading)
            
            stateMachine.send(.fail)
            #expect(stateMachine.currentState == .error)
            
            stateMachine.send(.reset)
            #expect(stateMachine.currentState == .idle)
        }
    }
}

// MARK: - Guard Condition Tests
@Suite("Guard Conditions")
struct GuardConditionTests {
    
    @Test("Guard condition allows transition when true")
    func testGuardAllowsTransition() async {
        await MainActor.run {
            let config = StateMachineConfig<TestState, TestEvent>(
                initialState: .idle,
                transitions: [
                    StateTransition(
                        from: .idle,
                        event: .start,
                        to: .loading,
                        guard: { _, _ in true }
                    )
                ]
            )
            let stateMachine = StateMachine(config: config)
            
            stateMachine.send(.start)
            #expect(stateMachine.currentState == .loading)
        }
    }
    
    @Test("Guard condition prevents transition when false")
    func testGuardPreventsTransition() async {
        await MainActor.run {
            let config = StateMachineConfig<TestState, TestEvent>(
                initialState: .idle,
                transitions: [
                    StateTransition(
                        from: .idle,
                        event: .start,
                        to: .loading,
                        guard: { _, _ in false }
                    )
                ]
            )
            let stateMachine = StateMachine(config: config)
            
            stateMachine.send(.start)
            #expect(stateMachine.currentState == .idle) // Should remain in idle
        }
    }
    
    @Test("Guard condition receives correct state and event")
    func testGuardReceivesCorrectParameters() async {
        await MainActor.run {
            var receivedState: TestState?
            var receivedEvent: TestEvent?
            
            let config = StateMachineConfig<TestState, TestEvent>(
                initialState: .idle,
                transitions: [
                    StateTransition(
                        from: .idle,
                        event: .start,
                        to: .loading,
                        guard: { state, event in
                            receivedState = state
                            receivedEvent = event
                            return true
                        }
                    )
                ]
            )
            let stateMachine = StateMachine(config: config)
            
            stateMachine.send(.start)
            
            #expect(receivedState == .idle)
            #expect(receivedEvent == .start)
        }
    }
    
    @Test("Can transition method respects guard conditions")
    func testCanTransitionWithGuards() async {
        await MainActor.run {
            let config = StateMachineConfig<TestState, TestEvent>(
                initialState: .idle,
                transitions: [
                    StateTransition(
                        from: .idle,
                        event: .start,
                        to: .loading,
                        guard: { _, _ in false }
                    )
                ]
            )
            let stateMachine = StateMachine(config: config)
            
            #expect(stateMachine.canTransition(with: .start) == false)
        }
    }
}

// MARK: - Action Tests
@Suite("Actions")
struct ActionTests {
    
    @Test("Action is executed on successful transition")
    func testActionExecution() async {
        await MainActor.run {
            var actionExecuted = false
            
            let config = StateMachineConfig<TestState, TestEvent>(
                initialState: .idle,
                transitions: [
                    StateTransition(
                        from: .idle,
                        event: .start,
                        to: .loading,
                        action: { _, _ in
                            actionExecuted = true
                        }
                    )
                ]
            )
            let stateMachine = StateMachine(config: config)
            
            stateMachine.send(.start)
            
            #expect(actionExecuted == true)
            #expect(stateMachine.currentState == .loading)
        }
    }
    
    @Test("Action is not executed when guard fails")
    func testActionNotExecutedWhenGuardFails() async {
        await MainActor.run {
            var actionExecuted = false
            
            let config = StateMachineConfig<TestState, TestEvent>(
                initialState: .idle,
                transitions: [
                    StateTransition(
                        from: .idle,
                        event: .start,
                        to: .loading,
                        guard: { _, _ in false },
                        action: { _, _ in
                            actionExecuted = true
                        }
                    )
                ]
            )
            let stateMachine = StateMachine(config: config)
            
            stateMachine.send(.start)
            
            #expect(actionExecuted == false)
            #expect(stateMachine.currentState == .idle)
        }
    }
    
    @Test("Action receives correct state and event parameters")
    func testActionReceivesCorrectParameters() async {
        await MainActor.run {
            var receivedState: TestState?
            var receivedEvent: TestEvent?
            
            let config = StateMachineConfig<TestState, TestEvent>(
                initialState: .idle,
                transitions: [
                    StateTransition(
                        from: .idle,
                        event: .start,
                        to: .loading,
                        action: { state, event in
                            receivedState = state
                            receivedEvent = event
                        }
                    )
                ]
            )
            let stateMachine = StateMachine(config: config)
            
            stateMachine.send(.start)
            
            #expect(receivedState == .idle)
            #expect(receivedEvent == .start)
        }
    }
}

// MARK: - Progress Calculation Tests
@Suite("Progress Calculation")
struct ProgressTests {
    
    @Test("Progress calculation for linear flow")
    func testLinearFlowProgress() async {
        await MainActor.run {
            let config = StateMachineConfig<FlowState, FlowEvent>(
                initialState: .step1,
                transitions: [
                    StateTransition(from: .step1, event: .next, to: .step2),
                    StateTransition(from: .step2, event: .next, to: .step3),
                    StateTransition(from: .step3, event: .next, to: .step4),
                    StateTransition(from: .step4, event: .next, to: .completed)
                ]
            )
            let stateMachine = StateMachine(config: config)
            
            // Test progress at each step
            #expect(stateMachine.getProgress() == 0.0) // step1 (index 0)
            
            stateMachine.send(.next)
            #expect(stateMachine.getProgress() == 0.25) // step2 (index 1)
            
            stateMachine.send(.next)
            #expect(stateMachine.getProgress() == 0.5) // step3 (index 2)
            
            stateMachine.send(.next)
            #expect(stateMachine.getProgress() == 0.75) // step4 (index 3)
            
            stateMachine.send(.next)
            #expect(stateMachine.getProgress() == 1.0) // completed (index 4)
        }
    }
    
    @Test("Progress calculation handles single state")
    func testSingleStateProgress() async {
        await MainActor.run {
            enum SingleState: String, State, CaseIterable {
                case only
                var description: String { rawValue }
            }
            
            enum SingleEvent: String, Event {
                case noop
                var type: String { rawValue }
            }
            
            let config = StateMachineConfig<SingleState, SingleEvent>(
                initialState: .only,
                transitions: []
            )
            let stateMachine = StateMachine(config: config)
            
            // Single state should be 0% progress (start of range)
            #expect(stateMachine.getProgress() == 0.0)
        }
    }
}

// MARK: - Available Transitions Tests
@Suite("Available Transitions")
struct AvailableTransitionsTests {
    
    @Test("Available transitions returns correct events")
    func testAvailableTransitions() async {
        await MainActor.run {
            let config = StateMachineConfig<TestState, TestEvent>(
                initialState: .idle,
                transitions: [
                    StateTransition(from: .idle, event: .start, to: .loading),
                    StateTransition(from: .idle, event: .reset, to: .idle),
                    StateTransition(from: .loading, event: .succeed, to: .success)
                ]
            )
            let stateMachine = StateMachine(config: config)
            
            let availableFromIdle = Set(stateMachine.getAvailableTransitions())
            let expectedFromIdle: Set<TestEvent> = [.start, .reset]
            
            #expect(availableFromIdle == expectedFromIdle)
            
            // Transition to loading and check available transitions
            stateMachine.send(.start)
            let availableFromLoading = Set(stateMachine.getAvailableTransitions())
            let expectedFromLoading: Set<TestEvent> = [.succeed]
            
            #expect(availableFromLoading == expectedFromLoading)
        }
    }
    
    @Test("Available transitions returns empty array when no transitions")
    func testNoAvailableTransitions() async {
        await MainActor.run {
            let config = StateMachineConfig<TestState, TestEvent>(
                initialState: .success,
                transitions: [
                    StateTransition(from: .idle, event: .start, to: .loading)
                ]
            )
            let stateMachine = StateMachine(config: config)
            
            let available = stateMachine.getAvailableTransitions()
            #expect(available.isEmpty)
        }
    }
}

// MARK: - State Change Callback Tests
@Suite("State Change Callbacks")
struct StateChangeCallbackTests {
    
    @Test("State change callback is called on transition")
    func testStateChangeCallback() async {
        await MainActor.run {
            var callbackCalled = false
            var previousState: TestState?
            var currentState: TestState?
            
            let config = StateMachineConfig<TestState, TestEvent>(
                initialState: .idle,
                transitions: [
                    StateTransition(from: .idle, event: .start, to: .loading)
                ],
                onStateChange: { prev, curr in
                    callbackCalled = true
                    previousState = prev
                    currentState = curr
                }
            )
            let stateMachine = StateMachine(config: config)
            
            stateMachine.send(.start)
            
            #expect(callbackCalled == true)
            #expect(previousState == .idle)
            #expect(currentState == .loading)
        }
    }
    
    @Test("State change callback is not called on failed transition")
    func testStateChangeCallbackNotCalledOnFailure() async {
        await MainActor.run {
            var callbackCalled = false
            
            let config = StateMachineConfig<TestState, TestEvent>(
                initialState: .idle,
                transitions: [
                    StateTransition(
                        from: .idle,
                        event: .start,
                        to: .loading,
                        guard: { _, _ in false }
                    )
                ],
                onStateChange: { _, _ in
                    callbackCalled = true
                }
            )
            let stateMachine = StateMachine(config: config)
            
            stateMachine.send(.start)
            
            #expect(callbackCalled == false)
        }
    }
}

// MARK: - Can Transition Tests
@Suite("Can Transition")
struct CanTransitionTests {
    
    @Test("Can transition returns true for valid transitions")
    func testCanTransitionValid() async {
        await MainActor.run {
            let config = StateMachineConfig<TestState, TestEvent>(
                initialState: .idle,
                transitions: [
                    StateTransition(from: .idle, event: .start, to: .loading)
                ]
            )
            let stateMachine = StateMachine(config: config)
            
            #expect(stateMachine.canTransition(with: .start) == true)
        }
    }
    
    @Test("Can transition returns false for invalid transitions")
    func testCanTransitionInvalid() async {
        await MainActor.run {
            let config = StateMachineConfig<TestState, TestEvent>(
                initialState: .idle,
                transitions: [
                    StateTransition(from: .idle, event: .start, to: .loading)
                ]
            )
            let stateMachine = StateMachine(config: config)
            
            #expect(stateMachine.canTransition(with: .succeed) == false)
        }
    }
    
    @Test("Can transition respects guard conditions")
    func testCanTransitionWithGuard() async {
        await MainActor.run {
            var guardResult = true
            
            let config = StateMachineConfig<TestState, TestEvent>(
                initialState: .idle,
                transitions: [
                    StateTransition(
                        from: .idle,
                        event: .start,
                        to: .loading,
                        guard: { _, _ in guardResult }
                    )
                ]
            )
            let stateMachine = StateMachine(config: config)
            
            #expect(stateMachine.canTransition(with: .start) == true)
            
            guardResult = false
            #expect(stateMachine.canTransition(with: .start) == false)
        }
    }
} 