//
//  TonePlayerObservable.swift
//  TonePlayer
//
//  Created by Joseph Pagliaro on 2/3/23.
//

import Foundation
import SwiftUI
import Combine
import AVFoundation

enum ToneRampType: String, CaseIterable, Identifiable {
    case none, linear, parablic, exponential
    var id: Self { self }
}

class TonePlayerObservable: ObservableObject {
    
    var toneGenerator:ToneGenerator
    @Published var component:Component
    
    @Published var favoriteFrequencies:[Double] = UserDefaults.standard.array(forKey: "FavoriteFrequencies") as? [Double] ?? defaultFavoriteFrequencies
    
    @Published var applyPhaseOffset = true
    @Published var applyAmplitudeInterpolation = true
    
    @Published var randomizeTimer:Timer?
    
    @Published var frequencyIncrementValue:Double = 1.0
    
        // Audio Engine
    let engine = AVAudioEngine()
    var srcNode:AVAudioSourceNode?
    var sampleRate:Float = 0
    var inputFormat:AVAudioFormat!
        // for ramping samples on start/stop
    var stopEngineDispatchGroup:DispatchGroup?
    let stopQueue = DispatchQueue(label: "com.limit-point.tone-player-stop-queue")
    var stopRequested = false // used to ramp down audio volume for a smooth stop
    var startRequested = false // used to ramp up audio volume for a smooth start
    
    @Published var isPlaying = false
    
    let octavesArray = OctavesArray()
    @Published var octaveViewColumnsCount = 3
    @Published var isShowingOctaveView = false
    
        // Audio Tone Export
    var audioDocument:AudioDocument?
    var audioDocumentExportURL:URL?
    @Published var showAudioExporter: Bool = false
    @Published var isExporting = false
    var audioPlayer: AVAudioPlayer? // to preview export
    
    var cancelBag = Set<AnyCancellable>()
    
        // MARK: Audio Engine
    
    init(component:Component) {
        self.component = component
        toneGenerator = ToneGenerator(component: component)
        connectAudioEngine()
        
        $favoriteFrequencies.sink { [weak self]  newFrequencies in 
            self?.saveFavoriteFrequencies()
        }
        .store(in: &cancelBag)
    }
    
    deinit {
        print("TonePlayerObservable deinit")
        engine.stop()
        disconnectAudioEngine()
    }
    
    func connectAudioEngine() {
        
        let mainMixer = engine.mainMixerNode
        
        let output = engine.outputNode
        let outputFormat = output.inputFormat(forBus: 0)
        sampleRate = Float(outputFormat.sampleRate)
        
        print("The audio engine sample rate is \(sampleRate)")
        
        inputFormat = AVAudioFormat(commonFormat: outputFormat.commonFormat,
                                    sampleRate: outputFormat.sampleRate,
                                    channels: 1,
                                    interleaved: outputFormat.isInterleaved)
        
        var currentIndex:Int = 0
        
        srcNode = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            
            guard let self = self else {
                return OSStatus(-1)
            }
            
            let sampleRange = currentIndex...currentIndex+Int(frameCount-1)
            
            let audioSamples = self.audioSamplesForRange(sampleRange: sampleRange)
            
            currentIndex += Int(frameCount)
            
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            for frame in 0..<Int(frameCount) {
                
                let value = Float(audioSamples[frame]) / Float(Int16.max)
                
                for buffer in ablPointer {
                    let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
                    buf[frame] = value
                }
            }
            
            if self.stopRequested {
                self.stopEngineDispatchGroup?.leave()
            }
            
            return noErr
        }
        
