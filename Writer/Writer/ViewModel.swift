//
//  ViewModel.swift
//  Writer
//
//  Created by Никита Пивоваров on 19.04.2024.
//

import Foundation
import RMQClient

class ViewModel: ObservableObject {
    
    @Published var isConnected = false
    @Published var counter = 0
    @Published var received = 0
    
    private lazy var connection = RMQConnection(delegate: RMQConnectionDelegateLogger())
    private var channel: RMQChannel?
    private var receivingQueue: RMQQueue?
    private var timer = Timer()
    
    public func onAppear() async {
        await connection.start()
        channel = connection.createChannel()
        receivingQueue = channel?.queue("output")
        receivingQueue?.subscribe({ [weak self] message in
            guard
                let self = self,
                let body = message.body,
                let data = try? JSONSerialization.jsonObject(with: body) as? [String: String]
            else { return }
            
            DispatchQueue.main.async {
                self.received += 5
            }
            
            write(result: data)
        })
    }
    
    public func setupTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { timer in
            DispatchQueue.main.async {
                self.isConnected = self.connection.isOpen()
            }
        }
    }
    
    private func write(result: [String: String]) {
        
        let filename = self.getDocumentsDirectory().appendingPathComponent("RabbitMQOutput.json")
        var resultDict = result
        if
            let oldData = try? Data(contentsOf: filename),
            var oldJSON = try? JSONSerialization.jsonObject(with: oldData) as? [String: String]
        {
            result.forEach { (key, value) in oldJSON[key] = value }
            resultDict = oldJSON
        }
        
        do {
            try JSONSerialization.data(withJSONObject: resultDict, options: .prettyPrinted).write(to: filename, options: .atomic)
            
            DispatchQueue.main.async {
                self.counter = resultDict.count
            }
        } catch { }
        
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}
