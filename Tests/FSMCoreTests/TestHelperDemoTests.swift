import Testing
@testable import FSMCore

// MARK: - Test Helper Demo Tests
@Suite("Test Helper Demonstrations")
struct TestHelperDemoTests {
    
    // MARK: - Using StateMachineTestHelper
    @Test("Demonstrate using test helper for linear flow")
    func testLinearFlowWithHelper() async {
        await MainActor.run {
            let machine = StateMachineTestHelper.createLinearFlowMachine()
            
            // Test using helper assertions
            machine.assertCurrentState(.step1)
            machine.assertCanTransition(with: .next)
            machine.assertCannotTransition(with: .previous)
            
            // Test progress assertions
            machine.assertProgress(0.0)
            
            // Test event sequence helper
            StateMachineTestHelper.verifyStateSequence(
                stateMachine: machine,
                events: [.next, .next, .next],
                expectedStates: [.step1, .step2, .step3, .completed]
            )
        }
    }
    
    @Test("Demonstrate using test helper for loading flow")
    func testLoadingFlowWithHelper() async {
        await MainActor.run {
            let machine = StateMachineTestHelper.createLoadingMachine()
            
            // Test success path
            StateMachineTestHelper.verifyStateSequence(
                stateMachine: machine,
                events: [.start, .succeed],
                expectedStates: [.idle, .loading, .success]
            )
            
            // Reset and test error path
            machine.send(.reset)
            machine.assertCurrentState(.idle)
            
            StateMachineTestHelper.verifyStateSequence(
                stateMachine: machine,
                events: [.start, .fail, .retry, .succeed],
                expectedStates: [.idle, .loading, .error, .loading, .success]
            )
        }
    }
    
    // MARK: - Using Mock Objects
    @Test("Demonstrate using mock state change observer")
    func testWithMockStateChangeObserver() async {
        await MainActor.run {
            let observer = MockStateChangeObserver<LoadingState>()
            
            let config = StateMachineConfig<LoadingState, LoadingEvent>(
                initialState: .idle,
                transitions: [
                    StateTransition(from: .idle, event: .start, to: .loading),
                    StateTransition(from: .loading, event: .succeed, to: .success)
                ],
                onStateChange: observer.onStateChange
            )
            
            let machine = StateMachine(config: config)
            
            // Initially no changes
            #expect(observer.changeCount == 0)
            
            // Trigger some state changes
            machine.send(.start)
            machine.send(.succeed)
            
            // Verify observer captured the changes
            #expect(observer.changeCount == 2)
            #expect(observer.stateChanges[0].from == .idle)
            #expect(observer.stateChanges[0].to == .loading)
            #expect(observer.stateChanges[1].from == .loading)
            #expect(observer.stateChanges[1].to == .success)
            #expect(observer.lastChange?.to == .success)
        }
    }
    
    @Test("Demonstrate using mock action executor")
    func testWithMockActionExecutor() async {
        await MainActor.run {
            let actionExecutor = MockActionExecutor()
            
            let config = StateMachineConfig<LoadingState, LoadingEvent>(
                initialState: .idle,
                transitions: [
                    StateTransition(
                        from: .idle,
                        event: .start,
                        to: .loading,
                        action: actionExecutor.createAction(name: "startLoading")
                    ),
                    StateTransition(
                        from: .loading,
                        event: .succeed,
                        to: .success,
                        action: actionExecutor.createAction(name: "handleSuccess")
                    )
                ]
            )
            
            let machine = StateMachine(config: config)
            
            // Initially no actions executed
            #expect(actionExecutor.executionCount == 0)
            
            // Trigger transitions that have actions
            machine.send(.start)
            #expect(actionExecutor.executionCount == 1)
            #expect(actionExecutor.lastAction == "startLoading")
            
            machine.send(.succeed)
            #expect(actionExecutor.executionCount == 2)
            #expect(actionExecutor.lastAction == "handleSuccess")
            #expect(actionExecutor.executedActions == ["startLoading", "handleSuccess"])
        }
    }
    
