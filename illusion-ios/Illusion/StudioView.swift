import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct StudioView: View {
    @EnvironmentObject private var studio: Studio
    @State private var imageSelection: PhotosPickerItem?
    @State private var backgroundSelection: PhotosPickerItem?
    @State private var performing = false
    @State private var help = false
    @State private var importingFile = false
    @State private var fileIsBackground = false
    @State private var loadingImage = false
    @State private var loadingBackground = false
    private let paper = Color(red: 0.96, green: 0.97, blue: 0.94)

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 18) {
                HStack {
                    Label("illusion.", systemImage: "sparkles").font(.system(size: 30, weight: .bold, design: .rounded))
                    Spacer()
                    Button { help = true } label: { Image(systemName: "questionmark.circle").font(.title2).frame(width: 44, height: 44) }.accessibilityLabel("Mode d’emploi")
                }
                if geometry.size.width > 700 {
                    HStack(alignment: .top, spacing: 24) {
                        settings.frame(width: 300)
                        VStack(alignment: .leading, spacing: 20) {
                            Text("La magie, au bout des doigts.").font(.largeTitle.weight(.medium))
                            Text("Préparez votre illusion. Le reste est entre vos mains.").foregroundStyle(.secondary)
                            preview
                            Text("Glissez pour révéler. Touchez une partie révélée pour la faire disparaître.").font(.callout).foregroundStyle(.secondary)
                            Spacer(minLength: 0)
                        }
                    }
                } else {
                    preview.frame(height: min(geometry.size.height * 0.36, 320))
                    settings
                }
            }.padding(20).background(paper)
        }
        .sheet(isPresented: $help) { helpSheet }
        .fullScreenCover(isPresented: $performing, onDismiss: { studio.reset() }) { PerformanceView() }
        .alert("Illusion", isPresented: Binding(get: { studio.error != nil }, set: { if !$0 { studio.error = nil } })) {
            Button("OK") { studio.error = nil }
        } message: { Text(studio.error ?? "") }
        .task(id: imageSelection) { await loadPhoto(imageSelection, background: false) }
        .task(id: backgroundSelection) { await loadPhoto(backgroundSelection, background: true) }
        .fileImporter(isPresented: $importingFile, allowedContentTypes: [.image]) { result in
            do {
                let url = try result.get(), access = url.startAccessingSecurityScopedResource()
                defer { if access { url.stopAccessingSecurityScopedResource() } }
                studio.importImage(try Data(contentsOf: url), asBackground: fileIsBackground)
            } catch { studio.error = "Importation impossible : \(error.localizedDescription)" }
        }
    }

    private var preview: some View {
        VStack(spacing: 10) {
            HStack {
                Label("RÉPÉTITION", systemImage: "circle.fill").font(.caption2).foregroundStyle(.secondary)
                Spacer()
                Button { studio.reset() } label: { Label("Recommencer", systemImage: "arrow.counterclockwise") }.font(.caption).frame(minHeight: 44)
            }
            MagicCanvas().clipShape(RoundedRectangle(cornerRadius: 14)).aspectRatio(4/3, contentMode: .fit)
        }
    }

    private var settings: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Votre illusion").font(.title2.weight(.semibold))
                GroupBox {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("01  L’image à révéler").font(.headline)
                        PhotosPicker(selection: $imageSelection, matching: .images) { Label(studio.image == nil ? "Choisir une photo" : "Changer la photo", systemImage: "photo.on.rectangle") }.frame(minHeight: 44)
                        if loadingImage { ProgressView("Chargement…") }
                        if let image = studio.image { Image(uiImage: image).resizable().scaledToFit().frame(height: 65).accessibilityLabel("Image choisie") }
                        Button("Choisir dans Fichiers", systemImage: "folder") { fileIsBackground = false; importingFile = true }.font(.callout)
                        HStack(spacing: 12) {
                            motifButton("heart.fill", label: "Cœur")
                            motifButton("card", label: "As de pique")
                            motifButton("star.fill", label: "Étoile")
                        }
                        Text("Taille : \(Int(studio.settings.size * 100)) %").font(.caption)
                        Slider(value: $studio.settings.size, in: 0.15...1, onEditingChanged: { editing in if !editing { studio.save() } }).accessibilityLabel("Taille de l’image")
                            .onChange(of: studio.settings.size) { _, _ in studio.reset() }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
                GroupBox {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("02  Le fond de scène").font(.headline)
                        ColorPicker("Fond uni", selection: Binding(get: { Color(uiColor: studio.color) }, set: { studio.chooseColor($0) }), supportsOpacity: false)
                        PhotosPicker(selection: $backgroundSelection, matching: .images) { Label("Choisir une photo de fond", systemImage: "photo") }.frame(minHeight: 44)
                        if loadingBackground { ProgressView("Chargement…") }
                        if let background = studio.background {
                            Image(uiImage: background).resizable().scaledToFit().frame(height: 65).accessibilityLabel("Fond choisi")
                            Button("Revenir au fond uni") { studio.chooseColor(Color(uiColor: studio.color)) }
                        }
                        Button("Choisir dans Fichiers", systemImage: "folder") { fileIsBackground = true; importingFile = true }.font(.callout)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
                GroupBox {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("03  Le geste magique").font(.headline)
                        Text("Largeur : \(Int(studio.settings.brush)) points").font(.caption)
                        Slider(value: $studio.settings.brush, in: 20...150, onEditingChanged: { editing in if !editing { studio.save() } }).accessibilityLabel("Largeur du grattage")
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
                Button { studio.reset(); performing = true } label: {
                    Label("Lancer le spectacle", systemImage: "sparkles").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 12)
                }.buttonStyle(.borderedProminent).disabled(loadingImage || loadingBackground)
                Text("Vos images restent sur cet appareil.").font(.caption).foregroundStyle(.secondary)
            }.padding(.bottom, 20)
        }.scrollIndicators(.hidden)
    }
    private func motifButton(_ name: String, label: String) -> some View {
        Button { studio.chooseMotif(name) } label: {
            Image(systemName: name == "card" ? "suit.spade.fill" : name)
                .font(.title2).frame(width: 52, height: 52)
                .background(studio.image == nil && studio.settings.motif == name ? Color.accentColor.opacity(0.18) : Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 9))
        }.accessibilityLabel(label).accessibilityAddTraits(studio.image == nil && studio.settings.motif == name ? .isSelected : [])
    }
    @MainActor private func loadPhoto(_ selection: PhotosPickerItem?, background: Bool) async {
        guard let selection else { return }
        if background { loadingBackground = true } else { loadingImage = true }
        defer { if background { loadingBackground = false } else { loadingImage = false } }
        do {
            guard let data = try await selection.loadTransferable(type: Data.self) else {
                if !Task.isCancelled { studio.error = "La photo ne peut pas être chargée." }; return
            }
            guard !Task.isCancelled else { return }
            studio.importImage(data, asBackground: background)
            if background { backgroundSelection = nil } else { imageSelection = nil }
        } catch { if !Task.isCancelled { studio.error = "Impossible de charger la photo : \(error.localizedDescription)" } }
    }
    private var helpSheet: some View {
        NavigationStack {
            List {
                Section("Préparer") { Text("Choisissez l’image cachée et un fond uni ou une photo. Réglez la taille de l’image et la largeur du grattage.") }
                Section("Révéler") { Text("Glissez un doigt ou l’Apple Pencil sur la scène. Seules les zones grattées apparaissent. Un toucher bref sur une partie révélée fait disparaître l’image. Recommencer prépare un nouveau tour.") }
                Section("Spectacle") { Text("Lancez le spectacle pour masquer les réglages. Maintenez le × en haut à droite pendant une seconde pour quitter. Le verrouillage automatique est suspendu pendant le spectacle.") }
                Section("Confidentialité") { Text("Les images sont copiées dans le stockage privé de l’application. Aucun compte, serveur ou accès Internet n’est nécessaire une fois vos photos importées. Une photo stockée uniquement dans iCloud peut nécessiter une connexion lors de l’importation.") }
            }.navigationTitle("Le secret du tour").toolbar { ToolbarItem(placement: .confirmationAction) { Button("Fermer") { help = false } } }
        }
    }
}

struct PerformanceView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var previousIdleDisabled = false
    var body: some View {
        MagicCanvas().ignoresSafeArea()
            .overlay(alignment: .topTrailing) {
                Image(systemName: "xmark").font(.title3).foregroundStyle(.gray.opacity(0.45))
                    .frame(width: 52, height: 52).contentShape(Rectangle()).padding(8)
                    .onLongPressGesture(minimumDuration: 1) { dismiss() }
                    .accessibilityLabel("Quitter le spectacle")
                    .accessibilityHint("Maintenez pendant une seconde")
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAction { dismiss() }
            }
            .statusBarHidden().persistentSystemOverlays(.hidden)
            .onAppear { previousIdleDisabled = UIApplication.shared.isIdleTimerDisabled; UIApplication.shared.isIdleTimerDisabled = true }
            .onDisappear { UIApplication.shared.isIdleTimerDisabled = previousIdleDisabled }
            .onChange(of: scenePhase) { _, phase in UIApplication.shared.isIdleTimerDisabled = phase == .active ? true : previousIdleDisabled }
    }
}
