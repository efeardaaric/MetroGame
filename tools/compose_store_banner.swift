// Composes the App Store "Header" / "Search Results" creative assets on top of
// map art rendered by tools/store_media.tscn (--mode=banner).
//
//   swift tools/compose_store_banner.swift <map.png> <out.png|.jpg> <W> <H> <safeX> <safeY> <safeW> <safeH> <tr|en>
//
// Header (3840x1646):  safe area 1097,493 1646x661
// Search (1920x1280):  safe area 418,382 1084x515
// Output has no alpha channel (App Store requirement).
import AppKit
import CoreText

let a = CommandLine.arguments
let mapPath = a[1], outPath = a[2]
let W = CGFloat(Double(a[3])!), H = CGFloat(Double(a[4])!)
let safe = CGRect(x: Double(a[5])!, y: Double(a[6])!, width: Double(a[7])!, height: Double(a[8])!)
let lang = a[9]

let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let fontURL = root.appendingPathComponent("assets/fonts/BricolageGrotesque.ttf")
CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)

func font(_ size: CGFloat, weight: Double = 800) -> CTFont {
    let base = (CTFontManagerCreateFontDescriptorsFromURL(fontURL as CFURL) as! [CTFontDescriptor])[0]
    let wght = 0x77676874 // 'wght'
    let desc = CTFontDescriptorCreateCopyWithAttributes(base, [kCTFontVariationAttribute: [wght: weight]] as CFDictionary)
    return CTFontCreateWithFontDescriptor(desc, size, nil)
}

func rgb(_ r: Int, _ g: Int, _ b: Int, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: alpha)
}
let NAVY = rgb(20, 35, 61), DEEP = rgb(10, 16, 30), WHITE = rgb(250, 246, 236), YELLOW = rgb(245, 186, 38)
let LINES = [rgb(230, 57, 70), rgb(33, 111, 219), rgb(22, 170, 140), rgb(245, 186, 38)]

let cs = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: Int(W), height: Int(H), bitsPerComponent: 8, bytesPerRow: 0, space: cs,
                    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
// work in top-left coordinates
ctx.translateBy(x: 0, y: H)
ctx.scaleBy(x: 1, y: -1)

// --- background map (cover) -------------------------------------------------
let mapSrc = CGImageSourceCreateWithURL(URL(fileURLWithPath: mapPath) as CFURL, nil)!
let map = CGImageSourceCreateImageAtIndex(mapSrc, 0, nil)!
let cover = max(W / CGFloat(map.width), H / CGFloat(map.height))
let mw = CGFloat(map.width) * cover, mh = CGFloat(map.height) * cover
ctx.saveGState()
ctx.translateBy(x: (W - mw) / 2, y: (H + mh) / 2)
ctx.scaleBy(x: 1, y: -1)   // CGImage draws bottom-up
ctx.draw(map, in: CGRect(x: 0, y: 0, width: mw, height: mh))
ctx.restoreGState()

// soften the map behind the title, deepen the edges (radial vignette)
let center = CGPoint(x: safe.midX, y: safe.midY)
let vignette = CGGradient(colorsSpace: cs, colors: [rgb(10, 16, 30, 0.10), rgb(10, 16, 30, 0.35), rgb(10, 16, 30, 0.82)] as CFArray,
                          locations: [0, 0.55, 1])!
ctx.saveGState()
ctx.scaleBy(x: 1, y: H / W * 1.6)   // elliptical
ctx.drawRadialGradient(vignette, startCenter: CGPoint(x: center.x, y: center.y / (H / W * 1.6)), startRadius: 0,
                       endCenter: CGPoint(x: center.x, y: center.y / (H / W * 1.6)), endRadius: W * 0.62, options: [.drawsAfterEndLocation])
ctx.restoreGState()

// --- text helpers --------------------------------------------------------------
func line(_ s: String, _ f: CTFont, _ c: CGColor, kern: CGFloat = 0) -> CTLine {
    let attr = NSAttributedString(string: s, attributes: [
        NSAttributedString.Key(kCTFontAttributeName as String): f,
        NSAttributedString.Key(kCTForegroundColorAttributeName as String): c,
        NSAttributedString.Key(kCTKernAttributeName as String): kern,
    ])
    return CTLineCreateWithAttributedString(attr)
}
func width(_ l: CTLine) -> CGFloat { CGFloat(CTLineGetTypographicBounds(l, nil, nil, nil)) }
func capHeight(_ f: CTFont) -> CGFloat { CTFontGetCapHeight(f) }
// draws with the cap-height box's top-left at (x, top)
func draw(_ l: CTLine, x: CGFloat, top: CGFloat, f: CTFont, shadow: Bool = true) {
    ctx.saveGState()
    let fs = CTFontGetSize(f)
    if shadow { ctx.setShadow(offset: CGSize(width: 0, height: fs * 0.05), blur: fs * 0.12, color: rgb(0, 0, 0, 0.45)) }
    ctx.textMatrix = CGAffineTransform(scaleX: 1, y: -1)
    ctx.textPosition = CGPoint(x: x, y: top + capHeight(f))
    CTLineDraw(l, ctx)
    ctx.restoreGState()
}

// --- layout inside the safe area ----------------------------------------------
let h = safe.height
var size = h * 0.25
var title1 = line("METRO TYCOON", font(size), WHITE, kern: size * 0.01)
let maxTitleW = safe.width * 0.84
if width(title1) > maxTitleW { size *= maxTitleW / width(title1); title1 = line("METRO TYCOON", font(size), WHITE, kern: size * 0.01) }
let f1 = font(size)
let f2 = font(size * 1.08, weight: 800)
let title2 = line("TÜRKİYE", f2, YELLOW, kern: size * 0.06)
let tag = lang == "tr" ? "Şehrini raylarla ör" : "Weave your city with rails"
let f3 = font(h * 0.10, weight: 700)
let tagLine = line(tag, f3, WHITE, kern: h * 0.002)

