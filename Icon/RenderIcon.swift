#!/usr/bin/env swift
//
// RenderIcon.swift — deterministic, code-drawn app icon for Dumpling Breath.
//
// Run from the repo root:   swift Icon/RenderIcon.swift
//
// No randomness, no external assets, no network. Pure Core Graphics. Every run
// produces byte-for-byte identical PNGs. See Icon/README.md for the why and for
// how to swap in commissioned final art later.
//
// The mark: ONE warm, over-stuffed dumpling, caught mid-squeeze — two soft
// thumb-tips press its lower cheeks inward (a gentle pinch + displaced
// highlights), on a warm neutral ground. No hands, no fingers, no face by
// default. Same procedural-but-warm character as the in-app dumpling
// (Sources/Views/DumplingShape.swift, Sources/Views/DumplingView.swift).
//
// Outputs:
//   App/Assets.xcassets/AppIcon.appiconset/icon-1024.png         (ship default, faceless)
//   Icon/icon-1024-dots.png                                     (A/B: subliminal closed-eye arcs; not wired)
//   App/Assets.xcassets/AppIcon.appiconset/icon-1024-dark.png    (iOS 18 dark appearance)
//   App/Assets.xcassets/AppIcon.appiconset/icon-1024-tinted.png  (iOS 18 tinted: flat grayscale silhouette)
//   Watch/Assets.xcassets/AppIcon.appiconset/icon-1024.png       (watchOS-tuned: bigger, simpler ground)
//   docs/icon-preview.png                                        (contact sheet for the 40 pt / grayscale tests)
//

import Foundation
import CoreGraphics
import ImageIO
import CoreText
import UniformTypeIdentifiers

// MARK: - Colour helpers

let sRGB = CGColorSpace(name: CGColorSpace.sRGB)!
let deviceGray = CGColorSpaceCreateDeviceGray()

/// 0–255 sRGB → CGColor.
func c(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) -> CGColor {
    CGColor(colorSpace: sRGB, components: [CGFloat(r / 255), CGFloat(g / 255), CGFloat(b / 255), CGFloat(a)])!
}
/// Same colour, new alpha (defaults to fully transparent for gradient tails).
func fade(_ x: CGColor, _ a: Double = 0) -> CGColor {
    let k = x.components!
    return CGColor(colorSpace: sRGB, components: [k[0], k[1], k[2], CGFloat(a)])!
}

// MARK: - Context / gradient helpers  (native y-up: larger y == toward the TOP of the icon)

