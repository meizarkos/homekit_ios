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
                            Text("\(Int(mode.temperature))°")
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
            HandleModeView(name: name, temperature: temperature, sound: sound, luminosity: luminosity)
        }
        .navigationTitle("Modes")
    }
}
