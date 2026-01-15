//
//  TonePlayerApp.swift
//  TonePlayer
//
//  Created by Joseph Pagliaro on 2/3/23.
//

import SwiftUI
import AVFoundation
import Accelerate

struct HelpMenu: View {
    var body: some View {
        Group {
            
            Link("Limit Point LLC", destination: URL(
                string: "https://www.limit-point.com/")!)
            Divider() 
            Link("TonePlayer", destination: URL(
                string: "https://www.limitpointstore.com/products/toneplayer/")!)
            
        }
    }
}

func SampleSineAtNyquistRate(_ frequency:Int) {
    
    let f = frequency
    let sampleRate = 2 * f // Nyquist rate
    let delta_t:Double = 1.0 / Double(sampleRate)
    
    var samples = [Double](repeating: -1, count: sampleRate)
    
    print("sampleRate = \(sampleRate)")
    
    for i in 1...sampleRate {
        let t = (Double(i-1) * delta_t)
        samples[i-1] = sin(2 * Double.pi * Double(f) * t) // sin(2 π f t)
    }
    
    let maximum = vDSP.maximum(samples)
    let minimum = vDSP.minimum(samples)
    
    print("maximum = \(String(format: "%.9f", maximum)), \(maximum)")
    print("minimum = \(String(format: "%.9f", minimum)), \(minimum)")
}

@main
struct TonePlayerApp: App {
    
#if os(iOS)    
    var audioSessionObserver: Any!
#endif
    
    init() {
        FileManager.deleteDocumentsSubdirectory(subdirectoryName: kTemporarySubdirectoryName)
        
        //GenerateTonePlayerSample()
        //SampleSineAtNyquistRate(51963)

#if os(iOS)         
        func setUpAudioSession() {
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            } catch {
                print("Failed to set audio session route sharing policy: \(error.localizedDescription)")
            }
            
            print("Configured audio session")
        }
        
        let notificationCenter = NotificationCenter.default
        
        audioSessionObserver = notificationCenter.addObserver(forName: AVAudioSession.mediaServicesWereResetNotification, object: nil, queue: nil) { _ in
            setUpAudioSession()
        }
        
        setUpAudioSession()
#endif
    }
    
    var body: some Scene {
        WindowGroup {
            TonePlayerView(tonePlayerObservable: TonePlayerObservable(component: defaultComponent), plotObservable: PlotObservable(defaultComponent.type))
        }
#if os(macOS)
        .defaultSize(width: 600, height: 800)
        .commands {
            CommandGroup(replacing: .help) {
                HelpMenu()
            }
        }
#endif
    }
}
