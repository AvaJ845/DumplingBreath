import SwiftUI

/// A plump, pleated dumpling silhouette. Pure geometry, no images.
///
/// This is now just the *outline*: `DumplingView` renders it at a fixed neutral
/// `openness` and the Metal `dumplingSquish` distortion shader does the living
/// motion — inflate/deflate, the thumb dimple, the idle wobble. The `openness`
/// parameter is still honoured (Reduce Motion draws a static form and animates
/// scale/opacity around it) and keeps the shape usable on its own, e.g. as a
/// mask or in the Watch target.
struct DumplingShape: Shape {
    /// 0 = deflated and wide, 1 = round and full.
    var openness: Double

    var animatableData: Double {
        get { openness }
        set { openness = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let o = min(max(openness, 0), 1)
        let squash = 0.74 + 0.26 * o          // squat when empty, round when full
        let bulge = 1.0 + 0.035 * o
        let bodyW = rect.width * bulge
        let bodyH = rect.height * squash * bulge
        let body = CGRect(
            x: rect.midX - bodyW / 2,
            y: rect.midY - bodyH / 2,
            width: bodyW,
            height: bodyH)

        var path = Path()
        path.addRoundedRect(
            in: body,
            cornerSize: CGSize(width: bodyW / 2, height: bodyH / 2))

        // Top crimp: pleats deepen as the dumpling fills.
        let pleatCount = 5
        let pleatDepth = rect.height * 0.09 * o
        if pleatDepth > 0.5 {
            let step = body.width / CGFloat(pleatCount)
            for i in 0..<pleatCount {
                let x = body.minX + step * (CGFloat(i) + 0.5)
                var pleat = Path()
                pleat.move(to: CGPoint(x: x, y: body.minY))
                pleat.addQuadCurve(
                    to: CGPoint(x: x + step * 0.5, y: body.minY + pleatDepth),
                    control: CGPoint(x: x + 3, y: body.minY + pleatDepth * 0.55))
                path.addPath(pleat)
            }
        }
        return path
    }
}

#Preview {
    VStack(spacing: 40) {
        ForEach([0.0, 0.5, 1.0], id: \.self) { o in
            DumplingShape(openness: o)
                .fill(.orange.gradient)
                .frame(width: 160, height: 160)
        }
    }
    .padding()
}
