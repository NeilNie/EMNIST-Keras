//
//  HandwritingView.swift
//
//  Copyright (c) 2017 Neil Nie. All rights reserved.
//  This class is written for WWDC 2017 Scholarship application

import UIKit

public class HandwritingView: UIView {
    
    public var mainImageView: UIImageView!
    public var tempImageView: UIImageView!
    public var processedImageView : UIImageView!
    public var percentLabel : UILabel!
    public var outputLabel: UILabel!
    public var clearButton : UIButton!
    public var snapshotBox = UIView()
    
    var lastPoint = CGPoint.zero
    var brushWidth: CGFloat = 22
    var swiped = false
    
    var boundingBox: CGRect?
    var drawing = false
    var timer = Timer()
    var network: SwiftMind!
    
    public override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        let label = UILabel(frame: CGRect(x: 25, y: 20, width: 230, height: 30))
        label.text = "Please write a number"
        label.font = UIFont.init(name: "HelveticaNeue-Medium", size: 20)
        label.textColor = UIColor.black
        self.addSubview(label)
        
        let viewLength = self.frame.width / 3 + 35
        
        outputLabel = UILabel(frame: CGRect(x: 25, y: 520, width: viewLength, height: viewLength))
        outputLabel.textAlignment = NSTextAlignment.center
        outputLabel.font = UIFont.init(name: "HelveticaNeue", size: 130)
        outputLabel.textColor = UIColor.black
        outputLabel.backgroundColor = UIColor.white
        
        processedImageView = UIImageView.init(frame: CGRect(x: 212, y: 520, width: viewLength, height: viewLength))
        processedImageView.backgroundColor = UIColor.white
        self.addSubview(processedImageView)
        
        percentLabel = UILabel.init(frame: CGRect.init(x: 25, y: 650, width: viewLength, height: 30))
        label.font = UIFont.init(name: "HelveticaNeue-Bold", size: 20)
        percentLabel.textColor = UIColor.black
        percentLabel.textAlignment = NSTextAlignment.center
        percentLabel.backgroundColor = UIColor.clear
        self.addSubview(outputLabel)
        self.addSubview(percentLabel)
        
