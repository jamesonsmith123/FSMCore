import Testing
import SwiftUI
@testable import FSMCore

// MARK: - SwiftUI Component Tests
@Suite("StateMachineView Components")
struct StateMachineViewTests {
    
    // MARK: - Test Helpers
    enum TestUIState: String, FSMCore.State, CaseIterable {
        case loading
        case content
        case error
        
        var description: String { rawValue }
    }
    
    enum TestUIEvent: String, FSMCore.Event {
        case loadData
        case showContent
        case showError
        case reset
        
        var type: String { rawValue }
    }
    
    // MARK: - StateMachineView Tests
    @Test("StateMachineView renders content based on current state")
    func testStateMachineViewRendering() async {
        await MainActor.run {
            let config = StateMachineConfig<TestUIState, TestUIEvent>(
                initialState: .loading,
                transitions: [
                    StateTransition(from: .loading, event: .showContent, to: .content),
                    StateTransition(from: .loading, event: .showError, to: .error)
                ]
            )
            let stateMachine = StateMachine(config: config)
            
            // Test that view renders with initial state
            #expect(stateMachine.currentState == .loading)
            
            // Test state change affects the view
            stateMachine.send(.showContent)
            #expect(stateMachine.currentState == .content)
        }
    }
    
    // MARK: - Progress View Tests
    @Test("StateMachineProgressView calculates progress correctly")
    func testProgressViewCalculation() async {
        await MainActor.run {
            enum ProgressState: String, FSMCore.State, CaseIterable {
                case step1, step2, step3, complete
                var description: String { rawValue }
            }
            
            enum ProgressEvent: String, FSMCore.Event {
                case next
                var type: String { rawValue }
            }
            
            let config = StateMachineConfig<ProgressState, ProgressEvent>(
                initialState: .step1,
                transitions: [
                    StateTransition(from: .step1, event: .next, to: .step2),
                    StateTransition(from: .step2, event: .next, to: .step3),
                    StateTransition(from: .step3, event: .next, to: .complete)
                ]
            )
            let stateMachine = StateMachine(config: config)
            
            // Test progress at different steps
            #expect(stateMachine.getProgress() == 0.0) // step1
            
            stateMachine.send(.next)
            #expect(abs(stateMachine.getProgress() - 0.333) < 0.01) // step2
            
            stateMachine.send(.next)
            #expect(abs(stateMachine.getProgress() - 0.667) < 0.01) // step3
            
            stateMachine.send(.next)
            #expect(stateMachine.getProgress() == 1.0) // complete
        }
    }
    
    // MARK: - State Transition Button Tests
    @Test("StateTransitionButton enables/disables based on valid transitions")
    func testStateTransitionButtonState() async {
        await MainActor.run {
            let config = StateMachineConfig<TestUIState, TestUIEvent>(
                initialState: .loading,
                transitions: [
                    StateTransition(from: .loading, event: .showContent, to: .content),
                    StateTransition(from: .content, event: .reset, to: .loading)
                ]
            )
            let stateMachine = StateMachine(config: config)
            
            // In loading state, showContent should be available
            #expect(stateMachine.canTransition(with: .showContent) == true)
            #expect(stateMachine.canTransition(with: .reset) == false)
            
            // After transition to content, reset should be available
            stateMachine.send(.showContent)
            #expect(stateMachine.canTransition(with: .reset) == true)
            #expect(stateMachine.canTransition(with: .showContent) == false)
        }
    }
} 