import SwiftUI

extension View {
    @ViewBuilder func nativeSearchPresentation() -> some View {
        if #available(macOS 14.1, *) { self.searchPresentationToolbarBehavior(.avoidHidingContent) }
        else { self }
    }
    @ViewBuilder func nativeGlass() -> some View {
        if #available(macOS 26, *) { self.glassEffect(.regular, in: .rect(cornerRadius: 12)) }
        else { self.background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12)) }
    }
    @ViewBuilder func nativeBackgroundExtension() -> some View {
        if #available(macOS 26, *) { self.backgroundExtensionEffect() }
        else { self }
    }
    @ViewBuilder func nativeButton(prominent: Bool) -> some View {
        if #available(macOS 26, *) {
            if prominent { self.buttonStyle(.glassProminent) } else { self.buttonStyle(.glass) }
        } else {
            if prominent { self.buttonStyle(.borderedProminent) } else { self.buttonStyle(.bordered) }
        }
    }
}
