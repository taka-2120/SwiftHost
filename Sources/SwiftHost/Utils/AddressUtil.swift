import Network

/// Utility functions for network address operations.
enum NetworkUtil {
    /// Finds an available port number for the server.
    ///
    /// Generates random port numbers in the range 1024-65535, avoiding commonly reserved ports.
    /// Retries up to 10 times if a reserved port is randomly selected.
    ///
    /// - Returns: An available port number, or nil if none found after maximum retries
    static func getAvailablePortNumber() -> UInt16? {
        let maxRetry = 10
        var tryCount = 0
        let reservedPorts: Set<UInt16> = [0, 22, 25, 80, 110, 143, 443, 993, 1080]

        var randomPort: UInt16
        while tryCount < maxRetry {
            tryCount += 1
            randomPort = UInt16.random(in: 1024...65535)

            if reservedPorts.contains(randomPort) { continue }

            return randomPort
        }

        return nil
    }

    /// Gets the current device's local IP address.
    ///
    /// Iterates through network interfaces to find the first active, non-loopback IPv4 address.
    ///
    /// - Returns: The device's IP address as a string, or nil if not found
    static func getCurrentDeviceIP() -> String? {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return nil
        }
        defer { freeifaddrs(firstAddr) }

        var ptr = firstAddr
        while true {
            let interface = ptr.pointee
            let flags = Int32(interface.ifa_flags)
            let isUp = (flags & IFF_UP) != 0
            let isLoopback = (flags & IFF_LOOPBACK) != 0

            if isUp && !isLoopback,
               let sa = interface.ifa_addr,
               sa.pointee.sa_family == sa_family_t(AF_INET) {
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                if getnameinfo(sa, socklen_t(sa.pointee.sa_len),
                              &hostname, socklen_t(hostname.count),
                              nil, 0, NI_NUMERICHOST) == 0 {
                    let nullIndex = hostname.firstIndex(of: 0) ?? hostname.endIndex
                    let bytes = hostname[..<nullIndex].map { UInt8(bitPattern: $0) }
                    return String(decoding: bytes, as: UTF8.self)
                }
            }

            guard let nextAddr = interface.ifa_next else { break }
            ptr = nextAddr
        }

        return nil
    }
}
