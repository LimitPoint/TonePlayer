//
//  ToneWriter.swift
//  TonePlayer
//
//  Created by Joseph Pagliaro on 2/21/23.
//

import SwiftUI
import Foundation
import AVFoundation

var toneWriter = ToneWriter()

/*
 Solve for t: e^(-2t) = 1/Int16.max, smallest positive value of Int16 (where positive means > 0)
 
 or in WolframAlpha:
 
 'evaluate solve exp(-2t) = Divide[1,32767.0] -> t = 5.1985885951776919399153766837350066151723800263211215177494011314'
 */
func GenerateTonePlayerSample() {
    let D = -log(1.0/Double(Int16.max)) / 2.0 // D = 5.198588595177692
    print(D)
    let scale:((Double)->Double) = {t in exp(-2 * t)} 
    TestToneWriter(wavetype: .sine, frequency: 440, amplitude: 1, duration: D, scale: scale)
}

func TestToneWriter(wavetype: WaveFunctionType, frequency:Double, amplitude: Double, duration: Double, scale: ((Double)->Double)? = nil) {
    if let documentsURL = FileManager.documentsURL(filename: nil, subdirectoryName: nil) {
        print(documentsURL)
        
        let destinationURL = documentsURL.appendingPathComponent("tonewriter - \(wavetype), \(frequency) hz, \(duration).wav")
        
        toneWriter.scale = scale
        
        toneWriter.saveComponentSamplesToFile(component: Component(type: wavetype, frequency: frequency, amplitude: amplitude, offset: 0), duration: duration,  destinationURL: destinationURL) { resultURL, message in
            if let resultURL = resultURL {
#if os(macOS)
                NSWorkspace.shared.open(resultURL)
#endif
                let asset = AVAsset(url: resultURL)
                Task {
                    do {
                        let duration = try await asset.load(.duration)
                        print("ToneWriter : audio duration = \(duration.seconds)")
                    }
                    catch {
                    }
                }
            }
            else {
                print("An error occurred : \(message ?? "No error message available.")")
            }
        }
    }
}

class ToneWriter {
       
    let kAudioWriterExpectsMediaDataInRealTime = false
    let kToneGeneratorQueue = "com.limit-point.tone-generator-queue"
    
    var scale: ((Double)->Double)? // scale factor range in [0,1]
    
    deinit {
        print("ToneWriter deinit")
    }
    
    func audioSamplesForRange(component:Component, sampleRate:Int, sampleRange:ClosedRange<Int>) -> [Int16] {
        
        var samples:[Int16] = []
        
        let delta_t:Double = 1.0 / Double(sampleRate)
        
        for i in sampleRange.lowerBound...sampleRange.upperBound {
            let t = Double(i) * delta_t
            
            var value = component.value(x: t) * Double(Int16.max)
            if let scale = scale {
                value = scale(t) * value
            }
            let valueInt16 = Int16(max(min(value, Double(Int16.max)), Double(Int16.min)))
            samples.append(valueInt16)
        }
        
        return samples
    }
    
    func rangeForIndex(bufferIndex:Int, bufferSize:Int, samplesRemaining:Int?) -> ClosedRange<Int> {
        let start = bufferIndex * bufferSize
        
        if let samplesRemaining = samplesRemaining {
            return start...(start + samplesRemaining - 1)
        }
        
        return start...(start + bufferSize - 1)
    }
    
