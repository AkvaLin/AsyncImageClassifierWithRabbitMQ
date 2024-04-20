//
//  ContentView.swift
//  Reader
//
//  Created by Никита Пивоваров on 19.04.2024.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject private var viewModel = ViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("READER")
                    .font(.largeTitle)
                
                HStack {
                    Text("Sent: \(viewModel.sent)")
                    Text("Requests: \(viewModel.requests)")
                    Text("URLs amount: \(viewModel.urls.count)")
                }
                
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
                
                ForEach(viewModel.models) { model in
                    Text(model.handler)
                        .font(.subheadline)
                    Text(model.images.joined(separator: "\n"))
                    Divider()
                }
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
}

#Preview {
    ContentView()
}
