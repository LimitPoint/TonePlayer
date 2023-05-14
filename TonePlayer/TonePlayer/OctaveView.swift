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
    
    var body: some View {
        VStack {
            HStack {
                
                Button("Done", action: { 
                    tonePlayerObservable.isShowingOctaveView = false
                }).padding()
                
                PlayButton(tonePlayerObservable: tonePlayerObservable, plotObservable: plotObservable)
                
            }
        
            ScrollView {
                LazyVGrid(columns: Array(repeating: .init(.flexible()), count: tonePlayerObservable.octaveViewColumnsCount), spacing: 10) {
                    ForEach(tonePlayerObservable.octavesArray.indices, id: \.self) { sectionIndex in
                        Section(header: Text("Octave \(sectionIndex)")) {
                            ForEach(tonePlayerObservable.octavesArray[sectionIndex], id: \.note) { tuple in
                                Button(action: {
                                    tonePlayerObservable.component.frequency = tuple.frequency
                                }) {
                                    Text(tuple.note)
                                }
                                .overlay(tonePlayerObservable.component.frequency == tuple.frequency ? RoundedRectangle(cornerRadius: 6) .stroke(.red, lineWidth: 1) : nil)
                            }
                        }
                    }
                }
            }
        }
        .background(Color.white)
    }
}

struct OctaveView_Previews: PreviewProvider {
    static var previews: some View {
        OctaveView(tonePlayerObservable: TonePlayerObservable(component: defaultComponent), plotObservable: PlotObservable(defaultComponent.type))
    }
}


