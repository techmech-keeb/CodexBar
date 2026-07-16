import Foundation

#if os(Windows)
// POSIX-shaped names are intentional here; they mirror the platform symbols
// the rest of the process layer compiles against on macOS/Linux.
// swiftlint:disable identifier_name type_name

/// POSIX process-id type for Windows builds. Persisted session records and
/// process bookkeeping keep their Int32 shape (matching every POSIX platform)
/// while actual process control stays unsupported on Windows until the
/// process-runner seam gains a Windows backend.
package typealias pid_t = Int32

/// The Windows ucrt defines SIGTERM but not SIGKILL. Process-tree termination
/// paths that reference SIGKILL never run on Windows (the PTY launchers throw
/// before any process exists), but the symbol must exist to compile.
let SIGKILL: Int32 = 9

/// Microsecond sleep shim backing the polling loops in the process/PTY layer;
/// those loops only ever observe processes that cannot be spawned on Windows.
func usleep(_ microseconds: UInt32) {
    Thread.sleep(forTimeInterval: TimeInterval(microseconds) / 1_000_000)
}

// swiftlint:enable identifier_name type_name
#endif
