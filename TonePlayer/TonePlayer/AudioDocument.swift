//
//  AudioDocument.swift
//  TonePlayer
//
//  Created by Joseph Pagliaro on 2/22/23.
//

import SwiftUI
import AVFoundation

/*
 AudioDocument is used by fileExporter to save audio to a location user can choose.
 */
class AudioDocument : FileDocument {
    
    var filename:String?
    var url:URL?
    
    static var readableContentTypes: [UTType] { [UTType.audio, UTType.mpeg4Audio, UTType.wav] }
    
    init(url:URL) {
        self.url = url
        filename = url.deletingPathExtension().lastPathComponent
    }
    
    required init(configuration: ReadConfiguration) throws {
        
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let url = self.url
        else {
            throw CocoaError(.fileWriteUnknown)
        }
        let fileWrapper = try FileWrapper(url: url)
        return fileWrapper
    }
}
