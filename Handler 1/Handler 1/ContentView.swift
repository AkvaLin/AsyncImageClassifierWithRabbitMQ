//
//  ContentView.swift
//  Handler 1
//
//  Created by Никита Пивоваров on 19.04.2024.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject private var viewModel = ViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("HANDLER 1")
                    .font(.largeTitle)
                
                HStack {
                    Text("Received: \(viewModel.received)")
                    Text("Sent: \(viewModel.sent)")
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
                
                ForEach(viewModel.vegetables) { vegetable in
                    Text(vegetable.name)
                    Text(vegetable.prediction)
                    Image(nsImage: vegetable.image)
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
