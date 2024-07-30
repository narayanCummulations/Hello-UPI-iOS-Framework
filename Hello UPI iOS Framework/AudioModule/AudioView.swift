//
//  AudioView.swift
//  Hello UPI iOS Framework
//
//  Created by Narayan Shettigar on 29/07/24.
//

import Foundation
import SwiftUI
import AVFoundation

struct AudioRecorderContentView: View {
    @ObservedObject private var audioRecorder = AudioRecorder()
    @State private var isShowingTranscription = false
    
    var body: some View {
        ZStack {
            
            VStack(spacing: 5) {
                if audioRecorder.isRecording {
                    VStack{
                        AudioWaveform(audioLevels: $audioRecorder.audioLevels)
                            .frame(width: 200, height: 20, alignment: .center)
                            .padding()
                            .shadow(radius: 5)
                    }
                } else {
                    Button(action: {
                        self.audioRecorder.startRecording()
                    }) {
                        Image(systemName: "mic")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.blue.opacity(0.8))
                            .clipShape(Circle())
                            .shadow(radius: 10)
                    }
                    .disabled(audioRecorder.isProcessing)
                }
                
                if let audioURL = audioRecorder.audioURL {
                    AudioPlayer(url: audioURL)
                }
                
                if !audioRecorder.transcription.isEmpty {
                    HStack{
                        Text("Transcription: ")
                            .font(.footnote)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.green)
                            .cornerRadius(10)
                        
                        Text(audioRecorder.transcription)
                            .font(.footnote)
                            .padding(8)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(10)
                            .shadow(radius: 5)
                            .transition(.scale)
                    }
                }
                
                HStack {
                    Spacer()
                    Button(action: {
                        self.audioRecorder.reset()
                    }) {
                        Text("Reset")
                            .font(.footnote)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(10)
                    }
                    .disabled(audioRecorder.isRecording)
                }
            }
            .padding()
        }
        .onAppear {
            audioRecorder.requestPermissions()
        }
    }
}


struct AudioPlayer: View {
    let url: URL
    @State private var isPlaying = false
    private var audioPlayer: AVAudioPlayer?
    private var audioSession: AVAudioSession!
    
    init(url: URL) {
        self.url = url
        self.audioPlayer = try? AVAudioPlayer(contentsOf: url)
        
        do {
            self.audioSession = AVAudioSession.sharedInstance()
            try self.audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try self.audioSession.setActive(true)
        } catch {
            print("Error setting up audio session: \(error.localizedDescription)")
        }
    }
    
    var body: some View {
        Button(action: {
            if isPlaying {
                self.audioPlayer?.pause()
            } else {
                self.audioPlayer?.play()
            }
            isPlaying.toggle()
        }) {
            HStack {
                Image(systemName: "play.circle.fill")
                    .font(.footnote)
                Text("Play Recording")
                    .font(.footnote)
                
            }
            .foregroundColor(.white)
            .padding(8)
            .background(Color.orange)
            .cornerRadius(20)
            .shadow(radius: 5)
        }
    }
}


struct AudioWaveform: View {
    @Binding var audioLevels: [CGFloat]
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 4) {
                ForEach(0..<min(self.audioLevels.count, 30), id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.black.opacity(0.5))
                        .frame(width: (geometry.size.width - 120) / 30, height: self.audioLevels[index] * geometry.size.height)
                }
            }
        }
        .frame(height: 50)
    }
}
