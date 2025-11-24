import SwiftUI
import HomeKit

struct HandleModeView : View {
    @StateObject var handleModeViewModel: HandleModeViewModel
    @EnvironmentObject var homeKitManager: HomeKitManager
    
    @State private var showCameraDeniedAlert = false
    
    init(temp: Int, sound: Int, luminosity: Int) {
        _handleModeViewModel = StateObject(
            wrappedValue: HandleModeViewModel(
                temp: temp,
                sound: sound,
                luminosity: luminosity
            )
        )
    }
    
    
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
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
                        temperature: $handleModeViewModel.temp,
                        changeTemperatureInHomekit: handleModeViewModel.callTempHomekit
                    )
                }
                .padding(.leading, 20)
                .padding(.top,20)
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
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color.black)
        }
    }
}
