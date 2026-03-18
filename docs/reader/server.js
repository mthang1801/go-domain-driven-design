const express = require('express');
const fs = require('fs');
const path = require('path');
const { Marked } = require('marked');
const { markedHighlight } = require('marked-highlight');
const hljs = require('highlight.js');

const app = express();
const PORT = 6868;
const DOCS_DIR = path.resolve(__dirname, '..');

// Configure marked with syntax highlighting
const marked = new Marked(
  markedHighlight({
    langPrefix: 'hljs language-',
    highlight(code, lang) {
      if (lang && hljs.getLanguage(lang)) {
        return hljs.highlight(code, { language: lang }).value;
      }
      return hljs.highlightAuto(code).value;
    }
  })
);

marked.setOptions({
  gfm: true,
  breaks: false,
});

// Serve static files
app.use('/static', express.static(path.join(__dirname, 'public')));

// API: Get file tree
app.get('/api/tree', (req, res) => {
  const tree = buildTree(DOCS_DIR, '');
  res.json(tree);
});

// API: Get markdown content (rendered as HTML)
app.get('/api/content', (req, res) => {
  const filePath = req.query.path;
  if (!filePath) {
    return res.status(400).json({ error: 'Missing path parameter' });
  }

  const fullPath = path.join(DOCS_DIR, filePath);
  const normalizedFull = path.normalize(fullPath);

  // Security: prevent directory traversal
  if (!normalizedFull.startsWith(DOCS_DIR)) {
    return res.status(403).json({ error: 'Access denied' });
  }

  if (!fs.existsSync(normalizedFull)) {
    return res.status(404).json({ error: 'File not found' });
  }

  const raw = fs.readFileSync(normalizedFull, 'utf-8');
  const html = marked.parse(raw);
  res.json({ html, raw, title: path.basename(filePath, '.md') });
});

// API: Search across all markdown files
app.get('/api/search', (req, res) => {
  const query = (req.query.q || '').toLowerCase().trim();
  if (!query || query.length < 2) {
    return res.json([]);
  }

  const results = [];
  searchFiles(DOCS_DIR, '', query, results);
  res.json(results.slice(0, 30));
});

// Serve index.html for all other routes
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

function buildTree(dirPath, relativePath) {
  const entries = fs.readdirSync(dirPath, { withFileTypes: true });
  const children = [];

  // Separate dirs and files, then sort
  const dirs = entries.filter(e => e.isDirectory() && !e.name.startsWith('.') && e.name !== 'node_modules' && e.name !== 'reader');
  const files = entries.filter(e => e.isFile() && e.name.endsWith('.md'));

  // Sort by name, but README first
  files.sort((a, b) => {
    if (a.name === 'README.md') return -1;
    if (b.name === 'README.md') return 1;
    return a.name.localeCompare(b.name);
  });

  dirs.sort((a, b) => a.name.localeCompare(b.name));

  for (const dir of dirs) {
    const childRelPath = path.join(relativePath, dir.name);
    const childFullPath = path.join(dirPath, dir.name);
    const subtree = buildTree(childFullPath, childRelPath);
    children.push({
      name: formatName(dir.name),
      rawName: dir.name,
      path: childRelPath,
      type: 'directory',
      children: subtree,
    });
  }

  for (const file of files) {
    const filRelPath = path.join(relativePath, file.name);
    children.push({
      name: formatName(file.name.replace('.md', '')),
      rawName: file.name,
      path: filRelPath,
      type: 'file',
    });
  }

  return children;
}

function formatName(name) {
  // Convert kebab-case/snake_case to Title Case, handle numbered prefixes
  return name
    .replace(/^\d+-/, match => match) // keep number prefix
    .replace(/[-_]/g, ' ')
    .replace(/\b\w/g, c => c.toUpperCase());
}

function searchFiles(dirPath, relativePath, query, results) {
  const entries = fs.readdirSync(dirPath, { withFileTypes: true });

  for (const entry of entries) {
    if (entry.name.startsWith('.') || entry.name === 'node_modules' || entry.name === 'reader') continue;

    const childRelPath = path.join(relativePath, entry.name);
    const childFullPath = path.join(dirPath, entry.name);

    if (entry.isDirectory()) {
      searchFiles(childFullPath, childRelPath, query, results);
    } else if (entry.isFile() && entry.name.endsWith('.md')) {
      const content = fs.readFileSync(childFullPath, 'utf-8');
      const lowerContent = content.toLowerCase();
      const idx = lowerContent.indexOf(query);
      if (idx !== -1) {
        // Get context around match
        const start = Math.max(0, idx - 60);
        const end = Math.min(content.length, idx + query.length + 60);
        const snippet = content.substring(start, end).replace(/\n/g, ' ');
        results.push({
          path: childRelPath,
          name: formatName(entry.name.replace('.md', '')),
          snippet: (start > 0 ? '...' : '') + snippet + (end < content.length ? '...' : ''),
        });
      }
    }
  }
}

app.listen(PORT, () => {
  console.log(`\n  📚 Docs Reader is running at:`);
  console.log(`  ➜  http://localhost:${PORT}\n`);
});
