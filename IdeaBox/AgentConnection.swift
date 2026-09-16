import Foundation
import Combine
import Security

protocol AgentKeyStorage {
    func read() throws -> String
    func write(_ key: String) throws
    func remove() throws
}

#if DEBUG
/// Screenshots and UI tests never read or replace the user's actual Keychain entry.
final class AgentPreviewKeyStorage: AgentKeyStorage {
    private var value = ""
    func read() throws -> String { value }
    func write(_ key: String) throws { value = key }
    func remove() throws { value = "" }
}
#endif

struct KeychainAgentKeyStorage: AgentKeyStorage {
    private let service = "com.example.IdeaBox.deepseek"
    private let account = "personal-api-key"

    private var query: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: account,
         kSecAttrSynchronizable as String: false]
    }

    func read() throws -> String {
        var request = query
        request[kSecReturnData as String] = true
        request[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(request as CFDictionary, &result)
        if status == errSecItemNotFound { return "" }
        guard status == errSecSuccess, let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else { throw AgentConnectionError.keychain }
        return value
    }

    func write(_ key: String) throws {
        let attributes: [String: Any] = [
            kSecValueData as String: Data(key.utf8),
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var addition = query
            attributes.forEach { addition[$0.key] = $0.value }
            guard SecItemAdd(addition as CFDictionary, nil) == errSecSuccess else { throw AgentConnectionError.keychain }
        } else if status != errSecSuccess {
            throw AgentConnectionError.keychain
        }
    }

    func remove() throws {
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw AgentConnectionError.keychain }
    }
}

enum AgentConnectionError: LocalizedError {
    case keychain, missingKey, invalidKey, invalidModel

    var errorDescription: String? {
        switch self {
        case .keychain: "暂时无法访问钥匙串，请解锁 iPhone 后重试。"
        case .missingKey: "先在连接设置中填写你的 DeepSeek API Key。"
        case .invalidKey: "请填写有效的 API Key，密钥中不能含空格或换行。"
        case .invalidModel: "请填写有效的模型名称，例如 deepseek-flash。"
        }
    }
}

@MainActor
final class AgentConnection: ObservableObject {
    @Published private(set) var isConfigured = false
    @Published private(set) var model: String
    private let storage: any AgentKeyStorage
    private let preferences: UserDefaults
    private static let modelKey = "agent.deepseek.model"

    init(storage: any AgentKeyStorage = KeychainAgentKeyStorage(), preferences: UserDefaults = .standard) {
        self.storage = storage
        self.preferences = preferences
        model = preferences.string(forKey: Self.modelKey) ?? "deepseek-flash"
        isConfigured = (try? storage.read().isEmpty == false) ?? false
    }

    func readKey() throws -> String { try storage.read() }

    func save(apiKey: String, model: String) throws {
        let values = try validated(apiKey: apiKey, model: model)
        try storage.write(values.key)
        preferences.set(values.model, forKey: Self.modelKey)
        self.model = values.model
        isConfigured = true
    }

    func removeKey() throws {
        try storage.remove()
        isConfigured = false
    }

    func test(apiKey: String, model: String) async throws {
        let values = try validated(apiKey: apiKey, model: model)
        try await DeepSeekClient().testConnection(apiKey: values.key, model: values.model)
    }

    private func validated(apiKey: String, model: String) throws -> (key: String, model: String) {
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let model = model.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { throw AgentConnectionError.missingKey }
        guard key.count <= 512, !key.contains(where: \.isWhitespace) else { throw AgentConnectionError.invalidKey }
        guard !model.isEmpty, model.count <= 100,
              model.unicodeScalars.allSatisfy({ CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_.:/").contains($0) })
        else { throw AgentConnectionError.invalidModel }
        return (key, model)
    }
}
