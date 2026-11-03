import SwiftUI
import ImageIO

struct Settings: Codable {
    var motif = "heart.fill"
    var red = 0.92
    var green = 0.90
    var blue = 0.86
    var size = 0.55
    var brush = 60.0
}

@MainActor
final class Studio: ObservableObject {
    @Published var settings = Settings()
    @Published var image: UIImage?
    @Published var background: UIImage?
    @Published var revision = UUID()
    @Published var error: String?
    private let folder: URL

    init() {
        folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Illusion", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            if let data = try? Data(contentsOf: folder.appendingPathComponent("settings.json")), let saved = try? JSONDecoder().decode(Settings.self, from: data) { settings = saved }
            settings.size = min(1, max(0.15, settings.size))
            settings.brush = min(150, max(20, settings.brush))
            image = UIImage(contentsOfFile: folder.appendingPathComponent("image.png").path)
            background = UIImage(contentsOfFile: folder.appendingPathComponent("background.png").path)
        } catch { self.error = "Impossible de charger les choix enregistrés : \(error.localizedDescription)" }
    }

    var color: UIColor { UIColor(red: settings.red, green: settings.green, blue: settings.blue, alpha: 1) }
    var artwork: UIImage { image ?? Self.motif(settings.motif) }

    func reset() { revision = UUID() }
    func save() {
        do { try JSONEncoder().encode(settings).write(to: folder.appendingPathComponent("settings.json"), options: .atomic) }
        catch { self.error = "Les réglages ne peuvent pas être enregistrés : \(error.localizedDescription)" }
    }
    func chooseMotif(_ name: String) {
        do { try remove("image.png"); image = nil; settings.motif = name; save(); reset() }
        catch { self.error = error.localizedDescription }
    }
    func chooseColor(_ value: Color) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard UIColor(value).getRed(&r, green: &g, blue: &b, alpha: &a) else { return }
        do {
            try remove("background.png"); background = nil
            settings.red = Double(r); settings.green = Double(g); settings.blue = Double(b)
            save(); reset()
        } catch { self.error = error.localizedDescription }
    }
    private func remove(_ name: String) throws {
        let url = folder.appendingPathComponent(name)
        if FileManager.default.fileExists(atPath: url.path) { try FileManager.default.removeItem(at: url) }
    }
    func importImage(_ data: Data, asBackground: Bool) {
        // Decode a bounded, orientation-correct thumbnail instead of a full-resolution photo.
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let cg = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 2048
              ] as CFDictionary) else { error = "Cette image est illisible. Essayez une photo HEIC, JPG ou PNG."; return }
        let decoded = UIImage(cgImage: cg)
        guard let png = decoded.pngData() else { error = "Impossible de préparer l’image."; return }
        do {
            try png.write(to: folder.appendingPathComponent(asBackground ? "background.png" : "image.png"), options: .atomic)
            if asBackground { background = decoded } else { image = decoded }
            reset()
        } catch { self.error = "Impossible d’enregistrer l’image : \(error.localizedDescription)" }
    }
    static func motif(_ name: String) -> UIImage {
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 600, height: 600), format: format).image { _ in
            if name == "card" {
                UIColor(red: 1, green: 0.98, blue: 0.94, alpha: 1).setFill()
                UIBezierPath(roundedRect: CGRect(x: 105, y: 15, width: 390, height: 570), cornerRadius: 24).fill()
                let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 65, weight: .medium), .foregroundColor: UIColor.black]
                ("A" as NSString).draw(at: CGPoint(x: 130, y: 35), withAttributes: attrs)
                UIImage(systemName: "suit.spade.fill")?.withTintColor(.black, renderingMode: .alwaysOriginal).draw(in: CGRect(x: 195, y: 185, width: 210, height: 230))
            } else {
                let tint: UIColor = name == "star.fill" ? .systemYellow : UIColor(red: 0.76, green: 0.19, blue: 0.28, alpha: 1)
                let symbol = UIImage(systemName: name, withConfiguration: UIImage.SymbolConfiguration(pointSize: 500, weight: .regular))?.withTintColor(tint, renderingMode: .alwaysOriginal)
                if let symbol { let ratio = min(550 / symbol.size.width, 550 / symbol.size.height); let size = CGSize(width: symbol.size.width * ratio, height: symbol.size.height * ratio); symbol.draw(in: CGRect(x: (600-size.width)/2, y: (600-size.height)/2, width: size.width, height: size.height)) }
            }
        }
    }
}
