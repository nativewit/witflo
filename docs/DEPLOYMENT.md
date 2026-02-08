# Deploying Witflo Docs to GitHub Pages

This guide shows you how to deploy the Witflo documentation to GitHub Pages.

## Prerequisites

- GitHub repository: `nativewit/witflo`
- Documentation is in the `/docs` directory
- VitePress configured with `base: '/'`

## Deployment Steps

### 1. Enable GitHub Pages

1. Go to your repository: https://github.com/nativewit/witflo
2. Click **Settings** → **Pages** (in the left sidebar)
3. Under **Source**, select:
   - Source: **GitHub Actions** (not "Deploy from a branch")

### 2. Push the Workflow File

The workflow file has already been created at `.github/workflows/deploy-docs.yml`.

Commit and push it:

```bash
git add .github/workflows/deploy-docs.yml
git commit -m "Add GitHub Pages deployment workflow"
git push origin main
```

### 3. Trigger the Deployment

The workflow will automatically run when:
- You push changes to the `docs/` directory
- You push changes to the workflow file itself
- You manually trigger it from the Actions tab

To manually trigger:
1. Go to **Actions** tab in your GitHub repository
2. Click **Deploy Docs** workflow
3. Click **Run workflow** → **Run workflow**

### 4. Access Your Documentation

Once the workflow completes (takes 2-3 minutes):

- Your docs will be live at: **https://nativewit.github.io/witflo/**

## How It Works

The GitHub Actions workflow:
1. ✅ Runs automatically on pushes to `main` branch (only when `docs/` changes)
2. ✅ Installs Node.js and dependencies
3. ✅ Builds the VitePress site (`npm run docs:build`)
4. ✅ Deploys to GitHub Pages
5. ✅ Can also be triggered manually from the Actions tab

## Local Preview

Before pushing, you can preview the built site locally:

```bash
cd docs
npm run docs:build
npm run docs:preview
```

This builds the site and serves it at `http://localhost:4173`

## Custom Domain (Optional)

If you want to use a custom domain (e.g., `docs.witflo.app`):

1. Add a `CNAME` file in `/docs/public/`:
   ```
   docs.witflo.app
   ```

2. Update VitePress config (`docs/.vitepress/config.ts`):
   ```ts
   export default withMermaid(defineConfig({
     // ... other config
     base: '/', // Keep as '/' for custom domain
   }))
   ```

3. Configure DNS:
   - Add a CNAME record pointing to `nativewit.github.io`

4. In GitHub Settings → Pages → Custom domain:
   - Enter: `docs.witflo.app`
   - Enable "Enforce HTTPS"

## Troubleshooting

### Workflow Fails on First Run

If you get a permissions error:
1. Go to **Settings** → **Actions** → **General**
2. Scroll to **Workflow permissions**
3. Select **Read and write permissions**
4. Check **Allow GitHub Actions to create and approve pull requests**
5. Click **Save**
6. Re-run the workflow

### Assets Not Loading (404s)

If CSS/JS files show 404 errors:
- Check that `base: '/'` in `config.ts` is correct
- If deploying to a subdirectory (e.g., `/witflo/`), change to `base: '/witflo/'`

### Docs Not Updating

- Check the **Actions** tab to see if the workflow ran successfully
- Clear your browser cache
- GitHub Pages can take 1-2 minutes to update after deployment

## Manual Deployment (Alternative)

If you prefer not to use GitHub Actions:

1. Build locally:
   ```bash
   cd docs
   npm run docs:build
   ```

2. The built site is in `docs/.vitepress/dist`

3. Deploy using `gh-pages` branch:
   ```bash
   npm install -g gh-pages
   gh-pages -d docs/.vitepress/dist
   ```

4. In GitHub Settings → Pages:
   - Source: **Deploy from a branch**
   - Branch: **gh-pages** / `/ (root)`

## Next Steps

- ✅ Workflow file created: `.github/workflows/deploy-docs.yml`
- ⏳ Commit and push the workflow
- ⏳ Enable GitHub Pages in repository settings
- ⏳ Watch the deployment in the Actions tab

Your documentation will be live at: **https://nativewit.github.io/witflo/**
