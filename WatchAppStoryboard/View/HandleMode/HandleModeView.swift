import SwiftUI
import HomeKit

struct HandleModeView : View {
    @StateObject var handleModeViewModel: HandleModeViewModel
    @State private var showCameraDeniedAlert = false
    @State private var showAccessorySelector = false
    @EnvironmentObject private var modeVM: ModeViewModel
    @Environment(\.dismiss) private var dismiss
    
    let editingMode: Mode?
    let homeName: String
    
    // Création d'un nouveau mode
    init(name: String, temperature: Int, sound: Int, luminosity: Int, homeName: String) {
        self.homeName = homeName
        _handleModeViewModel = StateObject(
            wrappedValue: HandleModeViewModel(
                name: name,
                temperature: temperature,
                sound: sound,
                luminosity: luminosity,
                homeName: homeName
            )
        )
        self.editingMode = nil
    }
    
    // Modification d'un mode existant
    init(mode: Mode, homeName: String) {
        self.homeName = homeName
        _handleModeViewModel = StateObject(
            wrappedValue: HandleModeViewModel(
                name: mode.name,
                temperature: mode.temperature,
                sound: mode.sound,
                luminosity: mode.luminosity,
                homeName: homeName
            )
        )
        self.editingMode = mode
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                // Sélecteur d'accessoires
                Button(action: {
                    showAccessorySelector = true
                }) {
                    HStack {
                        Image(systemName: "lightbulb.circle.fill")
                        VStack(alignment: .leading) {
                            Text("Accessoires sélectionnés")
                                .font(.headline)
                            Text("Lumière: \(handleModeViewModel.selectedLightAccessory?.name ?? "Aucune")")
                                .font(.caption)
                            Text("Son: \(handleModeViewModel.selectedSoundAccessory?.name ?? "Aucun")")
                                .font(.caption)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                
                HStack(spacing: 25) {
                    VerticalSlider(
                        handleModeViewModel : handleModeViewModel,
                        houseParameter: $handleModeViewModel.luminosity,
                        setHouseParameterInHomekit: handleModeViewModel.callLuminosityHomekit,
                        icon: "sun.max.fill"
                    )
                    VerticalSlider(
                        handleModeViewModel : handleModeViewModel,
                        houseParameter: $handleModeViewModel.sound,
                        setHouseParameterInHomekit: handleModeViewModel.callSoundHomekit,
                        icon: "speaker.fill"
                    )
                    Temperature(
                        handleModeViewModel : handleModeViewModel,
                        temperature: $handleModeViewModel.temperature,
                        changeTemperatureInHomekit: handleModeViewModel.callTempHomekit
                    )
                }
                .padding(.leading, 20)
                .frame(maxWidth: .infinity, alignment: .center)
                
                HStack(spacing : 30) {
                    ColorCircleButton(
                        colorEnum: LightColor.yellow, selectedColor: $handleModeViewModel.selectedColor,
                        changeColorFunction: handleModeViewModel.updateColor
                    )
                    ColorCircleButton(
                        colorEnum: LightColor.blue, selectedColor: $handleModeViewModel.selectedColor,
                        changeColorFunction: handleModeViewModel.updateColor
                    )
                    ColorCircleButton(
                        colorEnum: LightColor.red, selectedColor: $handleModeViewModel.selectedColor,
                        changeColorFunction: handleModeViewModel.updateColor
                    )
                }
                .padding(.leading, 20)
                .frame(maxWidth: .infinity, alignment: .center)
                
                Button(action: {
                    if(handleModeViewModel.isAutoModeOn == true){
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
                    VStack(spacing: 15) {
                        Image(systemName: "bolt.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.white)
                        Text("Auto-mode")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 15)
                    .padding(.bottom, 15)
                    .frame(maxWidth: .infinity, minHeight: 70)
                    .background(handleModeViewModel.isAutoModeOn ? Color.blue : Color.gray)
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .animation(.easeInOut(duration: 0.2), value: handleModeViewModel.isAutoModeOn)
                }
                .alert("Camera Access Denied", isPresented: $showCameraDeniedAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("Please enable camera access in Settings to use Auto-mode.")
                }
                
                VStack(spacing: 15){
                    TextField("Renseignez le nom du mode", text: $handleModeViewModel.name)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    
                    Button(action: {
                        saveMode()
                    }){
                        Text(editingMode == nil ? "Créer" : "Modifier")
                            .font(.headline)
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color.black)
            .navigationTitle(editingMode == nil ? "Nouveau Mode" : "Modifier Mode")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showAccessorySelector) {
                AccessorySelectorView(viewModel: handleModeViewModel, homeName: homeName)
            }
        }
    }
    
    private func saveMode(){
        guard !handleModeViewModel.name.isEmpty else {
            return
        }
        
        if let existingMode = editingMode {
            var updatedMode = existingMode
            updatedMode.name = handleModeViewModel.name
            updatedMode.temperature = handleModeViewModel.temperature
            updatedMode.sound = handleModeViewModel.sound
            updatedMode.luminosity = handleModeViewModel.luminosity
            
            modeVM.updateModes(updatedMode)
        } else {
            let newMode = Mode(
                name: handleModeViewModel.name,
                temperature: handleModeViewModel.temperature,
                sound: handleModeViewModel.sound,
                luminosity: handleModeViewModel.luminosity
            )
            modeVM.addModes(newMode)
        }
        
        dismiss()
    }
}

// Nouvelle vue pour sélectionner les accessoires
struct AccessorySelectorView: View {
    @ObservedObject var viewModel: HandleModeViewModel
    @Environment(\.dismiss) private var dismiss
    let homeName: String
    
    var currentHome: HMHome? {
        HomeKitManager.shared.homeManager.homes.first { $0.name == homeName }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Accessoire Lumière")) {
                    if let home = currentHome, !home.accessories.isEmpty {
                        ForEach(home.accessories, id: \.uniqueIdentifier) { accessory in
                            Button(action: {
                                viewModel.selectedLightAccessory = accessory
                                // Appliquer immédiatement la luminosité actuelle
                                viewModel.callLuminosityHomekit()
                            }) {
                                HStack {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundColor(.yellow)
                                    Text(accessory.name)
                                    Spacer()
                                    if viewModel.selectedLightAccessory?.uniqueIdentifier == accessory.uniqueIdentifier {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    } else {
                        Text("Aucun accessoire disponible")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Accessoire Son")) {
                    if let home = currentHome, !home.accessories.isEmpty {
                        ForEach(home.accessories, id: \.uniqueIdentifier) { accessory in
                            Button(action: {
                                viewModel.selectedSoundAccessory = accessory
                                // Appliquer immédiatement le volume actuel
                                viewModel.callSoundHomekit()
                            }) {
                                HStack {
                                    Image(systemName: "speaker.wave.2.fill")
                                        .foregroundColor(.blue)
                                    Text(accessory.name)
                                    Spacer()
                                    if viewModel.selectedSoundAccessory?.uniqueIdentifier == accessory.uniqueIdentifier {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    } else {
                        Text("Aucun accessoire disponible")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Sélectionner accessoires")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Terminé") {
                        dismiss()
                    }
                }
            }
        }
    }
}
