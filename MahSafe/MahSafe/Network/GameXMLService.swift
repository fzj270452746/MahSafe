//
//  GameXMLService.swift
//  MahSafe
//

import Foundation

struct GameXMLNode {
    let name: String
    let attributes: [String: String]
    let text: String
    let children: [GameXMLNode]

    func child(named name: String) -> GameXMLNode? {
        children.first { $0.name == name }
    }

    func children(named name: String) -> [GameXMLNode] {
        children.filter { $0.name == name }
    }

    func value(named name: String) -> String? {
        child(named: name)?.text.nilIfEmpty
    }
}

struct GameBasicInfo {
    let id: String?
    let name: String?
    let version: String?
    let build: String?
    let platform: String?
    let changelog: String?
    let shortDescription: String?
    let fullDescription: String?
}

struct GameXMLDocument {
    let root: GameXMLNode

    var basicInfo: GameBasicInfo {
        let appInfo = root.child(named: "AppInfo")
        let description = root.child(named: "gameDescription")

        return GameBasicInfo(
            id: root.attributes["id"],
            name: appInfo?.value(named: "name"),
            version: appInfo?.value(named: "version"),
            build: appInfo?.value(named: "build"),
            platform: appInfo?.value(named: "platform"),
            changelog: appInfo?.value(named: "changelog"),
            shortDescription: description?.value(named: "shortDescription"),
            fullDescription: description?.value(named: "fullDescription")
        )
    }
}

enum GameXMLServiceError: LocalizedError {
    case invalidURL(String)
    case requestFailed(Error)
    case invalidResponse
    case httpStatus(Int)
    case emptyResponse
    case parseFailed(String)
    case invalidRoot(expected: String, actual: String?)

    var errorDescription: String? {
        switch self {
        case let .invalidURL(url):
            return "Invalid XML URL: \(url)"
        case let .requestFailed(error):
            return "XML request failed: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid Response"
        case let .httpStatus(statusCode):
            return "XML response returned HTTP status \(statusCode)."
        case .emptyResponse:
            return "Empty Response"
        case let .parseFailed(message):
            return "XML parse failed: \(message)"
        case let .invalidRoot(expected, actual):
            return "Invalid XML root: expected <\(expected)>, got \(actual.map { "<\($0)>" } ?? "none")."
        }
    }
}

final class GameXMLService {
    private let session: URLSession
    private let timeout: TimeInterval

    init(session: URLSession = .shared, timeout: TimeInterval = 30) {
        self.session = session
        self.timeout = timeout
    }

    func fetch(from urlString: String) async throws -> GameXMLDocument {
        guard let url = URL(string: urlString),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              url.host != nil else {
            throw GameXMLServiceError.invalidURL(urlString)
        }

        return try await fetch(from: url)
    }

    func fetch(from url: URL) async throws -> GameXMLDocument {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = timeout
        request.setValue("application/xml, text/xml;q=0.9, */*;q=0.8", forHTTPHeaderField: "Accept")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw GameXMLServiceError.requestFailed(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GameXMLServiceError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw GameXMLServiceError.httpStatus(httpResponse.statusCode)
        }

        guard !data.isEmpty else {
            throw GameXMLServiceError.emptyResponse
        }

        return try parse(data: data)
    }

    func parse(data: Data) throws -> GameXMLDocument {
        let builder = GameXMLTreeBuilder()
        let parser = XMLParser(data: data)
        parser.delegate = builder

        guard parser.parse(), let root = builder.root else {
            let message = builder.parserError?.localizedDescription ?? "Unknown parse error"
            throw GameXMLServiceError.parseFailed(message)
        }

        guard root.name == "game" else {
            throw GameXMLServiceError.invalidRoot(expected: "game", actual: root.name)
        }

        return GameXMLDocument(root: root)
    }
}

private final class GameXMLTreeBuilder: NSObject, XMLParserDelegate {
    private(set) var root: GameXMLNode?
    private var stack: [MutableGameXMLNode] = []
    private(set) var parserError: Error?

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        stack.append(MutableGameXMLNode(name: elementName, attributes: attributeDict))
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        stack.last?.text += string
    }

    func parser(_ parser: XMLParser, foundCDATA CDATA: Data) {
        guard let string = String(data: CDATA, encoding: .utf8) else { return }
        stack.last?.text += string
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        guard let node = stack.popLast() else { return }
        let immutableNode = node.makeImmutable()

        if let parent = stack.last {
            parent.children.append(immutableNode)
        } else {
            root = immutableNode
        }
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        parserError = parseError
    }
}

private final class MutableGameXMLNode {
    let name: String
    let attributes: [String: String]
    var text = ""
    var children: [GameXMLNode] = []

    init(name: String, attributes: [String: String]) {
        self.name = name
        self.attributes = attributes
    }

    func makeImmutable() -> GameXMLNode {
        GameXMLNode(
            name: name,
            attributes: attributes,
            text: text.trimmingCharacters(in: .whitespacesAndNewlines),
            children: children
        )
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
