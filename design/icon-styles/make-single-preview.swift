import AppKit
let input = CommandLine.arguments[1]
let output = CommandLine.arguments[2]
let title = CommandLine.arguments[3]
let image = NSImage(contentsOfFile: input)!
let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 720, pixelsHigh: 820, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
NSGraphicsContext.current!.imageInterpolation = .high
NSColor(calibratedWhite: 0.96, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: 720, height: 820).fill()
NSAttributedString(string: title, attributes: [.font: NSFont.systemFont(ofSize: 24, weight: .semibold), .foregroundColor: NSColor.black]).draw(at: NSPoint(x: 36, y: 766))
image.draw(in: NSRect(x: 60, y: 144, width: 600, height: 600), from: .zero, operation: .sourceOver, fraction: 1)
NSColor(calibratedWhite: 0.14, alpha: 1).setFill()
NSBezierPath(roundedRect: NSRect(x: 36, y: 26, width: 648, height: 100), xRadius: 16, yRadius: 16).fill()
for (size, center) in [(32, 126), (48, 266), (64, 426)] {
    image.draw(in: NSRect(x: CGFloat(center - size/2), y: 83 - CGFloat(size)/2, width: CGFloat(size), height: CGFloat(size)), from: .zero, operation: .sourceOver, fraction: 1)
}
NSAttributedString(string: "32 / 48 / 64 px", attributes: [.font: NSFont.systemFont(ofSize: 14), .foregroundColor: NSColor.lightGray]).draw(at: NSPoint(x: 527, y: 71))
try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: output))
