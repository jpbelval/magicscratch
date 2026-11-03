# Vérification du projet

Effectuée le 31 octobre 2026 sous Linux.

- Les quatre fichiers Swift passent l’analyse syntaxique Tree-sitter Swift sans erreur ni nœud manquant.
- Le fichier `project.pbxproj` est analysable au format OpenStep. Les références internes et les chemins des sources/ressources sont résolus.
- Info.plist, PrivacyInfo.xcprivacy, les catalogues JSON et le schéma partagé XML sont analysables.
- L’icône fournie est une image PNG RGB opaque de 1024 × 1024 pixels.

Non effectué : compilation/type-checking avec le SDK iOS, exécution sur simulateur, essais iPad/Apple Pencil, signature et distribution TestFlight. La compilation peut utiliser Xcode sur macOS ou xtool sous Linux avec le SDK Apple. Voir README.md pour la commande de compilation et le protocole d’essai.

## Configuration xtool

xtool 1.24.0 a été téléchargé depuis la release officielle et exécuté localement. Les clés de `xtool.yml` ont été vérifiées contre PackSchema.swift de cette version. Le manifeste SwiftPM utilise une bibliothèque comme point d’entrée xtool, les quatre sources existantes et le mode de langage Swift 5. Les substitutions Xcode ont été retirées du plist propre à xtool.

`xtool sdk status` : Not installed. `xtool dev build --ipa` lancé avec un terminal atteint la demande `Path to Xcode.xip:`. Arrêt à cette étape faute de SDK fourni. La compilation SwiftPM et la signature ne sont donc pas validées.
