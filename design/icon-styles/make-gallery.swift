import AppKit
let folder = CommandLine.arguments[1]
let width = 1500
let height = 1765
let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
NSGraphicsContext.current!.imageInterpolation = .high
NSColor(calibratedWhite: 0.955, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: width, height: height).fill()
func label(_ text: String, _ x: CGFloat, _ y: CGFloat, _ size: CGFloat, _ weight: NSFont.Weight = .regular, _ color: NSColor = .black) {
    NSAttributedString(string: text, attributes: [.font: NSFont.systemFont(ofSize: size, weight: weight), .foregroundColor: color]).draw(at: NSPoint(x: x, y: y))
}
label("Android Bridge · Graphic Style Exploration", 36, 1710, 28, .semibold)
label("Android 마스코트와 파일 교환 · 그래픽 스타일과 레이아웃 비교", 36, 1675, 17, .regular, .darkGray)
let items = [("01", "Soft 3D", "부드러운 입체감 · 캐릭터 중심"), ("02", "Bold Illustration", "굵은 윤곽선 · 그래픽 중심"), ("03", "Minimal Symbol", "단순한 형태 · 밝은 파우더 블루"), ("04", "Frosted Glass", "반투명 재질 · 빛과 깊이"), ("05", "Isometric", "사선 배치 · 정교한 원근감"), ("06", "Dark Enamel", "다크 바탕 · 에나멜과 금속"), ("07", "File Exchange", "두 파일 사이의 교환 · 플랫 심볼"), ("08", "Android Courier", "파일을 건네는 캐릭터 · 소프트 클레이"), ("09", "Transfer Halo", "전송 화살표와 얼굴 · 입체 에나멜")]
for (index, item) in items.enumerated() {
    let col = index % 3
    let row = index / 3
    let x = CGFloat(24 + col * 494)
    let y = CGFloat(22 + (2 - row) * 545)
    NSColor.white.setFill()
    NSBezierPath(roundedRect: NSRect(x: x, y: y, width: 464, height: 525), xRadius: 20, yRadius: 20).fill()
    let image = NSImage(contentsOfFile: "\(folder)/\(item.0).png")!
    image.draw(in: NSRect(x: x + 42, y: y + 124, width: 380, height: 380), from: .zero, operation: .sourceOver, fraction: 1)
    label("\(item.0)   \(item.1)", x + 22, y + 104, 22, .semibold)
    label(item.2, x + 22, y + 77, 15, .regular, .darkGray)
    NSColor(calibratedWhite: 0.14, alpha: 1).setFill()
    NSBezierPath(roundedRect: NSRect(x: x + 22, y: y + 12, width: 420, height: 55), xRadius: 12, yRadius: 12).fill()
    for (size, offset) in [(32, 35), (48, 91), (64, 161)] {
        image.draw(in: NSRect(x: x + CGFloat(offset), y: y + 12 + CGFloat(55 - size)/2, width: CGFloat(size), height: CGFloat(size)), from: .zero, operation: .sourceOver, fraction: 1)
    }
    label("32 / 48 / 64 px", x + 263, y + 31, 14, .regular, .lightGray)
}
try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "\(folder)/Gallery.png"))
