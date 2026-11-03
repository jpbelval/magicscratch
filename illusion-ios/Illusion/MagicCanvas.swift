import SwiftUI
import UIKit

struct MagicCanvas: UIViewRepresentable {
    @EnvironmentObject var studio: Studio
    func makeUIView(context: Context) -> ScratchView { ScratchView() }
    func updateUIView(_ view: ScratchView, context: Context) {
        view.brushWidth = CGFloat(studio.settings.brush)
        if view.revision != studio.revision {
            view.configure(image: studio.artwork, background: studio.background, color: studio.color,
                           size: CGFloat(studio.settings.size), revision: studio.revision)
        }
    }
}

final class ScratchView: UIView {
    struct Stroke { var points: [CGPoint]; let width: CGFloat; let layer: CAShapeLayer }
    var revision: UUID?
    var brushWidth: CGFloat = 60
    private let backdrop = CALayer()
    private let picture = CALayer()
    private let revealMask = CALayer()
    private var image: CGImage?
    private var fraction: CGFloat = 0.55
    private var strokes: [Stroke] = []
    private var vanished = false
    private var primary: UITouch?
    private var start = CGPoint.zero
    private var startedAt: TimeInterval = 0
    private var startedOnImage = false
    private var dragged = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        isMultipleTouchEnabled = false
        isOpaque = true
        clipsToBounds = true
        layer.addSublayer(backdrop); layer.addSublayer(picture)
        picture.contentsGravity = .resizeAspect
        picture.mask = revealMask
        backdrop.contentsGravity = .resizeAspectFill
        isAccessibilityElement = true
        accessibilityLabel = "Scène magique"
        accessibilityHint = "Glissez pour révéler l’image, puis touchez une partie révélée pour la faire disparaître."
        accessibilityTraits = [.allowsDirectInteraction]
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(image: UIImage, background: UIImage?, color: UIColor, size: CGFloat, revision: UUID) {
        self.revision = revision; self.image = image.cgImage; fraction = size
        primary = nil; strokes.removeAll(); vanished = false
        CATransaction.begin(); CATransaction.setDisableActions(true)
        revealMask.sublayers = nil; picture.isHidden = false
        picture.contents = image.cgImage; backdrop.contents = background?.cgImage
        backdrop.backgroundColor = color.cgColor
        CATransaction.commit(); setNeedsLayout()
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 0, bounds.height > 0, let image else { return }
        CATransaction.begin(); CATransaction.setDisableActions(true)
        backdrop.frame = bounds
        let side = min(bounds.width, bounds.height) * fraction
        let scale = min(side / CGFloat(image.width), side / CGFloat(image.height))
        let size = CGSize(width: CGFloat(image.width) * scale, height: CGFloat(image.height) * scale)
        picture.frame = CGRect(x: bounds.midX-size.width/2, y: bounds.midY-size.height/2, width: size.width, height: size.height)
        // Mask paths use scene coordinates, offset into the image's coordinate system.
        revealMask.frame = CGRect(x: -picture.frame.minX, y: -picture.frame.minY, width: bounds.width, height: bounds.height)
        for index in strokes.indices { updateStroke(index) }
        CATransaction.commit()
    }
    private func normalized(_ point: CGPoint) -> CGPoint { CGPoint(x: point.x / max(1, bounds.width), y: point.y / max(1, bounds.height)) }
    private func updateStroke(_ index: Int) {
        let stroke = strokes[index], path = UIBezierPath()
        for (offset, p) in stroke.points.enumerated() {
            let point = CGPoint(x: p.x * bounds.width, y: p.y * bounds.height)
            if offset == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        stroke.layer.path = path.cgPath
        stroke.layer.lineWidth = stroke.width * min(bounds.width, bounds.height)
    }
    private func revealed(at point: CGPoint) -> Bool {
        guard !vanished, picture.frame.contains(point), let image else { return false }
        let inStroke = strokes.contains { stroke in
            stroke.layer.path?.copy(strokingWithWidth: stroke.layer.lineWidth, lineCap: .round, lineJoin: .round, miterLimit: 10).contains(point) == true
        }
        guard inStroke else { return false }
        // Respect transparency: touching an empty part of a PNG must not dismiss it.
        let x = min(image.width-1, max(0, Int((point.x-picture.frame.minX)/picture.frame.width * CGFloat(image.width))))
        let y = min(image.height-1, max(0, Int((point.y-picture.frame.minY)/picture.frame.height * CGFloat(image.height))))
        guard let pixel = image.cropping(to: CGRect(x: CGFloat(x), y: CGFloat(y), width: 1, height: 1)) else { return false }
        var bytes = [UInt8](repeating: 0, count: 4)
        return bytes.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(data: buffer.baseAddress, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            context.draw(pixel, in: CGRect(x: 0, y: 0, width: 1, height: 1))
            return buffer[3] > 30
        }
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard primary == nil, !vanished, let touch = touches.first else { return }
        primary = touch; start = touch.location(in: self); startedAt = touch.timestamp
        dragged = false; startedOnImage = revealed(at: start)
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = primary, touches.contains(touch), !vanished else { return }
        let point = touch.location(in: self)
        guard dragged || hypot(point.x-start.x, point.y-start.y) > 6 else { return }
        if !dragged {
            dragged = true
            let shape = CAShapeLayer(); shape.strokeColor = UIColor.white.cgColor
            shape.fillColor = nil; shape.lineCap = .round; shape.lineJoin = .round
            revealMask.addSublayer(shape)
            strokes.append(Stroke(points: [normalized(start)], width: brushWidth/max(1, min(bounds.width, bounds.height)), layer: shape))
        }
        for sample in event?.coalescedTouches(for: touch) ?? [touch] { strokes[strokes.count-1].points.append(normalized(sample.location(in: self))) }
        CATransaction.begin(); CATransaction.setDisableActions(true)
        updateStroke(strokes.count-1); CATransaction.commit()
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = primary, touches.contains(touch) else { return }
        let point = touch.location(in: self)
        if !dragged, startedOnImage, touch.timestamp-startedAt < 0.5, hypot(point.x-start.x, point.y-start.y) < 6 {
            vanished = true
            CATransaction.begin(); CATransaction.setDisableActions(true); picture.isHidden = true; CATransaction.commit()
        }
        primary = nil
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { primary = nil }
}
