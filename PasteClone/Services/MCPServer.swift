import Foundation
import Network
import os.log

private let logger = Logger(subsystem: "com.you.PasteClone", category: "MCPServer")

/// 本地只读 MCP 服务（对齐 Paste MCP）：127.0.0.1 + Bearer token，默认关闭。
/// 支持 streamable HTTP 的 MCP 客户端直连；stdio 客户端走 scripts/mcp_bridge.py。
final class MCPServer {
    static let shared = MCPServer()

    static let port: UInt16 = 47821

    static var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "mcpEnabled") }
        set {
            UserDefaults.standard.set(newValue, forKey: "mcpEnabled")
            newValue ? shared.start() : shared.stop()
        }
    }

    static var token: String {
        if let t = UserDefaults.standard.string(forKey: "mcpToken"), !t.isEmpty { return t }
        let t = UUID().uuidString
        UserDefaults.standard.set(t, forKey: "mcpToken")
        return t
    }

    weak var store: ClipboardStore?

    private var listener: NWListener?
    private let queue = DispatchQueue(label: "com.you.justpaste.mcp", qos: .utility)

    func start() {
        stop()
        let params = NWParameters.tcp
        params.requiredInterfaceType = .loopback   // 仅本机回环
        guard let port = NWEndpoint.Port(rawValue: Self.port),
              let listener = try? NWListener(using: params, on: port) else {
            logger.error("MCP 监听端口失败")
            return
        }
        listener.newConnectionHandler = { [weak self] conn in self?.handle(conn) }
        listener.start(queue: queue)
        self.listener = listener
        logger.info("MCP 服务已启动: 127.0.0.1:\(Self.port, privacy: .public)")
    }

    func stop() {
        listener?.cancel()
        listener = nil
    }

    // MARK: - HTTP（单请求短连接）

    private func handle(_ conn: NWConnection) {
        conn.start(queue: queue)
        receiveHeaders(conn, buffer: Data())
    }

    private func receiveHeaders(_ conn: NWConnection, buffer: Data) {
        conn.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { [weak self] data, _, isComplete, _ in
            guard let self else { conn.cancel(); return }
            var buffer = buffer
            if let data { buffer.append(data) }
            guard let headerEnd = buffer.range(of: Data("\r\n\r\n".utf8)) else {
                if isComplete { conn.cancel() } else { self.receiveHeaders(conn, buffer: buffer) }
                return
            }
            let header = String(decoding: buffer[..<headerEnd.lowerBound], as: UTF8.self)
            let contentLength = header.components(separatedBy: "\r\n")
                .first { $0.lowercased().hasPrefix("content-length:") }
                .flatMap { Int($0.dropFirst("content-length:".count).trimmingCharacters(in: .whitespaces)) } ?? 0
            let body = buffer.subdata(in: headerEnd.upperBound..<buffer.count)
            self.receiveBody(conn, header: header, body: body, needed: contentLength)
        }
    }

    private func receiveBody(_ conn: NWConnection, header: String, body: Data, needed: Int) {
        if body.count >= needed {
            respond(conn, header: header, body: body.prefix(needed))
            return
        }
        conn.receive(minimumIncompleteLength: 1, maximumLength: needed - body.count) { [weak self] data, _, isComplete, _ in
            guard let self else { conn.cancel(); return }
            var body = body
            if let data { body.append(data) }
            if isComplete && body.count < needed { conn.cancel(); return }
            self.receiveBody(conn, header: header, body: body, needed: needed)
        }
    }

    private func respond(_ conn: NWConnection, status: String, json: [String: Any]) {
        let payload = (try? JSONSerialization.data(withJSONObject: json)) ?? Data()
        var head = "HTTP/1.1 \(status)\r\nContent-Type: application/json\r\nContent-Length: \(payload.count)\r\nConnection: close\r\n"
        if status == "200 OK" { head += "MCP-Protocol-Version: 2025-06-18\r\n" }
        var packet = Data(head.utf8)
        packet.append(payload)
        conn.send(content: packet, completion: .contentProcessed { _ in conn.cancel() })
    }

    private func respond(_ conn: NWConnection, header: String, body: Data) {
        guard header.hasPrefix("POST"),
              header.range(of: "\r\n", options: []) != nil else {
            respond(conn, status: "405 Method Not Allowed", json: ["error": "POST only"])
            return
        }
        let auth = header.components(separatedBy: "\r\n")
            .first { $0.lowercased().hasPrefix("authorization:") }
            .map { $0.dropFirst("authorization:".count).trimmingCharacters(in: .whitespaces) } ?? ""
        guard auth == "Bearer \(Self.token)" else {
            respond(conn, status: "401 Unauthorized", json: ["error": "invalid token"])
            return
        }
        guard let request = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
              let method = request["method"] as? String else {
            respond(conn, status: "400 Bad Request", json: ["error": "invalid JSON-RPC"])
            return
        }
        let id = request["id"]  // 可能是 String/Int/NSNull
        let reply: [String: Any]
        switch method {
        case "initialize":
            reply = ["protocolVersion": "2025-06-18",
                     "capabilities": ["tools": [String: Any]()],
                     "serverInfo": ["name": "just-paste", "version": "1.12.0"]]
        case "notifications/initialized", "notifications/cancelled":
            conn.cancel(); return  // 通知无响应
        case "ping":
            reply = [String: Any]()
        case "tools/list":
            reply = ["tools": Self.toolDefinitions]
        case "tools/call":
            reply = callTool(request)
        default:
            respond(conn, status: "200 OK", json: ["jsonrpc": "2.0", "id": id ?? NSNull(),
                                                   "error": ["code": -32601, "message": "method not found"]])
            return
        }
        respond(conn, status: "200 OK", json: ["jsonrpc": "2.0", "id": id ?? NSNull(), "result": reply])
    }

    // MARK: - Tools

    private static let toolDefinitions: [[String: Any]] = [
        ["name": "search_history",
         "description": "在 Just Paste 剪贴板历史中模糊搜索（内容、来源 App、图片 OCR 文本）",
         "inputSchema": ["type": "object",
                         "properties": ["query": ["type": "string"],
                                        "limit": ["type": "integer", "default": 10]],
                         "required": ["query"]]],
        ["name": "get_latest",
         "description": "获取最近复制的 N 条剪贴板内容",
         "inputSchema": ["type": "object",
                         "properties": ["count": ["type": "integer", "default": 5]]]],
        ["name": "list_pinboards",
         "description": "列出全部收藏夹（看板）及各自条目数",
         "inputSchema": ["type": "object", "properties": [String: Any]()]],
    ]

    private func callTool(_ request: [String: Any]) -> [String: Any] {
        let params = request["params"] as? [String: Any] ?? [:]
        let name = params["name"] as? String ?? ""
        let args = params["arguments"] as? [String: Any] ?? [:]

        // 读 UI 数据必须回主线程
        let lines: [String] = DispatchQueue.main.sync { [weak self] in
            guard let store = self?.store else { return ["错误：剪贴板存储不可用"] }
            switch name {
            case "search_history":
                let query = args["query"] as? String ?? ""
                let limit = min(max(args["limit"] as? Int ?? 10, 1), 50)
                guard !query.isEmpty else { return ["错误：query 不能为空"] }
                let ranked = store.items.compactMap { item -> (ClipboardItem, Int)? in
                    let scores = [ClipboardStore.fuzzyScore(query, item.displayText),
                                  item.sourceAppName.flatMap { ClipboardStore.fuzzyScore(query, $0) },
                                  item.ocrText.flatMap { ClipboardStore.fuzzyScore(query, $0) }]
                    guard let best = scores.compactMap({ $0 }).max() else { return nil }
                    return (item, best)
                }.sorted { $0.1 > $1.1 }.prefix(limit)
                return ranked.map { "[\($0.0.typeLabel)] \($0.0.displayText.prefix(300))" }
            case "get_latest":
                let count = min(max(args["count"] as? Int ?? 5, 1), 50)
                return store.items.prefix(count).map { "[\($0.typeLabel)] \($0.displayText.prefix(300))" }
            case "list_pinboards":
                return store.collections.map { name in
                    let count = store.items.count { $0.collectionName == name }
                    return "\(name)（\(count) 条）"
                }
            default:
                return ["错误：未知工具 \(name)"]
            }
        }
        let text = lines.isEmpty ? "（无匹配结果）" : lines.joined(separator: "\n---\n")
        return ["content": [["type": "text", "text": text]]]
    }
}
