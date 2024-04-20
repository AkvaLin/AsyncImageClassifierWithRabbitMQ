//
//  ViewModel.swift
//  Handler 3
//
//  Created by Никита Пивоваров on 19.04.2024.
//

import Foundation
import RMQClient

class ViewModel: ObservableObject {
    
    @Published var isConnected = false
    @Published var vegetables = [Model]()
    @Published var received = 0
    @Published var sent = 0
    
    private lazy var connection = RMQConnection(delegate: RMQConnectionDelegateLogger())
    private var queue: RMQQueue?
    private let queueName = "Handler3"
    private var timer = Timer()
    private let imageClassifier = ImageClassifier()
    
    public func onAppear() async {
        await connection.start()
        let ch = connection.createChannel()
        queue = ch.queue(queueName)
        queue?.subscribe({ [weak self] message in
            guard
                let self = self,
                let body = message.body,
                let json = try? JSONSerialization.jsonObject(with: body) as? [String: String]
            else { return }
            
            DispatchQueue.main.async {
                self.received += 5
            }
            
            let data = Dictionary(uniqueKeysWithValues:
                                    json.map { key, value in (key, Data(base64Encoded: value) ?? Data()) })
            
            let images = Dictionary(uniqueKeysWithValues:
                                        data.map { key, value in (key, NSImage(data: value) ?? NSImage(size: NSSize())) })
            
            classification(images: Dictionary(uniqueKeysWithValues:
                                                images.map { key, value in (key, self.convertImage(image: value)) })) { result in
                var newVegetables = [Model]()
                
                result.forEach { (key: String, value: String) in
                    newVegetables.append(Model(image: images[key, default: NSImage(size: NSSize())],
                                                 name: key,
                                                 prediction: value))
                }
                
                DispatchQueue.main.async {
                    self.vegetables = newVegetables
                }
                
                if let outputData = try? JSONSerialization.data(withJSONObject: result) {
                    let outputQueue = ch.queue("output")
                    ch.defaultExchange().publish(outputData, routingKey: outputQueue.name)
                    DispatchQueue.main.async {
                        self.sent += 5
                    }
                }
                
                let inputQueue = ch.queue("input")
                ch.defaultExchange().publish(self.queueName.data(using: .utf8)!, routingKey: inputQueue.name)
            }
        })
        
        let inputQueue = ch.queue("input")
        ch.defaultExchange().publish(queueName.data(using: .utf8)!, routingKey: inputQueue.name)
    }
    
    public func setupTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { timer in
            DispatchQueue.main.async {
                self.isConnected = self.connection.isOpen()
            }
        }
    }
    
    private func classification(images: [String: CGImage], clouser: @escaping ([String: String]) -> Void) {
        
        var result = [String: String]()
        let group = DispatchGroup()
        
        group.enter()
        DispatchQueue.global().async {
            images.forEach { (name, image) in
                self.imageClassifier.predict(input: image) { prediction in
                    result.updateValue(prediction ?? "unknown", forKey: name)
                    if result.count == images.count {
                        group.leave()
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            clouser(result)
        }
    }
    
    private func convertImage(image: NSImage) -> CGImage {
        var imageRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        guard let cgImage = image.cgImage(forProposedRect: &imageRect,
                                          context: nil,
                                          hints: nil)
        else { fatalError("Failed to convert NSImage to CGImage") }
        
        return cgImage
    }
}
