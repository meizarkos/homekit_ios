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
            List {
                ForEach(modeVM.modes) { mode in
                    Button {
                        modeToEdit = mode
                        showEditor = true
                    } label: {
                        HStack {
                            Text(mode.name)
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
                }
                .onDelete { indexSet in
                    modeVM.deleteMode(at: indexSet)
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
                // Modifier un mode existant
                HandleModeView(mode: mode, homeName: name)
            } else {
                // Créer un nouveau mode
                HandleModeView(name: name, temperature: temperature, sound: sound, luminosity: luminosity, homeName: name)
            }
        }
        .navigationTitle("Modes - \(name)")
    }
}