    @Test("Demonstrate using mock guard condition")
    func testWithMockGuardCondition() async {
        await MainActor.run {
            let guardCondition = MockGuardCondition()
            
            let config = StateMachineConfig<FormState, FormEvent>(
                initialState: .editing,
                transitions: [
                    StateTransition(
                        from: .editing,
                        event: .submit,
                        to: .submitting,
                        guard: guardCondition.guardFunction
                    )
                ]
            )
            
            let machine = StateMachine(config: config)
            
            // Test with guard allowing transition
            guardCondition.shouldAllow = true
            machine.send(.submit)
            #expect(machine.currentState == .submitting)
            #expect(guardCondition.evaluationCount == 1)
            
            // Reset machine to editing state (create new machine for demo)
            let newConfig = StateMachineConfig<FormState, FormEvent>(
                initialState: .editing,
                transitions: [
                    StateTransition(
                        from: .editing,
                        event: .submit,
                        to: .submitting,
                        guard: guardCondition.guardFunction
                    )
                ]
            )
            let newMachine = StateMachine(config: newConfig)
            
            // Test with guard preventing transition
            guardCondition.shouldAllow = false
            newMachine.send(.submit)
            #expect(newMachine.currentState == .editing) // Should stay in editing
            #expect(guardCondition.evaluationCount == 2) // Guard was evaluated again
        }
    }
    
    // MARK: - Using Logging Helper
    @Test("Demonstrate using logging state machine")
    func testWithLoggingStateMachine() async {
        await MainActor.run {
            let logger = MockLogger()
            
            let machine = StateMachineTestHelper.createLoggingStateMachine(
                initialState: LoadingState.idle,
                transitions: [
                    StateTransition(from: .idle, event: LoadingEvent.start, to: .loading),
                    StateTransition(from: .loading, event: LoadingEvent.succeed, to: .success),
                    StateTransition(from: .loading, event: LoadingEvent.fail, to: .error)
                ],
                logger: logger
            )
            
            // Initially no log entries
            #expect(logger.isEmpty)
            
            // Trigger state changes and verify logging
            machine.send(.start)
            #expect(logger.logs == ["idle -> loading"])
            
            machine.send(.succeed)
            #expect(logger.logs == ["idle -> loading", "loading -> success"])
        }
    }
    
    // MARK: - Complex Integration Test
    @Test("Demonstrate complex integration test with all helpers")
    func testComplexIntegrationWithAllHelpers() async {
        await MainActor.run {
            let logger = MockLogger()
            let observer = MockStateChangeObserver<FormState>()
            let actionExecutor = MockActionExecutor()
            let guardCondition = MockGuardCondition()
            
            // Create a complex state machine with all features
            let config = StateMachineConfig<FormState, FormEvent>(
                initialState: .editing,
                transitions: [
                    StateTransition(
                        from: .editing,
                        event: .submit,
                        to: .submitting,
                        guard: guardCondition.guardFunction,
                        action: actionExecutor.createAction(name: "startSubmission")
                    ),
                    StateTransition(
                        from: .submitting,
                        event: .succeed,
                        to: .success,
                        action: actionExecutor.createAction(name: "handleSubmissionSuccess")
                    ),
                    StateTransition(
                        from: .submitting,
                        event: .fail,
                        to: .error,
                        action: actionExecutor.createAction(name: "handleSubmissionError")
                    ),
                    StateTransition(from: .success, event: .reset, to: .editing),
                    StateTransition(from: .error, event: .reset, to: .editing)
                ],
                onStateChange: { previous, current in
                    logger.log("\(previous) -> \(current)")
                    observer.onStateChange(previous, current)
                }
            )
            
            let machine = StateMachine(config: config)
            
            // Test successful submission flow
            guardCondition.shouldAllow = true
            
            machine.send(.submit)
            machine.send(.succeed)
            
            // Verify all aspects
            #expect(machine.currentState == .success)
            #expect(guardCondition.evaluationCount == 1)
            #expect(actionExecutor.executionCount == 2)
            #expect(actionExecutor.executedActions == ["startSubmission", "handleSubmissionSuccess"])
            #expect(observer.changeCount == 2)
            #expect(logger.logs == ["editing -> submitting", "submitting -> success"])
            
            // Test error recovery
            machine.send(.reset)
            
            // Now test failure flow
            guardCondition.shouldAllow = true // Still allow the guard to pass
            
            machine.send(.submit)
            machine.send(.fail)
            
            #expect(machine.currentState == .error)
            #expect(actionExecutor.executedActions.contains("handleSubmissionError"))
            #expect(observer.changeCount == 5) // 2 previous + 2 new transitions + 1 reset = 5 total
        }
    }
} 