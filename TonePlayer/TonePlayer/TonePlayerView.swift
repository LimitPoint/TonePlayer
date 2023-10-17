//
//  TonePlayerView.swift
//  TonePlayer
//
//  Created by Joseph Pagliaro on 2/3/23.
//
import SwiftUI

#if os(macOS)
extension NSTextField {
    open override var focusRingType: NSFocusRingType {
        get { .none }
        set { }
    }
}
#endif

struct SignalPicker: View {
    
    @ObservedObject var tonePlayerObservable:TonePlayerObservable 
    @ObservedObject var plotObservable:PlotObservable 
    
    var body: some View {
        HStack {
            
            Picker("", selection: $tonePlayerObservable.component.type) {
                ForEach(WaveFunctionType.allCases) { type in
                    Text(type.rawValue)
                }
            }
            .frame(width:200)
        }
        .onChange(of: tonePlayerObservable.component.type) { newComponentType in
            plotObservable.waveform = unitFunction(newComponentType)
        }
    }
}

struct FrequencyTextFieldView: View {
    
    @ObservedObject var tonePlayerObservable:TonePlayerObservable 
    
    @Binding var frequencyString:String
    @Binding var sliderValue:Double
    
    @FocusState var isTextFieldFocused: Bool
    
    func textInputDone() {
        if let v = Double(frequencyString), tonePlayerObservable.frequencyRange().contains(v) {
            sliderValue = pianoKeyForFrequency(v)
            tonePlayerObservable.component.frequency = frequencyForPianoKey(sliderValue)
        }
        else {
            frequencyString = String(format: frequencyDisplayPrecision, tonePlayerObservable.component.frequency)
        }
    }
    
    var body: some View {
        HStack {
            TextField("", text: $frequencyString, onEditingChanged: { editing in // tab key
                if editing == false {
                    textInputDone()
                }
            })
            .multilineTextAlignment(.center)
            .frame(width:300)
            .focused($isTextFieldFocused)
            .onChange(of: isTextFieldFocused) { newIsTextFieldFocused in  // return, but no tab
                if newIsTextFieldFocused == false {
                    textInputDone()
                }
            }
            .onSubmit { // return
                textInputDone()
            }
        }
#if os(iOS)
        .keyboardType(.decimalPad)
#endif
        
    }
}

struct FrequencyIncrementPickerView: View {
    
    @ObservedObject var tonePlayerObservable:TonePlayerObservable 
    
    var body: some View {
        VStack {
            Picker("", selection: $tonePlayerObservable.frequencyIncrementValue) {
                ForEach(frequencyIncrementValues, id: \.self) { value in
                    Text(String(value))
                }
            }
            .frame(width: 100)
        }
    }
}

struct AdjustFrequencyView: View {
    
    @ObservedObject var tonePlayerObservable:TonePlayerObservable 
    
    var body: some View {
        HStack {
            
            Button(action: {
                tonePlayerObservable.halveFrequency()
            }, label: {
                HStack {
                    Text("x ½")
                        .foregroundStyle(.red, .gray)
                }
            })
            .padding()
            .disabled(tonePlayerObservable.frequencyCanBeHalved() == false)
            .buttonStyle(BorderlessButtonStyle())
            
            Button(action: {
                tonePlayerObservable.decrementFrequency()
            }, label: {
                Image(systemName: "minus.square")
                    .foregroundStyle(.red, .gray)
            })
            .buttonStyle(BorderlessButtonStyle())
            .font(.system(size: 32, weight: .light))
            .frame(width: 44, height: 44)
            .disabled(tonePlayerObservable.canDecrementFrequency() == false)
            
            FrequencyIncrementPickerView(tonePlayerObservable: tonePlayerObservable)
            
            Button(action: {
                tonePlayerObservable.incrementFrequency()
            }, label: {
                Image(systemName: "plus.square")
                    .foregroundStyle(.green, .gray)
            })
            .buttonStyle(BorderlessButtonStyle())
            .font(.system(size: 32, weight: .light))
            .frame(width: 44, height: 44)
            .disabled(tonePlayerObservable.canIncrementFrequency() == false)
            
            Button(action: {
                tonePlayerObservable.doubleFrequency()
            }, label: {
                HStack {
                    Text("x 2")
                        .foregroundStyle(.green, .gray)
                }
            })
            .padding()
            .disabled(tonePlayerObservable.frequencyCanBeDoubled() == false)
            .buttonStyle(BorderlessButtonStyle())
        }
    }
}

