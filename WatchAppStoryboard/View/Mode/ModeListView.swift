import SwiftUI

struct ModeListView: View {
    @EnvironmentObject var modeVM: ModeViewModel
    @State private var showEditor = false
    @State private var modeToEdit: Mode? = nil
    var name: String
    var temperature: Int
    var sound: Int
    var luminosity: Int

    var body: some View {
        VStack {
            if let currentMode = modeVM.currentMode {
                CurrentModeCard(mode: currentMode)
                    .padding()
            }
            
            List {
                ForEach(modeVM.modes) { mode in
                    HStack {
                        Button {
                            if modeVM.currentMode?.id == mode.id {
                                modeVM.deselectMode()
                            } else {
                                modeVM.selectMode(mode)
                            }
                        } label: {
                            Image(systemName: modeVM.currentMode?.id == mode.id ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(modeVM.currentMode?.id == mode.id ? .green : .gray)
                                .font(.title3)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        
                        Button {
                            modeToEdit = mode
                            showEditor = true
                        } label: {
                            HStack {
                                Text(mode.name)
                                    .foregroundColor(.primary)
                                Spacer()
                                HStack(spacing: 15) {
                                    Label("\(mode.temperature)°", systemImage: "thermometer")
                                        .font(.caption)
                                    Label("\(mode.sound)%", systemImage: "speaker.wave.2")
                                        .font(.caption)
                                    Label("\(mode.luminosity)%", systemImage: "sun.max")
                                        .font(.caption)
                                }
                                .foregroundColor(.gray)
                            }
                        }
                        
                        Button {
                            if let index = modeVM.modes.firstIndex(where: { $0.id == mode.id }) {
                                modeVM.deleteMode(at: IndexSet(integer: index))
                            }
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }
            }

            Button {
                modeToEdit = nil
                showEditor = true
            } label: {
                Label("Créer un mode", systemImage: "plus.circle.fill")
                    .font(.title2)
            }
            .padding()
        }
        .sheet(isPresented: $showEditor) {
            if let mode = modeToEdit {
                HandleModeView(mode: mode, homeName: name)
                    .environmentObject(modeVM)
            } else {
                HandleModeView(name: name, temperature: temperature, sound: sound, luminosity: luminosity, homeName: name)
                    .environmentObject(modeVM)
            }
        }
        .navigationTitle("Modes - \(name)")
    }
}

struct CurrentModeCard: View {
    let mode: Mode
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Mode actif")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 20) {
                        Label("\(mode.temperature)°", systemImage: "thermometer")
                        Label("\(mode.sound)%", systemImage: "speaker.wave.2")
                        Label("\(mode.luminosity)%", systemImage: "sun.max")
                    }
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
                }
                Spacer()
            }
        }
        .padding()
        .background(Color.blue)
        .cornerRadius(12)
    }
}
