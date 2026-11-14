# DeckCraft on GitHub Pages

This repository publishes the prebuilt [DeckCraft](https://github.com/storytold/deckcraft) web app. The workflow downloads the official release with GitHub CLI, verifies its SHA-256 checksum, and deploys the static files to GitHub Pages; the WebAssembly binary is not committed here.

The intended URL is <https://mhammedamazil-hub.github.io/App/> once Pages is enabled and the deployment succeeds. Open it in a modern mobile, tablet, or desktop browser. DeckCraft uses WebGPU when available and falls back to WebGL2; browser/device support and the upstream app's touch layout may vary.

## Setup and updates

1. In repository **Settings → Pages**, set **Build and deployment → Source** to **GitHub Actions**.
2. Push the workflow to `main` or run **Deploy DeckCraft to GitHub Pages** from the Actions tab after the workflow exists on the default branch. The initial working branch can also trigger a deployment on push.
3. The workflow defaults to DeckCraft `0.18.1`. To deploy another release, run it manually with a version such as `0.18.1` (without the `v`), or update the default version in both the workflow and `scripts/prepare-site.sh`. Manual runs do not change that default.

Check the Actions run for deployment errors. GitHub Pages must be available for the repository, and the `github-pages` environment must allow the deploying branch. Files are from the upstream project and subject to its licenses; see the documentation included in the deployed release.
