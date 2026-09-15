import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// The geometry below is the single source shared by the app icon and launch artwork.
// Run from the repository root with: swift design/brand-20260906/generate.swift
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let design = root.appendingPathComponent("design/brand-20260906")
let catalog = root.appendingPathComponent("IdeaBox/Assets.xcassets")
let back = "M 70 106 H 186 C 198 106 208 116 208 128 V 180 C 208 199 193 213 175 213 H 81 C 63 213 48 199 48 180 V 128 C 48 116 58 106 70 106 Z"
let inside = "M 72 119 H 184 C 190 119 196 124 196 130 V 159 H 60 V 130 C 60 124 66 119 72 119 Z"
let front = "M 48 135 C 48 128 55 125 62 129 L 100 147 C 118 155 138 155 156 147 L 194 129 C 201 125 208 128 208 135 V 180 C 208 199 193 213 175 213 H 81 C 63 213 48 199 48 180 Z"
let spark = "M 139 42 C 141 42 142 44 143 49 C 146 60 150 64 161 67 C 167 69 169 70 169 72 C 169 74 167 75 161 77 C 150 80 146 84 143 95 C 142 100 141 102 139 102 C 137 102 136 100 135 95 C 132 84 128 80 117 77 C 111 75 109 74 109 72 C 109 70 111 69 117 67 C 128 64 132 60 135 49 C 136 44 137 42 139 42 Z"

func color(_ hex: UInt32) -> CGColor {
    CGColor(colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
            components: [CGFloat((hex >> 16) & 255) / 255,
                         CGFloat((hex >> 8) & 255) / 255,
                         CGFloat(hex & 255) / 255, 1])!
}

func path(_ source: String) -> CGPath {
    let tokens = source.split(separator: " ").map(String.init)
    let result = CGMutablePath()
    var index = 0
    func number() -> CGFloat { defer { index += 1 }; return CGFloat(Double(tokens[index])!) }
    func point() -> CGPoint { CGPoint(x: number(), y: number()) }
    while index < tokens.count {
        let command = tokens[index]
        index += 1
        switch command {
        case "M": result.move(to: point())
        case "L": result.addLine(to: point())
        case "H": result.addLine(to: CGPoint(x: number(), y: result.currentPoint.y))
        case "V": result.addLine(to: CGPoint(x: result.currentPoint.x, y: number()))
        case "C":
            let p1 = point(), p2 = point(), end = point()
            result.addCurve(to: end, control1: p1, control2: p2)
        case "Z": result.closeSubpath()
        default: fatalError("Unsupported path command \(command)")
        }
    }
    return result
}

func drawMark(_ context: CGContext) {
    context.setFillColor(color(0xD7D3F4)); context.addPath(path(back)); context.fillPath()
    context.setFillColor(color(0xB8B1E9)); context.addPath(path(inside)); context.fillPath()
    context.saveGState()
    context.addPath(path(front)); context.clip()
    let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
                              colors: [color(0x9992E6), color(0x7770DD)] as CFArray,
                              locations: [0, 1])!
    context.drawLinearGradient(gradient, start: CGPoint(x: 128, y: 129),
                               end: CGPoint(x: 128, y: 213), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    context.restoreGState()
    context.setFillColor(color(0x7770DD)); context.addPath(path(spark)); context.fillPath()
    context.setFillColor(color(0xA9C3AD)); context.fillEllipse(in: CGRect(x: 78, y: 55, width: 18, height: 18))
}

func bitmap(width: Int, height: Int, opaque: Bool, draw: (CGContext) -> Void) -> CGImage {
    let alpha: CGImageAlphaInfo = opaque ? .noneSkipLast : .premultipliedLast
    let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                            bytesPerRow: width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: alpha.rawValue)!
    context.translateBy(x: 0, y: CGFloat(height)); context.scaleBy(x: 1, y: -1)
    context.setShouldAntialias(true)
    draw(context)
    return context.makeImage()!
}

func writePNG(_ image: CGImage, to url: URL) throws {
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil)
    guard CGImageDestinationFinalize(dest) else { throw NSError(domain: "PNG export", code: 1) }
}

