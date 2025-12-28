import Foundation
import CryptoKit

enum SHA1 {
    /// Computes the SHA1 hash of the given data.
    ///
    /// - Parameter data: The data to hash
    /// - Returns: The SHA1 digest as a byte array
    static func hash(data: Data) -> [UInt8] {
        let digest = Insecure.SHA1.hash(data: data)
        return Array(digest)
    }
}
