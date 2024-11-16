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
                    TextEditor(text: $text)
                        .font(font)
                        .onChange(of: text) { newValue in
                            updateLineNumbers()
                            highlightSyntax()
                        }
                        .onAppear {
                            updateLineNumbers()
                            highlightSyntax()
                        }
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
                        
                        Text(AttributedString(highlightedText))
                            .textSelection(.enabled)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
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
        }
        .modelContainer(sharedModelContainer)
    }
    
    private func updateLineNumbers() {
        let lines = text.components(separatedBy: .newlines)
        lineNumbers = Array(1...max(1, lines.count))
    }
    
    private func highlightSyntax() {
        let formatted = text.split(separator: "\n")
            .enumerated()
            .map { (i, e) in
                "\(i + 1). \(e)"
            }
            .joined(separator: "\n")
        
        let attributedString = NSMutableAttributedString(string: formatted)
        
        // Swift keywords
        let keywords = "class|struct|enum|func|var|let|if|else|guard|return|while|for|in|switch|case|break|continue|default"
        attributedString.highlight(pattern: "\\b(\(keywords))\\b", with: .systemPink)
        
        // String literals
        attributedString.highlight(pattern: "\"[^\"\\\\]*(?:\\\\.[^\"\\\\]*)*\"", with: .systemRed)
        
        // Numbers
        attributedString.highlight(pattern: "\\b\\d+\\.?\\d*\\b", with: .systemOrange)
        
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
