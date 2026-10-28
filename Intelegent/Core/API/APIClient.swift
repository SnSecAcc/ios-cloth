import Foundation

enum APIError: LocalizedError {
    case http(status: Int, message: String?)
    case decoding(Error)
    case network(Error)

    var errorDescription: String? {
        switch self {
        case .http(_, let message?): message
        case .http(let status, nil): "Ошибка сервера (\(status))"
        case .decoding: "Не удалось прочитать ответ сервера"
        case .network: "Нет соединения с сервером"
        }
    }
}

/// Клиент Laravel API.
///
/// Пока на бэкенде нет входа по токену, работаем как сайт: сессия и корзина гостя
/// живут в cookie (HTTPCookieStorage сохраняет их между запусками), для POST нужен XSRF-токен.
/// Origin/Referer сайта нужны Sanctum, чтобы считать запрос «своим» и поднять сессию.
/// TODO: после добавления Sanctum-токенов заменить на заголовок Authorization: Bearer.
actor APIClient {
    static let shared = APIClient()

    static let baseURL = URL(string: "https://api.intelegent.shop")!
    private static let siteOrigin = "https://intelegent.shop"

    private let session: URLSession
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    init() {
        let config = URLSessionConfiguration.default
        config.httpCookieStorage = .shared
        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true
        config.timeoutIntervalForRequest = 20
        config.requestCachePolicy = .useProtocolCachePolicy
        session = URLSession(configuration: config)
    }

    // MARK: - Публичные методы

    func get<T: Decodable>(_ path: String, query: [URLQueryItem] = []) async throws -> T {
        try await send(path, method: "GET", query: query, body: nil)
    }

    func post<T: Decodable>(_ path: String, body: [String: Any] = [:]) async throws -> T {
        try await send(path, method: "POST", query: [], body: body)
    }

    // MARK: - Запрос

    private func send<T: Decodable>(_ path: String, method: String, query: [URLQueryItem], body: [String: Any]?, retried: Bool = false) async throws -> T {
        if method != "GET", xsrfToken() == nil {
            try await refreshCSRF()
        }

        let request = try makeRequest(path, method: method, query: query, body: body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.network(error)
        }

        let status = (response as? HTTPURLResponse)?.statusCode ?? 0

        // 419 — протух CSRF: обновляем и повторяем один раз (как apiFetch на сайте)
        if status == 419, !retried {
            try await refreshCSRF()
            return try await send(path, method: method, query: query, body: body, retried: true)
        }

        guard (200..<300).contains(status) else {
            let message = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["message"] as? String
            throw APIError.http(status: status, message: message)
        }

        if T.self == EmptyResponse.self {
            return EmptyResponse() as! T
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            #if DEBUG
            print("[API] decode \(path):", error)
            #endif
            throw APIError.decoding(error)
        }
    }

    private func makeRequest(_ path: String, method: String, query: [URLQueryItem], body: [String: Any]?) throws -> URLRequest {
        let clean = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        var components = URLComponents(url: Self.baseURL.appendingPathComponent("api/" + clean), resolvingAgainstBaseURL: false)!

        if !query.isEmpty {
            components.queryItems = query
        }

        var request = URLRequest(url: components.url!)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(Self.siteOrigin, forHTTPHeaderField: "Origin")
        request.setValue(Self.siteOrigin + "/", forHTTPHeaderField: "Referer")

        if let token = xsrfToken() {
            request.setValue(token, forHTTPHeaderField: "X-XSRF-TOKEN")
        }

        if let body, method != "GET" {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        return request
    }

    // MARK: - CSRF

    private func refreshCSRF() async throws {
        var request = URLRequest(url: Self.baseURL.appendingPathComponent("sanctum/csrf-cookie"))
        request.setValue(Self.siteOrigin, forHTTPHeaderField: "Origin")
        request.setValue(Self.siteOrigin + "/", forHTTPHeaderField: "Referer")

        do {
            _ = try await session.data(for: request)
        } catch {
            throw APIError.network(error)
        }
    }

    /// Значение cookie XSRF-TOKEN (Laravel кладёт его url-encoded)
    private func xsrfToken() -> String? {
        HTTPCookieStorage.shared.cookies(for: Self.baseURL)?
            .first { $0.name == "XSRF-TOKEN" }?
            .value
            .removingPercentEncoding
    }
}

/// Для запросов, ответ которых не нужен
struct EmptyResponse: Decodable {}
