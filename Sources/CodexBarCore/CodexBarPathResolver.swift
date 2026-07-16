import Foundation

public protocol CodexBarPathResolver: Sendable {
    var homeDirectory: URL { get }

    func codexBarConfigFileURL(
        environment: [String: String],
        fileManager: FileManager) -> URL
    func cacheDirectoryURL() -> URL
    func logsDirectoryURL() -> URL
    func logFileURL() -> URL
    func codexHomeURL(environment: [String: String]) -> URL
    func codebuffCredentialsFileURL() -> URL
    func kiloAuthFileURL() -> URL
    func kimiCodeHomeURL(environment: [String: String]) -> URL
}

public struct DefaultCodexBarPathResolver: CodexBarPathResolver, @unchecked Sendable {
    public static let shared = DefaultCodexBarPathResolver()

    public let homeDirectory: URL
    private let fileManager: FileManager

    public init(
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser,
        fileManager: FileManager = .default)
    {
        self.homeDirectory = homeDirectory
        self.fileManager = fileManager
    }

    public func codexBarConfigFileURL(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        fileManager: FileManager = .default) -> URL
    {
        if let override = Self.cleaned(environment[CodexBarConfigStore.pathEnvironmentKey]), !override.isEmpty {
            let expanded = (override as NSString).expandingTildeInPath
            return URL(fileURLWithPath: expanded)
        }

        if let xdgConfigHome = Self.cleaned(environment[CodexBarConfigStore.xdgConfigHomeEnvironmentKey]),
           !xdgConfigHome.isEmpty
        {
            let expanded = (xdgConfigHome as NSString).expandingTildeInPath
            if (expanded as NSString).isAbsolutePath {
                return URL(fileURLWithPath: expanded, isDirectory: true)
                    .appendingPathComponent("codexbar", isDirectory: true)
                    .appendingPathComponent("config.json")
            }
        }

        let xdgDefault = self.homeDirectory
            .appendingPathComponent(".config", isDirectory: true)
            .appendingPathComponent("codexbar", isDirectory: true)
            .appendingPathComponent("config.json")
        if fileManager.fileExists(atPath: xdgDefault.path) {
            return xdgDefault
        }

        let legacy = self.homeDirectory
            .appendingPathComponent(".codexbar", isDirectory: true)
            .appendingPathComponent("config.json")
        if fileManager.fileExists(atPath: legacy.path) {
            return legacy
        }

        return xdgDefault
    }

    public func cacheDirectoryURL() -> URL {
        if let root = self.fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            return root.appendingPathComponent("com.steipete.codexbar", isDirectory: true)
        }
        return self.homeDirectory
            .appendingPathComponent(".cache", isDirectory: true)
            .appendingPathComponent("codexbar", isDirectory: true)
    }

    public func logsDirectoryURL() -> URL {
        let base = self.fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first
            ?? self.homeDirectory.appendingPathComponent("Library", isDirectory: true)
        return base
            .appendingPathComponent("Logs", isDirectory: true)
            .appendingPathComponent("CodexBar", isDirectory: true)
    }

    public func logFileURL() -> URL {
        self.logsDirectoryURL().appendingPathComponent("CodexBar.log", isDirectory: false)
    }

    public func codexHomeURL(environment: [String: String] = ProcessInfo.processInfo.environment) -> URL {
        if let raw = Self.cleaned(environment["CODEX_HOME"]), !raw.isEmpty {
            return URL(fileURLWithPath: raw, isDirectory: true)
        }
        return self.homeDirectory.appendingPathComponent(".codex", isDirectory: true)
    }

    public func codebuffCredentialsFileURL() -> URL {
        self.homeDirectory
            .appendingPathComponent(".config", isDirectory: true)
            .appendingPathComponent("manicode", isDirectory: true)
            .appendingPathComponent("credentials.json", isDirectory: false)
    }

    public func kiloAuthFileURL() -> URL {
        self.homeDirectory
            .appendingPathComponent(".local", isDirectory: true)
            .appendingPathComponent("share", isDirectory: true)
            .appendingPathComponent("kilo", isDirectory: true)
            .appendingPathComponent("auth.json", isDirectory: false)
    }

    public func kimiCodeHomeURL(environment: [String: String] = ProcessInfo.processInfo.environment) -> URL {
        if let override = Self.cleaned(environment[KimiSettingsReader.codeHomeEnvironmentKey]) {
            return URL(fileURLWithPath: override, isDirectory: true)
        }
        return self.homeDirectory.appendingPathComponent(".kimi-code", isDirectory: true)
    }

    private static func cleaned(_ raw: String?) -> String? {
        raw?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
