# Witflo Documentation

This directory contains the official Witflo documentation site built with [VitePress](https://vitepress.dev/).

## Development

### Local Development

```bash
npm run docs:dev
```

Open http://localhost:5173 in your browser.

### File Structure

```
docs/
├── .vitepress/
│   └── config.ts          # VitePress configuration
├── public/                # Static assets
├── guide/                 # User guide pages
├── developers/            # Developer documentation
├── security/              # Security documentation
└── index.md              # Homepage
```

### Adding New Pages

1. Create a new `.md` file in the appropriate directory
2. Add it to the sidebar in `.vitepress/config.ts`
3. Write content using markdown

Example:

```markdown
# Page Title

Your content here...

## Section

More content...
```

### Markdown Features

VitePress supports:

- **GitHub Flavored Markdown**
- **Code highlighting** with language tags
- **Custom containers** (tip, warning, danger, info)
- **Embedded Vue components**
- **Emoji** :rocket:

#### Code Blocks

\`\`\`dart
void main() {
  print('Hello, Witflo!');
}
\`\`\`

#### Custom Containers

```markdown
::: tip
This is a tip
:::

::: warning
This is a warning
:::

::: danger
This is a danger alert
:::
```

## Deployment

### GitHub Pages

1. Build the site:
   ```bash
   npm run docs:build
   ```

2. The output will be in `.vitepress/dist/`

3. Deploy to GitHub Pages:
   ```bash
   # Add to git
   git add .
   git commit -m "docs: Update documentation"
   git push
   ```

4. Configure GitHub Pages to use GitHub Actions (see `.github/workflows/deploy-docs.yml`)

### Custom Domain

Update `.vitepress/config.ts`:

```ts
export default defineConfig({
  // ... other config
  base: '/', // For custom domain
  // base: '/witflo/', // For GitHub Pages
})
```

## Contributing

To contribute to the documentation:

1. Fork the repository
2. Create a feature branch (`git checkout -b docs/improve-guide`)
3. Make your changes
4. Test locally (`npm run docs:dev`)
5. Commit and push
6. Open a pull request

## Style Guide

### Headings

- Use `#` for page title (H1) - only one per page
- Use `##` for main sections (H2)
- Use `###` for subsections (H3)
- Don't skip heading levels

### Writing Style

- Write in clear, simple language
- Use active voice
- Be concise
- Use examples
- Use code blocks for commands and code

### Formatting

- Use **bold** for emphasis
- Use `code` for inline code, commands, file paths
- Use code blocks for multi-line code
- Use lists for steps or options

## Troubleshooting

### Port already in use

```bash
# Kill process on port 5173
lsof -ti:5173 | xargs kill -9
```

### Build errors

```bash
# Clean and reinstall
rm -rf node_modules .vitepress/cache
npm install
```

## Resources

- [VitePress Documentation](https://vitepress.dev/)
- [Markdown Guide](https://www.markdownguide.org/)
- [Witflo Main Repo](https://github.com/nativewit/witflo)

## License

Documentation is licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).

Code examples in documentation are licensed under [MPL-2.0](../witflo/LICENSE).
