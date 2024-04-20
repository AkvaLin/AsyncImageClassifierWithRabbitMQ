//
//  ContentView.swift
//  Writer
//
//  Created by Никита Пивоваров on 19.04.2024.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject private var viewModel = ViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("WRITER")
                .font(.largeTitle)
            
            Text("Received: \(viewModel.received)")
            
            Group {
                if viewModel.isConnected {
                    Text("Connection established")
                        .foregroundStyle(.green)
                } else {
                    Text("Not connected")
                        .foregroundStyle(.red)
                }
            }
            .font(.body)
            
            Text("Saved rows: \(viewModel.counter)")
        }
        .padding()
        .onAppear {
            viewModel.setupTimer()
            Task {
                await viewModel.onAppear()
            }
        }
    }
}

#Preview {
    ContentView()
}
