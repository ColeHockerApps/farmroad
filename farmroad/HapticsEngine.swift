import Combine
import Foundation
import CoreHaptics
import UIKit

final class HapticsEngine: ObservableObject {
    static let shared = HapticsEngine()

    private var engine: CHHapticEngine?
    private var isPrepared = false

    private init() {}

    func prepare() {
        guard !isPrepared else { return }
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            isPrepared = true
            return
        }

        do {
            engine = try CHHapticEngine()
            engine?.stoppedHandler = { _ in }
            engine?.resetHandler = { [weak self] in
                self?.isPrepared = false
                self?.prepare()
            }
            try engine?.start()
            isPrepared = true
        } catch {
            isPrepared = true
        }
    }

    func tapSoft() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.7)
    }

    func tapLight() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.8)
    }

    func tapRigid() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.9)
    }

    func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    func tick() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    func popCelebration() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            success()
            return
        }
        prepare()

        let events: [CHHapticEvent] = [
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                ],
                relativeTime: 0.0
            ),
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
                ],
                relativeTime: 0.07
            ),
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                ],
                relativeTime: 0.14
            )
        ]

        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            success()
        }
    }

    func pulseAttention() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            warning()
            return
        }
        prepare()

        let intensityCurve = CHHapticParameterCurve(
            parameterID: .hapticIntensityControl,
            controlPoints: [
                .init(relativeTime: 0.0, value: 0.2),
                .init(relativeTime: 0.08, value: 0.8),
                .init(relativeTime: 0.18, value: 0.15)
            ],
            relativeTime: 0.0
        )

        let sharpnessCurve = CHHapticParameterCurve(
            parameterID: .hapticSharpnessControl,
            controlPoints: [
                .init(relativeTime: 0.0, value: 0.2),
                .init(relativeTime: 0.08, value: 0.6),
                .init(relativeTime: 0.18, value: 0.2)
            ],
            relativeTime: 0.0
        )

        let base = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.2),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
            ],
            relativeTime: 0.0,
            duration: 0.2
        )

        do {
            let pattern = try CHHapticPattern(events: [base], parameterCurves: [intensityCurve, sharpnessCurve])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            warning()
        }
    }
}