struct FrequencySliderView: View {
    
    @ObservedObject var tonePlayerObservable:TonePlayerObservable 
    
    @Binding var textString:String
    @Binding var sliderValue:Double
    
    @State private var isEditing = false
    
    var body: some View {
        Slider(value: $sliderValue,
               in: tonePlayerObservable.frequencySliderRange(),
               onEditingChanged: { editing in
            isEditing = editing
        }
        )
        .onChange(of: sliderValue) { newSliderValue in
            if isEditing { // manual changes
                tonePlayerObservable.component.frequency = frequencyForPianoKey(sliderValue)
            }
        }
        .onChange(of: tonePlayerObservable.component.frequency) { frequency in 
            if isEditing == false { 
                sliderValue = pianoKeyForFrequency(frequency)
            }
            textString = String(format: frequencyDisplayPrecision, tonePlayerObservable.component.frequency)
        }
    }
}

struct FrequencyNoteView: View {
    
    @ObservedObject var tonePlayerObservable:TonePlayerObservable 
        
    @State var frequencyNoteString:String = ""
    
    var body: some View {
        HStack {
            Image(systemName: "music.note")
            Text(frequencyNoteString)
                .frame(width:100)
                .textSelection(.enabled)
            
            Button(action: {
                tonePlayerObservable.isShowingOctaveView = true
            }, label: {
                HStack {
                    Text("Select Note...")
                }
            })
            .buttonStyle(BorderlessButtonStyle())
        }
        .onChange(of: tonePlayerObservable.component.frequency) { frequency in 
            frequencyNoteString = pianoNoteForFrequency(frequency)
        }
        .onAppear {
            frequencyNoteString = pianoNoteForFrequency(tonePlayerObservable.component.frequency)
        }
    }
}

struct FrequencyView: View {
    
    @ObservedObject var tonePlayerObservable:TonePlayerObservable 
    
    @State var sliderValue:Double = 0
    @State var frequencyString:String = ""
    
    var body: some View {
        
        VStack {
            VStack {
                VStack {
                    Text("Frequency (Hz)")
                        .font(.headline.smallCaps())
                    FrequencyTextFieldView(tonePlayerObservable: tonePlayerObservable, frequencyString: $frequencyString, sliderValue: $sliderValue)
                    
                    FrequencyNoteView(tonePlayerObservable: tonePlayerObservable)
                        .padding()
                    
                    AdjustFrequencyView(tonePlayerObservable: tonePlayerObservable)
                }
                
                if kShowApplyToggle {
                    Toggle(isOn: $tonePlayerObservable.applyPhaseOffset) {
                        Text("Apply Phase Offset")
                    }
                    .padding()
                }
            }
            
            FrequencySliderView(tonePlayerObservable: tonePlayerObservable, textString: $frequencyString, sliderValue: $sliderValue)
        }
        .onAppear {
            sliderValue = pianoKeyForFrequency(tonePlayerObservable.component.frequency)
            frequencyString = String(format: frequencyDisplayPrecision, tonePlayerObservable.component.frequency)
        }
    }
}

struct VolumeView: View {
    
    @ObservedObject var tonePlayerObservable:TonePlayerObservable 
    
