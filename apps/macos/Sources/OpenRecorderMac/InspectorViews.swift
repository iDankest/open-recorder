import AVFoundation
import AppKit
import CoreGraphics
import SwiftUI
import UniformTypeIdentifiers

struct SettingsInspector: View {
    @Binding var borderRadius: Double
    @Binding var padding: Double
    @Binding var shadow: Double
    @Binding var backgroundBlur: Double
    @Binding var background: BackgroundStyle
    @Binding var inset: Double
    @Binding var insetColor: SerializableColor
    @Binding var insetOpacity: Double
    @Binding var insetBalance: VideoInsetBalance
    @Binding var showCursor: Bool
    @Binding var loopCursor: Bool
    @Binding var cursorSize: Double
    @Binding var cursorSmoothing: Double
    @Binding var cursorStyle: CursorStyle
    @Binding var cursorVariant: CursorVariant
    @Binding var facecamEnabled: Bool
    @Binding var facecamSize: Double
    @Binding var facecamBorderWidth: Double
    @Binding var facecamAnchor: String
    var recordingSession: RecordingSession?

    @State private var activeTab: InspectorTab = .appearance
    @State private var hoveredTab: InspectorTab?

    private let railWidth: CGFloat = 48
    private let railButtonSize: CGFloat = 36
    private let railButtonSpacing: CGFloat = 6
    private let railVerticalPadding: CGFloat = 12

    private var hasRecordedCamera: Bool {
        recordingSession?.hasRecordedCamera == true
    }

    var body: some View {
        HStack(spacing: 0) {
            inspectorRail
            inspectorContent
        }
        .overlay(alignment: .topLeading) {
            if let hoveredTab {
                InspectorRailTooltip(title: hoveredTab.title)
                    .frame(width: 0, alignment: .trailing)
                    .offset(x: -10, y: railItemOffset(for: hoveredTab) + 4)
                    .transition(.opacity)
                    .zIndex(5)
            }
        }
        .studioEditorPaneChrome(clipContent: false)
        .animation(.snappy(duration: 0.14), value: hoveredTab?.id)
    }

    private func openExternal(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        NSWorkspace.shared.open(url)
    }

