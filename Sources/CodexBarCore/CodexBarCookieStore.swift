import Foundation

#if !os(Windows)
import SweetCookieKit
#endif

public enum CodexBarCookieStoreError: LocalizedError, Sendable, Equatable {
    case unsupportedPlatform

    public var errorDescription: String? {
        switch self {
        case .unsupportedPlatform:
            "Browser cookie import is not supported on this platform. "
                + "On Windows, cookie-linked providers run in a degraded state "
                + "until a Windows cookie adapter is added."
        }
    }
}

#if os(macOS)
public protocol CodexBarCookieStore: Sendable {
    func records(
        matching query: BrowserCookieQuery,
        in browser: Browser,
        logger: ((String) -> Void)?) throws -> [BrowserCookieStoreRecords]
}

public struct SweetCookieKitCookieStore: CodexBarCookieStore {
    private let client: BrowserCookieClient

    public init(client: BrowserCookieClient = BrowserCookieClient()) {
        self.client = client
    }

    public func records(
        matching query: BrowserCookieQuery,
        in browser: Browser,
        logger: ((String) -> Void)? = nil) throws -> [BrowserCookieStoreRecords]
    {
        try self.client.codexBarRecords(matching: query, in: browser, logger: logger)
    }
}

public typealias DefaultCodexBarCookieStore = SweetCookieKitCookieStore
#else
public protocol CodexBarCookieStore: Sendable {}

public struct UnsupportedCodexBarCookieStore: CodexBarCookieStore {
    public init() {}

    public func unavailableCookieImportMessage() -> String {
        CodexBarCookieStoreError.unsupportedPlatform.localizedDescription
    }
}

public typealias DefaultCodexBarCookieStore = UnsupportedCodexBarCookieStore
#endif