func makeContext(_ n: Int) -> CGContext {
    let ctx = CGContext(data: nil, width: n, height: n, bitsPerComponent: 8, bytesPerRow: 0,
                        space: sRGB, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    ctx.interpolationQuality = .high
    ctx.setAllowsAntialiasing(true)
    ctx.setShouldAntialias(true)
    return ctx
}

func radial(_ ctx: CGContext, _ center: CGPoint, _ rIn: CGFloat, _ rOut: CGFloat, _ inner: CGColor, _ outer: CGColor) {
    let g = CGGradient(colorsSpace: sRGB, colors: [inner, outer] as CFArray, locations: [0, 1])!
    ctx.drawRadialGradient(g, startCenter: center, startRadius: rIn, endCenter: center, endRadius: rOut,
                           options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
}

func linear(_ ctx: CGContext, _ p0: CGPoint, _ p1: CGPoint, _ stops: [(CGFloat, CGColor)]) {
    let g = CGGradient(colorsSpace: sRGB, colors: stops.map { $0.1 } as CFArray,
                       locations: stops.map { $0.0 })!
    ctx.drawLinearGradient(g, start: p0, end: p1, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
}

func angDiff(_ x: Double, _ y: Double) -> Double {
    var d = x - y
    while d > .pi { d -= 2 * .pi }
    while d < -.pi { d += 2 * .pi }
    return d
}

// MARK: - The dumpling silhouette

/// A plump super-ellipse with two *local* soft dimples pressed into the lower
/// cheeks — the squeeze read that must survive to 40 pt. The dents are localised
/// in angle (they don't cinch the whole waist) and each has a small displaced
/// bulge just above it, as if the filling pushed up.
///
/// - dentDepth:  ~0.10 fraction of the radius removed at the dimple centre
/// - dentAngle:  how far *below* the horizon each cheek dimple sits (radians)
func bodyPath(cx: Double, cy: Double, a: Double, b: Double, n: Double,
              dentDepth: Double, dentAngle: Double, dentSigma: Double = 0.34,
              steps: Int = 1440) -> CGPath {
    let p = CGMutablePath()
    let rightC = -dentAngle
    let leftC = .pi + dentAngle
    // displaced flesh: the cheek muffin-tops just above each dimple
    let bulges = [rightC + 0.42, leftC - 0.42]
    for i in 0...steps {
        let t = Double(i) / Double(steps) * 2 * .pi
        let ct = cos(t), st = sin(t)
        let ex = copysign(pow(abs(ct), 2 / n), ct)
        let ey = copysign(pow(abs(st), 2 / n), st)

        let dR = angDiff(t, rightC), dL = angDiff(t, leftC)
        let dent = dentDepth * (exp(-dR * dR / (2 * dentSigma * dentSigma))
                              + exp(-dL * dL / (2 * dentSigma * dentSigma)))
        var bulge = 0.0
        if dentDepth > 0.001 {
            for L in bulges {
                let d = angDiff(t, L)
                bulge += 0.34 * dentDepth * exp(-d * d / (2 * 0.24 * 0.24))
            }
        }
        let k = (1 - dent) * (1 + bulge)
        let x = cx + a * ex * k
        let y = cy + b * ey * k
        if i == 0 { p.move(to: CGPoint(x: x, y: y)) } else { p.addLine(to: CGPoint(x: x, y: y)) }
    }
    p.closeSubpath()
    return p
}

// MARK: - Palette

struct Palette {
    var groundCenter: CGColor
    var groundMid: CGColor
    var groundEdge: CGColor
    var glow: CGColor
    var bodyTop: CGColor
    var bodyBottom: CGColor
    var occlusion: CGColor
    var highlight: CGColor
    var pleat: CGColor
    var shadow: CGColor
    var thumbTop: CGColor
    var thumbBottom: CGColor
    var thumbShadow: CGColor
    var arc: CGColor
}

let standardPalette = Palette(
    groundCenter: c(150, 126, 100), groundMid: c(137, 114, 89), groundEdge: c(115, 95, 73),
    glow: c(226, 205, 170, 0.16),
    bodyTop: c(252, 245, 232), bodyBottom: c(238, 220, 194),
    occlusion: c(212, 187, 148, 0.55),
    highlight: c(255, 253, 247),
    pleat: c(199, 172, 131, 0.36),
    shadow: c(44, 34, 26, 0.34),
    thumbTop: c(231, 201, 167), thumbBottom: c(202, 167, 127),
    thumbShadow: c(56, 41, 30, 0.34),
    arc: c(122, 98, 72, 0.55))

let darkPalette = Palette(
    groundCenter: c(43, 35, 29), groundMid: c(32, 26, 21), groundEdge: c(18, 14, 11),
    glow: c(98, 74, 49, 0.22),
    bodyTop: c(236, 221, 193), bodyBottom: c(201, 176, 141),
    occlusion: c(148, 122, 90, 0.48),
    highlight: c(255, 250, 238),
    pleat: c(150, 123, 90, 0.42),
    shadow: c(0, 0, 0, 0.46),
    thumbTop: c(205, 177, 145), thumbBottom: c(174, 144, 111),
    thumbShadow: c(0, 0, 0, 0.36),
    arc: c(150, 124, 95, 0.5))

var watchPalette: Palette = {
    var p = standardPalette
    p.groundCenter = c(145, 121, 95)
    p.groundMid = c(139, 116, 91)
    p.groundEdge = c(127, 105, 82)
    p.glow = c(226, 205, 170, 0.10)
    return p
}()

// MARK: - Pieces

func thumbTipPath(center: CGPoint, rX: Double, rY: Double, angle: Double) -> CGPath {
    var t = CGAffineTransform(translationX: center.x, y: center.y).rotated(by: angle)
    return CGPath(ellipseIn: CGRect(x: -rX, y: -rY, width: 2 * rX, height: 2 * rY), transform: &t)
}

/// One soft thumb pressed against a cheek — a rounded, matte, tapered form
/// angled up-and-inward toward the dimple, its far end running off frame. It is
/// drawn UNDER the cheek overhang (the caller repaints the lower body over it),
/// so only the part below the cheek shows: a thumb, pressing, no hand, no nail.
/// `side` is -1 (left) / +1 (right); `tip` is the cheek dimple on the surface.
func drawThumb(_ ctx: CGContext, side: Double, tip: CGPoint, a: Double, W: Double, pal: Palette) {
    // A small rounded fingertip, mostly buried behind the cheek (repainted over
    // later) so only a soft pressing nub shows right at the pinch.
    let rX = W * 0.058, rY = W * 0.076
    let center = CGPoint(x: tip.x + side * rX * 0.12, y: tip.y - W * 0.002)
    let shape = thumbTipPath(center: center, rX: rX, rY: rY, angle: side * 0.20)

    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: -side * W * 0.006, height: -W * 0.005),
                  blur: W * 0.016, color: pal.thumbShadow)
    ctx.addPath(shape); ctx.setFillColor(pal.thumbBottom); ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(shape); ctx.clip()
    linear(ctx, CGPoint(x: center.x, y: center.y + rY), CGPoint(x: center.x, y: center.y - rY),
           [(0, pal.thumbTop), (1, pal.thumbBottom)])
    radial(ctx, CGPoint(x: center.x + side * rX * 0.2, y: center.y + rY * 0.4), 0, rX * 1.3,
           fade(pal.highlight, 0.28), fade(pal.highlight, 0))
    ctx.restoreGState()
}

enum FaceStyle { case none, arcs }

func renderIcon(size n: Int, palette pal: Palette, face: FaceStyle,
                bodyFraction: Double, simpleGround: Bool) -> CGImage {
    let ctx = makeContext(n)
    let W = Double(n)
    let cx = W * 0.5
    let cy = W * 0.487
    let a = W * bodyFraction / 2
    let b = a / 1.06
    let expo = 2.2
    let dentDepth = 0.135
    let dentAngle = 0.02                    // dimples sit right at the widest point
    let dentSigma = 0.185
    let path = bodyPath(cx: cx, cy: cy, a: a, b: b, n: expo,
                        dentDepth: dentDepth, dentAngle: dentAngle, dentSigma: dentSigma)
    let dentR = CGPoint(x: cx + a * (1 - dentDepth), y: cy - b * sin(dentAngle))
    let dentL = CGPoint(x: cx - a * (1 - dentDepth), y: cy - b * sin(dentAngle))

    // The dumpling's full interior shading. Painted once before the thumbs and
    // again over them, so each cheek visibly muffin-tops the thumb it hides.
    func paintBody() {
        ctx.saveGState()
        ctx.addPath(path); ctx.clip()

        linear(ctx, CGPoint(x: cx, y: cy + b), CGPoint(x: cx, y: cy - b),
               [(0, pal.bodyTop), (0.58, c(246, 235, 216)), (1, pal.bodyBottom)])
        linear(ctx, CGPoint(x: cx, y: cy - b * 0.28), CGPoint(x: cx, y: cy - b * 1.02),
               [(0, fade(pal.occlusion, 0)), (1, pal.occlusion)])
        radial(ctx, CGPoint(x: cx - a * 0.30, y: cy + b * 0.42), 0, a * 1.18,
               fade(pal.highlight, 0.34), fade(pal.highlight, 0))

        // a lit lip on the flesh that squishes out above & below each pinch
        for (s, dp) in [(-1.0, dentL), (1.0, dentR)] {
            radial(ctx, CGPoint(x: dp.x - s * a * 0.02, y: dp.y + b * 0.24), 0, a * 0.14,
                   fade(pal.highlight, 0.48), fade(pal.highlight, 0))
            radial(ctx, CGPoint(x: dp.x - s * a * 0.02, y: dp.y - b * 0.24), 0, a * 0.12,
                   fade(pal.highlight, 0.26), fade(pal.highlight, 0))
        }

        // crimp — a small gathered pleat-fan at the crown; melts away by 40 pt
        let crimpTip = CGPoint(x: cx, y: cy + b * 0.78)
        let crimpN = 6
        for i in 0..<crimpN {
            let f = (Double(i) - Double(crimpN - 1) / 2) / (Double(crimpN - 1) / 2)
            let baseX = cx + f * a * 0.26
            let baseY = cy + b * (0.99 - 0.05 * f * f)
            ctx.setLineCap(.round)
            ctx.setStrokeColor(pal.pleat); ctx.setLineWidth(a * 0.024)
            var p = CGMutablePath()
            p.move(to: crimpTip)
            p.addQuadCurve(to: CGPoint(x: baseX, y: baseY),
                           control: CGPoint(x: cx + f * a * 0.09, y: (crimpTip.y + baseY) / 2))
            ctx.addPath(p); ctx.strokePath()
            ctx.setStrokeColor(fade(pal.highlight, 0.26)); ctx.setLineWidth(a * 0.012)
            p = CGMutablePath()
            p.move(to: CGPoint(x: crimpTip.x - a * 0.012, y: crimpTip.y))
            p.addQuadCurve(to: CGPoint(x: baseX - a * 0.02, y: baseY),
                           control: CGPoint(x: cx + f * a * 0.09 - a * 0.02, y: (crimpTip.y + baseY) / 2))
            ctx.addPath(p); ctx.strokePath()
        }
        radial(ctx, CGPoint(x: cx, y: cy + b * 0.80), a * 0.02, a * 0.30,
               fade(pal.occlusion, 0.16), fade(pal.occlusion, 0))

        if face == .arcs {
            ctx.setStrokeColor(pal.arc); ctx.setLineWidth(a * 0.034); ctx.setLineCap(.round)
            for s in [-1.0, 1.0] {
                let mid = cx + s * a * 0.26
                let ey = cy + b * 0.14
                let p = CGMutablePath()
                p.move(to: CGPoint(x: mid - a * 0.10, y: ey))
                p.addQuadCurve(to: CGPoint(x: mid + a * 0.10, y: ey),
                               control: CGPoint(x: mid, y: ey - a * 0.09))
                ctx.addPath(p); ctx.strokePath()
            }
        }
        ctx.restoreGState()
    }

    // 1. Warm neutral ground — a soft low-saturation radial, never a loud gradient.
    ctx.setFillColor(pal.groundMid)
    ctx.fill(CGRect(x: 0, y: 0, width: W, height: W))
    let gStops = simpleGround ? [pal.groundCenter, pal.groundEdge] : [pal.groundCenter, pal.groundMid, pal.groundEdge]
    let gLocs: [CGFloat] = simpleGround ? [0, 1] : [0, 0.6, 1]
    let gg = CGGradient(colorsSpace: sRGB, colors: gStops as CFArray, locations: gLocs)!
    ctx.drawRadialGradient(gg, startCenter: CGPoint(x: cx, y: cy + W * 0.03), startRadius: 0,
                           endCenter: CGPoint(x: cx, y: cy + W * 0.03), endRadius: W * 0.72,
                           options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])

    // 2. Faint ambient glow behind the dumpling — decoration only, survives grayscale as a soft lift.
    radial(ctx, CGPoint(x: cx, y: cy + W * 0.01), W * 0.05, W * 0.42, pal.glow, fade(pal.glow, 0))

    // 3. Contact shadow, then the matte body.
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -W * 0.020), blur: W * 0.052, color: pal.shadow)
    ctx.addPath(path); ctx.setFillColor(pal.bodyBottom); ctx.fillPath()
    ctx.restoreGState()

    // 4. Body, thumbs, then the body again over the thumbs → the pinch overhang.
    paintBody()
    drawThumb(ctx, side: -1, tip: dentL, a: a, W: W, pal: pal)
    drawThumb(ctx, side: 1, tip: dentR, a: a, W: W, pal: pal)
    paintBody()

    // 5. A soft, wide shadow behind each thumb-pad so it sits into the cheek (body only).
    ctx.saveGState()
    ctx.addPath(path); ctx.clip()
    for (s, dp) in [(-1.0, dentL), (1.0, dentR)] {
        radial(ctx, CGPoint(x: dp.x - s * a * 0.06, y: dp.y), 0, a * 0.20,
               fade(pal.thumbShadow, 0.10), fade(pal.thumbShadow, 0))
    }
    ctx.restoreGState()

    return ctx.makeImage()!
}