    func sampleBufferForSamples(audioSamples:[Int16], bufferIndex:Int, sampleRate:Int, bufferSize:Int) -> CMSampleBuffer? {
        
        var sampleBuffer:CMSampleBuffer?
        
        let bytesInt16 = MemoryLayout<Int16>.stride
        let dataSize = audioSamples.count * bytesInt16
        
        var samplesBlock:CMBlockBuffer? 
        
        let memoryBlock:UnsafeMutableRawPointer = UnsafeMutableRawPointer.allocate(
            byteCount: dataSize,
            alignment: MemoryLayout<Int16>.alignment)
        
        let _ = audioSamples.withUnsafeBufferPointer { buffer in
            memoryBlock.initializeMemory(as: Int16.self, from: buffer.baseAddress!, count: buffer.count)
        }
        
        if CMBlockBufferCreateWithMemoryBlock(
            allocator: kCFAllocatorDefault, 
            memoryBlock: memoryBlock, 
            blockLength: dataSize, 
            blockAllocator: nil, 
            customBlockSource: nil, 
            offsetToData: 0, 
            dataLength: dataSize, 
            flags: 0, 
            blockBufferOut:&samplesBlock
        ) == kCMBlockBufferNoErr, let samplesBlock = samplesBlock {
            
            var asbd = AudioStreamBasicDescription()
            asbd.mSampleRate = Float64(sampleRate)
            asbd.mFormatID = kAudioFormatLinearPCM
            asbd.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked
            asbd.mBitsPerChannel = 16
            asbd.mChannelsPerFrame = 1
            asbd.mFramesPerPacket = 1
            asbd.mBytesPerFrame = 2
            asbd.mBytesPerPacket = 2
            
            var formatDesc: CMAudioFormatDescription?
            
            let sampleDuration = CMTimeMakeWithSeconds((1.0 / Float64(sampleRate)), preferredTimescale: Int32.max)
            
            if CMAudioFormatDescriptionCreate(allocator: nil, asbd: &asbd, layoutSize: 0, layout: nil, magicCookieSize: 0, magicCookie: nil, extensions: nil, formatDescriptionOut: &formatDesc) == noErr, let formatDesc = formatDesc {
                
                let sampleTime = CMTimeMultiply(sampleDuration, multiplier: Int32(bufferIndex * bufferSize))
                
                let timingInfo = CMSampleTimingInfo(duration: sampleDuration, presentationTimeStamp: sampleTime, decodeTimeStamp: .invalid)
                
                if CMSampleBufferCreate(allocator: kCFAllocatorDefault, dataBuffer: samplesBlock, dataReady: true, makeDataReadyCallback: nil, refcon: nil, formatDescription: formatDesc, sampleCount: audioSamples.count, sampleTimingEntryCount: 1, sampleTimingArray: [timingInfo], sampleSizeEntryCount: 0, sampleSizeArray: nil, sampleBufferOut: &sampleBuffer) == noErr, let sampleBuffer = sampleBuffer {
                    
                    guard sampleBuffer.isValid, sampleBuffer.numSamples == audioSamples.count else {
                        return nil
                    }
                }
            }
        }
        
        return sampleBuffer
    }
    
    func sampleBufferForComponent(component:Component, sampleRate:Int, bufferSize: Int, bufferIndex:Int, samplesRemaining:Int?) -> CMSampleBuffer? {
        
        let audioSamples = audioSamplesForRange(component: component, sampleRate: sampleRate, sampleRange: rangeForIndex(bufferIndex:bufferIndex, bufferSize: bufferSize, samplesRemaining: samplesRemaining))
        
        return sampleBufferForSamples(audioSamples: audioSamples, bufferIndex: bufferIndex, sampleRate: sampleRate, bufferSize: bufferSize)
    }
    
