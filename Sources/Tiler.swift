import Foundation

package enum Layout {
    case tile
    case monocle
}

package enum Tiler {
    package static func calculateFrames(count: Int, screen: CGRect, layout: Layout) -> [CGRect] {
        guard count > 0 else { return [] }
        switch layout {
        case .tile: return tileFrames(count: count, screen: screen)
        case .monocle: return monocleFrames(count: count, screen: screen)
        }
    }

    static func tile(windows: [TrackedWindow], screen: CGRect, layout: Layout) {
        let frames = calculateFrames(count: windows.count, screen: screen, layout: layout)
        for (i, frame) in frames.enumerated() {
            windows[i].setFrame(frame)
        }
    }

    private static func tileFrames(count: Int, screen: CGRect) -> [CGRect] {
        let outer = Config.shared.outerGap
        let inner = Config.shared.innerGap

        let inset = CGRect(
            x: screen.origin.x + outer,
            y: screen.origin.y + outer,
            width: screen.width - 2 * outer,
            height: screen.height - 2 * outer
        )

        if count == 1 {
            return [inset]
        }

        var result: [CGRect] = []
        result.reserveCapacity(count)
        let masterWidth = floor(inset.width * Config.shared.masterRatio) - inner / 2
        result.append(CGRect(
            x: inset.origin.x, y: inset.origin.y,
            width: masterWidth, height: inset.height
        ))

        let stackCount = count - 1
        let stackX = inset.origin.x + masterWidth + inner
        let stackWidth = inset.width - masterWidth - inner
        let totalStackHeight = inset.height - CGFloat(stackCount - 1) * inner
        let stackHeight = floor(totalStackHeight / CGFloat(stackCount))

        for i in 1..<count {
            let y = inset.origin.y + CGFloat(i - 1) * (stackHeight + inner)
            let h = (i == count - 1)
                ? inset.height - CGFloat(i - 1) * (stackHeight + inner)
                : stackHeight
            result.append(CGRect(
                x: stackX, y: y,
                width: stackWidth, height: h
            ))
        }
        return result
    }

    private static func monocleFrames(count: Int, screen: CGRect) -> [CGRect] {
        Array(repeating: screen, count: count)
    }
}
