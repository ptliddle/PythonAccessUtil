//
//  PythonSetupUtil.swift
//
//
//  Created by Peter Liddle on 1/3/24.
//

import Foundation
import AppKit


/// Simple class to request access from the user to the python library directory in sandboxed apps.
/// The class creates a secure bookmark after the user grants access so permission doesn't need to be asked on each run.
///
/// If you keep getting a can't access file issue check it hasn't been quarantined. This can be removed with `xattr -d com.apple.quarantine {"PYTHON_LIB_PATH"}/libpython3.10.dylib`
/// Replace "{"PYTHON_LIB_PATH"}" with the path to your python library. You may need to notify users of this in your app
open class PythonSetup {

   public enum PythonSetupError: Error {
       case pythonLibAccessFailed
       case invalidSuggestedPythonLibLocation
       case noPythonLibPathSelectedByUser
   }
    
    static var global = PythonSetup()
 
    var bookmarkURL: URL?

    static let pythonlib = "libpython3.10"
    static let applePythonExt = "dylib"
    static let linuxPythonExt = "so"
    
    static let PythonLibBookmarkStoreKey = "PYTHON_LIB_DIR"
    
    public static let basePythonLibDir = "/usr/local/bin/python3/lib"
    
    var securityScopedResourceUrl: URL?
    let suggestedPythonLibPath: String
    
    public init(suggestedPythonLibPath: String = PythonSetup.basePythonLibDir) {
        self.suggestedPythonLibPath = suggestedPythonLibPath
    }
    
    private func requestAccessAndCreateBookmark() async throws -> URL {
        let pythonDirUrl = try await self.selectPythonLibrary()
        let bookmarkData = try pythonDirUrl.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
        UserDefaults.standard.set(bookmarkData, forKey: Self.PythonLibBookmarkStoreKey)
        UserDefaults.standard.synchronize()
        return pythonDirUrl
    }
    
    /// Performs the same function as setupPython but allows you to call it from a synchronous context
    public func setupPythonSync() throws {
        Task {
            try await setupPython()
        }
    }
    
    /// Initalizes python by asking the user to grant access to the lib folder on their machine. Allowing access to python in a sandboxed environment.
    /// For this to work correctly 'Disable Library Validation" needs to be checked in 'Signing & Capabilities -> Hardened Runtime'
    public func setupPython() async throws {
        
// If we're on macOS we need to handle allowing access to the python libraries
#if os(macOS)
        
        var pythonDirUrl: URL = URL(fileURLWithPath: "")
        
        // Uncomment this to wipe stored bookmark, useful when testing code
        // UserDefaults.standard.removeObject(forKey: "PYTHON_LIB_DIR")
        
        do {
            // Check to see if we have a secure bookmark first
            if let pythonLibDirBookmarkData = UserDefaults.standard.data(forKey: "PYTHON_LIB_DIR") {
                var isStale = false
                bookmarkURL = try URL(resolvingBookmarkData: pythonLibDirBookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
                
                if isStale {
                    pythonDirUrl = try await requestAccessAndCreateBookmark()
                }
                else {
                    pythonDirUrl = bookmarkURL!
                    securityScopedResourceUrl = pythonDirUrl
                    _ = pythonDirUrl.startAccessingSecurityScopedResource()
                }
                
            }
            else {
                pythonDirUrl = try await requestAccessAndCreateBookmark()
            }
        }
        catch(let error) {
            print("!!!PYTHON SETUP FAILED, PYTHON INTEGRATION WON'T WORK!!!")
            throw error
        }
        
        let libPath: String
        if #available(macOS 13, *) {
            let pythonLibUrl = pythonDirUrl.appending(component: Self.pythonlib).appendingPathExtension(Self.applePythonExt) //URL(string: SwiftLangchainWrapper.basePythonLibDir)!.appending(component: Self.pythonlib).appendingPathExtension(Self.applePythonExt)
            libPath = pythonLibUrl.path()
        }
        else {
            let pythonLibUrl = pythonDirUrl.appendingPathComponent(Self.pythonlib).appendingPathExtension(Self.applePythonExt) //URL(string: SwiftLangchainWrapper.basePythonLibDir)!.appending(component: Self.pythonlib).appendingPathExtension(Self.applePythonExt)
            libPath = pythonLibUrl.path
        }
            
        setenv("PYTHON_LIBRARY", libPath, 1)
#else
        // Placeholder for non MacOS setup. You'll need to set platforms in Package.swift if/when this is implemented
#endif
    }
    
    deinit {
        stopSecureAccess()
    }
    
    public func stopSecureAccess() {
        securityScopedResourceUrl?.stopAccessingSecurityScopedResource()
    }
    
    @MainActor
    func selectPythonLibrary() async throws -> URL {
        
        guard let suggestedPythonLibUrl =  URL(string: suggestedPythonLibPath) else {
            throw PythonSetupError.invalidSuggestedPythonLibLocation
        }
        
        let openPanel = NSOpenPanel()
        openPanel.message = "You need to select the location of the directory containing your Python libraries to allow access (defaulted path is a guess at the location)"
        openPanel.showsResizeIndicator = true
        openPanel.showsHiddenFiles = false
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.directoryURL = suggestedPythonLibUrl
        openPanel.allowedFileTypes = ["dylib"]
        
        let result = await openPanel.begin()

        guard result == NSApplication.ModalResponse.OK, let selectedUrl = openPanel.url else {
            print("User canceled the open panel")
            throw PythonSetupError.noPythonLibPathSelectedByUser
        }
        
        if #available(macOS 13.0, *) {
            print("Selected Python library: \(selectedUrl.path())")
        } else {
            print("Selected Python library: \(selectedUrl.path)")
        }
        
        // You can now use this path in your application
        return selectedUrl
    }
}
