import AppKit
let folder = CommandLine.arguments[1]
let image = NSImage(contentsOfFile: "\(folder)/A-v2.png")!
let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 800, pixelsHigh: 930, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
NSGraphicsContext.current!.imageInterpolation = .high
NSColor(calibratedWhite: 0.96, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: 800, height: 930).fill()
func text(_ s: String, _ x: CGFloat, _ y: CGFloat, _ size: CGFloat, _ color: NSColor = .black) {
    NSAttributedString(string: s, attributes: [.font: NSFont.systemFont(ofSize: size, weight: .medium), .foregroundColor: color]).draw(at: NSPoint(x: x, y: y))
}
text("A · 폴더 안의 Android와 파일", 42, 875, 26)
image.draw(in: NSRect(x: 90, y: 240, width: 620, height: 620), from: .zero, operation: .sourceOver, fraction: 1)
NSColor(calibratedWhite: 0.14, alpha: 1).setFill()
NSBezierPath(roundedRect: NSRect(x: 40, y: 32, width: 720, height: 183), xRadius: 20, yRadius: 20).fill()
for (size, center) in [(32, 115), (48, 255), (64, 415), (128, 625)] {
    image.draw(in: NSRect(x: CGFloat(center - size/2), y: 109 - CGFloat(size)/2, width: CGFloat(size), height: CGFloat(size)), from: .zero, operation: .sourceOver, fraction: 1)
    text("\(size) px", CGFloat(center - 22), 49, 14, .lightGray)
}
try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "\(folder)/A-v2-preview.png"))
