# FSMCore Setup Instructions

Follow these steps to integrate the FSMCore package into your iOS or macOS project.

## 🔧 Adding FSMCore to Your Project

### Option 1: Swift Package Manager (Recommended)

#### In Package.swift
Add FSMCore to your package dependencies:

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "YourProject",
    dependencies: [
        .package(url: "https://github.com/your-username/FSMCore", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "YourProject",
            dependencies: ["FSMCore"]
        )
    ]
)
```

#### In Xcode Project
1. Open your Xcode project
2. Select your **project file** (blue icon) in the navigator
3. Select your **app target**
4. Go to the **"Package Dependencies"** tab
5. Click the **"+"** button
6. Enter the FSMCore repository URL
7. Select version requirements
8. Click **"Add Package"**
9. Select **"FSMCore"** from the package products
10. Click **"Add Package"**

### Option 2: Local Development

If you have FSMCore locally:

1. In Xcode, go to **File > Add Package Dependencies**
2. Click **"Add Local..."**
3. Navigate to your FSMCore directory
4. Select the FSMCore folder (containing `Package.swift`)
5. Click **"Add Package"**
6. Select **"FSMCore"** and add to your target

## 📖 Basic Usage

### Import the Package
```swift
import FSMCore
```

### Define Your States and Events
```swift
enum AppState: String, State, CaseIterable {
    case loading, content, error
    var description: String { rawValue }
}

enum AppEvent: String, Event {
    case loadData, showContent, showError, retry
    var type: String { rawValue }
}
```

### Create a State Machine
```swift
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

### Use in SwiftUI
```swift
struct ContentView: View {
    @StateObject private var stateMachine = StateMachine(config: config)
    
    var body: some View {
        StateMachineView(stateMachine: stateMachine) { state, sendEvent in
            switch state {
            case .loading:
                ProgressView("Loading...")
            case .content:
                Text("Content loaded!")
            case .error:
                VStack {
                    Text("Error occurred")
                    Button("Retry") {
                        sendEvent(.retry)
                    }
                }
            }
        }
    }
}
```

## 🧪 Running Tests

### FSMCore Package Tests
```bash
swift test
```

### In Your Project
Add test dependencies:

```swift
.testTarget(
    name: "YourProjectTests",
    dependencies: ["YourProject", "FSMCore"]
)
```

Then use FSMCore test helpers:

```swift
import Testing
@testable import FSMCore

@Test("My state machine test")
func testStateMachine() async {
    await MainActor.run {
        let machine = StateMachineTestHelper.createSimpleTestMachine(
            initialState: .idle,
            transitions: [
                StateTransition(from: .idle, event: .start, to: .running)
            ]
        )
        
        machine.send(.start)
        machine.assertCurrentState(.running)
    }
}
```

## 🛠️ Troubleshooting

### Package Resolution Issues
- Clean Package Dependencies: **File > Packages > Reset Package Caches**
- Update packages: **File > Packages > Update To Latest Package Versions**
- Check minimum deployment target (iOS 14.0+ recommended)

### Build Errors
- Ensure Xcode 15+ is being used
- Verify Swift 5.9+ compatibility
- Check that your target supports the same platforms as FSMCore

### Import Errors
- Verify FSMCore appears in Package Dependencies
- Clean Build Folder: **Product > Clean Build Folder**
- Restart Xcode if needed

### Version Conflicts
- Check for dependency conflicts with other packages
- Specify exact version ranges if needed:
  ```swift
  .package(url: "...", exact: "1.0.0")
  ```

## 📋 Requirements

### Minimum Requirements
- **iOS**: 14.0+
- **macOS**: 11.0+
- **Xcode**: 15.0+
- **Swift**: 5.9+

### Recommended Setup
- **iOS**: 17.0+ (for latest SwiftUI features)
- **Xcode**: Latest stable version
- **Swift**: Latest version

## 🎯 Next Steps

1. **Explore Features**: Try guards, actions, and progress tracking
2. **Read Documentation**: Check [README.md](README.md) for detailed API docs
3. **Review Tests**: See [README_TESTING.md](README_TESTING.md) for testing patterns
4. **Check Examples**: Look at usage patterns in the README

## 📚 Additional Resources

- **[Main Documentation](README.md)** - Complete API reference
- **[Testing Guide](README_TESTING.md)** - Comprehensive testing examples
- **[Project Structure](PROJECT_STRUCTURE.md)** - Package architecture details

## 📞 Need Help?

- Check the comprehensive documentation
- Review the test suite for usage examples
- Look at the source code for implementation details
- File issues on the repository for bugs or feature requests 