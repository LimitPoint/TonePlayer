//
//  FavoriteFrequenciesView.swift
//  TonePlayer
//
//  Created by Joseph Pagliaro on 2/22/23.
//

import SwiftUI

struct FavoriteFrequenciesView: View {
    
    @ObservedObject var tonePlayerObservable:TonePlayerObservable 
    @ObservedObject var plotObservable:PlotObservable 
    
    @State private var showDeleteConfirmationAlert = false
    @State private var showDeleteAllConfirmationAlert = false
    @State private var indexToRemove:Int = 0
    
    var body: some View {
        VStack{
            
            HStack{
            
                Button(action: {
                    tonePlayerObservable.addFrequencyToFavorites()
                }) {
                    Text("Add Favorite")
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                }
                .buttonStyle(BorderlessButtonStyle())
                
                Spacer()
                
                Button(action: {
                    tonePlayerObservable.addDefaultFrequenciesToFavorites()
                }) {
                    Text("Add Healing")
                    Image(systemName: "bandage.fill")
                }
                .buttonStyle(BorderlessButtonStyle())
                
                Spacer()
                
                Button(action: {
                    if tonePlayerObservable.isPlaying {
                        plotObservable.stopPlayTimer()
                    }
                    showDeleteAllConfirmationAlert = true
                }) {
                    Text("Delete All")
                    Image(systemName: "trash.fill")

                }
                .buttonStyle(BorderlessButtonStyle())
                
                
            }
            .padding()
            .alert(isPresented: $showDeleteAllConfirmationAlert) {
                Alert(title: Text("Confirm"), message: Text("Are you sure you want to delete all favorites frequencies?\n\nThis cannot be undone."), primaryButton: .destructive(Text("Yes")) {
                    tonePlayerObservable.deleteAllFrequencyFavorites()
                    if tonePlayerObservable.isPlaying {
                        plotObservable.startPlayTimer()
                    }
                }, secondaryButton: .cancel() {
                    if tonePlayerObservable.isPlaying {
                        plotObservable.startPlayTimer()
                    }
                })

            }
            
            List {
                ForEach(tonePlayerObservable.favoriteFrequencies, id: \.self) { frequency in
                    HStack {
                        
                        Text("\(String(format: "%.3f", frequency))")
                        
                        Spacer()
                        
                        Button(action: {
                            tonePlayerObservable.setFrequencyToFavoriteFrequency(frequency)
                        }) {
                            Text("Set")
                            Image(systemName: "play.circle")
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        
                        Spacer()
                        
                        Button(action: {
                            if let index = tonePlayerObservable.favoriteFrequencies.firstIndex(of: frequency) {
                                indexToRemove = index
                                showDeleteConfirmationAlert = true
                            }
                        }) {
                            Text("Delete")
                            Image(systemName: "trash")
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    .padding(8)
                }
            }
            .alert(isPresented: $showDeleteConfirmationAlert) {
                Alert(title: Text("Confirm"), message: Text("Are you sure you want to delete frequency \(String(format: "%.3f", tonePlayerObservable.favoriteFrequencies[indexToRemove]))?\n\nThis cannot be undone."), primaryButton: .destructive(Text("Yes")) {
                    tonePlayerObservable.removeFavoriteFrequency(at: indexToRemove)
                }, secondaryButton: .cancel())
            }
        }
    }
}

struct FavoriteFrequenciesView_Previews: PreviewProvider {
    static var previews: some View {
        FavoriteFrequenciesView(tonePlayerObservable: TonePlayerObservable(component: defaultComponent), plotObservable: PlotObservable(defaultComponent.type))
    }
}
