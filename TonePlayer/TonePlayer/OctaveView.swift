//
//  OctaveView.swift
//  TonePlayer
//
//  Created by Joseph Pagliaro on 2/20/23.
//

import SwiftUI

struct OctaveView: View {
    
    @ObservedObject var tonePlayerObservable:TonePlayerObservable 
    @ObservedObject var plotObservable:PlotObservable 
    
    @State var showFrequencies = true
    
    var body: some View {
        VStack {
            HStack {
                
                Button("Done", action: { 
                    tonePlayerObservable.isShowingOctaveView = false
                })
                .padding()
                
                PlayButton(tonePlayerObservable: tonePlayerObservable, plotObservable: plotObservable)
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Toggle(isOn: $showFrequencies) {
                        
                    }
            
                    Text("Show Frequencies")
                }
                .padding()
            }
        
            ScrollView {
                LazyVGrid(columns: Array(repeating: .init(.flexible()), count: tonePlayerObservable.octaveViewColumnsCount), spacing: 10) {
                    ForEach(tonePlayerObservable.octavesArray.indices, id: \.self) { sectionIndex in
                        Section(header: Text("Octave \(sectionIndex)")) {
                            ForEach(tonePlayerObservable.octavesArray[sectionIndex], id: \.note) { tuple in
                                Button(action: {
                                    tonePlayerObservable.component.frequency = tuple.frequency
                                }) {
                                    if showFrequencies {
                                        VStack {
                                            Text(tuple.note)
                                            Text(String(format: "%.2f", tuple.frequency))
                                                .font(.caption)
                                        }
                                    }
                                    else {
                                        Text(tuple.note)
                                    }
                                }
                                #if os(macOS)
                                .foregroundColor(.blue) 
                                .buttonStyle(PlainButtonStyle())
                                #endif
                                .overlay(tonePlayerObservable.component.frequency == tuple.frequency ? RoundedRectangle(cornerRadius: 6) .stroke(.red, lineWidth: 1) : nil)
                            }
                        }
                    }
                }
            }
#if os(macOS) // may alleviate bottom cutoff in iOS by not animating?
            .animation(.easeInOut(duration: 0.5), value: showFrequencies)
#endif
        }
    }
}

struct OctaveView_Previews: PreviewProvider {
    static var previews: some View {
        OctaveView(tonePlayerObservable: TonePlayerObservable(component: defaultComponent), plotObservable: PlotObservable(defaultComponent.type))
    }
}