        clearButton = UIButton(frame: CGRect.init(x: self.frame.width - 90, y: 13, width: 80, height: 50))
        clearButton.setTitleColor(UIColor.black, for: UIControlState.normal)
        clearButton.setTitle("Clear", for: UIControlState.normal)
        clearButton.addTarget(self, action: #selector(clearScreen(sender:)), for: UIControlEvents.touchUpInside)
        self.addSubview(clearButton)
        
        backgroundColor = UIColor.init(red: 242.0 / 255.0, green: 242.0 / 255.0, blue: 242.0 / 255.0, alpha: 1.0)
        mainImageView = UIImageView(frame: CGRect.init(x: 25, y: 60, width: Double(frame.size.width - 50), height: 450))
        tempImageView = UIImageView(frame: CGRect.init(x: 25, y: 60, width: Double(frame.size.width - 50), height: 450))
        mainImageView.backgroundColor = UIColor.white
        self.addSubview(mainImageView)
        self.addSubview(tempImageView)
        
        snapshotBox.layer.borderColor = UIColor.green.cgColor
        snapshotBox.layer.borderWidth = 5.0
        self.addSubview(snapshotBox)
        
        network = Storage.read(Bundle.main.url(forResource: "mindData", withExtension: nil)!)
        print(network.dimension)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Actions
    
    @objc func clearScreen(sender: UIButton?) {
        self.snapshotBox.frame = CGRect.init(x: 0, y: 0, width: 0, height: 0)
        mainImageView.image = nil
    }

    public func drawLineFrom(_ fromPoint: CGPoint, toPoint: CGPoint) {

        UIGraphicsBeginImageContext(self.tempImageView.frame.size)
        let context = UIGraphicsGetCurrentContext()
        tempImageView.image?.draw(in: CGRect(x: 0, y: 0, width: self.tempImageView.frame.size.width, height: self.tempImageView.frame.size.height))

        context?.move(to: CGPoint(x: fromPoint.x, y: fromPoint.y))
        context?.addLine(to: CGPoint(x: toPoint.x, y: toPoint.y))

        context?.setLineCap(CGLineCap.round)
        context?.setLineWidth(brushWidth)
        context?.setStrokeColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        context?.setBlendMode(CGBlendMode.normal)

        context?.strokePath()

        tempImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        tempImageView.alpha = 1.0
        UIGraphicsEndImageContext()
        
    }
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?){
        
        let touch = touches.first
        if Double((touch?.location(in: self).y)!) < 50.0 || Double((touch?.location(in: self).y)!) > 530.0 {
            let alert = UIAlertController(title: "Opps", message: "Please write on the canvas", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
            //self.present(alert, animated: true, completion: nil)
        }else{
            swiped = false
            lastPoint = (touch?.location(in: tempImageView))!
            
            if boundingBox == nil {
                boundingBox = CGRect(x: lastPoint.x - brushWidth / 2 + 60,
                                     y: lastPoint.y - brushWidth / 2 + 60,
                                     width: brushWidth,
                                     height: brushWidth)
            }
            snapshotBox.frame = boundingBox!
            
            timer.invalidate()
            drawing = true
        }
    }
    
    override open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        swiped = true
        if let touch = touches.first {
            let currentPoint = touch.location(in: tempImageView)
            drawLineFrom(lastPoint, toPoint: currentPoint)
            
            lastPoint = currentPoint
        }

        if lastPoint.x < boundingBox!.minX {
            self.updateRect(rect: &boundingBox!, minX: lastPoint.x - brushWidth - 50, maxX: nil, minY: nil, maxY: nil)
        } else if lastPoint.x > boundingBox!.maxX {
            self.updateRect(rect: &boundingBox!, minX: nil, maxX: lastPoint.x + brushWidth + 50, minY: nil, maxY: nil)
        }
        if lastPoint.y < boundingBox!.minY {
            self.updateRect(rect: &boundingBox!, minX: nil, maxX: nil, minY: lastPoint.y - self.brushWidth + 10, maxY: nil)
        } else if lastPoint.y > boundingBox!.maxY {
            self.updateRect(rect: &boundingBox!, minX: nil, maxX: nil, minY: nil, maxY: lastPoint.y + self.brushWidth + 50)
        }
        self.snapshotBox.frame = boundingBox!
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {

        if !swiped {
            drawLineFrom(lastPoint, toPoint: lastPoint)
        }
        
        UIGraphicsBeginImageContext(mainImageView.frame.size)
        mainImageView.image?.draw(in: CGRect(x: 0, y: 0, width: self.tempImageView.frame.size.width, height: self.tempImageView.frame.size.height), blendMode: CGBlendMode.normal, alpha: 1.0)
        tempImageView.image?.draw(in: CGRect(x: 0, y: 0, width: self.tempImageView.frame.size.width, height: self.tempImageView.frame.size.height), blendMode: CGBlendMode.normal, alpha: 1.0)
        mainImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        tempImageView.image = nil
        
        timer = Timer.scheduledTimer(timeInterval: 0.4, target: self, selector: #selector(timerExpired), userInfo: nil, repeats: false)
        drawing = false
        super.touchesEnded(touches, with: event)
    }
    
    @objc func timerExpired(sender: Timer) {
        self.classifyImage()
        self.boundingBox = nil
    }
}

extension HandwritingView {
    
    public func classifyImage() {

        guard let imageArray = self.scanImage() else {
            self.clearScreen(sender: nil)
            return
        }
        let result = self.extractResult(output: try! network.predict(inputs: imageArray))
        outputLabel.text = "\(result?.index ?? 0)"
        percentLabel.text = "\(result?.value.rounded() ?? 00.0)%"
    }
    
    private func extractResult(output: [Float]) -> (index: Int, value: Double)? {
        let max = output.max()
        return (output.index(of: max!)!, Double(max! * 100.0))
    }
    
    private func scanImage() -> [Float]? {
        var pixelsArray = [Float]()
        guard let image = self.mainImageView.image else {
            return nil
        }
        // Extract drawing from canvas and remove surrounding whitespace
        let croppedImage = self.cropImage(image: image, toRect: boundingBox!)
        // Scale character to max 20px in either dimension
        let scaledImage = self.scaleImageToSize(image: croppedImage, maxLength: 25)
        // Center character in 28x28 white box
        let character = self.addBorderToImage(image: scaledImage)
        
        self.processedImageView.image = character
        
        let pixelData = character.cgImage!.dataProvider!.data
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        let bytesPerRow = character.cgImage!.bytesPerRow
        let bytesPerPixel = (character.cgImage!.bitsPerPixel / 8)
        var position = 0
        for _ in 0..<Int(character.size.height) {
            for _ in 0..<Int(character.size.width) {
                let alpha = Float(data[position + 3])
                pixelsArray.append(alpha / 255)
                position += bytesPerPixel
            }
            if position % bytesPerRow != 0 {
                position += (bytesPerRow - (position % bytesPerRow))
            }
        }
        return pixelsArray
    }
    
    private func cropImage(image: UIImage, toRect: CGRect) -> UIImage {
        let imageRef = image.cgImage!.cropping(to: toRect)
        let newImage = UIImage(cgImage: imageRef!)
        return newImage
    }
    
    private func scaleImageToSize(image: UIImage, maxLength: CGFloat) -> UIImage {
        let size = CGSize(width: min(23 * image.size.width / image.size.height, 23), height: min(23 * image.size.height / image.size.width, 23))
        let newRect = CGRect(x: 0, y: 0, width: size.width, height: size.height).integral
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        let context = UIGraphicsGetCurrentContext()
        context!.interpolationQuality = CGInterpolationQuality.none
        image.draw(in: newRect)
        let newImageRef = context!.makeImage()! as CGImage
        let newImage = UIImage(cgImage: newImageRef, scale: 1.0, orientation: UIImageOrientation.up)
        UIGraphicsEndImageContext()
        return newImage
    }
    
    private func addBorderToImage(image: UIImage) -> UIImage {
        UIGraphicsBeginImageContext(CGSize(width: 28, height: 28))
        let white = UIImage(named: "white.png")!
        white.draw(at: CGPoint.zero)
        image.draw(at: CGPoint(x: (28 - image.size.width) / 2, y: (28 - image.size.height) / 2))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    public func updateRect( rect: inout CGRect, minX: CGFloat?, maxX: CGFloat?, minY: CGFloat?, maxY: CGFloat?) {
        rect = CGRect(x: minX ?? rect.minX,
                      y: minY ?? rect.minY,
                      width: (maxX ?? rect.maxX) - (minX ?? rect.minX),
                      height: (maxY ?? rect.maxY) - (minY ?? rect.minY))
    }
}
