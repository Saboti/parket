import CoreGraphics
@testable import ParketCore

enum TilerTests {
    static let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)

    static func runAll() -> (passed: Int, failed: Int) {
        var passed = 0
        var failed = 0

        func check(_ condition: Bool, _ message: String, file: String = #file, line: Int = #line) {
            if condition {
                passed += 1
            } else {
                fputs("FAIL \(file):\(line): \(message)\n", stderr)
                failed += 1
            }
        }

        do {
            let frames = Tiler.calculateFrames(count: 0, screen: screen, layout: .tile)
            check(frames.isEmpty, "empty returns empty")
        }

        do {
            let frames = Tiler.calculateFrames(count: 1, screen: screen, layout: .tile)
            check(frames.count == 1, "single window count")
            check(frames[0] == screen, "single window covers screen")
        }

        do {
            let frames = Tiler.calculateFrames(count: 2, screen: screen, layout: .tile)
            let masterWidth = floor(1920 * Config.shared.masterRatio)
            check(frames.count == 2, "two windows count")
            check(frames[0].width == masterWidth, "master width")
            check(frames[1].width == 1920 - masterWidth, "stack width")
            check(frames[0].height == 1080, "master height")
            check(frames[1].height == 1080, "stack height")
        }

        do {
            let frames = Tiler.calculateFrames(count: 3, screen: screen, layout: .tile)
            let stackHeight = floor(1080.0 / 2.0)
            check(frames.count == 3, "three windows count")
            check(frames[1].height == stackHeight, "first stack height")
            check(frames[2].height == 1080 - stackHeight, "last stack height")
        }

        for count in 4...8 {
            let frames = Tiler.calculateFrames(count: count, screen: screen, layout: .tile)
            let stack = frames.dropFirst().sorted { $0.origin.y < $1.origin.y }
            for i in 1..<stack.count {
                let prevBottom = stack[i - 1].origin.y + stack[i - 1].height
                let gap = abs(stack[i].origin.y - prevBottom)
                check(gap < 0.001, "contiguous y at count=\(count) i=\(i)")
            }
        }

        for count in 1...8 {
            let frames = Tiler.calculateFrames(count: count, screen: screen, layout: .tile)
            let totalArea = frames.reduce(0.0) { $0 + $1.width * $1.height }
            let screenArea = screen.width * screen.height
            check(abs(totalArea - screenArea) < 1.0, "area coverage at count=\(count)")
        }

        do {
            let offset = CGRect(x: 100, y: 50, width: 1920, height: 1080)
            let frames = Tiler.calculateFrames(count: 2, screen: offset, layout: .tile)
            check(frames[0].origin.x == 100, "offset master x")
            check(frames[0].origin.y == 50, "offset master y")
            check(frames[1].origin.x == 100 + floor(1920 * Config.shared.masterRatio), "offset stack x")
            check(frames[1].origin.y == 50, "offset stack y")
        }

        do {
            let frames = Tiler.calculateFrames(count: 5, screen: screen, layout: .monocle)
            check(frames.count == 5, "monocle count")
            for f in frames {
                check(f == screen, "monocle frame == screen")
            }
        }

        do {
            let hidden = WindowManager.hiddenWindowPosition(for: screen, desktopMaxX: screen.maxX)
            check(hidden.x == screen.maxX - 1, "hidden window keeps 1px visible on right edge")
            check(hidden.y == screen.maxY - 1, "hidden window keeps 1px visible on bottom edge")
        }

        do {
            let secondScreen = CGRect(x: 1920, y: 0, width: 2560, height: 1440)
            let hidden = WindowManager.hiddenWindowPosition(for: screen, desktopMaxX: secondScreen.maxX)
            check(hidden.x == secondScreen.maxX - 1, "hidden window uses rightmost desktop edge")
            check(hidden.y == screen.maxY - 1, "hidden window stays aligned to source screen bottom")
        }

        do {
            let toml = try Toml.parse("""
            workspace_count = 5

            [[apps]]
            bundle_id = "com.apple.Terminal"
            workspace = 2
            """)
            let config = Config.parseToml(toml)
            check(config.appRules == [AppRule(bundleID: "com.apple.Terminal", workspaceIndex: 1, floating: false)], "app rules parse bundle id and workspace")
            check(config.workspaceIndex(for: "com.apple.Terminal", default: 0) == 1, "app rule overrides active workspace")
        } catch {
            check(false, "app rule config parses")
        }

        do {
            let toml = try Toml.parse("""
            workspace_count = 3

            [[apps]]
            bundle_id = "com.apple.Terminal"
            workspace = 4
            """)
            let config = Config.parseToml(toml)
            check(config.appRules.isEmpty, "invalid app rule workspace is ignored")
            check(config.workspaceIndex(for: "com.apple.Safari", default: 2) == 2, "unknown app falls back to active workspace")
        } catch {
            check(false, "invalid app rule config parses")
        }

        do {
            let toml = try Toml.parse("""
            [[apps]]
            bundle_id = "com.apple.systempreferences"
            floating = true
            """)
            let config = Config.parseToml(toml)
            check(config.appRules == [AppRule(bundleID: "com.apple.systempreferences", workspaceIndex: nil, floating: true)], "floating app rule parses")
            check(config.isFloatingApp("com.apple.systempreferences"), "floating app lookup matches bundle id")
            check(config.workspaceIndex(for: "com.apple.systempreferences", default: 2) == 2, "floating app leaves workspace unchanged")
        } catch {
            check(false, "floating app rule config parses")
        }

        do {
            let toml = try Toml.parse("""
            [[apps]]
            bundle_id = "com.apple.systempreferences"
            workspace = 2
            floating = true
            """)
            let config = Config.parseToml(toml)
            check(config.appRules == [AppRule(bundleID: "com.apple.systempreferences", workspaceIndex: nil, floating: true)], "floating app rule ignores workspace")
            check(config.workspaceIndex(for: "com.apple.systempreferences", default: 1) == 1, "floating app conflict still leaves workspace unchanged")
        } catch {
            check(false, "floating workspace conflict config parses")
        }

        do {
            let focusedIndex = WorkspaceManager.focusedMonitorIndex(
                preferredDisplayID: 2,
                displayIDs: [1, 2]
            )
            check(focusedIndex == 1, "startup prefers primary display instead of leftmost screen")
        }

        do {
            let focusedIndex = WorkspaceManager.focusedMonitorIndex(
                preferredDisplayID: 9,
                displayIDs: [1, 2]
            )
            check(focusedIndex == 0, "missing preferred display falls back to first monitor")
        }

        return (passed, failed)
    }
}
