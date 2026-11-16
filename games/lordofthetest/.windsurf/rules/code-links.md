# Clickable Source Code Links

When referencing source code in chat responses, always provide clickable links using this exact format:

```
[filename.ext:LINE](windsurf://file/c:/absolute/path/to/filename.ext:LINE)
```

Rules:
- Use the `windsurf://file/` URI scheme (NOT plain paths or GitHub-style `#L` anchors)
- Use forward slashes in the path
- Put the line number after a colon at the end (`:70`), and also show it in the link text
- Use the file's absolute path starting from the drive letter, e.g. `c:/Minetest/...`
