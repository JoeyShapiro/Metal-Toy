//
//  ContentView.swift
//  Metal Toy
//
//  Created by Joey Shapiro on 11/11/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    @State private var text: String = "stuff"
    @State private var running: Bool = false
    @State private var epoch: Double = 0

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                    } label: {
                        Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                    }
                }
                .onDelete(perform: deleteItems)
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
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .font(.body)
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

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}
