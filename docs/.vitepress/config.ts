import { defineConfig } from 'vitepress'
import { withMermaid } from 'vitepress-plugin-mermaid'

// https://vitepress.dev/reference/site-config
export default withMermaid(defineConfig({
  title: "Witflo",
  description: "Zero-trust, privacy-first, offline-first encrypted notes",
  base: '/',
  
  // Ignore dead links in README.md (not part of docs site)
  ignoreDeadLinks: [
    /^http:\/\/localhost/,
    /\.\.\/LICENSE/
  ],
  
  head: [
    ['link', { rel: 'icon', href: '/favicon.ico' }]
  ],

  themeConfig: {
    // https://vitepress.dev/reference/default-theme-config
    logo: '/logo.svg',
    
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Guide', link: '/guide/getting-started' },
      { text: 'Security', link: '/security/encryption' }
    ],

    sidebar: {
      '/guide/': [
        {
          text: 'User Guide',
          items: [
            { text: 'Getting Started', link: '/guide/getting-started' },
            { text: 'Installation', link: '/guide/installation' },
            { text: 'Features', link: '/guide/features' },
            { text: 'FAQ', link: '/guide/faq' }
          ]
        }
      ],
      '/security/': [
        {
          text: 'Security & Privacy',
          items: [
            { text: 'Encryption', link: '/security/encryption' },
            { text: 'Privacy Guarantees', link: '/security/privacy' }
          ]
        }
      ]
    },

    socialLinks: [
      { icon: 'github', link: 'https://github.com/nativewit/witflo' }
    ],

    footer: {
      message: 'Released under the AGPL-3.0 License.',
      copyright: 'Copyright © 2025-present Witflo'
    },

    search: {
      provider: 'local'
    }
  },
  
  // Mermaid configuration - auto-detect theme based on VitePress dark mode
  mermaid: {
    // This will be overridden by the theme switcher
  },
  
  mermaidPlugin: {
    class: 'mermaid'
  }
}))
