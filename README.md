# FSMCore - Finite State Machine Library for SwiftUI

A powerful, type-safe Finite State Machine Swift package for SwiftUI applications, inspired by XState.

## 🚀 Features

- **Type-Safe**: Generic implementation ensures compile-time safety
- **SwiftUI Native**: Built specifically for SwiftUI with `@Published` state integration
- **Declarative**: Define states and transitions clearly and explicitly
- **Guard Conditions**: Conditional transitions based on custom logic
- **Actions**: Execute side effects during state transitions
- **Progress Tracking**: Built-in progress calculation for multi-step flows
- **Comprehensive Testing**: Full test suite with utilities and mock objects

## 📁 Package Structure

```
FSMCore/
├── Sources/FSMCore/
│   ├── StateMachine.swift       # Core state machine implementation
│   └── StateMachineView.swift   # SwiftUI integration components
├── Tests/FSMCoreTests/          # Comprehensive test suite
│   ├── StateMachineTests.swift      # Core functionality tests
│   ├── StateMachineViewTests.swift  # SwiftUI component tests
│   ├── StateMachineTestHelpers.swift # Test utilities and mocks
│   └── TestHelperDemoTests.swift    # Testing pattern examples
├── Package.swift               # Swift Package Manager configuration
├── README.md                   # This documentation
└── README_TESTING.md          # Comprehensive testing guide
```

## 📖 Quick Start

### Installation

#### Swift Package Manager
Add FSMCore to your `Package.swift`:
```swift
dependencies: [
    .package(url: "https://github.com/your-username/FSMCore", from: "1.0.0")
]
```

#### Xcode Package Dependencies
1. File → Add Package Dependencies
2. Enter the FSMCore repository URL
3. Select FSMCore as your target dependency

### Basic Usage

```swift
import FSMCore

// Define your states
enum AppState: String, State, CaseIterable {
    case loading, content, error
    var description: String { rawValue }
}

// Define your events
enum AppEvent: String, Event {
    case loadData, showContent, showError, retry
    var type: String { rawValue }
}

// Create your state machine
let config = StateMachineConfig<AppState, AppEvent>(
    initialState: .loading,
    transitions: [
        StateTransition(from: .loading, event: .showContent, to: .content),
        StateTransition(from: .loading, event: .showError, to: .error),
        StateTransition(from: .error, event: .retry, to: .loading)
    ]
)

@StateObject private var stateMachine = StateMachine(config: config)
```

### SwiftUI Integration

```swift
import SwiftUI
import FSMCore

struct ContentView: View {
    @StateObject private var stateMachine = StateMachine(config: config)
    
    var body: some View {
        StateMachineView(stateMachine: stateMachine) { state, sendEvent in
            switch state {
            case .loading: 
                LoadingView()
            case .content: 
                ContentView()
            case .error: 
                ErrorView { 
                    sendEvent(.retry) 
                }
            }
        }
    }
}
```

## 🎯 Core Components

### StateMachine
The heart of the library - a generic, observable state machine:

```swift
class StateMachine<S: State, E: Event>: ObservableObject {
    @Published private(set) var currentState: S
    
    func send(_ event: E)
    func canTransition(with event: E) -> Bool
    func getAvailableTransitions() -> [E]
    func getProgress() -> Double
}
```

### StateMachineView
SwiftUI component for reactive state machine UI:

```swift
StateMachineView(stateMachine: stateMachine) { state, sendEvent in
    // Your state-based UI here
}
```

### Advanced Features

#### Guard Conditions
```swift
StateTransition(
    from: .form, 
    event: .submit, 
    to: .submitting,
    guard: { isFormValid() }
)
```

#### Actions
```swift
StateTransition(
    from: .idle, 
    event: .start, 
    to: .loading,
    action: { logAnalytics("process_started") }
)
```

#### Progress Tracking
```swift
let progress = stateMachine.getProgress()
// Returns 0.0 to 1.0 for linear flows
```

## 🧪 Testing

Run the comprehensive test suite:

```bash
swift test
```

The package includes 31+ tests covering:
- Core state machine functionality
- SwiftUI component integration
- Guard conditions and actions
- Progress calculation
- Test utilities and helpers

See [README_TESTING.md](README_TESTING.md) for detailed testing documentation.

## 📚 Example Usage Patterns

### Multi-Step Onboarding Flow
```swift
enum OnboardingState: String, State, CaseIterable {
    case welcome, profile, preferences, complete
    var description: String { rawValue }
}

enum OnboardingEvent: String, Event {
    case next, back, skip, complete
    var type: String { rawValue }
}
```

### Loading States with Error Handling
```swift
enum LoadingState: String, State, CaseIterable {
    case idle, loading, success, error
    var description: String { rawValue }
}

enum LoadingEvent: String, Event {
    case load, success, failure, retry
    var type: String { rawValue }
}
```

### Form Validation Flow
```swift
enum FormState: String, State, CaseIterable {
    case editing, validating, valid, invalid, submitting, submitted
    var description: String { rawValue }
}
```

## 🔧 Configuration Options

### StateMachineConfig
```swift
let config = StateMachineConfig<MyState, MyEvent>(
    initialState: .idle,
    transitions: [
        // Your transitions here
    ],
    onStateChange: { from, to in
        print("Transitioned from \(from) to \(to)")
    }
)
```

### Transition Options
- **Basic**: `StateTransition(from:event:to:)`
- **With Guard**: `StateTransition(from:event:to:guard:)`
- **With Action**: `StateTransition(from:event:to:action:)`
- **Full**: `StateTransition(from:event:to:guard:action:)`

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass: `swift test`
5. Submit a pull request

## 📄 License

This project is available under the MIT license. See LICENSE file for more info. 