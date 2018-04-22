//
//  SwiftMind.swift
//
//
//  Created by Yongyang Nie on 3/11/17.
//  
//  This class is written for WWDC 2017 Scholarship application

import Foundation
import Accelerate

public enum SwiftMindError: Error {
    case InvalidInputsError(String)
    case InvalidAnswerError(String)
    case InvalidWeightsError(String)
}

public final class SwiftMind {
    
    public var learningRate: Float
    public var momentum: Float
    public var dimension = [Int]()
    
    public var weights: [[Float]]
    public var results: [[Float]]
    public var errors: [[Float]]
    private var errorIndices: [[Int]]
    private var resultIndices: [[Int]]
    
    public init(size: [Int], learningRate: Float, momentum: Float, weights: [[Float]]? = nil) {
        
        self.weights = [[Float]]()
        errors = [[Float]]()
        results = [[Float]]()
        dimension = size
        self.learningRate = learningRate
        self.momentum = momentum
        errorIndices = [[Int]]()
        resultIndices = [[Int]]()
        
        if weights != nil {
            self.weights = weights!
        }
        
        for index in 0..<dimension.count-1{
            //add bias node to everything but final layer
            dimension[index] = dimension[index] + 1
            //get random weights
            if weights == nil {
                self.weights.append(self.randWeights(count: size[index + 1] * (size[index] + 1)))
            }
            
            var errorIndex = [Int]()
            var resultIndex = [Int]()
            for weightIndex in 0..<self.weights[index].count {
                errorIndex.append(weightIndex / (size[index] + 1))
                resultIndex.append(weightIndex % (size[index] + 1))
            }
            errorIndices.append(errorIndex)
            resultIndices.append(resultIndex)
        }
    }
    
    public init(){
        learningRate = 0.00
        momentum = 0.00
        dimension = [Int]()
        
        weights = [[Float]]()
        results = [[Float]]()
        errors = [[Float]]()
        errorIndices = [[Int]]()
        resultIndices = [[Int]]()
    }
    
    public func predict(inputs: [Float]) throws -> [Float]! {
        
        results = [[Float]]()
        
        var inputs = inputs
        inputs.insert(1.0, at: 0)
        self.results.append(inputs)
        for i in 0..<self.dimension.count-1{
            self.results.append(try! self.forwardFeed(layerIndex: i, inputs: self.results[i], weights: self.weights[i]))
        }
        return results.last!
    }
    
    public func forwardFeed(layerIndex: Int, inputs: [Float], weights: [Float]) throws -> [Float] {
        
        guard inputs.count == dimension[layerIndex] else {
            throw SwiftMindError.InvalidInputsError("Invalid number of outputs given in answer. Expected: \(self.dimension[layerIndex])")
        }
        
        var output = [Float](repeating: 0.0, count: dimension[layerIndex + 1])
        
        vDSP_mmul(weights, 1,
                  inputs, 1,
                  &output, 1,
                  vDSP_Length(self.dimension[layerIndex + 1]), vDSP_Length(1), vDSP_Length(self.dimension[layerIndex]))
        
        //every layer but the output layer has a bias node
        if layerIndex == dimension.count-2 {
            output = self.applyActivation(result: output, hasBias: 0)
        }else{
            output = self.applyActivation(result: output, hasBias: 1)
        }
        
        return output
    }
    
    public func backProp(answers: [Float]) throws {
        
        guard answers.count == dimension.last else {
            throw SwiftMindError.InvalidAnswerError("Invalid number of outputs given in answer: \(answers.count). Expected: \(dimension.last!)")
        }
        errors = [[Float]]()
        
        //calculate output error
        var outputError = [Float](repeating: 0, count: dimension.last!)
        for (index, answer) in answers.enumerated(){
            outputError[index] = (answer - results.last![index]) * NNMath.sigmoidPrime(y: results.last![index])
        }
        errors.append(outputError)
        
        //calculate error for hidden layers
        for index in (1..<dimension.count-1).reversed(){
            
            var error = [Float](repeating: 0.00, count: dimension[index])
            //calculate error
            vDSP_mmul(errors[0], 1,
                      weights[index], 1,
                      &error, 1,
                      vDSP_Length(1), vDSP_Length(self.dimension[index]), vDSP_Length(self.dimension[index + 1]))
            
            for (i, err) in error.enumerated() {
                error[i] = NNMath.sigmoidPrime(y: self.results[index][i]) * err
            }
            errors.insert(error, at: 0)
        }
        
        //apply error
        for (i, err) in errors.enumerated().reversed(){
            weights[i] = try! self.updateWeights(weights: weights[i], errs: err, hasBias: ((i == errors.count-1) ? 0 : 1), errorIndice: errorIndices[i], resultIndice: resultIndices[i], result: results[i])
        }
    }
}

extension SwiftMind {
    
    public func updateWeights(weights: [Float], errs: [Float], hasBias: Int, errorIndice: [Int], resultIndice: [Int], result : [Float]) throws -> [Float]{
        
        var newWeights = [Float](repeating: 0.0, count: weights.count)
        
        for i in 0..<weights.count {
            let errorIndex = errorIndice[i]
            let resultIndex = resultIndice[i]
            // Note: +1 on errorIndex to offset for bias 'error', which is ignored
            let err = errs[errorIndex + hasBias] * result[resultIndex] * learningRate
            newWeights[i] = weights[i] + err
        }
        return newWeights
    }
    
    public func applyActivation(result: [Float], hasBias: Int) -> [Float]{
        
        var output = [Float](repeating: 0, count: result.count)
        if hasBias == 1 {
            output[0] = 1.0
            for i in (1...result.count-1).reversed() {
                output[i] = NNMath.sigmoid(result[i - 1])
            }
        }else{
            for (index, value) in result.enumerated(){
                output[index] = NNMath.sigmoid(value)
            }
        }
        return output
    }
    
    public func randWeights(count: Int) -> [Float]{
        var weights = [Float]()
        for _ in 0..<count{
            let range = 1 / sqrt(Float(count))
            let rangeInt = UInt32(2_000_000 * range)
            let randomFloat = Float(arc4random_uniform(rangeInt)) - Float(rangeInt / 2)
            weights.append(randomFloat / 1_000_000)
        }
        return weights
    }
}

