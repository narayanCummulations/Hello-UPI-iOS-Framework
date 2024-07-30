//
//  AES_ALGO.swift
//  Hello UPI iOS Framework
//
//  Created by Narayan Shettigar on 22/07/24.
//

import Foundation
import CommonCrypto

public enum AESError: Error {
    case keyGenerationError
    case encryptionError
    case decryptionError
    case decodingError
}

public final class AESCrypt {
    private static let TAG = "AESCrypt"
    private static let AES_MODE = kCCAlgorithmAES
    private static let CHARSET = String.Encoding.utf8
    private static let HASH_ALGORITHM = CCPBKDFAlgorithm(kCCPRFHmacAlgSHA256)
    private static let ivBytes: [UInt8] = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                           0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
    private static let DEBUG_LOG_ENABLED = false

    private init() {}

    public static func encrypt(password: String, message: String) throws -> String {
        let key = try generateKey(password: password)
        print("key : \(key)")
        print("message : \(message)")
        let cipherText = try encrypt(key: key, iv: Data(ivBytes), message: message.data(using: CHARSET)!)
        print("this is cipherText:- \(cipherText)")
        let encoded = cipherText.base64EncodedString(options: [])
        print("this is encoded cipherText:- \(encoded)")
        var res = try decrypt(password: password, base64EncodedCipherText: encoded)
        print("decryt : \(res)")
        return encoded
    }

    public static func decrypt(password: String, base64EncodedCipherText: String) throws -> String {
        let key = try generateKey(password: password)
        
        guard let decodedCipherText = Data(base64Encoded: base64EncodedCipherText, options: []) else {
            throw AESError.decodingError
        }
        
        let decryptedBytes = try decrypt(key: key, iv: Data(ivBytes), decodedCipherText: decodedCipherText)
        
        guard let message = String(data: decryptedBytes, encoding: CHARSET) else {
            throw AESError.decodingError
        }
        print("decrypt message:- \(message)")
        return message
    }

    private static func generateKey(password: String) throws -> Data {
        let passwordData = password.data(using: .utf8)!
        var key = Data(count: kCCKeySizeAES256)
        let salt = Data() // Empty salt, matching the original code
        let rounds = 10000 // Number of PBKDF2 rounds

        let status = key.withUnsafeMutableBytes { keyBytes in
            passwordData.withUnsafeBytes { passwordBytes in
                CCKeyDerivationPBKDF(
                    CCPBKDFAlgorithm(kCCPBKDF2),
                    passwordBytes.baseAddress, passwordBytes.count,
                    salt.withUnsafeBytes { $0.baseAddress }, salt.count,
                    CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                    UInt32(rounds),
                    keyBytes.baseAddress, keyBytes.count)
            }
        }

        guard status == kCCSuccess else {
            throw AESError.keyGenerationError
        }

        return key
    }

    private static func encrypt(key: Data, iv: Data, message: Data) throws -> Data {
        let bufferSize = message.count + kCCBlockSizeAES128
        var buffer = Data(count: bufferSize)
        
        var numBytesEncrypted: Int = 0
        
        let status = key.withUnsafeBytes { keyBytes in
            iv.withUnsafeBytes { ivBytes in
                message.withUnsafeBytes { messageBytes in
                    buffer.withUnsafeMutableBytes { bufferBytes in
                        CCCrypt(
                            CCOperation(kCCEncrypt),
                            CCAlgorithm(AES_MODE),
                            CCOptions(kCCOptionPKCS7Padding),
                            keyBytes.baseAddress, keyBytes.count,
                            ivBytes.baseAddress,
                            messageBytes.baseAddress, messageBytes.count,
                            bufferBytes.baseAddress, bufferSize,
                            &numBytesEncrypted
                        )
                    }
                }
            }
        }
        
        guard status == kCCSuccess else {
            throw AESError.encryptionError
        }
        
        buffer.count = numBytesEncrypted
        return buffer
    }

    private static func decrypt(key: Data, iv: Data, decodedCipherText: Data) throws -> Data {
        let bufferSize = decodedCipherText.count + kCCBlockSizeAES128
        var buffer = Data(count: bufferSize)
        
        var numBytesDecrypted: Int = 0
        
        let status = key.withUnsafeBytes { keyBytes in
            iv.withUnsafeBytes { ivBytes in
                decodedCipherText.withUnsafeBytes { cipherTextBytes in
                    buffer.withUnsafeMutableBytes { bufferBytes in
                        CCCrypt(
                            CCOperation(kCCDecrypt),
                            CCAlgorithm(AES_MODE),
                            CCOptions(kCCOptionPKCS7Padding),
                            keyBytes.baseAddress, keyBytes.count,
                            ivBytes.baseAddress,
                            cipherTextBytes.baseAddress, cipherTextBytes.count,
                            bufferBytes.baseAddress, bufferSize,
                            &numBytesDecrypted
                        )
                    }
                }
            }
        }
        
        guard status == kCCSuccess else {
            throw AESError.decryptionError
        }
        
        buffer.count = numBytesDecrypted
        return buffer
    }
}
