# dcm-project.github.io

Official DCM project documentation website — architecture decisions, guides, blog posts, and demo recordings.

## Prerequisites

- [Hugo](https://gohugo.io/installation/) (extended version)
- [Go](https://go.dev/doc/install) 1.21+

## Local Development

```bash
# Clone the repository
git clone https://github.com/dcm-project/dcm-project.github.io.git
cd dcm-project.github.io

# Start local server with drafts
hugo server --buildDrafts

# Build for production
hugo --minify
```

The site will be available at http://localhost:1313

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-change`)
3. Make your changes
4. Test locally with `hugo server --buildDrafts`
5. Commit your changes (`git commit -s -m "Description of change"`)
6. Push to your fork and open a Pull Request

### Adding an ADR

1. Copy `content/docs/adr/adr-template.md` to `content/docs/adr/adr-NNN-short-title.md`
2. Update the frontmatter (title, weight) and remove `draft: true`
3. Fill in the sections
4. Add any diagrams to `static/images/adr/NNN-short-title/`

### Adding a Blog Post

Create a new file in `content/blog/` with frontmatter:

```yaml
---
title: "Your Post Title"
date: 2025-01-15
authors:
  - name: Your Name
---
```

## License

See [LICENSE](LICENSE) for details.