func icon(size: Int) -> CGImage {
    bitmap(width: size, height: size, opaque: true) { context in
        context.setFillColor(color(0xF7F6F2)); context.fill(CGRect(x: 0, y: 0, width: size, height: size))
        context.scaleBy(x: CGFloat(size) / 256, y: CGFloat(size) / 256)
        context.translateBy(x: 128, y: 128); context.scaleBy(x: 1.04, y: 1.04)
        context.translateBy(x: -128, y: -128)
        drawMark(context)
    }
}

let definition = """
<defs><linearGradient id="front" x1="128" y1="129" x2="128" y2="213" gradientUnits="userSpaceOnUse"><stop stop-color="#9992E6"/><stop offset="1" stop-color="#7770DD"/></linearGradient></defs>
"""
let boxSVG = "<path fill=\"#D7D3F4\" d=\"\(back)\"/><path fill=\"#B8B1E9\" d=\"\(inside)\"/><path fill=\"url(#front)\" d=\"\(front)\"/>"
let sparkSVG = "<path fill=\"#7770DD\" d=\"\(spark)\"/>"
let seedSVG = "<circle cx=\"87\" cy=\"64\" r=\"9\" fill=\"#A9C3AD\"/>"
func svg(_ body: String, size: Int = 256) -> String {
    "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"\(size)\" height=\"\(size)\" viewBox=\"0 0 256 256\">\(definition)\(body)</svg>\n"
}

let markSVG = svg(boxSVG + sparkSVG + seedSVG)
try markSVG.write(to: design.appendingPathComponent("brand-mark.svg"), atomically: true, encoding: .utf8)
try svg("<rect width=\"256\" height=\"256\" fill=\"#F7F6F2\"/><g transform=\"translate(128 128) scale(1.04) translate(-128 -128)\">\(boxSVG)\(sparkSVG)\(seedSVG)</g>", size: 1024)
    .write(to: design.appendingPathComponent("app-icon.svg"), atomically: true, encoding: .utf8)

let boxBackSVG = "<path fill=\"#D7D3F4\" d=\"\(back)\"/><path fill=\"#B8B1E9\" d=\"\(inside)\"/>"
let boxFrontSVG = "<path fill=\"url(#front)\" d=\"\(front)\"/>"
for (name, body) in [("BrandBox", boxSVG), ("BrandBoxBack", boxBackSVG), ("BrandBoxFront", boxFrontSVG), ("BrandSpark", sparkSVG), ("BrandSeed", seedSVG)] {
    let directory = catalog.appendingPathComponent("\(name).imageset")
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try svg(body).write(to: directory.appendingPathComponent("\(name).svg"), atomically: true, encoding: .utf8)
    let contents = """
    {"images":[{"filename":"\(name).svg","idiom":"universal"}],"info":{"author":"xcode","version":1},"properties":{"preserves-vector-representation":true}}
    """
    try contents.write(to: directory.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)
}

let markDirectory = catalog.appendingPathComponent("BrandMark.imageset")
try FileManager.default.createDirectory(at: markDirectory, withIntermediateDirectories: true)
for scale in 1...3 {
    let size = scale * 256
    let image = bitmap(width: size, height: size, opaque: false) { context in
        context.scaleBy(x: CGFloat(scale), y: CGFloat(scale)); drawMark(context)
    }
    try writePNG(image, to: markDirectory.appendingPathComponent("BrandMark@\(scale)x.png"))
}
try """
{"images":[{"filename":"BrandMark@1x.png","idiom":"universal","scale":"1x"},{"filename":"BrandMark@2x.png","idiom":"universal","scale":"2x"},{"filename":"BrandMark@3x.png","idiom":"universal","scale":"3x"}],"info":{"author":"xcode","version":1}}
""".write(to: markDirectory.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)

let iconDirectory = catalog.appendingPathComponent("AppIcon.appiconset")
let entries = try JSONSerialization.jsonObject(with: Data(contentsOf: iconDirectory.appendingPathComponent("Contents.json"))) as! [String: Any]
for entry in entries["images"] as! [[String: String]] {
    let logical = Double(entry["size"]!.split(separator: "x")[0])!
    let multiplier = Double(entry["scale"]!.dropLast())!
    let size = Int(logical * multiplier)
    try writePNG(icon(size: size), to: iconDirectory.appendingPathComponent(entry["filename"]!))
    print("AppIcon: \(entry["filename"]!) \(size)×\(size) RGB")
}
try writePNG(icon(size: 1024), to: design.appendingPathComponent("app-icon-1024.png"))