/// iOS 18 tinted appearance: one flat grayscale silhouette of the dumpling form,
/// pinched cheeks kept (that IS the form now), no thumbs, no interior modelling.
func renderTinted(size n: Int) -> CGImage {
    let ctx = makeContext(n)
    let W = Double(n)
    ctx.setFillColor(c(26, 24, 22))
    ctx.fill(CGRect(x: 0, y: 0, width: W, height: W))
    radial(ctx, CGPoint(x: W * 0.5, y: W * 0.52), 0, W * 0.72, c(34, 31, 28), c(19, 17, 15))

    let cx = W * 0.5, cy = W * 0.505
    let a = W * 0.62 / 2
    let b = a / 1.06
    let path = bodyPath(cx: cx, cy: cy, a: a, b: b, n: 2.2,
                        dentDepth: 0.135, dentAngle: 0.02, dentSigma: 0.19)
    ctx.addPath(path)
    ctx.setFillColor(c(208, 208, 208))
    ctx.fillPath()
    return ctx.makeImage()!
}

// MARK: - Output

func writePNG(_ img: CGImage, _ path: String) {
    let url = URL(fileURLWithPath: path)
    try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                             withIntermediateDirectories: true)
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        fatalError("cannot create \(path)")
    }
    CGImageDestinationAddImage(dest, img, [kCGImageDestinationOptimizeColorForSharing: false] as CFDictionary)
    guard CGImageDestinationFinalize(dest) else { fatalError("cannot write \(path)") }
    print("  wrote \(url.lastPathComponent)  (\(img.width)x\(img.height))")
}

