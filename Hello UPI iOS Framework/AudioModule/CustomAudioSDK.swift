//
//  CustomAuidoSDK.swift
//  SampleAudioApp
//
//  Created by Narayan Shettigar on 18/07/24.
//

import Foundation
import SwiftUI
import Speech
import AVFoundation

class AudioRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate, SFSpeechRecognizerDelegate {
    @Published var isRecording = false
    @Published var isProcessing = false
    @Published var audioURL: URL?
    @Published var transcription = ""
    
    private var audioRecorder: AVAudioRecorder?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    private var lastSpeechTimestamp: Date?
    private let silenceTimeout: TimeInterval = 1.0
    private var silenceTimer: Timer?
    
    @Published var audioLevels: [CGFloat] = Array(repeating: 0.2, count: 30)
    private var levelUpdateTimer: Timer?
    
    override init() {
        super.init()
        speechRecognizer.delegate = self
    }
    
    func reset() {
        // Stop recording if it's in progress
        if isRecording {
            stopRecording()
        }
        
        // Reset all published properties
        isRecording = false
        isProcessing = false
        audioURL = nil
        transcription = ""
        
        // Reset audio levels
        audioLevels = Array(repeating: 0.2, count: 30)
        
        // Cancel and reset speech recognition
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        
        // Stop and reset audio engine
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        // Invalidate and reset timers
        silenceTimer?.invalidate()
        silenceTimer = nil
        levelUpdateTimer?.invalidate()
        levelUpdateTimer = nil
        
        // Reset audio recorder
        audioRecorder = nil
        
        // Reset speech recognizer
        speechRecognizer.delegate = self
        
        // Reset last speech timestamp
        lastSpeechTimestamp = nil
        
        // Remove the recorded audio file if it exists
        if let audioURL = audioURL {
            try? FileManager.default.removeItem(at: audioURL)
        }
        
        // Optionally, you might want to reset the audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Error resetting audio session: \(error)")
        }
    }

    
    func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                if status != .authorized {
                    print("Speech recognition not authorized")
                }
            }
        }
        
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if !granted {
                    print("Microphone access not granted")
                }
            }
        }
    }
    
    func startRecording() {
        isProcessing = true
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to set up audio session: \(error)")
            isProcessing = false
            return
        }
        
        startActualRecording()
    }

    private func startActualRecording() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            isRecording = true
            isProcessing = false
            
            startSpeechRecognition()
            startAudioLevelUpdates()
            
        } catch {
            print("Failed to start recording: \(error)")
            isProcessing = false
        }
    }

    func startSpeechRecognition() {
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            print("Unable to create recognition request")
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = false
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("Error starting audio engine: \(error)")
        }
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            if let result = result {
                self?.transcription = result.bestTranscription.formattedString
                self?.lastSpeechTimestamp = Date()
                
                if result.isFinal {
                    self?.stopRecording()
                }
            }
            
            if error != nil {
                print("Error: \(String(describing: error?.localizedDescription))")
            }
        }
        
        // Start a timer to check for prolonged silence
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self, self.isRecording else {
                timer.invalidate()
                return
            }
            
            if let lastSpeech = self.lastSpeechTimestamp,
               Date().timeIntervalSince(lastSpeech) > self.silenceTimeout {
                self.stopRecording()
                timer.invalidate()
            }
        }
    }

    
    private func startAudioLevelUpdates() {
        levelUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateAudioLevels()
        }
    }
    
    private func updateAudioLevels() {
        guard let audioRecorder = audioRecorder, audioRecorder.isRecording else { return }
        audioRecorder.updateMeters()
        let level = CGFloat(audioRecorder.averagePower(forChannel: 0))
        let normalizedLevel = min(max((level + 50) / 50, 0), 1) // Normalize the level to 0-1 range
        DispatchQueue.main.async {
            self.audioLevels.removeFirst()
            self.audioLevels.append(normalizedLevel)
        }
    }

    func stopRecording() {
        audioRecorder?.stop()
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionTask?.finish()
        
        silenceTimer?.invalidate()
        silenceTimer = nil
        
        levelUpdateTimer?.invalidate()
        levelUpdateTimer = nil
        
        DispatchQueue.main.async {
            self.isRecording = false
            self.audioURL = self.audioRecorder?.url
            self.audioLevels = Array(repeating: 0.2, count: 30)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.recognitionTask?.cancel()
            self?.recognitionTask = nil
            self?.recognitionRequest = nil
        }
    }
    
    func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
