//
//  PlotObservable.swift
//  TonePlayer
//
//  Created by Joseph Pagliaro on 2/12/23.
//

import SwiftUI
import Combine

class PlotObservable: ObservableObject  {
    
    @Published var paths:[Path] = []
    
    @Published var frameSize:CGSize = CGSize(width: 320, height: 320)
    @Published var waveform: (Double)->Double
    
    @Published var showExportAlert = false
    var outputURL:URL? = nil
    
    var rangeUpper:Double
    
    var phaseOffset:Double = 0
    var playTimer:Timer?
        
    var cancelBag = Set<AnyCancellable>()
    
    func updatePath() {
        
        paths.removeAll()
        
        let path = GeneratePath(a: 0, b: rangeUpper, period: 1, phaseOffset: phaseOffset, N: 1000, frameSize: frameSize, graph: self.waveform)
        
        paths.append(path)
    }
    
    init(_ type: WaveFunctionType, rangeUpper:Double = plotRangeUpper) {
        
        self.waveform = unitFunction(type)
        self.rangeUpper = rangeUpper
        
        self.updatePath()
        
        $frameSize.sink { size in
            DispatchQueue.main.async { [weak self] in
                self?.updatePath() 
            }
            
        }
        .store(in: &cancelBag)
        
        $waveform.sink { size in
            DispatchQueue.main.async { [weak self] in
                self?.phaseOffset = 0
                self?.updatePath() 
            }
            
        }
        .store(in: &cancelBag)
        
    }
    
    func startPlayTimer() { 
        let interval = 1.0 / 30.0
        let schedule = { [weak self] in
            self?.playTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
                self?.phaseOffset += interval / 2.0
                self?.updatePath()
            }
        }
        
        if self.playTimer == nil {
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
    
    func stopPlayTimer() {
        playTimer?.invalidate()
        playTimer = nil
        phaseOffset = 0
        updatePath() 
    }
    
    func exportPathsImage()  {
        
        DispatchQueue.global().async { [weak self] in
            
            guard let self = self else {
                return 
            }
            
            let url = FileManager.documentsURL(filename: "Paths", subdirectoryName: nil)!
            
            self.outputURL = ImagePathsToPNG(paths: self.paths, width: self.frameSize.width, height: self.frameSize.height, lineWidth: plotLineWidth, lineColor: plotLineColor, url: url)
            
            if let outputURL = self.outputURL {
                print(outputURL)
#if os(macOS)   
                if kOpenExportedImage {
                    NSWorkspace.shared.open(outputURL)
                }
#endif   
            }
            
            DispatchQueue.main.async {
                self.showExportAlert = true
            }
        }
    }
}
