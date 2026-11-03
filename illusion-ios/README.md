# Illusion — iOS native

Application SwiftUI + UIKit pour iPhone et iPad, iOS 17 minimum. Pas de WebView, de serveur, de dépendances tierces ni de génération de projet préalable.

## Compiler avec xtool sous Linux

Le projet contient `Package.swift`, `xtool.yml` et `xtool-Info.plist`, compatibles avec le schéma de configuration xtool 1.24.0. Les sources Swift sont partagées avec le projet Xcode. Le PNG de l’icône est fourni directement à xtool, sans compilation de catalogue Xcode.

Prérequis : installer la chaîne Swift requise par la version de xtool, puis télécharger Xcode depuis [Apple Developer](https://developer.apple.com/download/all/?q=Xcode) dans votre navigateur. Ce téléchargement demande votre connexion Apple et l’acceptation de la licence. xtool extrait le SDK Apple de cette archive ; un Mac n’est pas nécessaire à cette étape. Suivre le [guide officiel xtool](https://github.com/xtool-org/xtool/blob/1.24.0/Documentation/xtool.docc/Installation-Linux.md).

Dans cet espace de travail, xtool 1.24.0 est disponible via `../.tools/xtool` depuis le dossier `illusion-ios`. L’archive ZIP du projet ne contient pas ce binaire Linux ; installer xtool séparément sur une autre machine.

```sh
xtool sdk install /chemin/vers/Xcode.xip
# Depuis le dossier illusion-ios :
xtool dev build --ipa
```

Cette commande produit un paquet non signé, qui ne peut pas être installé tel quel. Pour signer et installer sur un appareil, modifier `bundleID` dans `xtool.yml` avec un identifiant unique, configurer votre authentification Apple localement via `xtool auth`, connecter et approuver votre iPad, puis utiliser `xtool dev`. Ne jamais placer de mots de passe ou clés dans ce dépôt.

État : xtool a été téléchargé et exécuté ; `sdk status` indique « Not installed ». La commande `dev build --ipa` atteint la demande du chemin `Xcode.xip` et a été interrompue faute de SDK. Aucun IPA natif n’a été compilé ou signé.

## Ouvrir et installer avec Xcode

1. Sur un Mac, ouvrir `Illusion.xcodeproj` dans Xcode 15 ou plus récent.
2. Sélectionner le schéma **Illusion**, puis un simulateur iPad/iPhone et **Run**.
3. Pour un appareil physique : dans **Illusion → Signing & Capabilities**, sélectionner son équipe Apple et remplacer `com.illusionmagic.Illusion` par un identifiant unique. Sélectionner l’iPad connecté, puis **Run**. Activer le mode développeur sur l’appareil si Xcode le demande.
4. Pour distribuer par TestFlight : sélectionner une destination iOS générique, **Product → Archive**, puis utiliser la distribution App Store Connect avec votre équipe Apple Developer.

Ce dépôt contient le projet source, pas un IPA signé. Il a été préparé sous Linux : une compilation iOS et les essais sur appareil restent à effectuer. Le projet peut être compilé avec Xcode sur Mac ou xtool sous Linux (voir ci-dessous).

### Compilation sans signature sur Mac

```sh
xcodebuild -project Illusion.xcodeproj -scheme Illusion \
  -configuration Debug -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/IllusionDerivedData CODE_SIGNING_ALLOWED=NO build
```

## Utilisation

- Importer une image depuis Photos ou Fichiers, ou choisir cœur, as de pique ou étoile.
- Choisir un fond uni ou une autre photo. Le fond remplit l’écran avec recadrage ; l’image cachée est centrée et conserve ses proportions.
- Glisser un doigt ou l’Apple Pencil pour révéler progressivement l’image. Un toucher bref sur une partie déjà révélée la fait disparaître immédiatement. Les pixels transparents de l’image ne déclenchent pas la disparition.
- **Recommencer** réarme le tour. **Lancer le spectacle** réinitialise la scène et masque les réglages.
- Maintenir **×** une seconde pour quitter le spectacle. L’extinction automatique est suspendue pendant le spectacle et restaurée en sortant.
- Les changements d’orientation redimensionnent les traits déjà dessinés.

Les photos importées sont corrigées selon leur orientation et réduites à 2048 pixels maximum. Les copies PNG et les réglages JSON restent dans Application Support. L’application n’envoie aucune donnée et ne demande pas l’accès global à la photothèque : le sélecteur système ne fournit que les photos choisies. L’import depuis iCloud peut nécessiter le réseau ; les images importées fonctionnent ensuite hors ligne.

## Validation avant distribution

La structure du projet, les ressources et la syntaxe des sources peuvent être vérifiées sous Linux. Cela ne remplace pas une compilation iOS ni des tests UIKit.

À exécuter sur simulateur puis sur iPad :

1. Révéler le cœur par plusieurs glissements ; vérifier qu’un relâchement après glissement ne le fait pas disparaître.
2. Toucher une partie révélée : disparition immédiate, aucun retour en continuant à gratter. Recommencer réarme.
3. Toucher une zone encore cachée ou transparente d’un PNG : pas de disparition.
4. Importer JPG/HEIC/PNG depuis Photos et Fichiers ; annuler un import ; essayer un fichier invalide ; vérifier le message d’erreur.
5. Choisir un fond photo puis revenir à une couleur. Fermer et relancer : réglages et photos conservés.
6. Tester portrait/paysage, multitâche iPad, petit iPhone, Apple Pencil et interruption par passage en arrière-plan.
7. Entrer et sortir du spectacle par appui long ; vérifier les marges du bouton ×, le masquage des commandes et le retour du verrouillage automatique.

## Documentation Apple

- [PhotosPickerItem](https://developer.apple.com/documentation/photosui/photospickeritem)
- [Gestion native des événements tactiles](https://developer.apple.com/documentation/uikit/handling-touches-in-your-view)
