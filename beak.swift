// beak: AlTavares/SwiftyShell @ 0.1.0

import Basic
import Foundation
import SwiftyShell

public func test(_ platform: String = "iOS", _ os: String = "11.4", simulator: String = "iPhone 8") {
    let cmd = "set -o pipefail && xcodebuild -scheme Nappa_\(platform) -destination 'OS=\(os),name=\(simulator)' UseNewBuildSystem=YES -configuration Debug ONLY_ACTIVE_ARCH=NO ENABLE_TESTABILITY=YES test | xcpretty -c"
    Shell.run(cmd)
}