func downscale(_ img: CGImage, _ m: Int, grayscale: Bool) -> CGImage {
    let space = grayscale ? deviceGray : sRGB
    let info = grayscale ? CGImageAlphaInfo.none.rawValue : CGImageAlphaInfo.noneSkipLast.rawValue
    let ctx = CGContext(data: nil, width: m, height: m, bitsPerComponent: 8, bytesPerRow: 0,
                        space: space, bitmapInfo: info)!
    ctx.interpolationQuality = .high
    ctx.draw(img, in: CGRect(x: 0, y: 0, width: m, height: m))
    return ctx.makeImage()!
}

func label(_ ctx: CGContext, _ s: String, _ x: Double, _ y: Double, _ size: Double, _ col: CGColor, center: Bool = false) {
    let font = CTFontCreateWithName("HelveticaNeue-Medium" as CFString, CGFloat(size), nil)
    let attr = CFAttributedStringCreate(nil, s as CFString,
                                        [kCTFontAttributeName: font,
                                         kCTForegroundColorAttributeName: col] as CFDictionary)!
    let line = CTLineCreateWithAttributedString(attr)
    var xx = x
    if center {
        let w = CTLineGetTypographicBounds(line, nil, nil, nil)
        xx = x - Double(w) / 2
    }
    ctx.textPosition = CGPoint(x: xx, y: y)
    CTLineDraw(line, ctx)
}

