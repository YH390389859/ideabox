import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Run from the repository root. Geometry mirrors LoomSign in LoomDesign.swift.
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let design = root.appendingPathComponent("design/loom-20260906/brand")
let assets = root.appendingPathComponent("IdeaBox/Assets.xcassets")
let space = CGColorSpace(name: CGColorSpace.sRGB)!
let iconScale: CGFloat = 0.81

func color(_ hex: UInt32, alpha: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: space, components: [CGFloat((hex >> 16) & 255) / 255,
        CGFloat((hex >> 8) & 255) / 255, CGFloat(hex & 255) / 255, alpha])!
}

func mark(_ context: CGContext, width: CGFloat = 256, hex: UInt32, strokeMultiplier: CGFloat = 1) {
    context.setLineCap(.round)
    for line in 0..<4 {
        let y = width * (0.28 + CGFloat(line) * 0.145)
        context.move(to: CGPoint(x: width * 0.08, y: y))
        context.addCurve(to: CGPoint(x: width * 0.92, y: y - width * 0.10),
                         control1: CGPoint(x: width * 0.37, y: y - width * 0.22),
                         control2: CGPoint(x: width * 0.64, y: y + width * 0.16))
        context.setStrokeColor(color(hex)); context.setLineWidth(max(1, width * 0.035) * strokeMultiplier)
        context.strokePath()

        let x = width * (0.28 + CGFloat(line) * 0.145)
        context.move(to: CGPoint(x: x, y: width * 0.08))
        context.addCurve(to: CGPoint(x: x - width * 0.10, y: width * 0.92),
                         control1: CGPoint(x: x - width * 0.22, y: width * 0.37),
                         control2: CGPoint(x: x + width * 0.16, y: width * 0.64))
        context.setStrokeColor(color(hex, alpha: 0.65)); context.setLineWidth(max(1, width * 0.025) * strokeMultiplier)
        context.strokePath()
    }
}

func bitmap(width: Int, height: Int, opaque: Bool, draw: (CGContext) -> Void) -> CGImage {
    let alpha: CGImageAlphaInfo = opaque ? .noneSkipLast : .premultipliedLast
    let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
        bytesPerRow: width * 4, space: space, bitmapInfo: alpha.rawValue)!
    context.translateBy(x: 0, y: CGFloat(height)); context.scaleBy(x: 1, y: -1)
    context.setShouldAntialias(true)
    draw(context)
    return context.makeImage()!
}

func write(_ image: CGImage, to url: URL) throws {
    let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else { throw NSError(domain: "PNG export", code: 1) }
}

func drawIcon(_ context: CGContext, size: CGFloat) {
    context.setFillColor(color(0xD9EB77)); context.fill(CGRect(x: 0, y: 0, width: size, height: size))
    context.saveGState(); context.scaleBy(x: size / 256, y: size / 256)
    context.translateBy(x: 128, y: 128); context.scaleBy(x: iconScale, y: iconScale)
    context.translateBy(x: -128, y: -128)
    mark(context, hex: 0x202A2B, strokeMultiplier: 1.3)
    context.restoreGState()
}

func icon(size: Int) -> CGImage {
    bitmap(width: size, height: size, opaque: true) { drawIcon($0, size: CGFloat(size)) }
}

func markSVG(hex: String, strokeMultiplier: Double = 1) -> String {
    var paths: [String] = []
    for line in 0..<4 {
        let y = 256 * (0.28 + Double(line) * 0.145)
        let x = y
        paths.append("<path d=\"M 20.48 \(y) C 94.72 \(y - 56.32) 163.84 \(y + 40.96) 235.52 \(y - 25.6)\" stroke-width=\"\(8.96 * strokeMultiplier)\"/>")
        paths.append("<path d=\"M \(x) 20.48 C \(x - 56.32) 94.72 \(x + 40.96) 163.84 \(x - 25.6) 235.52\" stroke-width=\"\(6.4 * strokeMultiplier)\" stroke-opacity=\"0.65\"/>")
    }
    return "<g fill=\"none\" stroke=\"\(hex)\" stroke-linecap=\"round\">\(paths.joined())</g>"
}

let iconSVG = "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"1024\" height=\"1024\" viewBox=\"0 0 256 256\"><rect width=\"256\" height=\"256\" fill=\"#D9EB77\"/><g transform=\"translate(128 128) scale(0.81) translate(-128 -128)\">\(markSVG(hex: "#202A2B", strokeMultiplier: 1.3))</g></svg>\n"
let launchSVG = "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"256\" height=\"256\" viewBox=\"0 0 256 256\">\(markSVG(hex: "#3555E8"))</svg>\n"
try iconSVG.write(to: design.appendingPathComponent("icon.svg"), atomically: true, encoding: .utf8)
try launchSVG.write(to: design.appendingPathComponent("loom-launch.svg"), atomically: true, encoding: .utf8)

