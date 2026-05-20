import Foundation

enum OpenRecorderCaptureExclusion {
    static func shouldExcludeApplication(
        bundleIdentifier: String?,
        applicationName: String?,
        processID: pid_t?,
        currentProcessID: pid_t? = ProcessInfo.processInfo.processIdentifier,
        currentBundleIdentifier: String? = Bundle.main.bundleIdentifier
    ) -> Bool {
        if let processID,
           let currentProcessID,
           processID == currentProcessID {
            return true
        }

        let normalizedBundleIdentifier = cleaned(bundleIdentifier)?.lowercased()
        let normalizedCurrentBundleIdentifier = cleaned(currentBundleIdentifier)?.lowercased()
        if let normalizedBundleIdentifier,
           let normalizedCurrentBundleIdentifier,
           normalizedBundleIdentifier == normalizedCurrentBundleIdentifier {
            return true
        }

        if let normalizedBundleIdentifier,
           normalizedBundleIdentifier.hasPrefix("dev.openrecorder.app") {
            return true
        }

        if normalizedCurrentBundleIdentifier?.hasPrefix("dev.openrecorder.app") == true,
           let applicationName = cleaned(applicationName)?.lowercased(),
           openRecorderApplicationNames.contains(applicationName) {
            return true
        }

        return false
    }

    private static let openRecorderApplicationNames: Set<String> = [
        "open recorder",
        "open recorder dev",
        "openrecordermac"
    ]

    private static func cleaned(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed?.isEmpty == false ? trimmed : nil
    }
}
