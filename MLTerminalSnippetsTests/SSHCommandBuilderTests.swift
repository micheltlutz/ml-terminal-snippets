//
//  SSHCommandBuilderTests.swift
//  MLTerminalSnippetsTests
//

import Testing
@testable import MLTerminalSnippets

struct SSHCommandBuilderTests {
    @Test(.tags(.validation))
    func standardSSHWithoutKey() throws {
        let cmd = try SSHCommandBuilder.buildStandardSSH(
            host: "example.com",
            port: 22,
            username: "deploy",
            privateKeyPath: nil
        )
        #expect(cmd == "ssh deploy@example.com")
    }

    @Test(.tags(.validation))
    func standardSSHWithKeyAndPort() throws {
        let cmd = try SSHCommandBuilder.buildStandardSSH(
            host: "192.168.1.10",
            port: 2222,
            username: "ubuntu",
            privateKeyPath: "/Users/me/.ssh/key.pem"
        )
        #expect(cmd == "ssh -i /Users/me/.ssh/key.pem -p 2222 ubuntu@192.168.1.10")
    }

    @Test(.tags(.validation))
    func standardSSHQuotesPathWithSpaces() throws {
        let cmd = try SSHCommandBuilder.buildStandardSSH(
            host: "host",
            port: 22,
            username: "user",
            privateKeyPath: "/path/with spaces/key.pem"
        )
        #expect(cmd.contains("-i \"/path/with spaces/key.pem\""))
    }

    @Test(.tags(.validation))
    func customCommandModeReturnsTrimmedVerbatim() throws {
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

    @Test(.tags(.validation))
    func customCommandEmptyThrows() {
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

    @Test(.tags(.validation))
    func missingHostThrows() {
        #expect(throws: SSHCommandBuilderError.missingHost) {
            try SSHCommandBuilder.buildStandardSSH(
                host: "",
                port: 22,
                username: "user",
                privateKeyPath: nil
            )
        }
    }

    @Test(.tags(.validation), arguments: [
        SSHCommandBuilder.CommandTemplate.standardSSH,
        SSHCommandBuilder.CommandTemplate.sshCopyId,
        SSHCommandBuilder.CommandTemplate.addUserExample,
    ])
    func commandTemplatesIncludeHostAndUser(template: SSHCommandBuilder.CommandTemplate) {
        let text = template.text(
            host: "srv.com",
            port: 22,
            username: "root",
            privateKeyPath: "/k.pem"
        )
        #expect(text.contains("root@srv.com"))
    }
}