    func saveComponentSamplesToFile(component:Component, duration:Double = 3, sampleRate:Int = 44100, bufferSize:Int = 8192, destinationURL:URL, completion: @escaping (URL?, String?) -> ())  {
        
        guard let sampleBuffer = sampleBufferForComponent(component: component, sampleRate: sampleRate, bufferSize:  bufferSize, bufferIndex: 0, samplesRemaining: nil) else {
            completion(nil, "Invalid first sample buffer.")
            return
        }
        
        var actualDestinationURL = destinationURL
        
        if actualDestinationURL.pathExtension != "wav" {
            actualDestinationURL.deletePathExtension() // this can have unintended consequences, ex name = "x2.3"
            actualDestinationURL.appendPathExtension("wav")
        }
        
        try? FileManager.default.removeItem(at: actualDestinationURL)
        
        guard let assetWriter = try? AVAssetWriter(outputURL: actualDestinationURL, fileType: AVFileType.wav) else {
            completion(nil, "Can't create asset writer.")
            return
        }
        
        let sourceFormat = CMSampleBufferGetFormatDescription(sampleBuffer)
        
        let audioCompressionSettings = [AVFormatIDKey: kAudioFormatLinearPCM] as [String : Any]
        
        if assetWriter.canApply(outputSettings: audioCompressionSettings, forMediaType: AVMediaType.audio) == false {
            completion(nil, "Can't apply compression settings to asset writer.")
            return
        }
        
        let audioWriterInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings:audioCompressionSettings, sourceFormatHint: sourceFormat)
        
        audioWriterInput.expectsMediaDataInRealTime = kAudioWriterExpectsMediaDataInRealTime
        
        if assetWriter.canAdd(audioWriterInput) {
            assetWriter.add(audioWriterInput)
            
        } else {
            completion(nil, "Can't add audio input to asset writer.")
            return
        }
        
        let serialQueue: DispatchQueue = DispatchQueue(label: kToneGeneratorQueue)
        
        assetWriter.startWriting()
        assetWriter.startSession(atSourceTime: CMTime.zero)
        
        func finishWriting() {
            assetWriter.finishWriting {
                switch assetWriter.status {
                    case .failed:
                        
                        var errorMessage = ""
                        if let error = assetWriter.error {
                            
                            let nserr = error as NSError
                            
                            let description = nserr.localizedDescription
                            errorMessage = description
                            
                            if let failureReason = nserr.localizedFailureReason {
                                print("error = \(failureReason)")
                                errorMessage += ("Reason " + failureReason)
                            }
                        }
                        completion(nil, errorMessage)
                        print("saveComponentsSamplesToFile errorMessage = \(errorMessage)")
                        return
                    case .completed:
                        print("saveComponentsSamplesToFile completed : \(actualDestinationURL)")
                        completion(actualDestinationURL, nil)
                        return
                    default:
                        print("saveComponentsSamplesToFile other failure?")
                        completion(nil, nil)
                        return
                }
            }
        }
        
        var nbrSampleBuffers = Int(duration * Double(sampleRate)) / bufferSize
        
        let samplesRemaining = Int(duration * Double(sampleRate)) % bufferSize
        
        if samplesRemaining > 0 {
            nbrSampleBuffers += 1
        }
        
        print("samplesRemaining = \(samplesRemaining)")
        
        var bufferIndex = 0
        
        audioWriterInput.requestMediaDataWhenReady(on: serialQueue) { [weak self] in
            
            while audioWriterInput.isReadyForMoreMediaData, bufferIndex < nbrSampleBuffers {
                
                var currentSampleBuffer:CMSampleBuffer?
                
                if samplesRemaining > 0 {
                    if bufferIndex < nbrSampleBuffers-1 {
                        currentSampleBuffer = self?.sampleBufferForComponent(component: component, sampleRate: sampleRate, bufferSize: bufferSize, bufferIndex: bufferIndex, samplesRemaining: nil)
                    }
                    else {
                        currentSampleBuffer = self?.sampleBufferForComponent(component: component, sampleRate: sampleRate, bufferSize: bufferSize, bufferIndex: bufferIndex, samplesRemaining: samplesRemaining)
                    }
                }
                else {
                    currentSampleBuffer = self?.sampleBufferForComponent(component: component, sampleRate: sampleRate, bufferSize: bufferSize, bufferIndex: bufferIndex, samplesRemaining: nil)
                }
                
                if let currentSampleBuffer = currentSampleBuffer {
                    audioWriterInput.append(currentSampleBuffer)
                }
                
                bufferIndex += 1
                
                if bufferIndex == nbrSampleBuffers {
                    audioWriterInput.markAsFinished()
                    finishWriting()
                }
            }
        }
    }
}