    var body: some View {
        
        VStack {
            VStack {
                VStack {
                    Text("Amplitude")
                        .font(.headline.smallCaps())
                    Text("\(String(format: frequencyDisplayPrecision, tonePlayerObservable.component.amplitude))")
                        .monospacedDigit()
                }
                
                if kShowApplyToggle {
                    Toggle(isOn: $tonePlayerObservable.applyAmplitudeInterpolation) {
                        Text("Apply Amplitude Interpolation")
                    }
                    .padding()
                }
            }
            
            Slider(value: $tonePlayerObservable.component.amplitude,
                   in: 0.0...1.0
            )
        }
    }
}

struct PlayButton: View {
    
    @ObservedObject var tonePlayerObservable:TonePlayerObservable 
    @ObservedObject var plotObservable:PlotObservable 
    
    var body: some View {
        Group {
            if tonePlayerObservable.isPlaying {
                Button {
                    tonePlayerObservable.stopPlaying {
                        plotObservable.stopPlayTimer()
                    }
                } label: {
                    Image(systemName: "stop.circle")
                        .foregroundStyle(.red, .gray)
                }
            }
            else {
                Button {
                    tonePlayerObservable.startPlaying { success in
                        if success {
                            plotObservable.startPlayTimer()
                        }
                    }
                } label: {
                    Image(systemName: "play.circle")
                        .foregroundStyle(.green, .gray)
                        
                }
            }
        }
        .buttonStyle(BorderlessButtonStyle())
        .font(.system(size: 32, weight: .light))
        .frame(width: 44, height: 44)
        .imageScale(.large)
        
    }
}

struct RandomButton: View {
    
    @ObservedObject var tonePlayerObservable:TonePlayerObservable 
    
    var body: some View {
        if tonePlayerObservable.randomizeTimer != nil {
            Button {
                tonePlayerObservable.stopRandomizeTimer()
            } label: {
                Text("Stop Random")
                    .foregroundColor(.red)
            }
        }
        else {
            Button {
                tonePlayerObservable.startRandomizeTimer()
            } label: {
                Text("Start Random")
            }
        }
    }
}

struct ExportImageView: View {
    
    @ObservedObject var tonePlayerObservable:TonePlayerObservable 
    @ObservedObject var plotObservable:PlotObservable 
    
    var body: some View {
        HStack {
            
            Button(action: {
                plotObservable.exportPathsImage()
            }, label: {
                HStack {
                    Text("Export")
                    Image(systemName: "square.and.arrow.up")
                }
            })
            .buttonStyle(BorderlessButtonStyle())
#if os(macOS)                
            if let documentsURL = FileManager.documentsURL(filename: nil, subdirectoryName: nil) {
                Button(action: {
                    NSWorkspace.shared.open(documentsURL)
                }, label: {
                    HStack {
                        Text("Documents Folder")
                        Image(systemName: "folder")
                    }
                })
                .buttonStyle(BorderlessButtonStyle())
            }
#endif
        }
        .padding()
    }
}

struct ControlView: View {
    
    @ObservedObject var tonePlayerObservable:TonePlayerObservable 
    @ObservedObject var plotObservable:PlotObservable 
    
    var body: some View {
        
        ScrollView {
            VStack {
                PlotView(plotObservable: plotObservable, lineColor: plotLineColor, lineWidth: plotLineWidth)
                    .frame(minHeight: 150)
                
                if kShowExportImageButton {
                    ExportImageView(tonePlayerObservable: tonePlayerObservable, plotObservable: plotObservable)
                }
                
                SignalPicker(tonePlayerObservable: tonePlayerObservable, plotObservable: plotObservable)
                
                FrequencyView(tonePlayerObservable: tonePlayerObservable)
                
                VolumeView(tonePlayerObservable: tonePlayerObservable)
                
                VStack {
                    PlayButton(tonePlayerObservable: tonePlayerObservable, plotObservable: plotObservable)
                        .padding()
                    
                    ExportAudioView(tonePlayerObservable: tonePlayerObservable, plotObservable: plotObservable)
                }
                
                if kShowRandomButton {
                    RandomButton(tonePlayerObservable: tonePlayerObservable)
                        .padding()
                }
                
                FavoriteFrequenciesView(tonePlayerObservable: tonePlayerObservable, plotObservable: plotObservable)
                    .frame(minHeight: 900)
                
            }
        }
    }
}

