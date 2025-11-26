import SwiftUI

struct ColorCircleButton: View {
    var colorEnum: LightColor
    @Binding var selectedColor: LightColor?
    var changeColorFunction: ((LightColor?) -> (Void))

    var body: some View {
        Button {
            if selectedColor == colorEnum {
                selectedColor = nil
            } else {
                selectedColor = colorEnum
            }
            changeColorFunction(selectedColor)
        } label: {
            Circle()
                .fill(swiftUIColor(for: colorEnum))
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(
                            selectedColor == colorEnum ? Color.white : Color.black,
                            lineWidth: selectedColor == colorEnum ? 6 : 2
                        )
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(colorEnum.rawValue))
    }

    private func swiftUIColor(for color: LightColor) -> Color { // transform enum en vraie couleur
        switch color {
            case .yellow: return .yellow
            case .blue:   return .blue
            case .red:    return .red
        }
    }
}
