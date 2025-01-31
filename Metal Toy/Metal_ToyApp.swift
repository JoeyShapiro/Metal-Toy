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
    private let font = NSFont.monospacedSystemFont(ofSize: 12, weight: NSFont.Weight(rawValue: 0.0))
    @FocusState private var focused: Bool
    @State private var highlightedText: NSAttributedString = NSAttributedString()
    @State private var cursor = CGPoint.zero
    
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
        WindowGroup { // doesnt like any dragging / maybe app needs special veiw
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
                    ScrollView([.horizontal, .vertical]) {
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
                        CodeEditor(text: $text, cursor: $cursor)
                            .focused($focused)
                            
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
//            .frame(width: 1280, height: 720, alignment: .center)
        }
        .modelContainer(sharedModelContainer)
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
