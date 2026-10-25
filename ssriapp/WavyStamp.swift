import SwiftUI

struct WavyStamp: Shape {
    var waves: Int = 12
    var depth: CGFloat = 0.055

    func path(in rect: CGRect) -> Path {
        let radius = min(rect.width, rect.height) / 2
        let amplitude = radius * depth
        let centre = CGPoint(x: rect.midX, y: rect.midY)

        return Path { path in
            for step in 0..<720 {
                let angle = CGFloat(step) / 720 * .pi * 2
                let r = radius - amplitude
                    + amplitude * cos(CGFloat(waves) * angle)

                let point = CGPoint(
                    x: centre.x + r * cos(angle),
                    y: centre.y + r * sin(angle)
                )

                if step == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }

            path.closeSubpath()
        }
    }
}
