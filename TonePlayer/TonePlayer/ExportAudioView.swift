//
//  ExportAudioView.swift
//  TonePlayer
//
//  Created by Joseph Pagliaro on 2/22/23.
//

import SwiftUI
import AVFoundation

struct ExportAlertInfo: Identifiable {
    
    enum AlertType {
        case exporterSuccess
        case exporterFailed
    }
    
    let id: AlertType
    let title: String
    let message: String
}

struct ExportAudioView: View {
    
    @ObservedObject var tonePlayerObservable:TonePlayerObservable 
    @ObservedObject var plotObservable:PlotObservable 
    
    @State var duration:Double = 3
    @State var toneRampType:ToneRampType = .none
    
    @State var exportAlertInfo:ExportAlertInfo?
    
    var body: some View {
        VStack {
            
            HStack {
                Button(action: {
                    if tonePlayerObservable.isPlaying {
                        tonePlayerObservable.stopPlaying {
                            plotObservable.stopPlayTimer()
                        }
                    }
                    tonePlayerObservable.exportToneAudio(duration, toneRampType)
                }, label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(.green, .gray)
                    }
                })
                
                Button(action: {
                    tonePlayerObservable.stopAudioURL()
                                        
                    tonePlayerObservable.generateToneAudio(duration, toneRampType) { url in
                        if let url = url {
                            tonePlayerObservable.playAudioURL(url)
                        }
                        else {
                            print("Error - Tone not exported.")
                        }
                    }
                }, label: {
                    HStack {
                        Image(systemName: "wave.3.right.circle")
                            .foregroundStyle(.green, .gray)
                    }
                })
            }
            .buttonStyle(BorderlessButtonStyle())
            .font(.system(size: 32, weight: .light))
            .frame(width: 44, height: 44)
            .imageScale(.large)
                        
            Picker("", selection: $duration) {
                ForEach(exportToneAudioDurations, id: \.self) { value in
                    Text("\(String(format: "%.0f", value))")
                }
            }
            .frame(width: 100)
            
            Picker("", selection: $toneRampType) {
                ForEach(ToneRampType.allCases) { type in
                    Text(type.rawValue.capitalized)
                }
            }
            .frame(width: 130)
        }
        .fileExporter(isPresented: $tonePlayerObservable.showAudioExporter, document: tonePlayerObservable.audioDocument, contentType: UTType.wav, defaultFilename: tonePlayerObservable.audioDocument?.filename) { result in
            if case .success = result {
                do {
                    let exportedURL: URL = try result.get()
                    exportAlertInfo = ExportAlertInfo(id: .exporterSuccess, title: "Audio Saved", message: exportedURL.lastPathComponent)
                }
                catch {
                    exportAlertInfo = ExportAlertInfo(id: .exporterFailed, title: "Audio Not Saved", message: (tonePlayerObservable.audioDocument?.filename ?? ""))
                }
            } else {
                exportAlertInfo = ExportAlertInfo(id: .exporterFailed, title: "Audio Not Saved", message: (tonePlayerObservable.audioDocument?.filename ?? ""))
            }
        }
        .alert(item: $exportAlertInfo, content: { alertInfo in
            return Alert(title: Text(alertInfo.title), message: Text(alertInfo.message))
        })
    }
}

struct ExportAudioView_Previews: PreviewProvider {
    static var previews: some View {
        ExportAudioView(tonePlayerObservable: TonePlayerObservable(component: defaultComponent), plotObservable: PlotObservable(defaultComponent.type))
    }
}
