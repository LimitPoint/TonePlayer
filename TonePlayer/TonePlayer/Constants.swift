//
//  Constants.swift
//  TonePlayer
//
//  Created by Joseph Pagliaro on 2/21/23.
//

import SwiftUI

let frequencyDisplayPrecision = "%.3f"
let randomFrequencyRange = 50.0...10000.0
let frequencyIncrementValues:[Double] = [1000.0, 100.0, 10.0, 1.0, 0.1, 0.01, 0.001]

let kAudioExportName = "Tone Audio Export" 
let kTemporarySubdirectoryName = "Temporary"
let exportToneAudioDurations:[Double] = [1, 2, 3, 4, 5, 10, 30, 60, 300]

// Restrict UI
let kShowApplyToggle = true
let kShowExportImageButton = true
let kOpenExportedImage = true
let kShowRandomButton = true

let defaultComponent = Component(type: WaveFunctionType.sine, frequency: 440.0, amplitude: 0.1, offset: 0.0)
let defaultFavoriteFrequencies:[Double] = [40, 174, 285, 396, 417, 432, 440, 528, 639, 852, 963] // "healing frequencies"

let fouierSeriesTermCount = 3

let plotRangeUpper:Double = 2.0

let plotLineWidth:Double = 2.0
let plotLineColor = Color(red: 0.0, green: 0.45, blue: 0.90)

let softPink = Color(red: 249.0 / 255.0, green: 182.0 / 255.0, blue: 233.0 / 255.0, opacity:0.9)
