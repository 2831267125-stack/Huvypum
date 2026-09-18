import Foundation
import UIKit

enum HvpCoverArt {
    static func resolved(_ named: String) -> UIImage {
        UIImage(named: named) ?? image(named: named)
    }

    static func image(named: String) -> UIImage {
        let size = CGSize(width: 900, height: 1200)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let c1 = UIColor(red: 0.18, green: 0.14, blue: 0.42, alpha: 1).cgColor
            let c2 = UIColor(red: 0.10, green: 0.55, blue: 0.50, alpha: 1).cgColor
            let space = CGColorSpaceCreateDeviceRGB()
            if let gradient = CGGradient(colorsSpace: space, colors: [c1, c2] as CFArray, locations: [0, 1]) {
                ctx.cgContext.drawLinearGradient(
                    gradient,
                    start: .zero,
                    end: CGPoint(x: size.width, y: size.height),
                    options: []
                )
            }
        }
    }
}
