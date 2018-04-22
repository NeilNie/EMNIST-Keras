//
//  HandwritingLearnViewController.swift
//  Swift-AI-iOS
//
//  Created by Neil Nie on March 01 2017
//  Copyright © 2015 Appsidian. All rights reserved.
//

import UIKit

public class LearnerView : UIViewController, UITextFieldDelegate {
    
    var network : SwiftMind!
    var textField : UITextField!
    var canvas : UIImageView!
    
    override public func loadView() {
        
        let url = Bundle.main.url(forResource: "mindData_learn", withExtension: nil)!
        network = Storage.read(url)!
        
        let view = UIView()
        view.backgroundColor = UIColor.init(red: 247.0 / 255.0, green: 247.0 / 255.0, blue: 247.0 / 255.0, alpha: 1.0)
        
        canvas = UIImageView(frame: CGRect.init(x: 23, y: 60, width: 330, height: 330))
        canvas.backgroundColor = UIColor.white
        view.addSubview(canvas)
        
        textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.placeholder = "Please enter a number"
        view.addSubview(textField)
        
        self.view = view
        
        textField.translatesAutoresizingMaskIntoConstraints = false
        let margins = view.layoutMarginsGuide
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: margins.topAnchor, constant: 20),
            textField.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
        ])
        
        textField.addTarget(self, action: #selector(updateLabel), for: UIControlEvents.editingChanged)
    }
    
    @objc func updateLabel() {
        if !(self.textField.text?.isEmpty)! {
            self.canvas.image = self.generateCharacter(digit: Int(self.textField.text!)!)
        }
    }
}

// MARK: Neural network and drawing methods

extension LearnerView {
    
    public func generateCharacter(digit: Int) -> UIImage? {
        guard let inputArray = self.digitToArray(digit: digit) else {
            print("Error: Invalid digit: \(digit)")
            return nil
        }
        do {
            let output = try self.network.predict(inputs: inputArray)
            let image = self.pixelsToImage(pixelFloats: output!)
            return image
        } catch {
            print(error)
        }
        return nil
    }
    
    private func pixelsToImage(pixelFloats: [Float]) -> UIImage? {
        guard pixelFloats.count == 784 else {
            print("Error: Invalid number of pixels given: \(pixelFloats.count). Expected: 784")
            return nil
        }
        struct PixelData {
            let a: UInt8
            let r: UInt8
            let g: UInt8
            let b: UInt8
        }
        var pixels = [PixelData]()
        for pixelFloat in pixelFloats {
            pixels.append(PixelData(a: UInt8(pixelFloat * 255), r: 0, g: 0, b: 0))
        }
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
        var data = pixels
        let providerRef = CGDataProvider(data: NSData(bytes: &data, length: data.count * MemoryLayout<PixelData>.size))
        let cgim = CGImage(width: 28, height: 28, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: 28 * MemoryLayout<PixelData>.size, space: rgbColorSpace, bitmapInfo: bitmapInfo, provider: providerRef!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)
        return UIImage(cgImage: cgim!)
    }
    
    
    private func digitToArray(digit: Int) -> [Float]? {
        guard digit >= 0 && digit <= 9 else {
            return nil
        }
        var array = [Float](repeating: 0, count: 10)
        array[digit] = 1
        return array
    }
    
}