    private var inspectorRail: some View {
        ZStack(alignment: .topLeading) {
            activeRailBackground

            VStack(spacing: railButtonSpacing) {
                ForEach(InspectorTab.allCases) { tab in
                    InspectorRailButton(
                        tab: tab,
                        isActive: activeTab == tab,
                        size: railButtonSize
                    ) {
                        withAnimation(.snappy(duration: 0.22)) {
                            activeTab = tab
                        }
                    } onHoverChanged: { isHovering in
                        hoveredTab = isHovering ? tab : (hoveredTab == tab ? nil : hoveredTab)
                    }
                }
            }
            .padding(.vertical, railVerticalPadding)
            .frame(width: railWidth)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .frame(width: railWidth)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Theme.appBgMuted.opacity(0.54))
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Theme.borderStrong.opacity(0.44))
                .frame(width: 1)
        }
    }

    private var activeRailBackground: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.accent.opacity(0.14))
                .frame(width: railButtonSize, height: railButtonSize)
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Theme.accent.opacity(0.24), lineWidth: 1)
                }
                .offset(x: (railWidth - railButtonSize) / 2, y: railItemOffset(for: activeTab))

            Capsule()
                .fill(Theme.accent)
                .frame(width: 3, height: 14)
                .offset(x: 0, y: railItemOffset(for: activeTab) + 11)
        }
        .animation(.snappy(duration: 0.22), value: activeTab.id)
    }

    private func railItemOffset(for tab: InspectorTab) -> CGFloat {
        let index = InspectorTab.allCases.firstIndex(of: tab) ?? 0
        return railVerticalPadding + CGFloat(index) * (railButtonSize + railButtonSpacing)
    }

    private var inspectorContent: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    inspectorHeader
                    tabContent
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 18)
            }
            .scrollIndicators(.visible)

            Rectangle()
                .fill(Theme.borderStrong.opacity(0.44))
                .frame(height: 1)

            inspectorFooter
        }
    }

    private var inspectorHeader: some View {
        Text(activeTab.title)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(Theme.fg.opacity(0.96))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 18)
    }

    private var inspectorFooter: some View {
        HStack(spacing: 8) {
            InspectorFooterButton(title: "Report Bug", symbolName: "ladybug") {
                openExternal("https://github.com/imbhargav5/open-recorder/issues/new/choose")
            }
            InspectorFooterButton(title: "Star on GitHub", symbolName: "star") {
                openExternal("https://github.com/imbhargav5/open-recorder")
            }
        }
        .padding(12)
        .background(Theme.appBgMuted.opacity(0.38))
    }

    @ViewBuilder
    private var tabContent: some View {
        switch activeTab {
        case .appearance:
            InspectorGroup(title: "Frame", symbolName: "rectangle.on.rectangle", showsTopDivider: false) {
                InspectorSlider(title: "Shadow", valueText: "\(Int(shadow * 100))%", value: $shadow, range: 0...1, step: 0.01, defaultValue: 0.35, leadingSymbolName: "circle", trailingSymbolName: "circle.fill")
                InspectorSlider(title: "Roundness", valueText: "\(Int(borderRadius))px", value: $borderRadius, range: 0...25, step: 0.5, defaultValue: 12, leadingSymbolName: "rectangle", trailingSymbolName: "app")
                InspectorSlider(title: "Padding", valueText: "\(Int(padding))%", value: $padding, range: 0...100, step: 1, defaultValue: 18, leadingSymbolName: "arrow.down.right.and.arrow.up.left", trailingSymbolName: "arrow.up.left.and.arrow.down.right")
            }
            InspectorGroup(title: "Backdrop", symbolName: "photo.on.rectangle.angled") {
                InspectorSlider(title: "Inset", valueText: "\(Int(inset.rounded()))", value: $inset, range: 0...100, step: 1, defaultValue: 0, leadingSymbolName: "rectangle", trailingSymbolName: "rectangle.inset.filled")
                InspectorSlider(title: "Background Blur", valueText: String(format: "%.1fpx", backgroundBlur), value: $backgroundBlur, range: 0...8, step: 0.25, defaultValue: 0, leadingSymbolName: "camera.filters", trailingSymbolName: "drop.fill")
            }
            if inset > 0 {
                InspectorGroup(title: "Inset Styling", symbolName: "square.inset.filled") {
                    InsetColorPicker(color: $insetColor)
                    InspectorSlider(title: "Inset Opacity", valueText: String(format: "%.2f", insetOpacity), value: $insetOpacity, range: 0...1, step: 0.01, defaultValue: 1, leadingSymbolName: "circle", trailingSymbolName: "circle.fill")
                    InsetBalancePicker(balance: $insetBalance)
                }
            }
            BackgroundPickerView(selection: $background)
        case .cursor:
            InspectorGroup(title: "Cursor", symbolName: "cursorarrow", showsTopDivider: false) {
                InspectorSwitch(title: "Show Cursor", isOn: $showCursor)
                CursorStylePicker(selection: $cursorStyle, variant: $cursorVariant)
                CursorVariantPicker(style: cursorStyle, selection: $cursorVariant)
            }
            InspectorGroup(title: "Motion", symbolName: "point.3.connected.trianglepath.dotted") {
                InspectorSwitch(title: "Loop Cursor", isOn: $loopCursor)
                InspectorSlider(title: "Size", valueText: String(format: "%.2fx", cursorSize), value: $cursorSize, range: 1...8, step: 0.05, defaultValue: 1, leadingSymbolName: "cursorarrow", trailingSymbolName: "cursorarrow.rays")
                InspectorSlider(title: "Smoothing", valueText: String(format: "%.2f", cursorSmoothing), value: $cursorSmoothing, range: 0...2, step: 0.01, defaultValue: 0.45, leadingSymbolName: "point.topleft.down.curvedto.point.bottomright.up", trailingSymbolName: "waveform.path.ecg")
            }
        case .camera:
            InspectorGroup(title: "Facecam", symbolName: "camera", showsTopDivider: false) {
                InspectorSwitch(title: "Facecam", isOn: $facecamEnabled, isInteractive: hasRecordedCamera)
                    .disabled(!hasRecordedCamera)
                    .opacity(hasRecordedCamera ? 1 : 0.45)
                VStack(alignment: .leading, spacing: 15) {
                    InspectorSlider(title: "Facecam Size", valueText: "\(Int(facecamSize.rounded()))%", value: $facecamSize, range: 12...40, step: 1, defaultValue: 20, leadingSymbolName: "camera", trailingSymbolName: "camera.fill")
                    InspectorSlider(title: "Border Width", valueText: "\(Int(facecamBorderWidth.rounded()))px", value: $facecamBorderWidth, range: 0...16, step: 1, defaultValue: 2, leadingSymbolName: "square", trailingSymbolName: "square.inset.filled")
                    PositionGrid(selection: $facecamAnchor)
                }
                .disabled(!hasRecordedCamera || !facecamEnabled)
                .opacity(hasRecordedCamera && facecamEnabled ? 1 : 0.45)
            }
            if let path = recordingSession?.facecamVideoPath {
                SessionAssetRow(title: "Facecam File", path: path)
            }
        case .audio:
            InspectorGroup(title: "Preview", symbolName: "speaker.wave.2", showsTopDivider: false) {
                InspectorSwitch(title: "Mute Preview", isOn: .constant(false), isInteractive: false)
                InspectorSlider(title: "Volume", valueText: "100%", value: .constant(1), range: 0...1, step: 0.01, defaultValue: 1, leadingSymbolName: "speaker.slash", trailingSymbolName: "speaker.wave.2")
            }
            if let sourceName = recordingSession?.sourceName {
                SessionAssetRow(title: "Source", path: sourceName)
            }
        }
    }
}

