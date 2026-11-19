import SwiftUI

/// Liquid colours for a phase: warm while focusing, cool on a break.
struct LiquidPalette: Sendable {
    let surface: Color
    let depth: Color

    static func forPhase(_ phase: SessionPhase) -> LiquidPalette {
        if phase.isBreak {
            return LiquidPalette(
                surface: Color(red: 0.40, green: 0.93, blue: 0.86),
                depth: Color(red: 0.10, green: 0.42, blue: 0.95)
            )
        }
        return LiquidPalette(
            surface: Color(red: 1.00, green: 0.76, blue: 0.32),
            depth: Color(red: 0.95, green: 0.34, blue: 0.16)
        )
    }
}