let gap = size * 0.34
let padX = size * 0.55, padY = size * 0.42
let panelW = max(width(title1), width(title2)) + padX * 2
let panelH = capHeight(f1) + gap + capHeight(f2) + padY * 2
let stripGap = h * 0.075, stripH = h * 0.032, dotR = h * 0.036
let tagGap = h * 0.07
let pillPadX = h * 0.06, pillPadY = h * 0.035
let total = panelH + stripGap + dotR * 2 + tagGap + capHeight(f3) + pillPadY * 2
let panel = CGRect(x: safe.midX - panelW / 2, y: safe.midY - total / 2, width: panelW, height: panelH)

// soft dark halo behind the whole lock-up so map detail doesn't fight with it
let halo = CGGradient(colorsSpace: cs, colors: [rgb(10, 16, 30, 0.62), rgb(10, 16, 30, 0.0)] as CFArray, locations: [0, 1])!
ctx.saveGState()
let hx = panelW * 0.95, hy = total * 0.95
ctx.translateBy(x: safe.midX, y: safe.midY)
ctx.scaleBy(x: 1, y: hy / hx)
ctx.drawRadialGradient(halo, startCenter: .zero, startRadius: 0, endCenter: .zero, endRadius: hx, options: [])
ctx.restoreGState()

// panel with soft shadow + thin coloured top rule
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: h * 0.03), blur: h * 0.09, color: rgb(0, 0, 0, 0.55))
ctx.addPath(CGPath(roundedRect: panel, cornerWidth: size * 0.32, cornerHeight: size * 0.32, transform: nil))
ctx.setFillColor(rgb(20, 35, 61, 0.94))
ctx.fillPath()
ctx.restoreGState()
ctx.saveGState()
ctx.addPath(CGPath(roundedRect: panel, cornerWidth: size * 0.32, cornerHeight: size * 0.32, transform: nil))
ctx.clip()
let seg = panel.width / CGFloat(LINES.count)
for (i, c) in LINES.enumerated() {
    ctx.setFillColor(c)
    ctx.fill(CGRect(x: panel.minX + seg * CGFloat(i), y: panel.minY, width: seg + 1, height: size * 0.09))
}
ctx.restoreGState()
ctx.setStrokeColor(rgb(255, 255, 255, 0.10)); ctx.setLineWidth(max(2, size * 0.02))
ctx.addPath(CGPath(roundedRect: panel.insetBy(dx: size * 0.01, dy: size * 0.01), cornerWidth: size * 0.3, cornerHeight: size * 0.3, transform: nil))
ctx.strokePath()

let t1Top = panel.minY + padY + size * 0.04
draw(title1, x: safe.midX - width(title1) / 2, top: t1Top, f: f1)
draw(title2, x: safe.midX - width(title2) / 2, top: t1Top + capHeight(f1) + gap, f: f2)

// metro strip with stations, like the map legend
let stripW = panelW * 0.78
let sy = panel.maxY + stripGap + dotR
let sx0 = safe.midX - stripW / 2
let segW = stripW / CGFloat(LINES.count)
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: h * 0.008), blur: h * 0.03, color: rgb(0, 0, 0, 0.5))
for (i, c) in LINES.enumerated() {
    ctx.setFillColor(c)
    let r = CGRect(x: sx0 + segW * CGFloat(i), y: sy - stripH / 2, width: segW, height: stripH)
    ctx.addPath(CGPath(roundedRect: r, cornerWidth: stripH / 2, cornerHeight: stripH / 2, transform: nil)); ctx.fillPath()
}
for i in 1..<LINES.count {
    let p = CGPoint(x: sx0 + segW * CGFloat(i), y: sy)
    ctx.setFillColor(NAVY); ctx.fillEllipse(in: CGRect(x: p.x - dotR, y: p.y - dotR, width: dotR * 2, height: dotR * 2))
    let ir = dotR * 0.62
    ctx.setFillColor(WHITE); ctx.fillEllipse(in: CGRect(x: p.x - ir, y: p.y - ir, width: ir * 2, height: ir * 2))
}
ctx.restoreGState()

let pill = CGRect(x: safe.midX - width(tagLine) / 2 - pillPadX, y: sy + dotR + tagGap,
                  width: width(tagLine) + pillPadX * 2, height: capHeight(f3) + pillPadY * 2)
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: h * 0.012), blur: h * 0.04, color: rgb(0, 0, 0, 0.5))
ctx.addPath(CGPath(roundedRect: pill, cornerWidth: pill.height / 2, cornerHeight: pill.height / 2, transform: nil))
ctx.setFillColor(rgb(20, 35, 61, 0.92)); ctx.fillPath()
ctx.restoreGState()
draw(tagLine, x: safe.midX - width(tagLine) / 2, top: pill.minY + pillPadY, f: f3, shadow: false)

// --- write -------------------------------------------------------------------------
let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
let jpg = outPath.lowercased().hasSuffix(".jpg")
try! rep.representation(using: jpg ? .jpeg : .png, properties: jpg ? [.compressionFactor: 0.92] : [:])!
    .write(to: URL(fileURLWithPath: outPath))
print("ok", Int(W), "x", Int(H), outPath)
