//
//  OpenBoxTests.swift
//  OpenBoxTests
//
//  Created by jianliang on 2026/1/24.
//

import Testing
@testable import OpenBox

struct OpenBoxTests {

    @Test func normalizedIdentifierBaseCollapsesUnsupportedCharacters() async throws {
        #expect(
            ContainerSDKService.normalizedIdentifierBase("My Sandbox 🚀 / Beta")
                == "my-sandbox-beta"
        )
    }

    @Test func generatedSandboxIDMatchesContainerSyntax() async throws {
        let identifier = ContainerSDKService.makeSandboxID(name: "Sandbox For QA")
        #expect(identifier.hasPrefix("openbox-sandbox-for-qa-"))
        #expect(identifier.count <= 63)
        #expect(
            identifier.range(
                of: #"^[a-z0-9](?:[a-z0-9._-]{0,61}[a-z0-9])?$"#,
                options: .regularExpression
            ) != nil
        )
    }
}
