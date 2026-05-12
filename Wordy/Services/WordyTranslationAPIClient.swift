import Foundation
import FirebaseAuth

final class WordyTranslationAPIClient {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let translateURL: URL?
    private let backendEngineVersion: String
    private let includeDebug: Bool

    init(
        session: URLSession = .shared,
        configService: ConfigService = .shared
    ) {
        self.session = session

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        let encoder = JSONEncoder()
        self.encoder = encoder

        let baseURLString = configService.get("WORDY_BACKEND_URL")
            ?? configService.get("WORDY_BACKEND_BASE_URL")
        if let baseURLString,
           let resolvedBaseURL = URL(string: baseURLString) {
            self.translateURL = resolvedBaseURL.lastPathComponent == "translate"
                ? resolvedBaseURL
                : resolvedBaseURL.appendingPathComponent("translate")
        } else {
            self.translateURL = nil
        }
        self.backendEngineVersion = configService.get("WORDY_BACKEND_ENGINE_VERSION") ?? "v1"
        let configuredIncludeDebug = configService.get("WORDY_BACKEND_INCLUDE_DEBUG")?.lowercased()
#if DEBUG
        self.includeDebug = configuredIncludeDebug.map { ["1", "true", "yes"].contains($0) } ?? true
#else
        self.includeDebug = configuredIncludeDebug.map { ["1", "true", "yes"].contains($0) } ?? false
#endif
    }

    func translate(
        text: String,
        sourceLanguage: String,
        targetLanguage: String
    ) async throws -> WordCard {
        struct TranslationEnvelope: Decodable {
            let wordCard: WordCard?
            let warnings: [String]?
        }

        struct RequestBody: Encodable {
            let text: String
            let sourceLanguage: String
            let targetLanguage: String
            let includeExamples: Bool
            let includeSynonyms: Bool
            let includeMeanings: Bool
            let includeDebug: Bool
        }

        guard let translateURL else {
            print("[TranslationAPIClient] response error=missing backend URL in Config.plist")
            throw TranslationError.backendMisconfigured
        }

        let idToken = try await fetchFirebaseIDToken()
        var request = URLRequest(url: translateURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try encoder.encode(
            RequestBody(
                text: text,
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage,
                includeExamples: true,
                includeSynonyms: true,
                includeMeanings: true,
                includeDebug: includeDebug
            )
        )

        print("[TranslationAPIClient] request text=\(text) \(sourceLanguage)->\(targetLanguage) url=\(translateURL.absoluteString) debug=\(includeDebug)")

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TranslationError.invalidResponse
            }

            switch httpResponse.statusCode {
            case 200 ... 299:
                guard !data.isEmpty else {
                    throw TranslationError.emptyResponse
                }

#if DEBUG
                if let body = String(data: data, encoding: .utf8), includeDebug {
                    print("[TranslationAPIClient] response body=\(body)")
                }
#endif

                let wordCard: WordCard
                var payloadJSON: [String: Any]?
                let hasWordCardEnvelope: Bool = {
                    guard let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                        return false
                    }
                    payloadJSON = payload
                    return payload["wordCard"] != nil
                }()

                if hasWordCardEnvelope {
                    let envelope = try decoder.decode(TranslationEnvelope.self, from: data)
                    guard let nestedCard = envelope.wordCard else {
                        throw TranslationError.invalidWordCard
                    }
                    wordCard = nestedCard
                } else {
                    wordCard = try decoder.decode(WordCard.self, from: data)
                }

                var resolvedWordCard = wordCard
                if resolvedWordCard.mainTranslation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    throw TranslationError.invalidWordCard
                }

                let extractedPronunciation = extractPronunciation(from: payloadJSON)
                let extractedIPA = extractIPA(from: payloadJSON)
                let extractedEngineVersion = extractEngineVersion(from: payloadJSON)
                let extractedIdiomSemanticTranslation = extractIdiomSemanticTranslation(from: payloadJSON)
                let extractedIdiomLiteralTranslation = extractIdiomLiteralTranslation(from: payloadJSON)

