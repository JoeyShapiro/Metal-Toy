//
//  MetalView.swift
//  Plutonium
//
//  Created by Joey Shapiro on 10/14/24.
//

import SwiftUI
import MetalKit

struct MetalView: NSViewRepresentable {
    private var coordinator: Coordinator
    @Binding var source: String
    
    init(source: Binding<String>) {
        let device = MTLCreateSystemDefaultDevice()!
        self.coordinator = Coordinator(device: device)
        self._source = source
    }
    
    func makeNSView(context: Context) -> MTKView {
        let mtkView = MTKView()
        // idk, have to do this and set renderer as non null otherwise idk
        // metal view is created twice. first gets update, second gets draw
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.delegate = context.coordinator
        mtkView.colorPixelFormat = .bgra8Unorm
//        mtkView.preferredFramesPerSecond = 60
//        mtkView.enableSetNeedsDisplay = false
        
        return mtkView
    }
    
    func updateNSView(_ nsView: MTKView, context: Context) {
        self.coordinator.update(source: self.source) // todo update scale and size
    }
    
    func makeCoordinator() -> Coordinator {
        return self.coordinator
    }
    
    class Coordinator: NSObject, MTKViewDelegate {
        var renderer: Renderer
        let device: MTLDevice
        
        init(device: MTLDevice) {
            self.device = device
            renderer = Renderer(device: self.device, source: "")
            
//            super.init()
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            renderer.mtkView(view, drawableSizeWillChange: size)
        }
        
        func update(source: String) {
//            renderer.update()
            
            renderer = Renderer(device: self.device, source: source)
        }
        
        func draw(in view: MTKView) {
            renderer.draw(in: view)
        }
    }
}
