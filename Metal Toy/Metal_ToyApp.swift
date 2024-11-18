//
//  Metal_ToyApp.swift
//  Metal Toy
//
//  Created by Joey Shapiro on 11/11/24.
//

import SwiftUI
import SwiftData

@main
struct Metal_ToyApp: App {
    @State private var text: String = Bundle.main.readFile(named: "shader.txt") ?? "stuff"
    @State private var running: Bool = false
    @State private var epoch: Double = 0
    @Query private var items: [Item]
    @State private var selectedRange: NSRange?
    @State private var lineNumbers: [Int] = []
    private let font = Font.system(.body, design: .monospaced)
    @FocusState private var focused: Bool
    @State private var highlightedText: NSAttributedString = NSAttributedString()
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            NavigationSplitView {
                List {
                    ForEach(items) { item in
                        NavigationLink {
                            Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                        } label: {
                            Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                        }
                    }
                }
                .navigationSplitViewColumnWidth(min: 180, ideal: 200)
                .toolbar {
                    ToolbarItem {
                        Button(action: {  }) {
                            Label("Build", systemImage: "wrench.and.screwdriver.fill")
                        }
                    }
                }
            } detail: {
                HStack {
                    ScrollView {
                        // Line numbers
//                        VStack(alignment: .trailing) {
//                            ForEach(lineNumbers, id: \.self) { number in
//                                Text("\(number)")
//                                    .font(font)
//                                    .foregroundColor(.gray)
//                                    .padding(.horizontal, 8)
//                            }
//                        }
//                        
//                        // Text editor with syntax highlighting
                        ZStack {
                            Canvas(
                                opaque: true,
                                colorMode: .linear,
                                rendersAsynchronously: false
                            ) { context, size in
                                let path = Rectangle().path(in: CGRect(x: 0, y: size.height-50, width: 50, height: 50))
                                context.fill(path, with: .color(.blue))
                            }
                            Text(AttributedString(highlightedText))
                                .textSelection(.enabled)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                                .monospaced()
                                .onAppear() {
                                    format()
                                }
                                .onChange(of: text) { newValue in
                                    format()
                                }
                        }
                            
                    }
                    VStack {
                        MetalView(source: $text)
                        HStack {
                            Button {
                                print("reset")
                                epoch = 0
                            } label: {
                                Image(systemName: "backward.end.fill")
                            }
                            .buttonStyle(.accessoryBar)
                            .controlSize(.large)
                            .help("Reset")
                            Button {
                                running.toggle()
                            } label: {
                                Image(systemName: running ? "pause.fill" :"play.fill")
                            }
                            .buttonStyle(.accessoryBar)
                            .controlSize(.large)
                            .help(running ? "Pause" : "Play")
                            Text(epoch.description)
                        }.padding(.vertical, 5)
                    }
                }
            }
            .focusable()
            .focused($focused)
            .focusEffectDisabled().onKeyPress { key in
                print(key.debugDescription.debugDescription)
                var c = key.characters.first?.description ?? ""
                c = c.replacingOccurrences(of: "\r", with: "\n")
                self.text += c
                return .handled
            }
        }
        .modelContainer(sharedModelContainer)
    }
    
    private func format() {
        // Get the total number of lines to determine padding width
        let totalLines = text.split(separator: "\n").count
        // Calculate the width needed for the largest line number
        let n = String(totalLines).count
        
        let formatted = text.split(separator: "\n")
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

extension Bundle {
    func readFile(named fileName: String) -> String? {
        guard let path = Bundle.main.path(forResource: fileName, ofType: nil) else {
            return nil
        }
        return try? String(contentsOfFile: path, encoding: .utf8)
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
