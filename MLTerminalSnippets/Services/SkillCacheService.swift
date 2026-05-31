//
//  SkillCacheService.swift
//  MLTerminalSnippets
//

import Foundation

enum SkillCacheLocation: Sendable, Equatable {
    case bundled
    case userCache
}

enum SkillCacheService: Sendable {
    private nonisolated static let appSupportFolderName = "MLTerminalSnippets"
    private nonisolated static let skillsCacheFolderName = "SkillsCache"
    private nonisolated static let bundledCacheBundleName = "SkillsCache"

    nonisolated static func userCacheRoot() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base
            .appendingPathComponent(appSupportFolderName, isDirectory: true)
            .appendingPathComponent(skillsCacheFolderName, isDirectory: true)
    }

    nonisolated static func userCacheDirectory(for slug: String) -> URL {
        userCacheRoot().appendingPathComponent(slug, isDirectory: true)
    }

    /// Raiz dos skills empacotados (`SkillsCache.bundle/Contents/Resources/`).
    nonisolated static func bundledSkillsRoot() -> URL? {
        if let bundleURL = Bundle.main.url(
            forResource: bundledCacheBundleName,
            withExtension: "bundle"
        ) {
            let resources = bundleURL.appendingPathComponent("Contents/Resources", isDirectory: true)
            if FileManager.default.fileExists(atPath: resources.path) {
                return resources
            }
        }
        return nil
    }

    /// Pasta do skill no bundle do app.
    nonisolated static func bundledSkillDirectory(slug: String) -> URL? {
        guard let root = bundledSkillsRoot() else { return nil }
        let skillDir = root.appendingPathComponent(slug, isDirectory: true)
        guard SkillContentValidator.isValidSkillDirectory(skillDir) else { return nil }
        return skillDir
    }

    nonisolated static func resolveSource(for skill: SkillScaffoldItem) -> (url: URL, location: SkillCacheLocation)? {
        let userDir = userCacheDirectory(for: skill.slug)
        if SkillContentValidator.isValidSkillDirectory(userDir) {
            return (userDir, .userCache)
        }
        if let bundled = bundledSkillDirectory(slug: skill.slug) {
            return (bundled, .bundled)
        }
        return nil
    }

    nonisolated static func isAvailable(slug: String) -> Bool {
        SkillContentValidator.isValidSkillDirectory(userCacheDirectory(for: slug))
            || bundledSkillDirectory(slug: slug) != nil
    }

    /// Copia pasta importada pelo usuário para o cache em Application Support.
    nonisolated static func importToUserCache(from sourceFolder: URL, slug: String) throws {
        let destination = userCacheDirectory(for: slug)
        try FileManager.default.createDirectory(at: userCacheRoot(), withIntermediateDirectories: true)

        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.copyItem(at: sourceFolder, to: destination)

        guard SkillContentValidator.isValidSkillDirectory(destination) else {
            try? FileManager.default.removeItem(at: destination)
            throw SkillCacheError.invalidSkillFolder
        }
    }

    /// Copia skills do cache (bundle ou Application Support) para `.cursor/skills/{slug}/`.
    nonisolated static func installFromCache(
        skills: [SkillScaffoldItem],
        skillsRoot: URL,
        onProgress: (@Sendable (SkillInstallProgress) -> Void)? = nil
    ) throws -> [SkillInstallFailure] {
        try FileManager.default.createDirectory(at: skillsRoot, withIntermediateDirectories: true)

        var failures: [SkillInstallFailure] = []
        let total = skills.count

        for (index, skill) in skills.enumerated() {
            onProgress?(
                SkillInstallProgress(
                    current: index + 1,
                    total: total,
                    skillName: skill.name,
                    message: "Copiando \(skill.slug)…"
                )
            )

            let dest = skillsRoot.appendingPathComponent(skill.slug, isDirectory: true)
            if FileManager.default.fileExists(atPath: dest.path) {
                try FileManager.default.removeItem(at: dest)
            }

            guard let source = resolveSource(for: skill) else {
                failures.append(SkillInstallFailure(
                    skillName: skill.name,
                    reason: "skill não encontrado no cache local (importe a pasta ou use built-in do app)"
                ))
                continue
            }

            do {
                try FileManager.default.copyItem(at: source.url, to: dest)
                if SkillContentValidator.skillMarkdownURL(in: dest) == nil {
                    try? FileManager.default.removeItem(at: dest)
                    failures.append(SkillInstallFailure(
                        skillName: skill.name,
                        reason: "SKILL.md não encontrado após cópia"
                    ))
                }
            } catch {
                failures.append(SkillInstallFailure(
                    skillName: skill.name,
                    reason: error.localizedDescription
                ))
            }
        }

        return failures
    }

    /// Copia todos os built-ins do bundle para Application Support (opcional, p.ex. ação manual).
    nonisolated static func seedBuiltInsFromBundleToUserCache() throws -> [String] {
        var seeded: [String] = []
        for builtIn in SeedDataService.builtInRepositories {
            guard let bundled = bundledSkillDirectory(slug: builtIn.slug) else { continue }
            try importToUserCache(from: bundled, slug: builtIn.slug)
            seeded.append(builtIn.slug)
        }
        return seeded
    }
}

enum SkillCacheError: LocalizedError, Sendable {
    case invalidSkillFolder

    nonisolated var errorDescription: String? {
        switch self {
        case .invalidSkillFolder:
            return "A pasta selecionada não contém SKILL.md válido."
        }
    }
}