                let responseEngineVersion = httpResponse.value(forHTTPHeaderField: "X-Backend-Engine-Version")
                    ?? extractedEngineVersion
                    ?? resolvedWordCard.backendEngineVersion
                resolvedWordCard = WordCard(
                    id: resolvedWordCard.id,
                    originalText: resolvedWordCard.originalText,
                    normalizedText: resolvedWordCard.normalizedText,
                    sourceLanguage: resolvedWordCard.sourceLanguage,
                    targetLanguage: resolvedWordCard.targetLanguage,
                    inputType: resolvedWordCard.inputType,
                    mainTranslation: resolvedWordCard.mainTranslation,
                    translations: resolvedWordCard.translations,
                    meanings: resolvedWordCard.meanings,
                    examples: resolvedWordCard.examples,
                    synonyms: resolvedWordCard.synonyms,
                    antonyms: resolvedWordCard.antonyms,
                    relatedPhrases: resolvedWordCard.relatedPhrases,
                    createdAt: resolvedWordCard.createdAt,
                    updatedAt: resolvedWordCard.updatedAt,
                    backendEngineVersion: responseEngineVersion.isEmpty ? backendEngineVersion : responseEngineVersion,
                    pronunciation: firstNonEmpty(resolvedWordCard.pronunciation, extractedPronunciation),
                    ipaTranscription: firstNonEmpty(resolvedWordCard.ipaTranscription, extractedIPA, extractedPronunciation),
                    idiomSemanticTranslation: firstNonEmpty(resolvedWordCard.idiomSemanticTranslation, extractedIdiomSemanticTranslation),
                    idiomLiteralTranslation: firstNonEmpty(resolvedWordCard.idiomLiteralTranslation, extractedIdiomLiteralTranslation)
                )

