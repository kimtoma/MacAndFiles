import AppKit

// Package checked-in artwork; no image-generation service is needed to build.
guard CommandLine.arguments.count == 3 else {
    fputs("Usage: swift scripts/make-icon.swift <master.png> <output.iconset>\n", stderr)
    exit(1)
}
let sourceURL = URL(fileURLWithPath: CommandLine.arguments[1])
let directory = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
guard let image = NSImage(contentsOf: sourceURL),
      let source = NSBitmapImageRep(data: try Data(contentsOf: sourceURL)),
      source.pixelsWide == source.pixelsHigh, source.pixelsWide >= 1024 else {
    fputs("The icon master must be a square PNG of at least 1024 pixels.\n", stderr)
    exit(1)
}
try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
let sizes = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024)
]
for (name, size) in sizes {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    let context = NSGraphicsContext(bitmapImageRep: bitmap)!
    context.imageInterpolation = .high
    NSGraphicsContext.current = context
    image.draw(in: NSRect(x: 0, y: 0, width: size, height: size),
        from: .zero, operation: .copy, fraction: 1, respectFlipped: true,
        hints: [.interpolation: NSImageInterpolation.high])
    NSGraphicsContext.restoreGraphicsState()
    guard let png = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "MacAndFiles.Icon", code: 1)
    }
    try png.write(to: directory.appendingPathComponent(name + ".png"), options: .atomic)
}
print("Generated \(sizes.count) iconset images from \(sourceURL.lastPathComponent)")
