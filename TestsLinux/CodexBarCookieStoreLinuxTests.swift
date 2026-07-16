import Foundation
import Testing
@testable import CodexBarCore

struct CodexBarCookieStoreLinuxTests {
    @Test func `default cookie store is unsupported adapter outside macOS`() {
        #if os(macOS)
        #expect(DefaultCodexBarCookieStore.self == SweetCookieKitCookieStore.self)
        #else
        #expect(DefaultCodexBarCookieStore.self == UnsupportedCodexBarCookieStore.self)
        #endif
    }

    @Test func `unsupported cookie store reports Windows degraded message without secrets`() {
        let error = CodexBarCookieStoreError.unsupportedPlatform
        #expect(error.localizedDescription.contains("Windows"))
        #expect(error.localizedDescription.contains("degraded"))
        #expect(!error.localizedDescription.localizedCaseInsensitiveContains("cookie="))
        #expect(!error.localizedDescription.localizedCaseInsensitiveContains("token"))
    }
}