        if let srcNode = srcNode {
            engine.attach(srcNode)
            engine.connect(srcNode, to: mainMixer, format: inputFormat)
            engine.connect(mainMixer, to: output, format: outputFormat)
            mainMixer.outputVolume = 1
        }
    }
    
    func disconnectAudioEngine() {
        if let srcNode = srcNode {
            engine.detach(srcNode)
            self.srcNode = nil
        }
    }
    
    func audioSamplesForRange(sampleRange:ClosedRange<Int>) -> [Int16] {
        
        if stopRequested {
            var samples = toneGenerator.audioSamplesForRange(component: component, sampleRange: sampleRange, sampleRate: Int(sampleRate), applyPhaseOffset:applyPhaseOffset, applyAmplitudeInterpolation:applyAmplitudeInterpolation)
            
            samples = scaleAmplitudesDown(samples)
            
            return samples
        }
        
        var samples = toneGenerator.audioSamplesForRange(component: component, sampleRange: sampleRange, sampleRate: Int(sampleRate), applyPhaseOffset:applyPhaseOffset, applyAmplitudeInterpolation:applyAmplitudeInterpolation)
        
        if startRequested {
            samples = scaleAmplitudesUp(samples)
            startRequested = false
        }
        
        return samples
    }
    
    func startPlaying(completion: @escaping (Bool) -> ()) {
        do {
            try engine.start()
            startRequested = true
            DispatchQueue.main.async { [weak self] in
                self?.isPlaying = true
                completion(true)
            }
        }
        catch {
            DispatchQueue.main.async { [weak self] in
                self?.isPlaying = false
                completion(false)
            }
            print("Error starting audio engine.")
        }
    }
    
    func stopPlaying(completion: @escaping () -> ()) {
        
        DispatchQueue.main.async { [weak self] in
            self?.isPlaying = false
            completion()
        }
        
        if stopRequested == false, engine.isRunning {
            
            stopRequested = true
            
            stopEngineDispatchGroup = DispatchGroup()
            stopEngineDispatchGroup?.enter()
            stopEngineDispatchGroup?.notify(queue: stopQueue) { [weak self] in
                self?.stopRequested = false
                self?.engine.stop()
            }
        }
    }
    
        // MARK: Random Tones
    
    func randomizeComponentFrequency() {
        self.component.frequency = Double.random(in: randomFrequencyRange)
    }
    
    func startRandomizeTimer() { 
        let schedule = { [weak self] in
            self?.randomizeTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                self?.randomizeComponentFrequency()
            }
        }
        
        if self.randomizeTimer == nil {
            if Thread.isMainThread {
                schedule()
            }
            else {
                DispatchQueue.main.sync {
                    schedule()
                }
            }
        }
    }
    
    func stopRandomizeTimer() {
        randomizeTimer?.invalidate()
        randomizeTimer = nil
    }
    
        // MARK: Frequency Controls
    
    func frequencyCanBeDoubled() -> Bool {
        return frequencyRange().contains(self.component.frequency * 2.0)
    }
    
    func frequencyCanBeHalved() -> Bool {
        return frequencyRange().contains(self.component.frequency / 2.0)
    }
    
    func doubleFrequency() {
        if frequencyCanBeDoubled() {
            self.component.frequency = self.component.frequency * 2.0
        }
    }
    
    func halveFrequency() {
        if frequencyCanBeHalved() {
            self.component.frequency = self.component.frequency / 2.0
        }
    }
    
    func canIncrementFrequency() -> Bool {
        return frequencyRange().contains(self.component.frequency + frequencyIncrementValue)
    }
    
    func canDecrementFrequency() -> Bool {
        return frequencyRange().contains(self.component.frequency - frequencyIncrementValue)
    }
    
    func incrementFrequency() {
        if canIncrementFrequency() {
            self.component.frequency = self.component.frequency + frequencyIncrementValue
        }
    }
    
    func decrementFrequency() {
        if canDecrementFrequency() {
            self.component.frequency = self.component.frequency - frequencyIncrementValue
        }
    }
    
    func lowestFrequency() -> Double {
        return 20.0
    }
    
    func highestFrequency() -> Double {
        return Double(sampleRate) / 2.0
    }
    
    func frequencyRange() -> ClosedRange<Double> {
        return lowestFrequency()...highestFrequency()
    }
    
    func frequencySliderRange() -> ClosedRange<Double> {
        return pianoKeyForFrequency(lowestFrequency())...pianoKeyForFrequency(highestFrequency())
    }
    
        // MARK: Favorite Frequencies
    
    func saveFavoriteFrequencies() {
        UserDefaults.standard.set(favoriteFrequencies, forKey: "FavoriteFrequencies")
    }
    
    func deleteAllFrequencyFavorites() {
        favoriteFrequencies.removeAll()
        saveFavoriteFrequencies()
    }
    
    func removeFavoriteFrequency(at indexToRemove:Int) {
        favoriteFrequencies.remove(at: indexToRemove)
        saveFavoriteFrequencies()
    }
    
    func addFrequencyToFavorites() {
        favoriteFrequencies.append(component.frequency)
        saveFavoriteFrequencies()
    }
    
    func addDefaultFrequenciesToFavorites() {
        favoriteFrequencies.append(contentsOf: defaultFavoriteFrequencies)
        saveFavoriteFrequencies()
    }
    
    func setFrequencyToFavoriteFrequency(_ favoriteFrequency:Double) {
        component.frequency = favoriteFrequency
    }
    
        // MARK: Export to Tone File
    func toneRamp(toneRampType:ToneRampType, duration:Double) -> ((Double)->Double)? {
        
        var scale:((Double)->Double)?
        
        switch toneRampType {
                
            case .none:
                scale = nil
            case .linear:
                scale = {t in 1 - (t / duration)}
            case .parablic:
                scale = {t in pow(((t - duration)/duration), 2)}
            case .exponential:
                let a = log(Double(Int16.max)) / duration
                scale = {t in exp(-a * t)}
        }
        
        return scale
    }
    
    func generateToneAudio(_ duration:Double, _ toneRampType:ToneRampType, completion: @escaping (URL?) -> ()) {
        
        DispatchQueue.global().async { [weak self] in
            
            guard let self = self else {
                completion(nil)
                return
            }
            if let audioDocumentExportURL = self.audioDocumentExportURL {
                try? FileManager.default.removeItem(at: audioDocumentExportURL)
            }
            
            let outputURL = FileManager.documentsURL(filename: kAudioExportName, subdirectoryName: kTemporarySubdirectoryName)!
            
            toneWriter.scale = self.toneRamp(toneRampType: toneRampType, duration: duration)
            
            toneWriter.saveComponentSamplesToFile(component: self.component, duration: duration, destinationURL: outputURL) { url, message in
               completion(url)
            }
        }
    }
    
    func exportToneAudio(_ duration:Double, _ toneRampType:ToneRampType) {
        isExporting = true
        
        self.generateToneAudio(duration, toneRampType) { [weak self] url in
            
            guard let self = self else {
                return
            }
            
            if let url = url {
                self.audioDocumentExportURL = url
                
                self.audioDocument = AudioDocument(url: self.audioDocumentExportURL!)
                
                DispatchQueue.main.async {
                    self.isExporting = false
                    self.showAudioExporter = true
                }
            }
            else {
                DispatchQueue.main.async {
                    self.isExporting = false
                }
            }
        }
    }
    
        // MARK: Audio Player to Play Preview of Export

    func stopAudioURL() {
        audioPlayer?.stop()
    }
    
    func playAudioURL(_ url:URL) {
        
        do {
            audioPlayer?.stop()
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)         
            
            if let audioPlayer = audioPlayer {
                audioPlayer.prepareToPlay()
                audioPlayer.play()
            }
            
        } catch let error {
            print(error.localizedDescription)
        }
    }
}
