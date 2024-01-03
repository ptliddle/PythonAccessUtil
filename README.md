# PythonAccessUtil

PythonAccessUtil is a very simple package designed to work in concert with [PythonKit](https://github.com/pvieito/PythonKit) to allow PythonKit to access Python libraries in a sandboxed environment on MacOS. It works by asking the user to allow access to the Python Lib directory and then storing a secure bookmark so this doesn't need to be done everytime.
                                                                                   
### Usage

NOTE: As of Jan 2023 i am not aware of any app that has tried to make it into the AppStore utilizing this package. If you try please let me know

Make sure you allow libraries to be loaded without validaion by going to your App Target and checking `Disable Library Validation` under `Signing & Capabilities->Hardened Runtime->Runtime Exceptions`

Create an instance of `PythonSetup(suggestedPythonLibPath:)` optionally handing it the suggested location to find the Python libraries. If no suggested path is entered it will default to suggesting `/usr/local/bin/python3/lib`

Instantiation of the PythonSetup object should be done before using any class or struct within a file that imports PythonKit.
> In order for PythonKit to initialize correctly the Python libraries need to be available and accessible

### Swift Package Manager

Add the following dependency to your `Package.swift` manifest:

```swift
.package(url: "https://github.com/ptliddle/PythonAccessUtil", .branch("master"))
```

### Tools
The project contains a `findpython.sh` script which prints out the path for the Python library. this is useful for debugging or setting the suggested directory

### Example
```swift

import SwiftUI
import Foundation
import PythonAccessUtil

@main
struct AppUsingPython: App {

    let pythonConfig = PythonSetup(suggestedPythonLibPath: "/lib/python")

    init() {
        // This must be called before any file that imports PythonKit
        try? pythonConfig.setupPythonSync()
    }

    var body: some Scene {
        WindowGroup {
            // PythonKit is imported and Python code called within ContentView
            ContentView() 
        }
    }
}


```

### Troubleshooting

Sometimes you may run into an issue where Apple Gatekeeper will quarantine a library file after a number of attempts to allow access. To remedy this you can remove the quarantine flag with the shell command
```shell
xattr -d com.apple.quarantine {"PYTHON_LIB_PATH"}/libpython3.10.dylib
```
