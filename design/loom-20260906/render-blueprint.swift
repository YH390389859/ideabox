import AppKit

let directory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("design/loom-20260906")
let svgURL = directory.appendingPathComponent("blueprint.svg")
if let svg = NSImage(contentsOf: svgURL) {
    let width = 3000, height = 2300
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: width * 4, bitsPerPixel: 32)!
    bitmap.size = NSSize(width: width, height: height)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    svg.draw(in: NSRect(x: 0, y: 0, width: width, height: height), from: .zero, operation: .sourceOver, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()
    try bitmap.representation(using: .png, properties: [:])!.write(to: directory.appendingPathComponent("blueprint.png"))
    print("Rendered native SVG: \(svg.size) → \(width) × \(height)")
} else {
    print("NSImage SVG support unavailable")
    exit(1)
}