struct SessionAssetRow: View {
    var title: String
    var path: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(path)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .lineLimit(2)
                .textSelection(.enabled)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct InspectorRailButton: View {
    var tab: InspectorTab
    var isActive: Bool
    var size: CGFloat
    var action: () -> Void
    var onHoverChanged: (Bool) -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: tab.symbolName)
                .font(.system(size: 14, weight: .semibold))
                .frame(width: size, height: size)
                .foregroundStyle(isActive ? Theme.accent : Theme.fgSubtle)
                .background(Color.white.opacity(0.001), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .roundedHitTarget(12)
        }
        .buttonStyle(.plain)
        .onHover(perform: onHoverChanged)
    }
}

struct InspectorRailTooltip: View {
    var title: String

    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Theme.fg.opacity(0.94))
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .multilineTextAlignment(.trailing)
            .padding(.horizontal, 9)
            .frame(height: 28)
            .background(Theme.surfaceRaised.opacity(0.96), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(Theme.borderStrong.opacity(0.72), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.28), radius: 10, y: 5)
            .allowsHitTesting(false)
    }
}

struct InspectorFooterButton: View {
    var title: String
    var symbolName: String
    var action: () -> Void

    var body: some View {
        StudioButton(hitTarget: .rounded(7), action: action) {
            Label(title, systemImage: symbolName)
                .font(.system(size: 10, weight: .medium))
                .frame(maxWidth: .infinity)
                .frame(height: 30)
                .foregroundStyle(Theme.fgMuted)
                .background(Theme.overlay, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(Theme.borderSubtle, lineWidth: 1)
                }
        }
    }
}

enum InspectorTab: CaseIterable, Identifiable {
    case appearance
    case cursor
    case camera
    case audio

    var id: String { title }

    var title: String {
        switch self {
        case .appearance: "Appearance"
        case .cursor: "Cursor"
        case .camera: "Camera"
        case .audio: "Audio"
        }
    }

