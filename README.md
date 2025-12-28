# SwiftHost

A lightweight HTTP server library for Swift. Built with modern Swift concurrency, it lets you spin up a web server with minimal fuss.

## Requirements

- Swift 6.0 or later
- macOS 14+ or iOS 17+

## What's Inside

- **HTTP Server** - Built on Network framework, handles incoming connections efficiently with async/await
- **Routing** - Clean API for defining routes with wildcard and parameter matching
- **Middleware** - Process requests and responses the way you need
- **Error Handling** - Proper HTTP status codes and error types out of the box

## Getting Started

### Installation

Add to your `Package.swift`:

```swift
let package = Package(
    name: "YourApp",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(
            name: "YourApp",
            targets: ["YourApp"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/taka-2120/SwiftHost.git", .upToNextMajor(from: "1.0.0")), // << Add this!
        •••
    ],
    targets: [
        .target(
            name: "YourApp",
            dependencies: [
                .product(name: "SwiftHost", package: "SwiftHost"), // << Add this!
                •••
            ],
        ),
    ]
)
```

### Quick Example

```swift
import SwiftHost

let router = Router {
    Route(method: .get, path: "/") { _ in
        HTTPResponse.text("Hello, World!")
    }

    Route(method: .post, path: "/users/:id") { request in
        let userID = request.pathParameters["id"]
        return HTTPResponse.json(["userID": userID])
    }
}

let server = HTTPServer(port: 3000, router: router)
try server.start()
```

### Host Configuration

You can manually set the host/IP address:

```swift
// Bind to localhost only
let server = HTTPServer(host: "localhost", port: 3000, router: router)

// Bind to a specific IP
let server = HTTPServer(host: "192.168.1.100", port: 3000, router: router)

// Auto-detect (default)
let server = HTTPServer(port: 3000, router: router)
```

## Routing

Routes match on HTTP method and path. Paths support parameters and wildcards:

```swift
Route(method: .get, path: "/users/:id") { request in
    // Access path params
    let id = request.pathParameters["id"]
    return HTTPResponse.text("User: \(id)")
}

Route(method: .get, path: "/static/*") { request in
    // Wildcard matches /static/anything
    return HTTPResponse.text("Static file")
}
```

## Middleware

Add middleware to process requests and responses globally:

```swift
let router = Router {
    Route(method: .get, path: "/") { _ in
        HTTPResponse.text("Hello!")
    }
}

let server = HTTPServer(port: 3000, router: router)

// Add middleware
server.use(LoggingMiddleware())
server.use(CORSMiddleware())
```

Write your own:

```swift
struct AuthMiddleware: Middleware {
    func processRequest(_ request: HTTPRequest) async -> HTTPRequest {
        // Check auth header, modify request
        return request
    }

    func processResponse(_ response: HTTPResponse) async -> HTTPResponse {
        // Modify response if needed
        return response
    }
}
```

## Response Types

```swift
HTTPResponse.text("Hello", statusCode: .ok)
HTTPResponse.json(["key": "value"])
HTTPResponse.html("<h1>Hello</h1>")
HTTPResponse.empty(statusCode: .noContent)
```

## Server Callbacks

Monitor server state:

```swift
let server = HTTPServer(
    port: 3000,
    router: router,
    onChangeServerStatus: { state in
        print("Server state: \(state)")
    },
    onConnected: {
        print("Client connected")
    },
    onDisconnected: {
        print("Client disconnected")
    }
)
```

## WebSocket Support

SwiftHost includes built-in WebSocket support for real-time communication with web pages.

### Setting Up WebSocket Server

Create a WebSocket server with connection callbacks:

```swift
let webSocketServer = WebSocketServer(
    onConnected: { clientID in
        print("WebSocket client connected: \(clientID)")
    },
    onDisconnected: { clientID in
        print("WebSocket client disconnected: \(clientID)")
    },
    onMessage: { clientID, message in
        print("Message from \(clientID): \(message)")
    }
)
```

### Integrating with HTTP Server

Pass the WebSocket server to your HTTP server:

```swift
let router = Router {
    Route(method: .get, path: "/") { _ in
        HTTPResponse.html("""
        <script>
            const ws = new WebSocket('ws://' + location.host);
            ws.onmessage = (event) => {
                if (event.data === 'refresh') {
                    location.reload();
                }
            };
        </script>
        """)
    }
}

let server = HTTPServer(
    port: 3000,
    router: router,
    webSocketServer: webSocketServer
)
```

### Refreshing Web Pages

Refresh all connected pages:

```swift
await webSocketServer.refreshPage()
```

Refresh a specific page:

```swift
await webSocketServer.refreshPage(clientID)
```

### Sending Custom Messages

Send a message to all clients:

```swift
await webSocketServer.broadcast("Hello, clients!")
```

Send to a specific client:

```swift
await webSocketServer.sendText("Hello!", to: clientID)
```

### Managing Connections

Get connection count:

```swift
let count = await webSocketServer.getConnectionCount()
```

Get all connection IDs:

```swift
let ids = await webSocketServer.getConnectionIDs()
```

Close a specific connection:

```swift
await webSocketServer.closeConnection(clientID)
```

## License

[MIT License](LICENSE.txt)

## Author

Yu Takahashi
