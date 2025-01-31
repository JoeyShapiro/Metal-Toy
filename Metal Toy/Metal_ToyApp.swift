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
                        CodeEditor(text: $text)
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
}

extension Bundle {
    func readFile(named fileName: String) -> String? {
        guard let path = Bundle.main.path(forResource: fileName, ofType: nil) else {
            return nil
        }
        return try? String(contentsOfFile: path, encoding: .utf8)
    }
}