    var subtitle: String {
        switch self {
        case .appearance: "Appearance"
        case .cursor: "Cursor"
        case .camera: "Camera"
        case .audio: "Audio"
        }
    }

    var symbolName: String {
        switch self {
        case .appearance: "slider.horizontal.3"
        case .cursor: "cursorarrow"
        case .camera: "camera"
        case .audio: "speaker.wave.2"
        }
    }
}

struct InspectorGroup<Content: View>: View {
    var title: String
    var symbolName: String
    var showsTopDivider = true
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showsTopDivider {
                Rectangle()
                    .fill(Theme.borderStrong.opacity(0.55))
                    .frame(height: 1)
            }

            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.fg.opacity(0.94))
                Spacer(minLength: 0)
            }
            .padding(.top, 18)
            .padding(.bottom, 17)

            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .padding(.bottom, 18)
        }
    }
}

struct InspectorSlider: View {
    var title: String
    var valueText: String
    @Binding var value: Double
    var range: ClosedRange<Double>
    var step: Double
    var defaultValue: Double?
    var leadingSymbolName: String = "minus"
    var trailingSymbolName: String = "plus"
    var onEditingChanged: (Bool) -> Void = { _ in }

    @State private var draftValueText = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.fgMuted)
                    .lineLimit(1)
                Spacer(minLength: 12)

                resetControl
                    .frame(width: 44, alignment: .trailing)

                valueInput
            }
            .frame(height: 24)

            HStack(spacing: 8) {
                sliderIcon(leadingSymbolName)

                ElasticSlider(
                    value: $value,
                    range: range,
                    step: step,
                    onEditingChanged: onEditingChanged,
                    dragStep: intermediateStep,
                    trackHeight: 5,
                    hitHeight: 26,
                    fillColor: Color.primary.opacity(0.92),
                    thumbWidth: 8,
                    thumbHeight: 18,
                    thumbColor: Color.primary.opacity(0.96)
                )
                .accessibilityLabel(title)

                sliderIcon(trailingSymbolName)
            }
            .frame(height: 26)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            draftValueText = displayValueText
        }
        .onChange(of: valueText) { _, newValue in
            if !isInputFocused {
                draftValueText = displayValueText(for: newValue)
            }
        }
        .onChange(of: isInputFocused) { _, focused in
            if focused {
                draftValueText = displayValueText
            } else {
                commitDraftValue()
            }
        }
    }

    @ViewBuilder
    private var resetControl: some View {
        if let defaultValue, abs(value - defaultValue) > max(step / 2, 0.0001) {
                    StudioButton(hitTarget: .rounded(5)) {
                        withAnimation(.snappy(duration: 0.18)) {
                            value = clamped(defaultValue)
                        }
                    } label: {
                        Text("Reset")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.fgSubtle)
                    }
        } else {
            Color.clear
        }
    }

    private var valueInput: some View {
        TextField("", text: $draftValueText)
            .font(.system(size: 12, weight: .semibold, design: .monospaced))
            .foregroundStyle(Theme.fg)
            .monospacedDigit()
            .multilineTextAlignment(.trailing)
            .textFieldStyle(.plain)
            .focused($isInputFocused)
            .frame(width: inputWidth)
            .frame(height: 22)
            .padding(.horizontal, 5)
            .background(Theme.overlay, in: RoundedRectangle(cornerRadius: 5, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(isInputFocused ? Theme.accent.opacity(0.65) : Theme.borderSubtle, lineWidth: 1)
            }
            .onSubmit(commitDraftValue)
    }

    private var intermediateStep: Double {
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return step }
        return min(step, span / 200)
    }

    private var inputWidth: CGFloat {
        38
    }

    private var displayValueText: String {
        displayValueText(for: valueText)
    }

    private func displayValueText(for text: String) -> String {
        if text.hasSuffix("%") {
            let digits = text.filter(\.isNumber)
            return "\(String(digits.prefix(3)))%"
        }

        return text
    }

    private func sliderIcon(_ symbolName: String) -> some View {
        Image(systemName: symbolName)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Theme.fgSubtle)
            .frame(width: 18, height: 26)
    }

    private func commitDraftValue() {
        guard let nextValue = parsedDraftValue() else {
            draftValueText = displayValueText
            return
        }

        value = steppedValue(clamped(nextValue))
        draftValueText = displayValueText
    }

    private func parsedDraftValue() -> Double? {
        let trimmed = draftValueText.trimmingCharacters(in: .whitespacesAndNewlines)
        let numericCharacters = trimmed.filter { character in
            character.isNumber || character == "." || character == "-"
        }

        guard let rawValue = Double(numericCharacters) else { return nil }

        if valueText.contains("%"), range.upperBound <= 1 {
            return rawValue / 100
        }

        return rawValue
    }

    private func steppedValue(_ rawValue: Double) -> Double {
        let safeStep = max(step, Double.ulpOfOne)
        let stepped = (round((rawValue - range.lowerBound) / safeStep) * safeStep) + range.lowerBound
        return clamped(stepped)
    }

    private func clamped(_ rawValue: Double) -> Double {
        min(max(rawValue, range.lowerBound), range.upperBound)
    }
}

