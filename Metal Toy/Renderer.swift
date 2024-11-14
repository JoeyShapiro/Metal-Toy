//
//  Renderer.swift
//  Plutonium
//
//  Created by Joey Shapiro on 10/14/24.
//

import MetalKit

struct Uniforms {
    var resolution: SIMD2<Float>
    var scale: SIMD2<Float>
}

class Renderer: NSObject {
    var device: MTLDevice
    var commandQueue: MTLCommandQueue
    var pipelineState: MTLRenderPipelineState
    var uniformsBuffer: MTLBuffer
    var uniforms: Uniforms
    private var dirty = true
    private var source = ""
    
    let vertices: [Float] = [
        -1, -1,  // bottom left
         1, -1,  // bottom right
         -1,  1,  // top left
         1,  1,  // top right
    ]
    var vertexBuffer: MTLBuffer?
    
    init(device: MTLDevice) {
        // fatal seems harsh, but better than doing nothing at all
        guard let commandQueue = device.makeCommandQueue() else { fatalError("Failed to create command queue") }
        
        self.device = device
        self.commandQueue = commandQueue
        
        // dummy values i guess idk
        uniforms = Uniforms(resolution: SIMD2<Float>(Float(1),
                                                     Float(1)),
                            scale: SIMD2<Float>(Float(1),
                                                Float(1)))
        uniformsBuffer = device.makeBuffer(bytes: &uniforms,
                                           length: MemoryLayout<Uniforms>.stride,
                                           options: [])!
        // Set up function constants for player position
        let constantValues = MTLFunctionConstantValues()
        var useConstants = true
        constantValues.setConstantValue(&useConstants, type: .bool, index: 0)

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        do {
            // Create the render pipeline
            let library = try device.makeLibrary(source: source, options: .none)
            
            let vertexFunction = library.makeFunction(name: "vertexShader")
            let fragmentFunction = try library.makeFunction(name: "fragmentShader", constantValues: constantValues)
            
            pipelineDescriptor.vertexFunction = vertexFunction
            pipelineDescriptor.fragmentFunction = fragmentFunction
        } catch {
            print("Unable to create metal library: \(error)")
            
            let library = device.makeDefaultLibrary()!
            
            let vertexFunction = library.makeFunction(name: "vertexShader")
            let fragmentFunction = try! library.makeFunction(name: "fragmentShader", constantValues: constantValues)
            
            pipelineDescriptor.vertexFunction = vertexFunction
            pipelineDescriptor.fragmentFunction = fragmentFunction
        }
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("Unable to create render pipeline state: \(error)")
        }
        
        super.init()
        
        vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Float>.stride, options: [])
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        uniforms.resolution = SIMD2<Float>(Float(size.width), Float(size.height))
        uniforms.scale = SIMD2<Float>(Float(size.height/16), Float(size.width/16))
        memcpy(uniformsBuffer.contents(), &uniforms, MemoryLayout<Uniforms>.stride)
    }
    
    func update(source: String) {
        print("source (\(source.count))")
        self.source = source
        self.dirty = true
    }
    
    func draw(in view: MTKView) {
        if self.dirty {
            self.dirty = false
        }
        guard let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentBuffer(uniformsBuffer, offset: 0, index: 0)
        
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
