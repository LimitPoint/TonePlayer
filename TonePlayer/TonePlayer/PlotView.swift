//
//  PlotView.swift
//  TonePlayer
//
//  Created by Joseph Pagliaro on 2/12/23.
//

import SwiftUI

struct CurrentSizeReader: ViewModifier {
    @Binding var currentSize: CGSize
    @State var lastSize:CGSize = .zero // prevents too much view updating if value is stored in a published property of a View's observable object. 
    
    var geometryReader: some View {
        GeometryReader { proxy in
            Color.clear
                .execute {
                    if lastSize != proxy.size {
                        currentSize = proxy.size
                        lastSize = currentSize
                    }
                }
        }
    }
    
    func body(content: Content) -> some View {
        content
            .background(geometryReader)
    }
}

struct CurrentFrameReader: ViewModifier {
    @Binding var currentFrame: CGRect
    
    var coordinateSpace:CoordinateSpace
    
    var geometryReader: some View {
        GeometryReader { proxy in
            Color.clear
                .execute {
                    currentFrame = proxy.frame(in: coordinateSpace)
                    print("currentFrame = \(currentFrame)")
                }
        }
    }
    
    func body(content: Content) -> some View {
        content
            .background(geometryReader)
    }
}

extension View {
    func execute(_ closure: @escaping () -> Void) -> Self {
        DispatchQueue.main.async {
            closure()
        }
        return self
    }
    
    func currentSizeReader(currentSize: Binding<CGSize>) -> some View {
        modifier(CurrentSizeReader(currentSize: currentSize))
    }
    
    func currentFrameReader(currentFrame: Binding<CGRect>, coordinateSpace:CoordinateSpace) -> some View {
        modifier(CurrentFrameReader(currentFrame: currentFrame, coordinateSpace: coordinateSpace))
    }
}

struct PlotView: View {
    
    @StateObject var plotObservable: PlotObservable
    
    var lineColor:Color
    var lineWidth:Double
    
    let coordinateSpace = CoordinateSpace.named("ZStack")
    
    var body: some View {
        ZStack {
            ForEach(0 ..< plotObservable.paths.count, id:\.self) { i in
                plotObservable.paths[i]
                    .stroke(lineColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                    .scaleEffect(CGSize(width: 0.9, height: 0.9))
            }
        }
        .coordinateSpace(name: "ZStack")
        .currentSizeReader(currentSize: $plotObservable.frameSize)
        .alert("Export Image", isPresented: $plotObservable.showExportAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            if let url = plotObservable.outputURL {
#if os(macOS)
                Text("\(url.lastPathComponent) saved to documents.")
#else
                Text("\(url.lastPathComponent) saved to documents.\n\nSelect your device in the Finder, go to Files and open TonePlayer.")
#endif
            }
            else {
                Text("Image export failed.")
            }
        }
    }
}
