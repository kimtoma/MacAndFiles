# MacAndFiles

<img src="../../Resources/Icon/AppIcon-master.png" width="128" alt="MacAndFiles app icon">

[English](../../README.md) · [한국어](README.ko.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md) · [Español](README.es.md) · [Português](README.pt-BR.md) · [日本語](README.ja.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Русский](README.ru.md) · [हिन्दी](README.hi.md) · [Bahasa Indonesia](README.id.md) · [العربية](README.ar.md)

Native SwiftUI-App für USB-Dateiübertragungen zwischen Android und Apple-Silicon-Macs. Minimale Finder-Oberfläche mit Systemakzentfarbe, nativer Suche und Liquid Glass. Sie wird getrennt von Google Android File Transfer installiert.

## Voraussetzungen und Installation

Benötigt **Apple Silicon / arm64 und macOS 14.0 oder neuer**. Getestet mit macOS 27.2 und Galaxy Z Fold7; macOS 28, Intel und andere Geräte sind nicht geprüft. Nach dem Build `dist/MacAndFiles.app` starten oder das ZIP entpacken und die App in Programme ablegen. libmtp/libusb sind enthalten; zum Ausführen werden weder Homebrew noch Android Studio benötigt. Ad-hoc-signierter Entwicklungsbuild ohne Developer ID und Notarisierung.

## Verbinden und verwenden

Mit USB-Datenkabel verbinden, Android entsperren und „Dateiübertragung / Android Auto“ wählen. Android File Transfer, dessen Agent und andere MTP-Apps beenden. Geräte suchen, Gerät auswählen und verbinden. USB-Debugging und ADB sind nicht nötig. Ordner per Doppelklick öffnen; ⌘D sichert auf Mac, ⌘U sendet an Android. Finder-Dateien können abgelegt werden. ⌘↑ geht nach oben, ⌘⇧N erstellt einen Ordner, ⌘R aktualisiert. ⌘F durchsucht nur Namen im aktuellen Ordner; Löschen oder Esc stellt die Liste wieder her. Verborgene Suchobjekte werden abgewählt. Mehr enthält Hilfe, Trennen und Diagnose. Dateinamen vor dem Teilen von Protokollen prüfen.

## Sprachen

Verwendet die bevorzugte macOS-Sprache und die App-Sprache in Systemeinstellungen → Allgemein → Sprache & Region. Nach Änderungen neu starten. 13 Sprachen sind enthalten; andere verwenden Englisch. Datum, Größen und Prozentwerte folgen der Region. Datei- und Gerätenamen bleiben erhalten; Bibliotheksdiagnosen können englisch bleiben.

## Übertragungsverhalten

Namenskollisionen stoppen den Vorgang; nichts wird überschrieben. Downloads werden temporär geschrieben, nach Größe geprüft und dann unter dem endgültigen Namen abgelegt. Uploads prüfen die von Android gemeldete Größe. Abbruch oder Fehler erhält fertige Dateien und kann unvollständige Dateien auf Android hinterlassen. Ordner werden bis Tiefe 128 rekursiv kopiert; symbolische Links und Spezialdateien werden abgelehnt. Der Fortschritt umfasst Dateien und Bytes des gesamten Vorgangs. Nur über MTP freigegebene Inhalte sind zugänglich; Löschen, Umbenennen und Finder-Volumes sind nicht implementiert.

## Bauen und prüfen

Benötigt Swift 6.2+, macOS-26+-SDK, libmtp 1.1.23 und libusb 1.0.30. Das Skript prüft Versionen und Quellarchiv-SHA-256 und bündelt dynamische Bibliotheken mit Quellen. Das Quellarchiv schließt Builds und private Diagnosen aus. Folgende Befehle sind lesende Diagnosen, keine allgemeine Datei-CLI oder MCP. `--verify-transfer` schreibt UUID-Testdateien: GUI trennen, nur ein autorisiertes Testgerät verwenden und mögliche Reste prüfen.

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

## Lizenzen und Beiträge

Code, Skripte und Dokumentation: **MIT**. Android-Roboter: **CC BY 3.0**. libmtp/libusb: **LGPL-2.1-or-later**. Lizenzen und Hinweise beibehalten. Android ist eine Marke von Google LLC; dies ist keine offizielle App. MacAndFiles ist ein Entwicklungsname. Marken- und Notarisierungsanforderungen vor Veröffentlichung prüfen. Das englische README enthält die vollständige technische Referenz. Für Beiträge AGENT.md lesen. Dieser Ablauf hat noch nichts auf GitHub veröffentlicht.

[English reference](../../README.md) · [Validation](../../VALIDATION.md) · [LICENSE](../../LICENSE) · [Third-party notices](../../THIRD_PARTY_NOTICES.md) · [AGENT.md](../../AGENT.md) · [Release guide](../RELEASING.md) · [Localization guide](../LOCALIZATION.md)

## Terminal und Agenten

Installiere nach der App `maf` mit `scripts/install-cli.sh`. Ermittle IDs mit `maf devices` und `maf storages --device "ID"`. Auflisten, Hochladen, Herunterladen und Ordner erstellen: siehe `maf help` und [CLI-Anleitung](../CLI.md). Die Ausgabe ist JSON; Fehler liefern Fehlercodes und einen Exit-Status ungleich null. Trenne das Gerät in der GUI vor der CLI-Nutzung.

```sh
maf help
maf devices
maf storages --device "DEVICE_ID"
maf ls --device "DEVICE_ID" --storage 65537 --path /Download
```

## 1.0.0 (9)

Für macOS 14+ gebaut. Auf macOS 27.2 getestet; ältere Versionen brauchen noch Praxistests. Liquid Glass ab macOS 26.

Gesamtzahl, fertige Dateien, Gesamtfortschritt, mittlere Geschwindigkeit und geschätzte Restzeit. Fertige Dateien bleiben beim Stoppen erhalten.

maf unter Mehr → Terminal und Agenten installieren. Bei Bedarf ~/.local/bin zum PATH hinzufügen. Vor CLI-Dateiaktionen die GUI trennen.

maf nutzt denselben Motor: JSON-Ergebnisse, stabile Fehlercodes und klarer USB-Sitzungsstatus für Skripte und Agenten.

[MacAndFiles](https://kimtoma.github.io/MacAndFiles/de/) · [CLI](../CLI.md) · [Release](../RELEASING.md)
