import SwiftUI
import SwiftHost

struct ContentView: View {
    @State var server: HTTPServer?
    @State var webSocketServer: WebSocketServer?
    @State var url: URL?
    @State var connectedClients: Int = 0
    @State var statusMessage: String = "Server not started"
    @State var useLocalhost: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "network")
                .imageScale(.large)
                .foregroundStyle(.tint)
                .font(.system(size: 50))

            Text("WebSocket Auto-Refresh Demo")
                .font(.title)
                .bold()

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Status:")
                        .bold()
                    Text(statusMessage)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Connected Clients:")
                        .bold()
                    Text("\(connectedClients)")
                        .foregroundStyle(.secondary)
                }

                if let url {
                    HStack {
                        Text("Server URL:")
                            .bold()
                        Link(url.absoluteString, destination: url)
                    }
                }

                Toggle("Use localhost", isOn: $useLocalhost)
                    .onChange(of: useLocalhost) { _, _ in
                        Task {
                            await restartServer()
                        }
                    }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)

            Button(action: refreshAllPages) {
                Label("Refresh All Pages", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(connectedClients > 0 ? Color.blue : Color.gray)
                    .foregroundStyle(.white)
                    .cornerRadius(10)
            }
            .disabled(connectedClients == 0)

            Text("Open the server URL in a browser, then click 'Refresh All Pages' to see the magic!")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .task {
            await startServer()
        }
    }

    private func startServer() async {
        do {
            // Create WebSocket server with callbacks
            webSocketServer = WebSocketServer(
                onConnected: { id in
                    Task { @MainActor in
                        connectedClients += 1
                        statusMessage = "Client connected (ID: \(id.uuidString.prefix(8))...)"
                        print("WebSocket client connected: \(id)")
                    }
                },
                onDisconnected: { id in
                    Task { @MainActor in
                        connectedClients = max(0, connectedClients - 1)
                        statusMessage = "Client disconnected (ID: \(id.uuidString.prefix(8))...)"
                        print("WebSocket client disconnected: \(id)")
                    }
                },
                onMessage: { id, message in
                    print("Message from \(id): \(message)")
                }
            )

            // Create router with HTML page
            let router = Router {
                Route(path: "/") { request in
                    await HTTPResponse.html(htmlContent)
                }
            }

            await router.use(LoggingMiddleware())
            await router.use(CORSMiddleware())

            // Create HTTP server with WebSocket support
            // Demonstrate manual host setting
            server = HTTPServer(
                host: useLocalhost ? "localhost" : nil,  // nil = auto-detect
                port: 12345,
                router: router,
                webSocketServer: webSocketServer
            )

            try await server?.start()
            url = await server?.getURL()

            Task { @MainActor in
                statusMessage = "Server running"
            }
        } catch {
            Task { @MainActor in
                statusMessage = "Error: \(error.localizedDescription)"
            }
            print(error)
        }
    }

    private func refreshAllPages() {
        guard let webSocketServer else { return }
        Task {
            await webSocketServer.refreshPage()
            Task { @MainActor in
                statusMessage = "Refresh command sent to all clients"
            }
        }
    }

    private func restartServer() async {
        // Stop existing server
        await server?.stop()

        // Small delay to ensure port is released
        try? await Task.sleep(nanoseconds: 500_000_000)

        // Restart with new settings
        await startServer()
    }

    private var htmlContent: String {
        """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>WebSocket Auto-Refresh Demo</title>
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
                    max-width: 800px;
                    margin: 0 auto;
                    padding: 40px 20px;
                    background: #f5f5f5;
                }
                .container {
                    background: white;
                    padding: 30px;
                    border-radius: 10px;
                    box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
                }
                h1 {
                    color: #333;
                    margin-top: 0;
                }
                .status {
                    padding: 15px;
                    border-radius: 5px;
                    margin: 20px 0;
                    font-weight: 500;
                }
                .connected {
                    background: #d4edda;
                    color: #155724;
                    border: 1px solid #c3e6cb;
                }
                .disconnected {
                    background: #f8d7da;
                    color: #721c24;
                    border: 1px solid #f5c6cb;
                }
                .info {
                    background: #d1ecf1;
                    color: #0c5460;
                    border: 1px solid #bee5eb;
                    padding: 15px;
                    border-radius: 5px;
                    margin: 20px 0;
                }
                .timestamp {
                    color: #666;
                    font-size: 14px;
                    margin-top: 10px;
                }
                code {
                    background: #f4f4f4;
                    padding: 2px 6px;
                    border-radius: 3px;
                    font-family: 'Monaco', 'Courier New', monospace;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>WebSocket Auto-Refresh Demo</h1>

                <div class="status disconnected" id="status">
                    Disconnected
                </div>

                <div class="info">
                    <strong>How it works:</strong>
                    <p>This page connects to the SwiftHost WebSocket server. When your Swift app calls <code>webSocketServer.refreshPage()</code>, this page will automatically refresh.</p>
                </div>

                <div class="timestamp" id="timestamp">
                    Page loaded at: <span id="loadTime"></span>
                </div>
            </div>

            <script>
                let ws = null;
                const statusEl = document.getElementById('status');
                const loadTimeEl = document.getElementById('loadTime');

                function updateLoadTime() {
                    const now = new Date();
                    loadTimeEl.textContent = now.toLocaleTimeString();
                }

                function connect() {
                    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
                    const wsUrl = `${protocol}//${window.location.host}`;

                    ws = new WebSocket(wsUrl);

                    ws.onopen = function() {
                        console.log('WebSocket connected');
                        statusEl.className = 'status connected';
                        statusEl.textContent = 'Connected to WebSocket server';
                    };

                    ws.onmessage = function(event) {
                        console.log('Message received:', event.data);

                        if (event.data === 'refresh') {
                            console.log('Refresh command received, reloading page...');
                            window.location.reload();
                        }
                    };

                    ws.onerror = function(error) {
                        console.error('WebSocket error:', error);
                        statusEl.className = 'status disconnected';
                        statusEl.textContent = 'WebSocket error occurred';
                    };

                    ws.onclose = function() {
                        console.log('WebSocket disconnected');
                        statusEl.className = 'status disconnected';
                        statusEl.textContent = 'Disconnected from server';

                        setTimeout(connect, 2000);
                    };
                }

                updateLoadTime();
                connect();
            </script>
        </body>
        </html>
        """
    }
}

#Preview {
    ContentView()
}
