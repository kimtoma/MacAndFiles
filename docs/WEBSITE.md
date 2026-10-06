# Website

The primary website is <https://macandfiles.pages.dev/>. GitHub Pages remains a mirror at <https://kimtoma.github.io/MacAndFiles/>. Both serve the same static pages in 13 languages, with Cloudflare as the canonical URL.

Edit `website/locales/`, `website/assets/`, or `scripts/build-site.py`. Do not edit generated HTML under `docs/` by hand. The creator credit stays in English, including on RTL pages; Android artwork and bundled-library notices remain separate.

## Deploy to Cloudflare Pages

This is a Direct Upload Pages project, using the personal `kimtoma` Cloudflare account and production branch `main`. Deployments are manual; a Git push updates the GitHub Pages mirror but does not deploy Cloudflare.

```sh
npm --prefix website ci
npm --prefix website exec -- wrangler login --scopes account:read user:read pages:write
npm --prefix website run deploy
```

The deploy command regenerates and verifies the translated pages before uploading `docs/`. Wrangler is pinned in `website/package-lock.json`. Authentication stays in Wrangler's user configuration, outside the repository. No API token is required in source control.

For a fork, change the account in `website/package.json` and project in `website/wrangler.jsonc`, create your own Pages project, and update the canonical `URL` in `scripts/build-site.py` and README website links.

After deployment, check the production URL, language switching, the download link, creator profile link, and an RTL page. A successful upload alone does not verify the published site.
