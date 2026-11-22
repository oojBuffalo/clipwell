# Clipwell

A keyboard-first clipboard history for the macOS menu bar.

[![MIT license](https://img.shields.io/badge/license-MIT-17674d)](LICENSE)
![macOS 14 or later](https://img.shields.io/badge/macOS-14%2B-262d2b?logo=apple&logoColor=white)
![Swift tools 5.9 or later](https://img.shields.io/badge/Swift_tools-5.9%2B-F05138?logo=swift&logoColor=white)

Clipwell keeps a searchable history of text you copy on your Mac. Press **Control–Option–V** to find a previous clip, or use **Control–Option–1**, **2**, or **3** to put a recent clip back on the clipboard while you work in another app.

## Build and run

On macOS 14 or later with a Swift 5.9 or later toolchain, run the following commands.

```sh
git clone https://github.com/oojBuffalo/clipwell.git
cd clipwell
./script/build_and_run.sh
```

The script builds and opens `dist/Clipwell.app`. Look for the clipboard icon in the menu bar. To keep Clipwell in Applications, quit it from the icon’s right-click menu and move the bundle there.

## Use your history

1. Copy some text in any app with **Command–C**. If macOS asks for pasteboard access, allow it so Clipwell can capture new copies.
2. Press **Control–Option–V** or click the clipboard icon. Type part of a clip to filter the list.
3. Choose a clip with **↑** or **↓** and press **Return**. The panel closes and the selected text is on your clipboard.
4. Paste with **Command–V** in your destination app.

| Shortcut | Where | Action |
| --- | --- | --- |
| Control–Option–V | Any app | Open or close history |
| Control–Option–1 / 2 / 3 | Any app | Copy the newest, second-newest, or third-newest clip |
| ↑ / ↓ | History | Select the previous or next matching clip |
| Return | History | Copy the selection and close the panel |
| Command–P | History | Pin or unpin the selection |
| Command–1 / Command–2 | History | Show all clips or only pinned clips |
| Command–F | History | Focus the search field |
| Escape | Panel | Go back from a subpage or close history |

Click the pin beside the search field to show only pinned clips. Open **More options (···) → Keyboard Shortcuts** for the shortcut guide, including any global shortcuts unavailable on your Mac.

## History and privacy

Clipwell stores the latest **100 unpinned clips** plus anything you pin. Copying the same text again moves it to the top and preserves its pin. Clips and pause state persist across launches in `~/Library/Application Support/Clipwell/history.json`, a plain-text file readable by your macOS account.

Clipwell skips content that the source app marks confidential or transient. Choose **More options (···) → Pause History** before copying sensitive text from an app that leaves it unmarked. Click **Paused** to resume. **Clear Unpinned History** in the same menu keeps your pins and the current clipboard.

## Contributing

Clipwell is a Swift package with a single macOS executable and no external package dependencies. [AppMain.swift](Sources/Clipwell/AppMain.swift) owns the AppKit menu bar item and floating panel. [HistoryView.swift](Sources/Clipwell/HistoryView.swift) renders search and selection in SwiftUI. [HistoryStore.swift](Sources/Clipwell/HistoryStore.swift) monitors the pasteboard and saves the history.

Run the tests from the project root. They use isolated pasteboards and temporary storage.

```sh
swift test
```

## License

Clipwell is distributed under the [MIT License](LICENSE).
