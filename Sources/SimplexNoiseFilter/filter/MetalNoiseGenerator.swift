//
//  File.swift
//  SimplexNoiseFilter
//
//  Created by Влад Янковенко on 27.05.2025.
//

import Foundation

import Metal
import MetalKit

public class MetalNoiseGenerator {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let pipelineState: MTLComputePipelineState

    public init?(functionName: String = "noiseKernel") {
        // 1. Инициализация устройства и очереди
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else {
            print("Metal не поддерживается на этом устройстве")
            return nil
        }
        self.device = device
        self.commandQueue = commandQueue

        // 2. Загрузка шейдера из библиотеки
        guard let library = try? device.makeDefaultLibrary(bundle: .main),
              let kernelFunction = library.makeFunction(name: functionName) else {
            print("Не удалось загрузить функцию \(functionName) из Metal библиотеки")
            return nil
        }

        // 3. Создание compute pipeline
        do {
            pipelineState = try device.makeComputePipelineState(function: kernelFunction)
        } catch {
            print("Не удалось создать pipeline state: \(error)")
            return nil
        }
    }

    func createOutputTexture(width: Int, height: Int) -> MTLTexture? {
        // 4. Создаем текстуру вывода для результата шейдера
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba32Float,
                                                                         width: width,
                                                                         height: height,
                                                                         mipmapped: false)
        textureDescriptor.usage = [.shaderWrite, .shaderRead]
        return device.makeTexture(descriptor: textureDescriptor)
    }

    func makeSeedBuffer(seed: Int32) -> MTLBuffer? {
        // 5. Создаем буфер с seed
        var seedCopy = seed
        return device.makeBuffer(bytes: &seedCopy,
                                 length: MemoryLayout<Int32>.stride,
                                 options: [])
    }

    public func generateNoiseTexture(width: Int, height: Int, seed: Int32) -> MTLTexture? {
        guard let outputTexture = createOutputTexture(width: width, height: height),
              let seedBuffer = makeSeedBuffer(seed: seed),
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            print("Не удалось подготовить ресурсы для генерации шума")
            return nil
        }

        // 6. Настраиваем pipeline и ресурсы
        computeEncoder.setComputePipelineState(pipelineState)
        computeEncoder.setTexture(outputTexture, index: 0)
        computeEncoder.setBuffer(seedBuffer, offset: 0, index: 0)

        // 7. Запускаем шейдер по группам потоков
        let threadGroupSize = MTLSize(width: 16, height: 16, depth: 1)
        let threadGroups = MTLSize(width: (width + 15) / 16,
                                   height: (height + 15) / 16,
                                   depth: 1)

        computeEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
        computeEncoder.endEncoding()

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        return outputTexture
    }
}
