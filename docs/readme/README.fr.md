# MacAndFiles

<img src="../../Resources/Icon/AppIcon-master.png" width="128" alt="MacAndFiles app icon">

[English](../../README.md) · [한국어](README.ko.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md) · [Español](README.es.md) · [Português](README.pt-BR.md) · [日本語](README.ja.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Русский](README.ru.md) · [हिन्दी](README.hi.md) · [Bahasa Indonesia](README.id.md) · [العربية](README.ar.md)

App native SwiftUI pour transférer des fichiers par USB entre Android et un Mac Apple Silicon. Interface minimale façon Finder, couleur d’accent du système, recherche native et Liquid Glass. Elle s’installe séparément de Google Android File Transfer.

## Configuration et installation

Nécessite **Apple Silicon / arm64 et macOS 14.0 ou ultérieur**. Testée sur macOS 27.2 et Galaxy Z Fold7 ; macOS 28, Intel et les autres appareils ne sont pas vérifiés. Lancez `dist/MacAndFiles.app` après compilation, ou extrayez le ZIP et placez l’app dans Applications. libmtp/libusb sont inclus ; Homebrew et Android Studio ne sont pas nécessaires à l’exécution. Version de développement signée ad-hoc, sans Developer ID ni notarisation.

## Connexion et utilisation

Connectez avec un câble USB de données, déverrouillez Android et sélectionnez « Transfert de fichiers / Android Auto ». Quittez Android File Transfer, son Agent et les autres apps MTP. Recherchez les appareils, sélectionnez-en un et connectez-le. Le débogage USB et ADB ne sont pas nécessaires. Double-cliquez sur les dossiers ; ⌘D enregistre sur Mac, ⌘U envoie vers Android. Vous pouvez déposer des fichiers Finder. ⌘↑ remonte, ⌘⇧N crée un dossier, ⌘R actualise. ⌘F recherche uniquement les noms dans le dossier actuel ; effacer ou Esc restaure la liste. Les éléments masqués par la recherche sont désélectionnés. Plus contient aide, déconnexion et diagnostic. Vérifiez les noms avant de partager les journaux.

## Langues

Suit la langue préférée de macOS et la langue par app dans Réglages Système → Général → Langue et région. Relancez après modification. Inclut 13 langues ; les autres utilisent l’anglais. Dates, tailles et pourcentages suivent la région. Les noms de fichiers et appareils sont préservés ; les diagnostics de bibliothèques peuvent rester en anglais.

## Comportement des transferts

Un nom existant arrête l’opération sans écraser. Les téléchargements passent par un fichier temporaire et un contrôle de taille avant le nom final ; les envois vérifient la taille indiquée par Android. L’annulation ou l’échec conserve les fichiers terminés et peut laisser des fichiers incomplets sur Android. Les dossiers sont copiés récursivement avec une profondeur maximale de 128 ; liens symboliques et fichiers spéciaux sont refusés. La progression tient compte des fichiers et octets de toute l’opération. Seul le contenu exposé par MTP est accessible ; suppression, renommage et montage Finder ne sont pas implémentés.

## Compilation et vérification

Nécessite Swift 6.2+, SDK macOS 26+, libmtp 1.1.23 et libusb 1.0.30. Le script vérifie versions et SHA-256 des sources et inclut bibliothèques dynamiques et sources. L’archive exclut compilations et diagnostics privés. Les commandes suivantes sont des diagnostics en lecture seule, pas une CLI générale ni MCP. `--verify-transfer` écrit des fichiers UUID de test : déconnectez la GUI, utilisez seulement un appareil autorisé et vérifiez les résidus possibles.

```sh
brew install pkg-config
scripts/test.sh
scripts/test-localization.sh
scripts/test-cli.sh
scripts/test-progress.sh
scripts/build-app.sh
scripts/package-source.sh
```

```sh
"dist/MacAndFiles.app/Contents/MacOS/MacAndFiles" --diagnose
"dist/MacAndFiles.app/Contents/MacOS/MacAndFiles" --probe
```

## Licences et contributions

Code, scripts et documentation : **MIT**. Robot Android : **CC BY 3.0**. libmtp/libusb : **LGPL-2.1-or-later**. Conservez licences et avis. Android est une marque de Google LLC ; cette app n’est pas officielle. MacAndFiles est un nom de développement : examinez marque et notarisation avant publication. Le README anglais contient la référence technique complète. Lisez AGENT.md pour contribuer. Ce processus n’a pas encore publié sur GitHub.

[English reference](../../README.md) · [Validation](../../VALIDATION.md) · [LICENSE](../../LICENSE) · [Third-party notices](../../THIRD_PARTY_NOTICES.md) · [AGENT.md](../../AGENT.md) · [Release guide](../RELEASING.md) · [Localization guide](../LOCALIZATION.md)

## Terminal et agents

Après avoir installé l’app, installez `maf` avec `scripts/install-cli.sh`. Retrouvez les identifiants avec `maf devices` et `maf storages --device "ID"`. Consultez `maf help` et le [guide CLI](../CLI.md) pour lister, envoyer, télécharger et créer des dossiers. La sortie est JSON ; les échecs renvoient des codes d’erreur et un statut non nul. Déconnectez l’appareil dans l’interface avant d’utiliser la CLI.

```sh
maf help
maf devices
maf storages --device "DEVICE_ID"
maf ls --device "DEVICE_ID" --storage 65537 --path /Download
```

## 1.0.0 (9)

Compilée pour macOS 14+. Testée sur macOS 27.2 ; les versions antérieures restent à vérifier sur matériel réel. Liquid Glass dès macOS 26.

Nombre total, fichiers terminés, progression globale, vitesse moyenne et temps restant estimé. Les fichiers terminés restent conservés en cas d’arrêt.

Installez maf via Plus → Terminal et agents. Ajoutez ~/.local/bin au PATH si nécessaire. Déconnectez la GUI avant une opération CLI.

maf partage le moteur de transfert : résultats JSON, erreurs stables et état USB clair pour scripts et agents.

[MacAndFiles](https://macandfiles.pages.dev/fr/) · [CLI](../CLI.md) · [Release](../RELEASING.md)
