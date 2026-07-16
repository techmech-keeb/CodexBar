import CodexBarCore
import Foundation
import Testing

struct CodexBarPathResolverLinuxTests {
    @Test
    func `default resolver preserves existing config path precedence`() throws {
        let fileManager = FileManager.default
        let root = fileManager.temporaryDirectory
            .appendingPathComponent("codexbar-path-resolver-\(UUID().uuidString)", isDirectory: true)
        defer { try? fileManager.removeItem(at: root) }
        let home = root.appendingPathComponent("home", isDirectory: true)
        let legacy = home
            .appendingPathComponent(".codexbar", isDirectory: true)
            .appendingPathComponent("config.json", isDirectory: false)
        try fileManager.createDirectory(at: legacy.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("{}".utf8).write(to: legacy)

        let resolver = DefaultCodexBarPathResolver(homeDirectory: home, fileManager: fileManager)
        #expect(resolver.codexBarConfigFileURL(environment: [:], fileManager: fileManager) == legacy)
    }

    @Test
    func `default resolver exposes provider config paths under the existing Unix home layout`() {
        let home = URL(fileURLWithPath: "/tmp/codexbar-home", isDirectory: true)
        let resolver = DefaultCodexBarPathResolver(homeDirectory: home)

        #expect(resolver.codexHomeURL(environment: [:]).path == "/tmp/codexbar-home/.codex")
        #expect(resolver.codebuffCredentialsFileURL().path ==
            "/tmp/codexbar-home/.config/manicode/credentials.json")
        #expect(resolver.kiloAuthFileURL().path == "/tmp/codexbar-home/.local/share/kilo/auth.json")
        #expect(resolver.kimiCodeHomeURL(environment: [:]).path == "/tmp/codexbar-home/.kimi-code")
        #expect(resolver.logFileURL().lastPathComponent == "CodexBar.log")
        #expect(resolver.logFileURL().deletingLastPathComponent().lastPathComponent == "CodexBar")
    }

    @Test
    func `default resolver preserves environment overrides`() {
        let home = URL(fileURLWithPath: "/tmp/codexbar-home", isDirectory: true)
        let resolver = DefaultCodexBarPathResolver(homeDirectory: home)

        #expect(resolver.codexHomeURL(environment: ["CODEX_HOME": "/tmp/custom-codex"]).path ==
            "/tmp/custom-codex")
        #expect(resolver.kimiCodeHomeURL(environment: [KimiSettingsReader.codeHomeEnvironmentKey: "/tmp/kimi"]).path ==
            "/tmp/kimi")
    }
}
