import Network
import Foundation
import Darwin
import os

/// An HTTP server that listens for incoming connections and routes requests.
///
/// The server uses Network.framework for TCP connections and supports concurrent
/// request handling with keep-alive connections.
public actor HTTPServer {
    private typealias Sessions = [UUID: Task<Void, Never>]

    private let portNumber: UInt16?
    private let host: String?
    private let router: Router
    private var listener: NWListener?
    private var sessions = Sessions()
    private var isRunning = false
    private let onChangeServerStatus: @Sendable (NWListener.State) -> Void
    private let webSocketServer: WebSocketServer?

    /// Creates a new HTTP server.
    ///
    /// - Parameters:
    ///   - host: The host/IP address to bind to (default: auto-detect). Examples: "localhost", "127.0.0.1", "0.0.0.0"
    ///   - port: The port number to listen on (default: random available port)
    ///   - router: The router to handle incoming requests
    ///   - webSocketServer: Optional WebSocket server for handling WebSocket upgrades
    ///   - onChangeServerStatus: Callback when server status changes
    public init(
        host: String? = nil,
        port: UInt16? = nil,
        router: Router,
        webSocketServer: WebSocketServer? = nil,
        onChangeServerStatus: @escaping @Sendable (NWListener.State) -> Void = { _ in }
    ) {
        self.host = host
        if let port {
            portNumber = port
        } else {
            portNumber = NetworkUtil.getAvailablePortNumber()
        }
        self.router = router
        self.webSocketServer = webSocketServer
        self.onChangeServerStatus = onChangeServerStatus
    }

    /// Starts the HTTP server and begins listening for connections.
    ///
    /// - Throws: HTTPError.serverError if the port is invalid or listener cannot be created
    public func start() async throws {
        if isRunning {
            await stop()
        }
        
        guard let portNumber, let port = NWEndpoint.Port(rawValue: portNumber) else {
            throw HTTPError.serverError("Invalid port")
        }

        // Create listener with optional host binding
        let parameters = NWParameters.tcp

        // Configure TCP options for better reliability
        parameters.serviceClass = .responsiveData
        parameters.allowLocalEndpointReuse = true

        if let tcpOptions = parameters.defaultProtocolStack.transportProtocol as? NWProtocolTCP.Options {
            // Increase connection timeout to 60 seconds
            tcpOptions.connectionTimeout = 60
            // Enable TCP keep-alive
            tcpOptions.enableKeepalive = true
            tcpOptions.keepaliveInterval = 15
            tcpOptions.keepaliveCount = 5
            // Disable Nagle's algorithm for lower latency
            tcpOptions.noDelay = true
        }

        if let host = host {
            // Bind to specific host/interface
            // Resolve "localhost" to "127.0.0.1" for proper binding
            let resolvedHost = host == "localhost" ? "127.0.0.1" : host
            let localEndpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(resolvedHost), port: port)
            parameters.requiredLocalEndpoint = localEndpoint
            listener = try NWListener(using: parameters)
        } else {
            // Bind to all interfaces (default behavior)
            listener = try NWListener(using: parameters, on: port)
        }

        isRunning = true

        // Wait for the listener to be ready with timeout
        let hasResumed = OSAllocatedUnfairLock(initialState: false)
        let isReady = await withCheckedContinuation { continuation in
            listener?.stateUpdateHandler = { [weak self] state in
                self?.onChangeServerStatus(state)

                // Resume continuation when ready or failed
                hasResumed.withLock { resumed in
                    if !resumed {
                        switch state {
                        case .ready:
                            resumed = true
                            print("READY!")
                            continuation.resume(returning: true)
                        case .failed(let error):
                            resumed = true
                            print("Listener failed with error: \(error)")
                            continuation.resume(returning: false)
                        case .cancelled:
                            resumed = true
                            print("CANCELLED!")
                            continuation.resume(returning: false)
                        case .setup, .waiting:
                            break
                        @unknown default:
                            break
                        }
                    }
                }
            }

            listener?.newConnectionHandler = { [weak self] connection in
                Task { [weak self] in
                    await self?.handleNewConnection(connection)
                }
            }

            listener?.start(queue: .global(qos: .userInitiated))

            // Add timeout to prevent waiting indefinitely
            Task {
                try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds timeout
                hasResumed.withLock { resumed in
                    if !resumed {
                        resumed = true
                        print("Listener startup timed out after 30 seconds")
                        continuation.resume(returning: false)
                    }
                }
            }
        }

        guard isReady else {
            isRunning = false
            listener?.cancel()
            listener = nil
            throw HTTPError.serverError("Failed to start listener - timeout or error occurred")
        }
    }

    /// Gets the port number the server is listening on.
    ///
    /// - Returns: The port number, or nil if not set
    public func getPort() -> Int? {
        guard let portNumber else { return nil }
        return Int(portNumber)
    }

    /// Gets the host/IP address the server is using.
    ///
    /// - Returns: The host address (manual or auto-detected), or nil if unavailable
    public func getHost() -> String? {
        if let host = host {
            return host
        }
        return NetworkUtil.getCurrentDeviceIP()
    }

    /// Gets the full URL where the server is accessible.
    ///
    /// - Returns: The server URL (e.g., http://192.168.1.100:8080), or nil if unavailable
    public func getURL() -> URL? {
        guard let host = getHost(), let port = getPort() else {
            return nil
        }
        return .init(string: "http://\(host):\(port)")
    }

    /// Stops the server and cancels all active connections.
    public func stop() {
        listener?.cancel()
        listener = nil
        isRunning = false
    }

    /// Handles a new incoming connection by creating a session task.
    ///
    /// - Parameter connection: The new network connection
    private func handleNewConnection(_ connection: NWConnection) async {
        let sessionID = UUID()
        let sessionTask = Task {
            await processSessionTask(for: connection, id: sessionID)
        }

        sessions[sessionID] = sessionTask
    }

    /// Processes a client session, handling multiple requests over the same connection.
    ///
    /// Supports HTTP keep-alive for persistent connections and WebSocket upgrades.
    ///
    /// - Parameters:
    ///   - connection: The network connection
    ///   - id: The unique session identifier
    private func processSessionTask(for connection: NWConnection, id: UUID) async {
        connection.start(queue: .global(qos: .userInitiated))

        var isWebSocketUpgrade = false

        defer {
            // Only cancel the connection if it wasn't upgraded to WebSocket
            // WebSocketServer manages the connection after upgrade
            if !isWebSocketUpgrade {
                connection.cancel()
            }
            sessions.removeValue(forKey: id)
        }

        do {
            while !Task.isCancelled {
                guard let requestData = try await receiveData(from: connection) else {
                    break
                }

                let request = try HTTPRequest.parse(from: requestData)

                // Check for WebSocket upgrade request
                if let webSocketServer = webSocketServer,
                   request.headers["Upgrade"]?.lowercased() == "websocket" {
                    if let upgradeResponse = await webSocketServer.handleUpgrade(
                        request: request,
                        connection: connection
                    ) {
                        let responseData = upgradeResponse.toData()
                        await send(data: responseData, to: connection)
                        // Connection is now managed by WebSocketServer
                        isWebSocketUpgrade = true
                        return
                    }
                }

                let response = await router.handle(request)

                let responseData = response.toData()
                await send(data: responseData, to: connection)

                if request.headers["Connection"]?.lowercased() != "keep-alive" {
                    break
                }
            }
        } catch {
            let errorResponse = HTTPResponse.text(
                "Internal Server Error: \(error.localizedDescription)",
                statusCode: .internalServerError
            )
            await send(data: errorResponse.toData(), to: connection)
        }
    }

    /// Receives data from a network connection.
    ///
    /// - Parameter connection: The network connection to receive from
    /// - Returns: The received data, or nil if the connection closed
    /// - Throws: Network errors if the receive operation fails
    private func receiveData(from connection: NWConnection) async throws -> Data? {
        try await withCheckedThrowingContinuation { continuation in
            connection.receive(
                minimumIncompleteLength: 1,
                maximumLength: connection.maximumDatagramSize
            ) { data, _, isComplete, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                if let data {
                    continuation.resume(returning: data)
                    return
                }

                continuation.resume(returning: nil)
            }
        }
    }

    /// Sends data through a network connection.
    ///
    /// - Parameters:
    ///   - data: The data to send
    ///   - connection: The network connection to send through
    private func send(data: Data, to connection: NWConnection) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            connection.send(content: data, completion: .idempotent)
            // Force flush the connection to ensure data is sent
            connection.send(content: nil, contentContext: .finalMessage, isComplete: false, completion: .contentProcessed { _ in
                continuation.resume()
            })
        }
    }
}