                print("[TranslationAPIClient] response success status=\(httpResponse.statusCode)")
                return resolvedWordCard
            default:
                let backendError = parseBackendError(data: data)
                logErrorPayload(data: data, response: httpResponse)
                throw mapError(
                    statusCode: httpResponse.statusCode,
                    backendCode: backendError.code,
                    message: backendError.message
                )
            }
        } catch let error as TranslationError {
            print("[TranslationAPIClient] response error=\(error.localizedDescription)")
            throw error
        } catch let error as DecodingError {
            print("[TranslationAPIClient] decoding error=\(describeDecodingError(error))")
            throw TranslationError.decodingError
        } catch {
            if let urlError = error as? URLError {
                switch urlError.code {
                case .timedOut:
                    throw TranslationError.timeout
                case .notConnectedToInternet, .networkConnectionLost, .cannotConnectToHost, .cannotFindHost:
                    throw TranslationError.backendUnavailable
                default:
                    break
                }
            }

            print("[TranslationAPIClient] response error=\(error.localizedDescription)")
            throw TranslationError.networkError(error)
        }
    }

    private func fetchFirebaseIDToken() async throws -> String {
        guard let user = Auth.auth().currentUser else {
            throw TranslationError.authError
        }

        do {
            return try await user.getIDToken()
        } catch {
            throw TranslationError.authError
        }
    }

    private func parseBackendError(data: Data) -> (code: String?, message: String?) {
        struct ErrorEnvelope: Decodable {
            let error: ErrorPayload?
            let code: String?
            let message: String?
        }

        struct ErrorPayload: Decodable {
            let code: String?
            let message: String?
        }

        guard let envelope = try? decoder.decode(ErrorEnvelope.self, from: data) else {
            let rawBody = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return (nil, rawBody?.isEmpty == false ? rawBody : nil)
        }

        return (
            envelope.error?.code ?? envelope.code,
            envelope.error?.message ?? envelope.message
        )
    }

    private func mapError(statusCode: Int, backendCode: String?, message: String?) -> TranslationError {
        switch backendCode?.lowercased() {
        case "unauthorized":
            return .authError
        case "forbidden", "budget_exceeded", "daily_budget_exceeded", "quota_exceeded":
            return .budgetExceeded
        case "rate_limit_exceeded", "rate_limited":
            return .rateLimited
        case "invalid_request":
            return .apiError(message ?? "invalid_request")
        case "unsupported_language_pair":
            return .unsupportedLanguagePair
        case "backend_unavailable", "provider_timeout", "provider_unavailable", "translation_failed":
            return .backendUnavailable
        default:
            break
        }

        switch statusCode {
        case 401, 403:
            return .authError
        case 404, 422:
            return .unsupportedLanguagePair
        case 429:
            return .rateLimited
        case 500 ... 599:
            return .backendUnavailable
        default:
            return .apiError(message ?? "HTTP \(statusCode)")
        }
    }

    private func logErrorPayload(data: Data, response: HTTPURLResponse) {
        let body = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if body.isEmpty {
            print("[TranslationAPIClient] response status=\(response.statusCode) body=<empty>")
        } else {
            print("[TranslationAPIClient] response status=\(response.statusCode) body=\(body)")
        }
    }

    private func describeDecodingError(_ error: DecodingError) -> String {
        switch error {
        case .typeMismatch(let type, let context):
            return "typeMismatch(\(type)) path=\(context.codingPath.map(\.stringValue).joined(separator: ".")) \(context.debugDescription)"
        case .valueNotFound(let type, let context):
            return "valueNotFound(\(type)) path=\(context.codingPath.map(\.stringValue).joined(separator: ".")) \(context.debugDescription)"
        case .keyNotFound(let key, let context):
            return "keyNotFound(\(key.stringValue)) path=\(context.codingPath.map(\.stringValue).joined(separator: ".")) \(context.debugDescription)"
        case .dataCorrupted(let context):
            return "dataCorrupted path=\(context.codingPath.map(\.stringValue).joined(separator: ".")) \(context.debugDescription)"
        @unknown default:
            return error.localizedDescription
        }
    }

    private func firstNonEmpty(_ values: String?...) -> String? {
        for value in values {
            if let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty {
                return trimmed
            }
        }
        return nil
    }

    private func extractPronunciation(from payload: [String: Any]?) -> String? {
        guard let payload else { return nil }
        return firstNonEmpty(
            findString(in: payload, path: ["wordCard", "pronunciation"]),
            findString(in: payload, path: ["wordCard", "phonetic"]),
            findString(in: payload, path: ["wordCard", "metadata", "pronunciation"]),
            findString(in: payload, path: ["wordCard", "metadata", "phonetic"]),
            findString(in: payload, path: ["pronunciation"]),
            findString(in: payload, path: ["phonetic"])
        )
    }

    private func extractIPA(from payload: [String: Any]?) -> String? {
        guard let payload else { return nil }

        let direct = firstNonEmpty(
            findString(in: payload, path: ["wordCard", "ipaTranscription"]),
            findString(in: payload, path: ["wordCard", "ipa"]),
            findString(in: payload, path: ["wordCard", "transcription"]),
            findString(in: payload, path: ["wordCard", "metadata", "ipaTranscription"]),
            findString(in: payload, path: ["wordCard", "metadata", "ipa"]),
            findString(in: payload, path: ["wordCard", "metadata", "transcription"]),
            findString(in: payload, path: ["ipaTranscription"]),
            findString(in: payload, path: ["ipa"]),
            findString(in: payload, path: ["transcription"])
        )

        if let direct { return direct }

        // Common dictionary shape: phonetics: [{ text: "/..." }]
        if let phonetics = findArray(in: payload, path: ["wordCard", "phonetics"]) ?? findArray(in: payload, path: ["phonetics"]) {
            for item in phonetics {
                if let dict = item as? [String: Any],
                   let text = dict["text"] as? String,
                   !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return text
                }
            }
        }

        return nil
    }

    private func extractIdiomSemanticTranslation(from payload: [String: Any]?) -> String? {
        guard let payload else { return nil }
        return firstNonEmpty(
            findString(in: payload, path: ["wordCard", "idiomSemanticTranslation"]),
            findString(in: payload, path: ["wordCard", "metadata", "idiomSemanticTranslation"])
        )
    }

    private func extractIdiomLiteralTranslation(from payload: [String: Any]?) -> String? {
        guard let payload else { return nil }
        return firstNonEmpty(
            findString(in: payload, path: ["wordCard", "idiomLiteralTranslation"]),
            findString(in: payload, path: ["wordCard", "metadata", "idiomLiteralTranslation"])
        )
    }

    private func extractEngineVersion(from payload: [String: Any]?) -> String? {
        guard let payload else { return nil }
        return firstNonEmpty(
            findString(in: payload, path: ["wordCard", "backendEngineVersion"]),
            findString(in: payload, path: ["wordCard", "metadata", "engineVersion"]),
            findString(in: payload, path: ["metadata", "engineVersion"]),
            findString(in: payload, path: ["engineVersion"])
        )
    }

    private func findString(in payload: [String: Any], path: [String]) -> String? {
        var current: Any = payload
        for key in path {
            guard let dict = current as? [String: Any], let next = dict[key] else {
                return nil
            }
            current = next
        }
        return current as? String
    }

    private func findArray(in payload: [String: Any], path: [String]) -> [Any]? {
        var current: Any = payload
        for key in path {
            guard let dict = current as? [String: Any], let next = dict[key] else {
                return nil
            }
            current = next
        }
        return current as? [Any]
    }
}
