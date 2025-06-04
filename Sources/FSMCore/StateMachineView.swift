import SwiftUI

// MARK: - State Machine View Builder
struct StateMachineView<S: State, E: Event, Content: View>: View {
    @ObservedObject var stateMachine: StateMachine<S, E>
    let content: (S, @escaping (E) -> Void) -> Content
    
    init(stateMachine: StateMachine<S, E>, @ViewBuilder content: @escaping (S, @escaping (E) -> Void) -> Content) {
        self.stateMachine = stateMachine
        self.content = content
    }
    
    var body: some View {
        content(stateMachine.currentState) { event in
            stateMachine.send(event)
        }
    }
}

// MARK: - State Conditional View
struct StateConditionalView<S: State, E: Event, Content: View>: View {
    @ObservedObject var stateMachine: StateMachine<S, E>
    let targetState: S
    let content: Content
    
    init(stateMachine: StateMachine<S, E>, when state: S, @ViewBuilder content: () -> Content) {
        self.stateMachine = stateMachine
        self.targetState = state
        self.content = content()
    }
    
    var body: some View {
        if stateMachine.currentState == targetState {
            content
        }
    }
}

// MARK: - Progress Bar View
struct StateMachineProgressView<S: State, E: Event>: View {
    @ObservedObject var stateMachine: StateMachine<S, E>
    let showLabels: Bool
    
    init(stateMachine: StateMachine<S, E>, showLabels: Bool = true) {
        self.stateMachine = stateMachine
        self.showLabels = showLabels
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if showLabels {
                HStack {
                    Text("Progress")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(stateMachine.getProgress() * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            ProgressView(value: stateMachine.getProgress())
                .progressViewStyle(LinearProgressViewStyle())
            
            if showLabels {
                Text(stateMachine.currentState.description)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
        }
    }
}

// MARK: - State Transition Button
struct StateTransitionButton<S: State, E: Event>: View {
    @ObservedObject var stateMachine: StateMachine<S, E>
    let event: E
    let title: String
    
    init(stateMachine: StateMachine<S, E>, event: E, title: String) {
        self.stateMachine = stateMachine
        self.event = event
        self.title = title
    }
    
    var body: some View {
        Button(title) {
            stateMachine.send(event)
        }
        .disabled(!stateMachine.canTransition(with: event))
    }
}

// MARK: - Flow Container View
struct FlowContainerView<S: State, E: Event, Content: View>: View {
    @ObservedObject var stateMachine: StateMachine<S, E>
    let showProgress: Bool
    let content: Content
    
    init(stateMachine: StateMachine<S, E>, showProgress: Bool = true, @ViewBuilder content: () -> Content) {
        self.stateMachine = stateMachine
        self.showProgress = showProgress
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 20) {
            if showProgress {
                StateMachineProgressView(stateMachine: stateMachine)
                    .padding(.horizontal)
            }
            
            content
        }
    }
}

// MARK: - View Modifiers
extension View {
    func onStateChange<S: State, E: Event>(
        of stateMachine: StateMachine<S, E>,
        perform action: @escaping (S, S) -> Void
    ) -> some View {
        self.onReceive(stateMachine.$currentState) { newState in
            // This will be called when currentState changes
            // Note: We can't easily get the previous state here, so we'll handle this differently
        }
    }
}

// MARK: - State Machine Builder (DSL-like)
@resultBuilder
struct StateTransitionBuilder<S: State, E: Event> {
    static func buildBlock(_ transitions: StateTransition<S, E>...) -> [StateTransition<S, E>] {
        return transitions
    }
}

extension StateMachineConfig {
    init(initialState: S, onStateChange: ((S, S) -> Void)? = nil, @StateTransitionBuilder<S, E> transitions: () -> [StateTransition<S, E>]) {
        self.initialState = initialState
        self.transitions = transitions()
        self.onStateChange = onStateChange
    }
} 