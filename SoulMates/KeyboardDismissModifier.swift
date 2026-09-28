// KeyboardDismissModifier.swift
import SwiftUI

extension View {
    func addKeyboardDoneButton() -> some View {
        self.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil,
                        from: nil,
                        for: nil
                    )
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .padding(2)
                        .contentShape(Rectangle())
                        .buttonBorderShape(.circle)
                }
                .padding(.bottom,3)
            }
        }
    }
}
