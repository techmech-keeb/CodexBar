import Foundation

// Platforms without the Objective-C runtime (Linux, Windows) have no real
// autorelease pools; the call sites only need scoped execution.
#if !canImport(ObjectiveC)
@discardableResult
func autoreleasepool<Result>(_ work: () throws -> Result) rethrows -> Result {
    try work()
}
#endif