let iconDirectory = assets.appendingPathComponent("AppIcon.appiconset")
let entries = try JSONSerialization.jsonObject(with: Data(contentsOf: iconDirectory.appendingPathComponent("Contents.json"))) as! [String: Any]
for entry in entries["images"] as! [[String: String]] {
    let logical = Double(entry["size"]!.split(separator: "x")[0])!
    let scale = Double(entry["scale"]!.dropLast())!
    let size = Int(logical * scale)
    try write(icon(size: size), to: iconDirectory.appendingPathComponent(entry["filename"]!))
    print("AppIcon: \(entry["filename"]!) \(size)×\(size) RGB")
}
try write(icon(size: 1024), to: design.appendingPathComponent("icon.png"))

let launchDirectory = assets.appendingPathComponent("LoomLaunch.imageset")
try FileManager.default.createDirectory(at: launchDirectory, withIntermediateDirectories: true)
for scale in 1...3 {
    let size = scale * 256
    let image = bitmap(width: size, height: size, opaque: false) { context in
        context.scaleBy(x: CGFloat(scale), y: CGFloat(scale)); mark(context, hex: 0x3555E8)
    }
    try write(image, to: launchDirectory.appendingPathComponent("LoomLaunch@\(scale)x.png"))
}
try """
{"images":[{"filename":"LoomLaunch@1x.png","idiom":"universal","scale":"1x"},{"filename":"LoomLaunch@2x.png","idiom":"universal","scale":"2x"},{"filename":"LoomLaunch@3x.png","idiom":"universal","scale":"3x"}],"info":{"author":"xcode","version":1}}
""".write(to: launchDirectory.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)

func text(_ value: String, x: CGFloat, y: CGFloat, size: CGFloat, weight: NSFont.Weight = .regular, hex: UInt32, in context: CGContext) {
    let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: size, weight: weight), .foregroundColor: NSColor(cgColor: color(hex))!]
    let line = CTLineCreateWithAttributedString(NSAttributedString(string: value, attributes: attrs))
    context.saveGState(); context.translateBy(x: x, y: y); context.scaleBy(x: 1, y: -1)
    context.textPosition = .zero; CTLineDraw(line, context); context.restoreGState()
}

func previewIcon(_ context: CGContext, x: CGFloat, y: CGFloat, size: CGFloat) {
    context.saveGState()
    context.addPath(CGPath(roundedRect: CGRect(x: x, y: y, width: size, height: size), cornerWidth: size * 0.225, cornerHeight: size * 0.225, transform: nil)); context.clip()
    context.translateBy(x: x, y: y); drawIcon(context, size: size); context.restoreGState()
}

let preview = bitmap(width: 1400, height: 900, opaque: true) { context in
    context.setFillColor(color(0xF3F0E8)); context.fill(CGRect(x: 0, y: 0, width: 1400, height: 900))
    text("IDEABOX  /  DAILY LOOM", x: 80, y: 82, size: 16, weight: .medium, hex: 0x7C827C, in: context)
    previewIcon(context, x: 80, y: 178, size: 450)
    text("日常织机", x: 634, y: 260, size: 60, weight: .medium, hex: 0x202A2B, in: context)
    text("把每一天，织进生活里。", x: 636, y: 325, size: 25, hex: 0x7C827C, in: context)
    text("四横四纵 · 交错生长", x: 636, y: 409, size: 22, hex: 0x202A2B, in: context)
    for (index, value) in [UInt32(0xD9EB77), 0x202A2B, 0x3555E8, 0xF3F0E8].enumerated() {
        let x = CGFloat(636 + index * 144)
        context.setFillColor(color(value)); context.fillEllipse(in: CGRect(x: x, y: 466, width: 50, height: 50))
        if value == 0xF3F0E8 { context.setStrokeColor(color(0xD8D8CB)); context.setLineWidth(1); context.strokeEllipse(in: CGRect(x: x, y: 466, width: 50, height: 50)) }
        text(String(format: "#%06X", value), x: x - 6, y: 548, size: 15, weight: .medium, hex: 0x7C827C, in: context)
    }
    context.setFillColor(color(0xD8D8CB)); context.fill(CGRect(x: 80, y: 697, width: 1240, height: 1))
    text("FROM APP ICON TO OPENING MOTION", x: 80, y: 764, size: 15, weight: .medium, hex: 0x7C827C, in: context)
    text("图标识别 / 小尺寸 / 启动标记", x: 80, y: 806, size: 21, hex: 0x202A2B, in: context)
    previewIcon(context, x: 760, y: 730, size: 96)
    previewIcon(context, x: 902, y: 750, size: 64)
    previewIcon(context, x: 1012, y: 766, size: 40)
    context.saveGState(); context.translateBy(x: 1165, y: 731); context.scaleBy(x: 96 / 256, y: 96 / 256)
    mark(context, hex: 0x3555E8); context.restoreGState()
}
try write(preview, to: design.appendingPathComponent("preview.png"))
print("Exported launch assets, editable SVGs, and small-size preview.")
