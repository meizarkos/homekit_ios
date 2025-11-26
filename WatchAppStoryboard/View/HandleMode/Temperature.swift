import SwiftUI

struct Temperature: View {
    @ObservedObject var handleModeViewModel : HandleModeViewModel
    @Binding var temperature: Int
    var changeTemperatureInHomekit : (()->(Void))
    var buttonWidth : CGFloat = 100
    
    var body: some View {
        VStack(spacing: 20) {
            Button(action: {
                if(temperature < 30){
                    temperature += 1
                    changeTemperatureInHomekit()
                    handleModeViewModel.stopAutoMode()
                }
            }) {
                Image(systemName: "arrow.up")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 25, height: 25)
                    .foregroundColor(temperature < 30 ? .white : Color.gray.opacity(0.4))
                    .padding()
                    .frame(width: buttonWidth, height: 60)
                    .background(temperature < 30 ? Color.gray : Color.gray.opacity(0.4))
                    .cornerRadius(12)
            }
            
            Text(" \(temperature) C°")
                .font(.system(size: 36, weight: .medium, design: .rounded))
                .foregroundColor(.white)
            
            Button(action: {
                if(temperature > 10){
                    temperature -= 1
                    changeTemperatureInHomekit()
                    handleModeViewModel.stopAutoMode()
                }
            }) {
                Image(systemName: "arrow.down")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 25, height: 25)
                    .foregroundColor(temperature > 10 ? .white : Color.gray.opacity(0.4))
                    .padding()
                    .frame(width: buttonWidth, height: 60)
                    .background(temperature > 10 ? Color.gray : Color.gray.opacity(0.4))
                    .cornerRadius(12)
            }
        }
    }
}