struct TonePlayerView: View {
    
    @StateObject var tonePlayerObservable:TonePlayerObservable 
    @StateObject var plotObservable:PlotObservable 
    
    @State private var showToneWarningAlert = true
        
    var body: some View {
        VStack {
            if tonePlayerObservable.isShowingOctaveView {
                OctaveView(tonePlayerObservable: tonePlayerObservable, plotObservable: plotObservable)
            }
            else {
                ControlView(tonePlayerObservable: tonePlayerObservable, plotObservable: plotObservable)
            }
        }
#if os(macOS) 
        .onChange(of: tonePlayerObservable.audioEngineConfigurationChangeCount) { _ in
            DispatchQueue.main.async {
                if tonePlayerObservable.isPlaying {
                    tonePlayerObservable.stopPlaying { 
                        plotObservable.stopPlayTimer()
                        tonePlayerObservable.startPlaying { success in
                            if success {
                                plotObservable.startPlayTimer()
                            }
                        }
                    }
                }
            }
        }
#endif
#if os(iOS) 
        .onChange(of: tonePlayerObservable.shouldStopPlaying) { shouldStopPlaying in
            
            if shouldStopPlaying == true {
                DispatchQueue.main.async {
                    tonePlayerObservable.shouldStopPlaying = false
                    tonePlayerObservable.stopPlaying { 
                        plotObservable.stopPlayTimer()
                    }
                }
            }
        }
        .onChange(of: tonePlayerObservable.shouldStartPlaying) { shouldStartPlaying in
            
            if shouldStartPlaying == true {
                DispatchQueue.main.async {
                    tonePlayerObservable.shouldStartPlaying = false
                    tonePlayerObservable.startPlaying { success in
                        if success {
                            plotObservable.startPlayTimer()
                        }
                    }
                }
            }
        }  
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Button {
                    let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
                    let window = windowScene?.windows.first
                    window?.endEditing(true)
                } label : {
                    Text("Dismiss Keyboard")
                }
            }
        }
#endif
        .onAppear {
            plotObservable.waveform = unitFunction(tonePlayerObservable.component.type)
        }
        .alert("High Volume Alert!", isPresented: $showToneWarningAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Very high and very low frequencies may be difficult to hear.\n\nIf the volume is set very high to compensate then it may be too high for other frequencies, and that can damage your hearing.\n\nSet the volume low initially and increase it with care.")
                .multilineTextAlignment(.trailing)
        }
        .overlay(Group {
            if tonePlayerObservable.isExporting {          
                ProgressView("Exporting...")
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 16).fill(softPink))
            }
        })
        .padding()
    }
}

struct TonePlayerView_Previews: PreviewProvider {
    static var previews: some View {
        TonePlayerView(tonePlayerObservable: TonePlayerObservable(component: defaultComponent), plotObservable: PlotObservable(defaultComponent.type))
    }
}

struct ExportImageView_Previews: PreviewProvider {
    static var previews: some View {
        ExportImageView(tonePlayerObservable: TonePlayerObservable(component: defaultComponent), plotObservable: PlotObservable(defaultComponent.type))
    }
}

struct PlayButton_Previews: PreviewProvider {
    static var previews: some View {
        PlayButton(tonePlayerObservable: TonePlayerObservable(component: defaultComponent), plotObservable: PlotObservable(defaultComponent.type))
    }
}

struct AdjustFrequencyView_Previews: PreviewProvider {
    static var previews: some View {
        AdjustFrequencyView(tonePlayerObservable: TonePlayerObservable(component: defaultComponent))
    }
}