/// Contact sheet: the icon at 1024/180/120/87/60/40/29 px plus a 40 px grayscale,
/// each downsample shown enlarged so a human can judge the two hardest tests.
func buildContactSheet(master: CGImage) -> CGImage {
    let tiles: [(String, Int, Bool)] = [
        ("1024", 1024, false), ("180", 180, false), ("120", 120, false), ("87", 87, false),
        ("60", 60, false), ("40", 40, false), ("29", 29, false), ("40 · GRAYSCALE", 40, true),
    ]
    let box = 176, cols = 4, rows = 2
    let padX = 26, padTop = 64, labelH = 34, gapY = 34
    let cellW = box + padX
    let sheetW = cols * cellW + padX
    let sheetH = padTop + rows * (box + labelH) + (rows - 1) * gapY + padX
    let n = max(sheetW, sheetH)
    let ctx = makeContext(n)
    ctx.setFillColor(c(58, 58, 60))
    ctx.fill(CGRect(x: 0, y: 0, width: Double(n), height: Double(n)))
    let H = Double(n)
    func top(_ yFromTop: Double) -> Double { H - yFromTop }

    label(ctx, "Dumpling Breath — app icon, acceptance tests", Double(padX), top(40), 23, c(236, 232, 226))

    for (idx, tile) in tiles.enumerated() {
        let col = idx % cols, row = idx / cols
        let x0 = Double(padX + col * cellW)
        let yTopPx = Double(padTop + row * (box + labelH + gapY))
        let boxTop = top(yTopPx)
        let boxRect = CGRect(x: x0, y: boxTop - Double(box), width: Double(box), height: Double(box))

        ctx.setFillColor(c(44, 44, 46))
        ctx.fill(boxRect)
        let img = downscale(master, tile.1, grayscale: tile.2)
        ctx.saveGState()
        ctx.interpolationQuality = tile.1 >= 120 ? .high : .none
        ctx.draw(img, in: boxRect)
        ctx.restoreGState()
        ctx.setStrokeColor(c(90, 90, 92)); ctx.setLineWidth(1); ctx.stroke(boxRect)

        let txt = tile.2 ? tile.0 : "\(tile.0) px"
        label(ctx, txt, x0 + Double(box) / 2, boxTop - Double(box) - 24, 17, c(210, 208, 204), center: true)
    }
    return ctx.makeImage()!
}

