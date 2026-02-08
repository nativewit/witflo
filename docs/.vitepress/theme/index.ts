import DefaultTheme from 'vitepress/theme'
import { onMounted, watch } from 'vue'
import { useData } from 'vitepress'
import './custom.css'

export default {
  extends: DefaultTheme,
  setup() {
    const { isDark } = useData()

    onMounted(() => {
      // Set initial Mermaid theme
      updateMermaidTheme(isDark.value)
    })

    // Watch for theme changes
    watch(isDark, (newValue) => {
      updateMermaidTheme(newValue)
    })

    function updateMermaidTheme(dark: boolean) {
      if (typeof window !== 'undefined' && (window as any).mermaid) {
        const theme = dark ? 'dark' : 'default'
        ;(window as any).mermaid.initialize({ 
          theme,
          startOnLoad: true,
          flowchart: {
            useMaxWidth: true,
            htmlLabels: true,
            curve: 'basis'
          }
        })
        // Re-render all mermaid diagrams
        ;(window as any).mermaid.contentLoaded()
      }
    }
  }
}
