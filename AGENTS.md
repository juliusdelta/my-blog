# Agent Guidelines for Hugo Blog

## Build/Test Commands
- **Build**: `hugo` or `./build.sh` (includes git submodule update)
- **Development**: `hugo server` for local development with live reload
- **Clean build**: `hugo --cleanDestinationDir` to remove old files

## Technology Stack
- **Static Site Generator**: Hugo with PaperMod theme
- **Configuration**: `hugo.yaml` (YAML format)
- **Content**: Markdown files in `content/posts/`
- **Assets**: CSS in `assets/css/`, images in `assets/images/` and `static/`

## Content Guidelines
- **Posts**: Use frontmatter with `title`, `author`, `date`, `tags`, `categories`
- **Drafts**: Set `draft: true` in frontmatter
- **Shortcodes**: Use custom shortcodes like `{{< standout >}}`, `{{< blockquote >}}`
- **Structure**: Each post in its own directory with `index.md`

## Code Style
- **HTML Templates**: Use Go template syntax, 2-space indentation
- **Markdown**: Standard markdown with Hugo shortcodes
- **CSS**: Minimal custom styles in `assets/css/extended/custom.css`
- **Images**: Store in post directories or `assets/images/`
- **Configuration**: Use YAML format, maintain existing parameter structure