func text(_ value: String, at point: CGPoint, size: CGFloat, weight: NSFont.Weight = .regular, hex: UInt32, in context: CGContext) {
    let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: size, weight: weight), .foregroundColor: NSColor(cgColor: color(hex))!]
    let line = CTLineCreateWithAttributedString(NSAttributedString(string: value, attributes: attrs))
    context.saveGState(); context.translateBy(x: point.x, y: point.y); context.scaleBy(x: 1, y: -1)
    context.textPosition = .zero; CTLineDraw(line, context); context.restoreGState()
}

func drawPreviewIcon(_ context: CGContext, x: CGFloat, y: CGFloat, size: CGFloat) {
    context.saveGState()
    context.addPath(CGPath(roundedRect: CGRect(x: x, y: y, width: size, height: size), cornerWidth: size * 0.225, cornerHeight: size * 0.225, transform: nil)); context.clip()
    context.setFillColor(color(0xF7F6F2)); context.fill(CGRect(x: x, y: y, width: size, height: size))
    context.translateBy(x: x, y: y); context.scaleBy(x: size / 256, y: size / 256)
    context.translateBy(x: 128, y: 128); context.scaleBy(x: 1.04, y: 1.04); context.translateBy(x: -128, y: -128)
    drawMark(context); context.restoreGState()
}

let preview = bitmap(width: 1400, height: 900, opaque: true) { context in
    context.setFillColor(color(0xEDECE7)); context.fill(CGRect(x: 0, y: 0, width: 1400, height: 900))
    text("IDEABOX  /  BRAND IDENTITY", at: CGPoint(x: 88, y: 88), size: 16, weight: .medium, hex: 0x85838D, in: context)
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: 14), blur: 40, color: CGColor(red: 0.3, green: 0.25, blue: 0.4, alpha: 0.10))
    context.setFillColor(color(0xF7F6F2))
    context.addPath(CGPath(roundedRect: CGRect(x: 88, y: 177, width: 424, height: 424), cornerWidth: 95, cornerHeight: 95, transform: nil)); context.fillPath()
    context.restoreGState()
    drawPreviewIcon(context, x: 88, y: 177, size: 424)
    text("把灵感，轻轻收好。", at: CGPoint(x: 621, y: 253), size: 44, weight: .semibold, hex: 0x282735, in: context)
    text("A little room for every idea.", at: CGPoint(x: 623, y: 303), size: 25, hex: 0x85838D, in: context)
    text("温柔的容器 · 一闪而来的灵感 · 日常的新芽", at: CGPoint(x: 623, y: 380), size: 22, hex: 0x66636F, in: context)
    for (index, colorValue) in [UInt32(0xF7F6F2), 0x7770DD, 0xD7D3F4, 0xA9C3AD].enumerated() {
        let x = CGFloat(624 + index * 141)
        context.setFillColor(color(colorValue)); context.fillEllipse(in: CGRect(x: x, y: 432, width: 52, height: 52))
        text(String(format: "#%06X", colorValue), at: CGPoint(x: x - 7, y: 515), size: 16, weight: .medium, hex: 0x85838D, in: context)
    }
    context.setFillColor(color(0xDEDDD8)); context.fill(CGRect(x: 88, y: 682, width: 1224, height: 1))
    text("Every detail, considered.", at: CGPoint(x: 88, y: 764), size: 23, weight: .medium, hex: 0x66636F, in: context)
    text("应用图标 · 启动品牌标记 · 分层动效资产", at: CGPoint(x: 88, y: 806), size: 18, hex: 0x85838D, in: context)
    drawPreviewIcon(context, x: 824, y: 721, size: 96)
    drawPreviewIcon(context, x: 966, y: 743, size: 64)
    drawPreviewIcon(context, x: 1080, y: 757, size: 40)
    context.saveGState(); context.translateBy(x: 1190, y: 719); context.scaleBy(x: 0.40, y: 0.40); drawMark(context); context.restoreGState()
}
try writePNG(preview, to: design.appendingPathComponent("brand-preview.png"))
print("Brand SVGs, transparent launch assets, and preview exported.")
