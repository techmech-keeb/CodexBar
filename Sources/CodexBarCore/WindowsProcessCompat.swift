#if os(Windows)
/// POSIX process-id type for Windows builds. Persisted session records and
/// process bookkeeping keep their Int32 shape (matching every POSIX platform)
/// while actual process control stays unsupported on Windows until the
/// process-runner seam gains a Windows backend.
typealias pid_t = Int32

/// The Windows ucrt defines SIGTERM but not SIGKILL. Process-tree termination
/// paths that reference SIGKILL never run on Windows (the PTY launchers throw
/// before any process exists), but the symbol must exist to compile.
let SIGKILL: Int32 = 9
#endif
