# Beviamolo

Your smart wine cellar manager: photograph the label and the AI recognises the wine, keep every
bottle in its place in your cellar grid, find the right wine for your dish and share lists of
bottles with friends.

**Website:** <https://www.beviamolo.it>

This repository hosts the **Linux release builds** of Beviamolo. The application is proprietary:
the source code is not published here.

## Get Beviamolo

| Platform | Where |
|---|---|
| Android | [Google Play](https://play.google.com/store/apps/details?id=dev.lab897.beviamolo) |
| Windows | [Microsoft Store](https://apps.microsoft.com/detail/9PDBQRNKF360) |
| Linux | [Snap Store](https://snapcraft.io/beviamolo) · or the archive in [Releases](https://github.com/lab897/Beviamolo/releases) |

## Linux archive

Each [release](https://github.com/lab897/Beviamolo/releases) contains
`beviamolo-linux-x64.tar.gz` (x86_64) and its SHA-256 checksum.

```bash
sha256sum -c SHA256SUMS
tar -xzf beviamolo-linux-x64.tar.gz
./beviamolo-linux/bundle/beviamolo
```

The archive needs GTK 3 and libsecret, which most desktop distributions already include
(Debian/Ubuntu: `libgtk-3-0 libsecret-1-0`).

## Account and AI credits

A free Beviamolo account is required. Searching the wine catalogue is free; label recognition
and food pairing use AI credits, with a free monthly allowance included in every account.
No ads.

## License

Proprietary, free to use: see [LICENSE](LICENSE). The Terms of Service and the Privacy Policy
are in the app, under Settings → Info, Terms & Contacts.

## Support

From the app: Settings → Info, Terms & Contacts.