struct InsetColorPicker: View {
    @Binding var color: SerializableColor

    private var colorBinding: Binding<Color> {
        Binding(
            get: { color.color },
            set: { color = SerializableColor(NSColor($0)) }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ColorPicker("", selection: colorBinding, supportsOpacity: false)
                    .labelsHidden()
                    .frame(width: 34, height: 30)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Inset color")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text(color.hexString)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.primary.opacity(0.88))
                }

                Spacer(minLength: 0)

                Image(systemName: "paintpalette.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 28, height: 28)
                    .background(Theme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 7))
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 0), spacing: 6), count: 5), spacing: 6) {
                ForEach(BackgroundPresets.solidColors.prefix(10), id: \.self) { swatch in
                    StudioButton(hitTarget: .rounded(7)) {
                        color = swatch
                    } label: {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(swatch.color)
                            .frame(height: 30)
                            .overlay {
                                RoundedRectangle(cornerRadius: 7)
                                    .stroke(color == swatch ? Theme.accent : Theme.borderStrong, lineWidth: color == swatch ? 2 : 1)
                            }
                    }
                    .help(swatch.hexString)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 3)
    }
}

struct InsetBalancePicker: View {
    @Binding var balance: VideoInsetBalance

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Inset Balance")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("left: \(percent(balance.clamped.left)), top: \(percent(balance.clamped.top))")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.secondary.opacity(0.78))
            }

            GeometryReader { proxy in
                let resolvedBalance = balance.clamped
                let knobSize: CGFloat = 22
                let x = resolvedBalance.left * proxy.size.width
                let y = resolvedBalance.top * proxy.size.height

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Theme.overlay)

                    Path { path in
                        path.move(to: CGPoint(x: proxy.size.width / 2, y: 0))
                        path.addLine(to: CGPoint(x: proxy.size.width / 2, y: proxy.size.height))
                        path.move(to: CGPoint(x: 0, y: proxy.size.height / 2))
                        path.addLine(to: CGPoint(x: proxy.size.width, y: proxy.size.height / 2))
                    }
                    .stroke(Theme.border, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))

                    Circle()
                        .fill(Theme.surface)
                        .frame(width: knobSize, height: knobSize)
                        .overlay {
                            Circle()
                                .stroke(Theme.accent, lineWidth: 2)
                        }
                        .shadow(color: Color.black.opacity(0.24), radius: 8, y: 4)
                        .position(x: x, y: y)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Theme.border)
                }
                .rectangularHitTarget()
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            updateBalance(at: value.location, in: proxy.size)
                        }
                )
            }
            .frame(height: 116)

            StudioButton(hitTarget: .rounded(7)) {
                balance = .centered
            } label: {
                Label("Reset Balance", systemImage: "arrow.counterclockwise")
                    .font(.system(size: 11, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 30)
                    .foregroundStyle(Color.secondary.opacity(0.92))
                    .background(Theme.overlay, in: RoundedRectangle(cornerRadius: 7))
                    .overlay {
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(Theme.overlay)
                    }
            }
            .disabled(balance.clamped == .centered)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 3)
    }

    private func percent(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }

    private func updateBalance(at location: CGPoint, in size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        balance = VideoInsetBalance(
            left: max(0, min(location.x / size.width, 1)),
            top: max(0, min(location.y / size.height, 1))
        )
    }
}

