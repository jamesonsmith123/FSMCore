# FSMCore Package Structure

This document explains the organization of the FSMCore Swift package - a standalone finite state machine library for SwiftUI.

## Overview

**FSMCore** is a standalone Swift package that provides a powerful, type-safe finite state machine implementation for SwiftUI applications.

## Directory Structure

```
FSMCore/
├── Sources/FSMCore/
│   ├── StateMachine.swift       # Core state machine implementation
│   └── StateMachineView.swift   # SwiftUI integration components
├── Tests/FSMCoreTests/          # Complete test suite (31+ tests)
│   ├── StateMachineTests.swift      # Core functionality tests (21 tests)
│   ├── StateMachineViewTests.swift  # SwiftUI component tests (3 tests)
│   ├── StateMachineTestHelpers.swift # Test utilities and mocks
│   └── TestHelperDemoTests.swift    # Testing pattern examples (7 tests)
├── Package.swift               # Swift Package Manager configuration
├── README.md                   # Package documentation
├── README_TESTING.md          # Comprehensive testing guide
├── PROJECT_STRUCTURE.md       # This file
└── SETUP_INSTRUCTIONS.md      # Installation and setup guide
```

## 🏗️ Package Architecture

### Core Components

#### StateMachine.swift
The heart of the package containing:
- `StateMachine<S: State, E: Event>` class - The main state machine implementation
- `StateMachineConfig<S, E>` struct - Configuration for state machine setup
- `StateTransition<S, E>` struct - Individual transition definitions
- Protocol definitions for `State` and `Event`

#### StateMachineView.swift
SwiftUI integration components:
- `StateMachineView` - SwiftUI view for reactive state machine UI
- `StateMachineProgressView` - Progress tracking component
- `StateMachineDebugView` - Debug information display
- SwiftUI-specific extensions and helpers

### Testing Infrastructure

#### Comprehensive Test Coverage
- **Core Tests** (21 tests): State transitions, guards, actions, progress
- **SwiftUI Tests** (3 tests): View components and integration
- **Helper Tests** (7 tests): Testing utilities and patterns

#### Test Utilities
- `StateMachineTestHelper` - Factory methods for common test scenarios
- Mock objects for observers, actions, guards, and logging
- Assertion extensions for easy verification
- Pre-configured test state machines for common patterns

## 🔄 Package Benefits

### Clean Architecture
- **Pure Swift Package**: No external dependencies or app-specific code
- **Generic Implementation**: Works with any State and Event types
- **SwiftUI Native**: Built specifically for SwiftUI with `@Published` integration
- **Type Safety**: Compile-time guarantees for state transitions

### Developer Experience
- **Comprehensive Testing**: Full test suite with utilities and helpers
- **Documentation**: Detailed README files and inline documentation
- **Examples**: Testing patterns and usage examples included
- **Swift Package Manager**: Easy integration into any iOS project

## 📦 Package Distribution

### Installation Methods

#### Swift Package Manager (Package.swift)
```swift
dependencies: [
    .package(url: "https://github.com/your-username/FSMCore", from: "1.0.0")
]
```

#### Xcode Integration
1. File → Add Package Dependencies
2. Enter FSMCore repository URL
3. Select version or branch
4. Add to your app target

#### Local Development
```swift
dependencies: [
    .package(path: "../FSMCore")
]
```

## 🧪 Development Workflow

### Running Tests
```bash
swift test                    # Run all tests
swift test --parallel         # Run tests in parallel
swift test --verbose          # Verbose output
```

### Building the Package
```bash
swift build                   # Build for current platform
swift build --configuration release  # Release build
```

### Development Commands
```bash
swift package init           # Initialize new package (if needed)
swift package generate-xcodeproj  # Generate Xcode project
swift package resolve       # Resolve dependencies
swift package clean         # Clean build artifacts
```

## 📁 File Organization

### Source Files
| File | Purpose | Lines |
|------|---------|-------|
| `StateMachine.swift` | Core state machine logic, transitions, observers | ~112 |
| `StateMachineView.swift` | SwiftUI components, progress views, debug UI | ~146 |

### Test Files
| File | Purpose | Tests |
|------|---------|-------|
| `StateMachineTests.swift` | Core functionality tests | 21 |
| `StateMachineViewTests.swift` | SwiftUI component tests | 3 |
| `StateMachineTestHelpers.swift` | Test utilities, mocks, helpers | N/A |
| `TestHelperDemoTests.swift` | Testing pattern demonstrations | 7 |

### Documentation Files
| File | Purpose |
|------|---------|
| `README.md` | Main package documentation |
| `README_TESTING.md` | Comprehensive testing guide |
| `PROJECT_STRUCTURE.md` | This architectural overview |
| `SETUP_INSTRUCTIONS.md` | Installation and setup guide |

## 🎯 Usage Patterns

### Basic State Machine
```swift
import FSMCore

enum MyState: String, State, CaseIterable {
    case idle, loading, success, error
    var description: String { rawValue }
}

enum MyEvent: String, Event {
    case load, succeed, fail, retry
    var type: String { rawValue }
}

let config = StateMachineConfig<MyState, MyEvent>(
    initialState: .idle,
    transitions: [
        StateTransition(from: .idle, event: .load, to: .loading),
        StateTransition(from: .loading, event: .succeed, to: .success),
        StateTransition(from: .loading, event: .fail, to: .error),
        StateTransition(from: .error, event: .retry, to: .loading)
    ]
)

@StateObject private var stateMachine = StateMachine(config: config)
```

### SwiftUI Integration
```swift
struct ContentView: View {
    @StateObject private var stateMachine = StateMachine(config: config)
    
    var body: some View {
        StateMachineView(stateMachine: stateMachine) { state, sendEvent in
            switch state {
            case .idle: IdleView { sendEvent(.load) }
            case .loading: LoadingView()
            case .success: SuccessView()
            case .error: ErrorView { sendEvent(.retry) }
            }
        }
    }
}
```

## 🔍 Package Capabilities

### Core Features
- ✅ Type-safe state transitions
- ✅ Guard conditions for conditional transitions
- ✅ Actions executed on successful transitions
- ✅ Progress tracking for linear flows
- ✅ Available transitions enumeration
- ✅ State change observation
- ✅ SwiftUI reactive integration

### Testing Features
- ✅ Comprehensive test suite (31+ tests)
- ✅ Test helper utilities and factories
- ✅ Mock objects for complex scenarios
- ✅ Assertion extensions for easy verification
- ✅ Testing pattern demonstrations

### Developer Tools
- ✅ Debug view component
- ✅ Progress visualization
- ✅ State transition logging
- ✅ Comprehensive documentation
- ✅ Example usage patterns

## 📈 Package Maintenance

### Version Management
- Semantic versioning (SemVer)
- Tagged releases for stable versions
- Development branch for ongoing work
- Clear changelog documentation

### Quality Assurance
- Comprehensive test suite
- Continuous integration (if applicable)
- Code review processes
- Documentation updates with changes

This standalone package structure provides a professional, reusable finite state machine library that can be easily integrated into any SwiftUI project while maintaining clean architecture and comprehensive testing.
