//
//  ContentView.swift
//  FernbedienungDLNA
//
//  Created by Jannik Scheider on 15.05.24.
//
import SwiftUI

struct ContentView: View {
    @ObservedObject var tvManager = SmartTVManager()

    var body: some View {
        VStack {
            Text("Current Volume: \(tvManager.currentVolume)")
                .padding()
            HStack {
                Button("Increase Volume") {
                    tvManager.adjustVolume(change: 10)
                }
                Button("Decrease Volume") {
                    tvManager.adjustVolume(change: -10)
                }
            }
        }
        .onAppear {
            tvManager.startListening()
        }
    }
}

#Preview {
    ContentView()
}
