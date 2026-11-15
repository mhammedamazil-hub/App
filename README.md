# Craft apps on GitHub Pages

This repository hosts the official prebuilt browser releases of the [Storytold Craft apps](https://github.com/storytold) on a shared launcher page at <https://mhammedamazil-hub.github.io/App/>. Open it on a modern desktop, tablet, or phone browser. App downloads can be large; browser, GPU, and touch support differ by app and device.

The launcher includes 15 creative apps and ArtCraft Launcher. AniCraft and ArtCraft itself do not currently have a published web release asset and are not included. The list reflects releases available when this repository was updated, not automatic discovery of future apps.

## Deployment and updates

- Set **Settings → Pages → Build and deployment → Source** to **GitHub Actions**. Merging changes to `site/`, `scripts/`, or the workflow into `main` starts a deployment. You can also run **Deploy Craft apps to GitHub Pages** manually from Actions.
- `scripts/releases.tsv` pins each app's repository, archive prefix and version. To update an app, change its version to an existing release containing the corresponding web ZIP and `SHA256SUMS.txt`, then deploy again. Add newly published apps to this list and link them from `site/index.html`.
- The workflow uses GitHub CLI to download each archive and checksum file, verifies each archive's SHA-256 against the upstream checksum, then deploys all sites together. An unavailable release or failed checksum stops the deployment so a partial site is not published. The WebAssembly files are not committed to this repository. Checksums detect corruption but are not independent signature verification.
- Each app is under its own path, for example `/App/deckcraft/`. The previous DeckCraft root URL now opens the launcher instead.

Check Actions for deployment errors. Pages must be available for the repository and the `github-pages` environment must allow `main`. Apps and included documentation are provided by their upstream projects under their respective licenses.

## Install, use offline, and local files

- On HTTPS, open the launcher once while online, then use your browser's **Install** or **Add to Home Screen** option. The launcher itself is cached by its service worker. iPhone/iPad users can use Safari's Share → Add to Home Screen. Browser support varies.
- Select **Save offline** beside each app while connected and wait for the success message before going offline. This downloads all files included in that app's release and can consume substantial storage. Test in airplane mode. Browser storage quotas or eviction may remove cached files; the launcher requests persistent storage when supported, but the browser decides whether to grant it. Apps may require a compatible GPU or external services, so caching files cannot guarantee every feature works offline. **Update offline** replaces a saved copy only after all new files are cached; a failed update keeps the previous copy. **Remove** deletes the selected app's offline copy.
- **Local file vault** stores copies you choose in this browser's IndexedDB. Export or download your document from an app, then add that file to the vault; retrieve it using **Download**. The vault does not intercept app saves, sync across devices, or automatically back up work. Clearing browser/site data, eviction, or device loss can delete files. Keep separate backups and check each app's own save/export behavior.
- When a new release is deployed, saved offline copies remain pinned to the version shown until you choose **Update offline**. Opening an app with an offline copy uses that copy even while online. The app's files are stored in Cache Storage; the selected version and vault files use IndexedDB.

## Checks

`node tests/sw.test.cjs` exercises offline cache lookup, update failure and removal using mocked browser APIs. Full device testing still requires a real browser, storage space, and compatible graphics hardware.
