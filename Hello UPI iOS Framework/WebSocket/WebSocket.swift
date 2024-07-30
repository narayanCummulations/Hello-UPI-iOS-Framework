//
//  WebSocket.swift
//  Hello UPI iOS Framework
//
//  Created by Narayan Shettigar on 25/07/24.
//
import Foundation
import UIKit

class WebSocketManager: ObservableObject {
    @Published var isConnected = false
    @Published var lastMessage: String?
    
    private var webSocketTask: URLSessionWebSocketTask?
    private let url = URL(string: "wss://uatvoicepro.tonetag.com/cable")!
    
    private let CHANNEL_NAME = "Sdkchunksreckv1Channel"
    private let SUBSCRIBE = "subscribe"
    private let MESSAGE = "message"
    private let VOICE_SAMPLE = "voice_sample"
    private let TEXT_SAMPLE = "text_sample"
    private let STOP = "stop"
    
    private var chatRoomID: String = UUID().uuidString
    private var poolID: String = ""
    
    func connect() {
        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        receiveMessage()
        poolID = generateUniquePoolId()
        sendSubscribeMessage()
        isConnected = true
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    DispatchQueue.main.async {
                        self?.lastMessage = text
                        self?.handleMessage(text)
                        print(text)
                    }
                case .data(let data):
                    print("Received binary message: \(data)")
                @unknown default:
                    break
                }
                self?.receiveMessage()
            case .failure(let error):
                print("WebSocket receive error: \(error)")
            }
        }
    }
    
    func sendMessage(_ message: String) {
        let task = webSocketTask?.send(.string(message)) { error in
            if let error = error {
                print("WebSocket sending error: \(error)")
            }
        }
    }
    
    private func sendSubscribeMessage() {
        do {
            let subscribeMessage = [
                "command": SUBSCRIBE,
                "identifier": String(data: try JSONEncoder().encode([
                    "channel": CHANNEL_NAME,
                    "current_chatroom_id": chatRoomID,
                    "pool_id": poolID,
                    "lang_code": "\(MySDK.shared.configuration!.language.getValue())", // Change as needed
                    "env_type": MySDK.shared.configuration?.environment,
                    "d_id": UIDevice.current.identifierForVendor?.uuidString ?? "",
                    "version": "1.0", // Change to your SDK version
                    "bic": "H001", // Change as needed
                    "sub_key": MySDK.shared.configuration?.subscriptionKey
                ]), encoding: .utf8) ?? "{}"
            ]
            
            let jsonData = try JSONEncoder().encode(subscribeMessage)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                sendMessage(jsonString)
            }
        } catch {
            print("Error encoding subscribe message: \(error)")
        }
    }

    func sendVoiceSample(_ audioData: Data) {
        do {
            let base64Audio = audioData.base64EncodedString()
            let voiceMessage = [
                "command": MESSAGE,
                "identifier": String(data: try JSONEncoder().encode([
                    "channel": CHANNEL_NAME,
                    "current_chatroom_id": chatRoomID,
                    "pool_id": poolID,
                    // Add other identifier fields as in sendSubscribeMessage
                ]), encoding: .utf8) ?? "{}",
                "data": String(data: try JSONEncoder().encode([
                    "action": VOICE_SAMPLE,
                    "status": STOP,
                    "uuid": UUID().uuidString,
                    "origin": "user",
                    "v_sample": base64Audio
                    // Add other data fields as needed
                ]), encoding: .utf8) ?? "{}"
            ]
            
            let jsonData = try JSONEncoder().encode(voiceMessage)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                sendMessage(jsonString)
            }
        } catch {
            print("Error encoding voice message: \(error)")
        }
    }
    
    private func handleMessage(_ message: String) {
        // Implement message handling logic here
        // Parse the JSON and update your app state accordingly
    }
    
    private func generateUniquePoolId() -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
        return String((0..<8).map { _ in characters.randomElement()! })
    }
}
