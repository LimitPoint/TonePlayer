//
//  Draw.swift
//  TonePlayer
//
//  Created by Joseph Pagliaro on 2/7/23.
//
import Foundation
import SwiftUI

func DrawPathsInContext(context:CGContext, paths:[Path], width:Int, height:Int, lineWidth:Double, lineColor:Color, flipCGContext:Bool = true) {
    
    context.setLineWidth(lineWidth)
    context.setAllowsAntialiasing(true)
    
    if flipCGContext {
        context.translateBy(x: 0, y: Double(height));
        context.scaleBy(x: 1, y: -1)
    }
    
    context.setStrokeColor(lineColor.cgColor!)
    
    context.setLineCap(.round)
    
    for i in 0...paths.count-1 {
        let path = paths[i]
        
        context.beginPath()
        context.addPath(path.cgPath)
        context.drawPath(using: .stroke)
    }
}

#if os(macOS)

extension NSImage {
    var pngData: Data? {
        guard let tiffRepresentation = tiffRepresentation, let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else { return nil }
        return bitmapImage.representation(using: .png, properties: [:])
    }
    func pngWrite(to url: URL, options: Data.WritingOptions = .atomic) -> Bool {
        do {
            try pngData?.write(to: url, options: options)
            return true
        } catch {
            print(error)
            return false
        }
    }
}

func CreateNSImageForPaths(paths:[Path], width: Double, height: Double, lineWidth:Double, lineColor:Color) -> NSImage? {
    
    if  ((width == 0) || (height == 0)) {
        return nil
    }
    
    let size = NSSize(width: width, height:height)
    let img = NSImage(size: size)
    
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(size.width),
        pixelsHigh: Int(size.height),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: NSColorSpaceName.deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0) else {
        return nil
    }
    
    guard let nsGraphicsContext = NSGraphicsContext(bitmapImageRep: rep) else { return nil }
    
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = nsGraphicsContext
    
    let context = nsGraphicsContext.cgContext
    
    DrawPathsInContext(context: context, paths: paths, width: Int(width), height: Int(height), lineWidth: lineWidth, lineColor: lineColor, flipCGContext: true)
    
    NSGraphicsContext.restoreGraphicsState()
    
    img.addRepresentation(rep)
    
    return img
}
#else
extension UIImage {
    var pngData: Data? {
        return self.pngData()
    }
    func pngWrite(to url: URL, options: Data.WritingOptions = .atomic) -> Bool {
        do {
            try pngData?.write(to: url, options: options)
            return true
        } catch {
            print(error)
            return false
        }
    }
}

func CreateUIImageForPaths(paths:[Path], width: Double, height: Double, lineWidth:Double, lineColor:Color) -> UIImage? {
    
    UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 1.0)
    
    if let context = UIGraphicsGetCurrentContext() {
        
        DrawPathsInContext(context: context, paths: paths, width: Int(width), height: Int(height), lineWidth: lineWidth, lineColor: lineColor, flipCGContext: false)
        
        if let img = UIGraphicsGetImageFromCurrentImageContext() {
            UIGraphicsEndImageContext()
            return img
        }
    }
    
    return nil
}
#endif

func ImagePathsToPNG(paths:[Path], width: Double, height: Double, lineWidth: Double, lineColor: Color, url: URL) -> URL? {
    
    var destinationURL = url
    
    if destinationURL.pathExtension != "png" {
        destinationURL.deletePathExtension()
        destinationURL.appendPathExtension("png")
    }
    
    var outputURL:URL?
    
#if os(macOS)
    if let nsimage = CreateNSImageForPaths(paths: paths, width: width, height: height, lineWidth: lineWidth, lineColor: lineColor) {
        if nsimage.pngWrite(to: destinationURL) {
            outputURL = destinationURL
        }
    }
#else
    if let uiimage = CreateUIImageForPaths(paths: paths, width: width, height: height, lineWidth: lineWidth, lineColor: lineColor) {
        if uiimage.pngWrite(to: destinationURL) {
            outputURL = destinationURL
        }
    }    
#endif
    
    return outputURL
}

func GeneratePath(a:Double, b:Double, period:Double?, phaseOffset:Double, N:Int, frameSize:CGSize, inset:Double = 10.0, graph: (_ x:Double) -> Double) -> Path {
    
    guard frameSize.width > 0, frameSize.height > 0  else {
        return Path()
    }
    
    var plot_x:[Double] = []
    var plot_y:[Double] = []
    
    var minimum_y:Double = 0
    var maximum_y:Double = 0
    
    var minimum_x:Double = 0
    var maximum_x:Double = 0
    
    for i in 0...N {
        
        let x = a + (Double(i) * ((b - a) / Double(N)))
        
        var y:Double
        if let period = period {
            y = graph((x + phaseOffset).truncatingRemainder(dividingBy: period))
        }
        else {
            y = graph(x + phaseOffset)
        }
        
        if y < minimum_y {
            minimum_y = y
        }
        if y > maximum_y {
            maximum_y = y
        }
        
        if x < minimum_x {
            minimum_x = x
        }
        if x > maximum_x {
            maximum_x = x
        }
        
        plot_x.append(x)
        plot_y.append(y)
    }
    
    let frameRect = CGRect(x: 0, y: 0, width: frameSize.width, height: frameSize.height)
    let plotRect = frameRect.insetBy(dx: inset, dy: inset)
    
    let x0 = plotRect.origin.x
    let y0 = plotRect.origin.y
    let W = plotRect.width
    let H = plotRect.height
    
    func tx(_ x:Double) -> Double {
        if maximum_x == minimum_x {
            return x0 + W
        }
        return (x0 + W * ((x - minimum_x) / (maximum_x - minimum_x)))
    }
    
    func ty(_ y:Double) -> Double {
        if maximum_y == minimum_y {
            return frameSize.height - (y0 + H)
        }
        return frameSize.height - (y0 + H * ((y - minimum_y) / (maximum_y - minimum_y)))
    }
    
    plot_x = plot_x.map( { x in
        tx(x)
    })
    
    plot_y = plot_y.map( { y in
        ty(y)
    })
    
    let path = Path { path in
        path.move(to: CGPoint(x: plot_x[0], y: plot_y[0]))
        
        for i in 1...N {
            let x = plot_x[i]
            let y = plot_y[i]
            path.addLine(to: CGPoint(x: x, y: y))
        }
    }
    
    return path
}
