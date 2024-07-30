//
//  WebSocketView.swift
//  Hello UPI iOS Framework
//
//  Created by Narayan Shettigar on 29/07/24.
//

import Foundation
import SwiftUI

struct WebSocketView: View {
    @StateObject private var webSocketManager = WebSocketManager()
    
    var body: some View {
        VStack {
            Text("WebSocket Status: \(webSocketManager.isConnected ? "Connected" : "Disconnected")")
            Button("Connect") {
                webSocketManager.connect()
            }
            if let lastMessage = webSocketManager.lastMessage {
                Text("Last Message: \(lastMessage)")
            }
        }
    }
}
