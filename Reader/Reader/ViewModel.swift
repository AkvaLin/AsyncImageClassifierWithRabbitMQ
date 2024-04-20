//
//  ViewModel.swift
//  Reader
//
//  Created by Никита Пивоваров on 19.04.2024.
//

import Foundation
import RMQClient

class ViewModel: ObservableObject {
    
    @Published var isConnected = false
    @Published var models = [Model]()
    @Published var requests = 0
    @Published var sent = 0
    
    private lazy var connection = RMQConnection(delegate: RMQConnectionDelegateLogger())
    private var channel: RMQChannel?
    private var receivingQueue: RMQQueue?
    private var timer = Timer()
    public var urls: [URL] = []
    
    public func onAppear() async {
        getUrls()
        await connection.start()
        channel = connection.createChannel()
        receivingQueue = channel?.queue("input")
        receivingQueue?.subscribe({ [weak self] message in
            guard
                let self = self,
                let body = message.body,
                let id = String(data: body, encoding: .utf8)
            else { return }
            
            DispatchQueue.main.async {
                self.requests += 1
            }
            
            if let urls = getNUrls() {
                let inputs = getInputs(urls: urls)
                let newInputs = Dictionary(uniqueKeysWithValues:
                                            inputs.map { key, value in (key, value.base64EncodedString()) })
                
                if let data = try? JSONSerialization.data(withJSONObject: newInputs) {
                    publish(data: data, key: id)
                    DispatchQueue.main.async {
                        self.sent += newInputs.count
                        self.models.append(Model(handler: id, images: Array(newInputs.keys)))
                    }
                }
            }
        })
    }
    
    public func setupTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { timer in
            DispatchQueue.main.async {
                self.isConnected = self.connection.isOpen()
            }
        }
    }
    
    private func getUrls() {
        guard let urls = Bundle.main.urls(forResourcesWithExtension: nil, subdirectory: "Images.bundle") else { return }
        self.urls = urls
    }
    
    private func getInputs(urls: [URL]) -> [String: Data] {
        
        var data = [String: Data]()
        
        for url in urls {
            if let imageData = try? Data(contentsOf: url) {
                data[url.lastPathComponent, default: Data()] = imageData
            }
        }
        
        return data
    }
    
    private func publish(data: Data, key: String) {
        if let queue = channel?.queue(key) {
            channel?.defaultExchange().publish(data, routingKey: queue.name)
        }
    }
    
    private func getNUrls(amount: Int = 5) -> [URL]? {
        if urls.count == 0 {
            return nil
        }
        
        if urls.count > amount {
            let urls = Array(self.urls[0..<amount])
            self.urls.removeFirst(amount)
            return urls
        } else {
            let urls = self.urls
            self.urls = []
            return urls
        }
    }
}
