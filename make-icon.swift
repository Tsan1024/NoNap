// StayAwake: native vector-rendered nearly closed laptop with an awake indicator.
import AppKit

let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : FileManager.default.currentDirectoryPath
let iconset = "\(outDir)/StayAwake.iconset"
try FileManager.default.createDirectory(atPath: iconset, withIntermediateDirectories: true)

func render(_ size: Int) throws -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let cg = NSGraphicsContext.current!.cgContext
    cg.scaleBy(x: CGFloat(size) / 1024, y: CGFloat(size) / 1024)
    NSColor(srgbRed: 0.88, green: 0.95, blue: 0.91, alpha: 1).setFill()
    NSBezierPath(roundedRect: NSRect(x: 100, y: 100, width: 824, height: 824), xRadius: 184, yRadius: 184).fill()
    let ink = NSColor(srgbRed: 0.2, green: 0.25, blue: 0.24, alpha: 1)
    ink.setStroke()
    let lid = NSBezierPath()
    lid.lineWidth = 60
    lid.lineCapStyle = .round
    lid.move(to: NSPoint(x: 254, y: 636))
    lid.line(to: NSPoint(x: 766, y: 480))
    lid.stroke()
    ink.setFill()
    NSBezierPath(roundedRect: NSRect(x: 228, y: 374, width: 568, height: 66), xRadius: 33, yRadius: 33).fill()
    NSColor(srgbRed: 0.56, green: 0.86, blue: 0.64, alpha: 1).setFill()
    NSBezierPath(roundedRect: NSRect(x: 462, y: 394, width: 100, height: 26), xRadius: 13, yRadius: 13).fill()
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}
for (name, size) in [
    ("icon_16x16",16),("icon_16x16@2x",32),("icon_32x32",32),("icon_32x32@2x",64),
    ("icon_128x128",128),("icon_128x128@2x",256),("icon_256x256",256),
    ("icon_256x256@2x",512),("icon_512x512",512),("icon_512x512@2x",1024)
] {
    try render(size).write(to: URL(fileURLWithPath: "\(iconset)/\(name).png"))
}
try render(1024).write(to: URL(fileURLWithPath: "\(outDir)/StayAwake-1024.png"))
