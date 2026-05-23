import AppKit
import SwiftUI

struct BackgroundPickerView: View {
    @Binding var selection: BackgroundStyle
    var includeTransparent: Bool

    @State private var activeKind: BackgroundStylePresetKind

    private let tileCornerRadius: CGFloat = 7
    private let tileHeight: CGFloat = 32
    private let tileSpacing: CGFloat = 6

    init(selection: Binding<BackgroundStyle>, includeTransparent: Bool = true) {
        self._selection = selection
        self.includeTransparent = includeTransparent
        self._activeKind = State(initialValue: selection.wrappedValue.presetKind)
    }

    private var availableKinds: [BackgroundStylePresetKind] {
        if includeTransparent {
            BackgroundStylePresetKind.allCases
        } else {
            BackgroundStylePresetKind.allCases.filter { $0 != .transparent }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(Theme.borderStrong.opacity(0.55))
                .frame(height: 1)

            HStack(spacing: 8) {
                Text("Background")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.fg.opacity(0.94))
                Spacer(minLength: 0)
            }
            .padding(.top, 18)
            .padding(.bottom, 17)

            VStack(alignment: .leading, spacing: 9) {
                HStack(spacing: 5) {
                    ForEach(availableKinds) { kind in
                        StudioButton(hitTarget: .rounded(7), help: kind.title) {
                            activate(kind)
                        } label: {
                            Image(systemName: kind.symbolName)
                                .font(.system(size: 11, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 26)
                                .background(activeKind == kind ? Theme.accent.opacity(0.92) : Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                                .foregroundStyle(activeKind == kind ? Theme.accentFg : Theme.fgMuted)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .stroke(activeKind == kind ? Theme.accent.opacity(0.70) : Theme.borderSubtle, lineWidth: 1)
                                }
                        }
                    }
                }

                switch activeKind {
                case .gradient: gradientGrid
                case .color: colorGrid
                case .wallpaper: wallpaperGrid
                case .transparent: transparentNote
                }
            }
            .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onChange(of: selection) { _, newValue in
            let incoming = newValue.presetKind
            if activeKind != incoming {
                activeKind = incoming
            }
        }
    }

    private func activate(_ kind: BackgroundStylePresetKind) {
        activeKind = kind
        switch kind {
        case .gradient:
            if case .gradient = selection { return }
            selection = .gradient(BackgroundPresets.gradients[0])
        case .color:
            if case .solid = selection { return }
            selection = .solid(BackgroundPresets.solidColors[0])
        case .wallpaper:
            if case .wallpaper = selection { return }
            if let first = BackgroundPresets.wallpapers.first {
                selection = .wallpaper(first)
            }
        case .transparent:
            selection = .transparent
        }
    }

    private var selectedGradientID: String? {
        if case let .gradient(preset) = selection { return preset.id }
        return nil
    }

    private var selectedColor: SerializableColor? {
        if case let .solid(color) = selection { return color }
        return nil
    }

    private var selectedWallpaperID: String? {
        if case let .wallpaper(preset) = selection { return preset.id }
        return nil
    }

    private var gradientGrid: some View {
        LazyVGrid(columns: fourColumnGridItems, spacing: tileSpacing) {
            ForEach(BackgroundPresets.gradients) { preset in
                StudioButton(hitTarget: .rounded(7)) {
                    selection = .gradient(preset)
                } label: {
                    GradientSwatch(preset: preset)
                        .frame(maxWidth: .infinity)
                        .frame(height: tileHeight)
                        .overlay {
                            RoundedRectangle(cornerRadius: tileCornerRadius)
                                .stroke(selectedGradientID == preset.id ? Theme.accent : Theme.border, lineWidth: selectedGradientID == preset.id ? 2 : 1)
                        }
                }
                .help(preset.id.replacingOccurrences(of: "-", with: " ").capitalized)
            }
        }
    }

    private var colorGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 6), spacing: 6) {
            ForEach(BackgroundPresets.solidColors.indices, id: \.self) { index in
                let swatch = BackgroundPresets.solidColors[index]
                StudioButton(hitTarget: .circle) {
                    selection = .solid(swatch)
                } label: {
                    Circle()
                        .fill(swatch.color)
                        .frame(width: 28, height: 28)
                        .overlay {
                            Circle()
                                .stroke(selectedColor == swatch ? Theme.accent : Theme.borderStrong, lineWidth: selectedColor == swatch ? 2 : 1)
                        }
                }
            }
        }
    }

    private var wallpaperGrid: some View {
        LazyVGrid(columns: fourColumnGridItems, spacing: tileSpacing) {
            ForEach(BackgroundPresets.wallpapers) { preset in
                StudioButton(hitTarget: .rounded(7)) {
                    selection = .wallpaper(preset)
                } label: {
                    WallpaperThumbnail(preset: preset)
                        .frame(maxWidth: .infinity)
                        .frame(height: tileHeight)
                        .clipShape(RoundedRectangle(cornerRadius: tileCornerRadius))
                        .overlay {
                            RoundedRectangle(cornerRadius: tileCornerRadius)
                                .stroke(selectedWallpaperID == preset.id ? Theme.accent : Theme.border, lineWidth: selectedWallpaperID == preset.id ? 2 : 1)
                        }
                }
                .help(preset.label)
            }
        }
    }

    private var fourColumnGridItems: [GridItem] {
        Array(repeating: GridItem(.flexible(minimum: 44), spacing: tileSpacing), count: 4)
    }

    private var transparentNote: some View {
        HStack(spacing: 8) {
            Checkerboard()
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            Text("Transparent background. Exports keep the alpha channel.")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct GradientSwatch: View {
    let preset: GradientPreset

    var body: some View {
        switch preset.kind {
        case .linear:
            let endpoints = preset.unitEndpoints()
            return AnyView(
                RoundedRectangle(cornerRadius: 7).fill(
                    LinearGradient(
                        gradient: Gradient(stops: preset.swiftUIStops),
                        startPoint: endpoints.start,
                        endPoint: endpoints.end
                    )
                )
            )
        case let .radial(cx, cy):
            return AnyView(
                GeometryReader { proxy in
                    let endRadius = max(proxy.size.width, proxy.size.height)
                    RoundedRectangle(cornerRadius: 7).fill(
                        RadialGradient(
                            gradient: Gradient(stops: preset.swiftUIStops),
                            center: UnitPoint(x: cx, y: cy),
                            startRadius: 0,
                            endRadius: endRadius
                        )
                    )
                }
            )
        }
    }
}

struct WallpaperThumbnail: View {
    let preset: WallpaperPreset

    var body: some View {
        GeometryReader { proxy in
            thumbnailContent
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
        }
        .clipShape(RoundedRectangle(cornerRadius: 7))
    }

    @ViewBuilder
    private var thumbnailContent: some View {
        if let url = preset.thumbURL, let image = WallpaperImageCache.image(for: url) {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
        } else {
            RoundedRectangle(cornerRadius: 7)
                .fill(Theme.surfaceRaised)
                .overlay {
                    Image(systemName: "photo")
                        .foregroundStyle(Color.secondary)
                }
        }
    }
}

struct BackgroundFillView: View {
    let style: BackgroundStyle

    var body: some View {
        switch style {
        case .transparent:
            Checkerboard()
        case let .solid(color):
            color.color
        case let .gradient(preset):
            GeometryReader { proxy in
                gradientView(for: preset, in: proxy.size)
            }
        case let .wallpaper(preset):
            WallpaperFill(preset: preset)
        }
    }

    @ViewBuilder
    private func gradientView(for preset: GradientPreset, in size: CGSize) -> some View {
        switch preset.kind {
        case .linear:
            let endpoints = preset.unitEndpoints()
            LinearGradient(
                gradient: Gradient(stops: preset.swiftUIStops),
                startPoint: endpoints.start,
                endPoint: endpoints.end
            )
        case let .radial(cx, cy):
            let endRadius = hypot(size.width, size.height)
            RadialGradient(
                gradient: Gradient(stops: preset.swiftUIStops),
                center: UnitPoint(x: cx, y: cy),
                startRadius: 0,
                endRadius: endRadius
            )
        }
    }
}

struct WallpaperFill: View {
    let preset: WallpaperPreset

    var body: some View {
        Group {
            if let url = preset.fullURL, let image = WallpaperImageCache.image(for: url) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Theme.surfaceRaised
            }
        }
        .clipped()
    }
}
