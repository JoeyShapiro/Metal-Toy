//
//  CodeEditor.swift
//  Metal Toy
//
//  Created by Joey Shapiro on 1/28/25.
//

import SwiftUI

struct CodeEditor: View {
    @Binding var text: String
    @State var highlightedText: NSAttributedString = NSAttributedString()
    @Binding var font: NSFont
    @State var cursor: CGPoint = .zero
    @State var selectionStart: CGPoint = .zero
    @State var charSize: CGSize = .zero
    
    var body: some View {
        ZStack {
            Canvas(
                opaque: true,
                colorMode: .linear,
                rendersAsynchronously: false
            ) { context, size in
                // cursor
                let path = Rectangle().path(in: CGRect(x: cursor.x, y: cursor.y, width: self.font.maximumAdvancement.width/4, height: charSize.height))
                context.fill(path, with: .color(.blue))
                
                // highlight
                let selectionPath = Rectangle().path(in: CGRect(x: selectionStart.x, y: selectionStart.y, width: cursor.x - selectionStart.x, height: charSize.height))
                context.fill(selectionPath, with: .color(.blue.opacity(0.3)))
            }
            Text(AttributedString(highlightedText))
                .padding(0)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .font(Font(font))
                .onAppear() {
                    self.charSize = getCharSize() // hack / fun police'd
                    format()
                }
                .onChange(of: text) { old, new in
                    format()
                }
        }
        .gesture(DragGesture(minimumDistance: 0).onChanged { code in // includes scroll
            // convert to character on grid
            var col = (code.location.x / self.font.maximumAdvancement.width).rounded(.toNearestOrAwayFromZero)
            var row = (code.location.y / charSize.height).rounded(.down)
            
            // get char at that pos
            // doing 2d is needed because each row isnt full
            let data = highlightedText.string.split(separator: "\n", omittingEmptySubsequences: false)[Int(row)]
            
            if Int(col) < 3 {
                col = 3
            } else if Int(col) > data.count {
                col = CGFloat(data.count)
            }
            
            cursor = .init(x: col * self.font.maximumAdvancement.width, y: row * charSize.height)
            
            col = (code.startLocation.x / self.font.maximumAdvancement.width).rounded(.toNearestOrAwayFromZero)
            row = (code.startLocation.y / charSize.height).rounded(.down)
            
            selectionStart = .init(x: col * self.font.maximumAdvancement.width, y: row * charSize.height)
        })
        .focusable()
        .focusEffectDisabled()
        .onKeyPress { key in
            print(key.debugDescription)
            var c = key.characters.first ?? Character("")
            if c == "\r" {
                c = "\n"
            }
            
            var col = Int((cursor.x / self.font.maximumAdvancement.width).rounded(.toNearestOrAwayFromZero))
            let row = Int((cursor.y / charSize.height).rounded(.down))
            
            let data = highlightedText.string.split(separator: "\n", omittingEmptySubsequences: false)[row]
            // get the nth occurance of \n
            var start = 0
            for i in 0..<row {
                start += highlightedText.string.split(separator: "\n", omittingEmptySubsequences: false)[i].count + 1 - 3
            }
            
            // TODO check for range
            let u = c.unicodeScalars.first!.value
            switch u {
            case 127: // DEL
                text.remove(at: text.index(text.startIndex, offsetBy: start+(col-4)))
                cursor.x -= self.font.maximumAdvancement.width
                return .handled
            case 63232: // up
                cursor.y -= charSize.height
                return .handled
            case 63233: // down
                cursor.y += charSize.height
                return .handled
            case 63234: // left
                cursor.x -= self.font.maximumAdvancement.width
                return .handled
            case 63235: // right
                cursor.x += self.font.maximumAdvancement.width
                return .handled
            default:
                let _: Void = ()
            }
            
            if  col <= data.count {
                text.insert(contentsOf: String(c), at: text.index(text.startIndex, offsetBy: start+(col-3)))
                cursor.x += self.font.maximumAdvancement.width
            } else {
                col = data.count
            }
            
            //                cursor.offsetBy(dx: self.font.maximumAdvancement.width)
            return .handled
        }
        .onChange(of: font) {
            self.charSize = self.getCharSize()
        }
    }
    
    private func getCharSize() -> CGSize {
        let attributes = [NSAttributedString.Key.font: font]
        return ("J" as NSString).size(withAttributes: attributes)
    }
    
    private func format() {
        // Get the total number of lines to determine padding width
        // this bit me so many times. not sure why, i thought bug
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        // Calculate the width needed for the largest line number
        let n = String(lines.count).count
        
        let formatted = lines
            .enumerated()
            .map { (i, e) in
                "\(String(format: "%\(n)d", i + 1)) \(e)"
            }
            .joined(separator: "\n")
        
        let attributedString = NSMutableAttributedString(string: formatted)
        
        // Metal keywords
        var keywords = "using|namespace|struct|bool|constant|vertex|return"
        attributedString.highlight(pattern: "\\b(\(keywords))\\b", with: .systemPink)
        
        // Metal Processors
        keywords = "include"
        attributedString.highlight(pattern: "#(\(keywords))\\b", with: .systemOrange)
        
        // String literals
        attributedString.highlight(pattern: "\"[^\"\\\\]*(?:\\\\.[^\"\\\\]*)*\"", with: .systemRed)
        
        // Numbers
        attributedString.highlight(pattern: "\\b\\d+\\.?\\d*\\b", with: .systemYellow)
        
        // line numbers
        attributedString.highlight(pattern: "(^|\\n)\\s*\\d+", with: .systemGray)
        
        // Comments
        attributedString.highlight(pattern: "//.*$", with: .systemGreen)
        
        highlightedText = attributedString
    }
}


// Syntax highlighting support
extension NSMutableAttributedString {
    func highlight(pattern: String, with color: NSColor) {
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: self.length)
        regex?.enumerateMatches(in: self.string, range: range) { match, _, _ in
            if let matchRange = match?.range {
                self.addAttribute(.foregroundColor, value: color, range: matchRange)
            }
        }
    }
}
