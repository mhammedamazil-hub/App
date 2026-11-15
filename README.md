# Craft apps on GitHub Pages

This repository hosts the official prebuilt browser releases of the [Storytold Craft apps](https://github.com/storytold) on a shared launcher page at <https://mhammedamazil-hub.github.io/App/>. Open it on a modern desktop, tablet, or phone browser. App downloads can be large; browser, GPU, and touch support differ by app and device.

The launcher includes 15 creative apps and ArtCraft Launcher. AniCraft and ArtCraft itself do not currently have a published web release asset and are not included. The list reflects releases available when this repository was updated, not automatic discovery of future apps.

## Deployment and updates

- Set **Settings → Pages → Build and deployment → Source** to **GitHub Actions**. Merging changes to `site/`, `scripts/`, or the workflow into `main` starts a deployment. You can also run **Deploy Craft apps to GitHub Pages** manually from Actions.
- `scripts/releases.tsv` pins each app's repository, archive prefix and version. To update an app, change its version to an existing release containing the corresponding web ZIP and `SHA256SUMS.txt`, then deploy again. Add newly published apps to this list and link them from `site/index.html`.
- The workflow uses GitHub CLI to download each archive and checksum file, verifies each archive's SHA-256 against the upstream checksum, then deploys all sites together. An unavailable release or failed checksum stops the deployment so a partial site is not published. The WebAssembly files are not committed to this repository. Checksums detect corruption but are not independent signature verification.
- Each app is under its own path, for example `/App/deckcraft/`. The previous DeckCraft root URL now opens the launcher instead.

Check Actions for deployment errors. Pages must be available for the repository and the `github-pages` environment must allow `main`. Apps and included documentation are provided by their upstream projects under their respective licenses.