// MARK: - Luminance self-check (grayscale ≥ 3:1 acceptance bar)

func meanLuminance(_ img: CGImage, _ px: CGRect) -> Double {
    guard let crop = img.cropping(to: px) else { return .nan }
    let ctx = CGContext(data: nil, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 1,
                        space: deviceGray, bitmapInfo: CGImageAlphaInfo.none.rawValue)!
    ctx.interpolationQuality = .high
    ctx.draw(crop, in: CGRect(x: 0, y: 0, width: 1, height: 1))
    let v = Double(ctx.data!.load(as: UInt8.self)) / 255.0
    return v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
}
func contrastRatio(_ a: Double, _ b: Double) -> Double {
    let hi = max(a, b), lo = min(a, b)
    return (hi + 0.05) / (lo + 0.05)
}

// MARK: - main

let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
func out(_ rel: String) -> String { root.appendingPathComponent(rel).path }

let iosDir = "App/Assets.xcassets/AppIcon.appiconset"
let watchDir = "Watch/Assets.xcassets/AppIcon.appiconset"

print("Rendering Dumpling Breath icon set…")

let iosDefault = renderIcon(size: 1024, palette: standardPalette, face: .none,
                            bodyFraction: 0.58, simpleGround: false)
writePNG(iosDefault, out("\(iosDir)/icon-1024.png"))
// A/B variant — kept OUT of the appiconset (an unreferenced file there would
// trip an "unassigned child" warning). Drop it in over icon-1024.png to test.
writePNG(renderIcon(size: 1024, palette: standardPalette, face: .arcs,
                    bodyFraction: 0.58, simpleGround: false), out("Icon/icon-1024-dots.png"))
writePNG(renderIcon(size: 1024, palette: darkPalette, face: .none,
                    bodyFraction: 0.58, simpleGround: false), out("\(iosDir)/icon-1024-dark.png"))
writePNG(renderTinted(size: 1024), out("\(iosDir)/icon-1024-tinted.png"))
writePNG(renderIcon(size: 1024, palette: watchPalette, face: .none,
                    bodyFraction: 0.72, simpleGround: true), out("\(watchDir)/icon-1024.png"))
writePNG(buildContactSheet(master: iosDefault), out("docs/icon-preview.png"))

let bodyL = meanLuminance(iosDefault, CGRect(x: 452, y: 452, width: 120, height: 120))
let groundCornerL = meanLuminance(iosDefault, CGRect(x: 36, y: 36, width: 130, height: 130))
let groundTopL = meanLuminance(iosDefault, CGRect(x: 447, y: 70, width: 130, height: 90))
print("""

Grayscale self-check (shipped default, linear luminance):
  dumpling body    L = \(String(format: "%.3f", bodyL))
  ground (corner)  L = \(String(format: "%.3f", groundCornerL))   contrast = \(String(format: "%.2f", contrastRatio(bodyL, groundCornerL))) : 1
  ground (above)   L = \(String(format: "%.3f", groundTopL))   contrast = \(String(format: "%.2f", contrastRatio(bodyL, groundTopL))) : 1
  acceptance bar   = 3.00 : 1
""")
print("Done.")
