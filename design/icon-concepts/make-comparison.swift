import AppKit

let folder = CommandLine.arguments[1]
let width = 1200
let height = 1410
let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
NSGraphicsContext.current!.imageInterpolation = .high
NSColor(calibratedWhite: 0.96, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: width, height: height).fill()

func label(_ text: String, _ x: CGFloat, _ y: CGFloat, _ size: CGFloat, _ weight: NSFont.Weight = .regular, _ color: NSColor = .black) {
    NSAttributedString(string: text, attributes: [.font: NSFont.systemFont(ofSize: size, weight: weight), .foregroundColor: color]).draw(at: NSPoint(x: x, y: y))
}
label("Android Bridge · Icon Concepts", 48, 1337, 30, .semibold)
label("Android 캐릭터 · Finder 블루 · macOS 입체감", 48, 1300, 18, .regular, .darkGray)

let concepts = [("A", "폴더 + Android", "파일 관리와 전송 기능이 바로 보이는 구성"), ("B", "Android 페이스", "캐릭터의 실루엣과 존재감을 강조"), ("C", "전송 오비트", "순환 화살표로 양방향 전송을 강조"), ("D", "포켓 Android", "폴더 위로 올라온 친근한 캐릭터")]
for (index, concept) in concepts.enumerated() {
    let col = index % 2
    let row = index / 2
    let x = CGFloat(32 + col * 584)
    let y = CGFloat(40 + (1 - row) * 620)
    NSColor.white.setFill()
    NSBezierPath(roundedRect: NSRect(x: x, y: y, width: 552, height: 602), xRadius: 24, yRadius: 24).fill()
    let image = NSImage(contentsOfFile: "\(folder)/\(concept.0).png")!
    image.draw(in: NSRect(x: x + 86, y: y + 168, width: 380, height: 380), from: .zero, operation: .sourceOver, fraction: 1)
    label("\(concept.0)   \(concept.1)", x + 28, y + 128, 24, .semibold)
    label(concept.2, x + 28, y + 97, 16, .regular, .darkGray)
    NSColor(calibratedWhite: 0.14, alpha: 1).setFill()
    NSBezierPath(roundedRect: NSRect(x: x + 28, y: y + 19, width: 496, height: 63), xRadius: 14, yRadius: 14).fill()
    for (size, offset) in [(32, 42), (48, 96), (64, 164)] {
        image.draw(in: NSRect(x: x + CGFloat(offset), y: y + 19 + CGFloat(63 - size)/2, width: CGFloat(size), height: CGFloat(size)), from: .zero, operation: .sourceOver, fraction: 1)
    }
    label("Dock · 32 / 48 / 64 px", x + 274, y + 42, 14, .regular, .lightGray)
}
try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "\(folder)/Comparison.png"))
