# Print Collector Agent — Binaires publics 1Acces

Binaires standalone du Print Collector Agent pour collecte automatique
des volumes d'impression (module Gestion Impression ERP 1Acces).

## Téléchargement

Les derniers binaires sont disponibles sur la page [Releases](https://github.com/Ipercom/print-agent-releases/releases/latest) :

- macOS Apple Silicon : `print-agent-macos-arm64`
- macOS Intel : `print-agent-macos-x64`
- Linux x64 : `print-agent-linux-x64`
- Linux ARM64 (Raspberry Pi) : `print-agent-linux-arm64`
- Windows x64 : `print-agent-win-x64.exe`

## Vérification intégrité

`SHA256SUMS.txt` contient les empreintes SHA-256. Vérifier avant exécution :

```bash
sha256sum -c SHA256SUMS.txt
```

## Code source

Code source privé dans [Ipercom/ERP-PME](https://github.com/Ipercom/ERP-PME)
(accès réservé). Ce repo public héberge uniquement les binaires compilés.

## Signature

**Actuellement non signés** — macOS Gatekeeper et Windows SmartScreen
afficheront un avertissement au premier lancement. Solutions :
- **macOS** : `xattr -cr <binaire>` avant exécution
- **Windows** : "Exécuter quand même" dans le dialog SmartScreen

Signatures Apple Developer ID + Windows Authenticode prévues en v1.1.

## Licence

Propriétaire — 1Acces (SAH SOLUTIONS). Usage strictement réservé aux clients.
