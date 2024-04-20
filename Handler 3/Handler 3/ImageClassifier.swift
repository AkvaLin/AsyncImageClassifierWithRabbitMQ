//
//  ImageClassifier.swift
//  Handler 1
//
//  Created by Никита Пивоваров on 20.04.2024.
//

import Foundation
import CoreImage

final class ImageClassifier {
    let classifier = try? MyImageClassifier_2()
    
    public func predict(input: CGImage, clouser: @escaping (String?) -> Void) {
        guard let classifier = classifier else { clouser(nil); return }
        
        Task {
            guard let input = try? MyImageClassifier_2Input(imageWith: input) else { return }
            
            do {
                let prediction = try await classifier.prediction(input: input)
                clouser(prediction.target)
            } catch {
                print(error)
            }
        }
    }
}
