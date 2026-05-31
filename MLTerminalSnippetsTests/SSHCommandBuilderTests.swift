//
//  SSHCommandBuilderTests.swift
//  MLTerminalSnippetsTests
//

import Testing
@testable import MLTerminalSnippets

struct SSHCommandBuilderTests {
    @Test func standardSSHWithoutKey() throws {
        let cmd = try SSHCommandBuilder.buildStandardSSH(
            host: "example.com",
            port: 22,
            username: "deploy",
            privateKeyPath: nil
        )
        #expect(cmd == "ssh deploy@example.com")
    }

    @Test func standardSSHWithKeyAndPort() throws {
        let cmd = try SSHCommandBuilder.buildStandardSSH(
            host: "192.168.1.10",
            port: 2222,
            username: "ubuntu",
            privateKeyPath: "/Users/me/.ssh/key.pem"
        )
        #expect(cmd == "ssh -i /Users/me/.ssh/key.pem -p 2222 ubuntu@192.168.1.10")
    }

    @Test func standardSSHQuotesPathWithSpaces() throws {
        let cmd = try SSHCommandBuilder.buildStandardSSH(
            host: "host",
            port: 22,
            username: "user",
            privateKeyPath: "/path/with spaces/key.pem"
        )
        #expect(cmd.contains("-i \"/path/with spaces/key.pem\""))
    }

    @Test func customCommandModeReturnsVerbatim() throws {
        let cmd = try SSHCommandBuilder.build(
            authMode: .customCommand,
            host: "ignored",
            port: 22,
            username: "user",
            privateKeyPath: nil,
            customCommand: "  ssh -vvv user@host  "
        )
        #expect(cmd == "ssh -vvv user@host")
    }

    @Test func customCommandEmptyThrows() {
        #expect(throws: SSHCommandBuilderError.missingCustomCommand) {
            try SSHCommandBuilder.build(
                authMode: .customCommand,
                host: "h",
                port: 22,
                username: "u",
                privateKeyPath: nil,
                customCommand: "   "
            )
        }
    }

    @Test func missingHostThrows() {
        #expect(throws: SSHCommandBuilderError.missingHost) {
            try SSHCommandBuilder.buildStandardSSH(
                host: "",
                port: 22,
                username: "user",
                privateKeyPath: nil
            )
        }
    }

    @Test func sshCopyIdTemplate() {
        let text = SSHCommandBuilder.CommandTemplate.sshCopyId.text(
            host: "srv.com",
            port: 22,
            username: "root",
            privateKeyPath: "/k.pem"
        )
        #expect(text.contains("ssh-copy-id"))
        #expect(text.contains("root@srv.com"))
    }
}
