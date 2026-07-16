import Foundation

#if canImport(CoreFoundation)
import CoreFoundation
#endif

extension NSNumber {
    /// True when this number wraps a JSON boolean rather than a numeric value.
    /// JSON booleans bridge to `NSNumber` too, so numeric parsers use this to
    /// reject `true`/`false` without rejecting genuine numbers.
    var codexBarIsBoolean: Bool {
        #if canImport(CoreFoundation)
        return CFGetTypeID(self) == CFBooleanGetTypeID()
        #else
        // CoreFoundation is not an importable module on Windows;
        // swift-corelibs-foundation encodes JSON booleans as signed-char ("c")
        // numbers, matching Darwin's __NSCFBoolean encoding.
        return String(cString: self.objCType) == "c"
        #endif
    }
}
