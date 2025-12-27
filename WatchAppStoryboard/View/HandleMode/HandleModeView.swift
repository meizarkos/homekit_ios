import SwiftUI
import HomeKit

struct HandleModeView: View {
    @StateObject var handleModeViewModel: HandleModeViewModel
    @State private var showCameraDeniedAlert = false
    @EnvironmentObject private var modeVM: ModeViewModel
    @Environment(\.dismiss) private var dismiss

    let editingMode: Mode?

    private var availableLights: [HMAccessory] {
        HomeKitManager.shared.getAllLightsFromHome()
    }

    init(name: String, temperature: Int, sound: Int, luminosity: Int) {
        _handleModeViewModel = StateObject(
            wrappedValue: HandleModeViewModel(
                name: name,
                temperature: temperature,
                sound: sound,
                luminosity: luminosity
            )
        )
        self.editingMode = nil
    }

    init(mode: Mode) {
        _handleModeViewModel = StateObject(
            wrappedValue: HandleModeViewModel(
                name: mode.name,
                temperature: mode.temperature,
                sound: mode.sound,
                luminosity: mode.luminosity
            )
        )
        self.editingMode = mode
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {

                // Sliders / Temp
                HStack(spacing: 25) {
                    VerticalSlider(
                        handleModeViewModel: handleModeViewModel,
                        houseParameter: $handleModeViewModel.luminosity,
                        setHouseParameterInHomekit: handleModeViewModel.callLuminosityHomekit,
                        icon: "sun.max.fill"
                    )
                    VerticalSlider(
                        handleModeViewModel: handleModeViewModel,
                        houseParameter: $handleModeViewModel.sound,
                        setHouseParameterInHomekit: handleModeViewModel.callSoundHomekit,
                        icon: "speaker.fill"
                    )
                    Temperature(
                        handleModeViewModel: handleModeViewModel,
                        temperature: $handleModeViewModel.temperature,
                        changeTemperatureInHomekit: handleModeViewModel.callTempHomekit
                    )
                }
                .padding(.top, 20)

                // Couleurs
                HStack(spacing: 30) {
                    ColorCircleButton(colorEnum: .yellow, selectedColor: $handleModeViewModel.selectedColor,
                                      changeColorFunction: handleModeViewModel.updateColor)
                    ColorCircleButton(colorEnum: .blue, selectedColor: $handleModeViewModel.selectedColor,
                                      changeColorFunction: handleModeViewModel.updateColor)
                    ColorCircleButton(colorEnum: .red, selectedColor: $handleModeViewModel.selectedColor,
                                      changeColorFunction: handleModeViewModel.updateColor)
                }

                //  Sélection des ampoules pour ce mode
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ampoules contrôlées par ce mode")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)

                    if availableLights.isEmpty {
                        Text("Aucune ampoule détectée dans la maison.")
                            .foregroundColor(.gray)
                            .padding(.horizontal, 20)
                    } else {
                        List {
                            ForEach(availableLights, id: \.uniqueIdentifier) { accessory in
                                Button {
                                    let id = accessory.uniqueIdentifier
                                    if handleModeViewModel.selectedLightAccessoryIds.contains(id) {
                                        handleModeViewModel.selectedLightAccessoryIds.remove(id)
                                    } else {
                                        handleModeViewModel.selectedLightAccessoryIds.insert(id)
                                    }

                                    // Optionnel : applique direct la luminosité quand on coche
                                    handleModeViewModel.callLuminosityHomekit()
                                } label: {
                                    HStack {
                                        Text(accessory.name)
                                        Spacer()
                                        if handleModeViewModel.selectedLightAccessoryIds.contains(accessory.uniqueIdentifier) {
                                            Image(systemName: "checkmark.circle.fill")
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(maxHeight: 160)
                    }
                }

                // Auto-mode
                Button(action: {
                    if handleModeViewModel.isAutoModeOn {
                        handleModeViewModel.stopAutoMode()
                        return
                    }
                    handleModeViewModel.requestCameraPermission { granted in
                        if granted {
                            handleModeViewModel.startAutoMode()
                        } else {
                            handleModeViewModel.isAutoModeOn = false
                            showCameraDeniedAlert = true
                        }
                    }
                }) {
                    VStack(spacing: 10) {
                        Image(systemName: "bolt.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 26, height: 26)
                            .foregroundColor(.white)
                        Text("Auto-mode")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .background(handleModeViewModel.isAutoModeOn ? Color.blue : Color.gray)
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                }
                .alert("Camera Access Denied", isPresented: $showCameraDeniedAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("Please enable camera access in Settings to use Auto-mode.")
                }

                // Nom + Save
                VStack(spacing: 12) {
                    TextField("Renseignez le nom du mode", text: $handleModeViewModel.name)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                        .padding(.horizontal, 20)

                    Button(action: { saveMode() }) {
                        Text(editingMode == nil ? "Créer" : "Modifier")
                            .font(.headline)
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                            .padding(.horizontal, 20)
                    }
                }

                Spacer()
            }
            .background(Color.black)
            .navigationTitle(editingMode == nil ? "Nouveau Mode" : "Modifier Mode")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                ActiveHandleModeHolder.shared.current = handleModeViewModel
            }
            .onDisappear {
                if ActiveHandleModeHolder.shared.current === handleModeViewModel {
                    ActiveHandleModeHolder.shared.current = nil
                }
            }

        }
    }

    private func saveMode() {
        guard !handleModeViewModel.name.isEmpty else { return }

        if let existingMode = editingMode {
            var updated = existingMode
            updated.name = handleModeViewModel.name
            updated.temperature = handleModeViewModel.temperature
            updated.sound = handleModeViewModel.sound
            updated.luminosity = handleModeViewModel.luminosity

            // ✅ on sauvegarde les ampoules choisies
            updated.lightAccessoryIds = Array(handleModeViewModel.selectedLightAccessoryIds)

            modeVM.updateModes(updated)
        } else {
            let newMode = Mode(
                name: handleModeViewModel.name,
                temperature: handleModeViewModel.temperature,
                sound: handleModeViewModel.sound,
                luminosity: handleModeViewModel.luminosity,
                lightAccessoryIds: Array(handleModeViewModel.selectedLightAccessoryIds)
            )
            modeVM.addModes(newMode)
        }

        dismiss()
    }
}