struct CursorStylePicker: View {
    @Binding var selection: CursorStyle
    @Binding var variant: CursorVariant

    private let columns = Array(repeating: GridItem(.flexible(minimum: 0), spacing: 6), count: 2)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Style")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(CursorStyle.allCases) { style in
                    StudioButton(hitTarget: .rounded(7), help: style.title) {
                        selection = style
                        variant = style.resolvedVariant(variant)
                    } label: {
                        VStack(spacing: 5) {
                            CursorGlyphView(style: style, variant: style.resolvedVariant(variant), scale: 0.56)
                                .frame(width: 38, height: 34)
                            Text(style.title)
                                .font(.system(size: 10, weight: .semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .foregroundStyle(selection == style ? Color.white : Color.primary.opacity(0.86))
                        .background(selection == style ? Theme.accent.opacity(0.82) : Theme.overlay, in: RoundedRectangle(cornerRadius: 7))
                        .overlay {
                            RoundedRectangle(cornerRadius: 7)
                                .stroke(selection == style ? Theme.accent.opacity(0.95) : Theme.overlay)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 3)
    }
}

struct CursorVariantPicker: View {
    var style: CursorStyle
    @Binding var selection: CursorVariant

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Variant")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                ForEach(style.supportedVariants) { variant in
                    StudioButton(hitTarget: .rounded(7), help: variant.title) {
                        selection = variant
                    } label: {
                        VStack(spacing: 4) {
                            CursorGlyphView(style: style, variant: variant, scale: 0.42)
                                .frame(width: 28, height: 24)
                            Text(variant.title)
                                .font(.system(size: 9, weight: .semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .foregroundStyle(selection == variant ? Color.white : Color.primary.opacity(0.82))
                        .background(selection == variant ? Theme.accent.opacity(0.82) : Theme.overlay, in: RoundedRectangle(cornerRadius: 7))
                        .overlay {
                            RoundedRectangle(cornerRadius: 7)
                                .stroke(selection == variant ? Theme.accent.opacity(0.95) : Theme.border, lineWidth: selection == variant ? 2 : 1)
                        }
                        .overlay(alignment: .topTrailing) {
                            if selection == variant {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(Color.white)
                                    .padding(4)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 3)
        .onAppear(perform: normalizeSelection)
        .onChange(of: style) { _, _ in
            normalizeSelection()
        }
    }

    private func normalizeSelection() {
        selection = style.resolvedVariant(selection)
    }
}

struct InspectorSwitch: View {
    var title: String
    @Binding var isOn: Bool
    var isInteractive = true

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.fgMuted)
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .allowsHitTesting(isInteractive)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .rectangularHitTarget()
        .onTapGesture {
            guard isInteractive else { return }
            isOn.toggle()
        }
    }
}

struct PositionGrid: View {
    @Binding var selection: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Position")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 3), spacing: 5) {
                ForEach(FacecamAnchor.allCases) { anchor in
                    StudioButton(hitTarget: .rounded(5), help: anchor.title) {
                        selection = anchor.rawValue
                    } label: {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(isSelected(anchor) ? Theme.accent.opacity(0.28) : Theme.overlay)
                            .frame(height: 28)
                            .overlay {
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(isSelected(anchor) ? Theme.accent.opacity(0.5) : Theme.overlay)
                            }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 3)
    }

    private func isSelected(_ anchor: FacecamAnchor) -> Bool {
        FacecamAnchor.resolve(selection) == anchor
    }
}
