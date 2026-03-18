/* ========================================
   Go DDD Docs Reader – app.js
   ======================================== */

(function () {
  'use strict';

  // DOM refs
  const sidebar = document.getElementById('sidebar');
  const sidebarOverlay = document.getElementById('sidebarOverlay');
  const hamburger = document.getElementById('hamburger');
  const navTree = document.getElementById('navTree');
  const searchInput = document.getElementById('searchInput');
  const searchResults = document.getElementById('searchResults');
  const contentArea = document.getElementById('contentArea');
  const markdownBody = document.getElementById('markdownBody');
  const welcomeScreen = document.getElementById('welcomeScreen');
  const welcomeStats = document.getElementById('welcomeStats');
  const quickLinks = document.getElementById('quickLinks');
  const breadcrumb = document.getElementById('breadcrumb');
  const themeToggle = document.getElementById('themeToggle');
  const tocNav = document.getElementById('tocNav');
  const btnScrollTop = document.getElementById('btnScrollTop');
  const readingProgress = document.getElementById('readingProgress');

  let treeData = [];
  let currentPath = null;
  let searchTimeout = null;
  let tocObserver = null;  // Track the IntersectionObserver to disconnect later

  // ========================================
  // Initialization
  // ========================================
  async function init() {
    setupTheme();
    setupEventListeners();
    await loadTree();
    renderWelcome();

    // Check URL hash for initial page
    if (window.location.hash) {
      const path = decodeURIComponent(window.location.hash.slice(1));
      if (path) loadContent(path);
    }
  }

  // ========================================
  // Theme Management
  // ========================================
  function setupTheme() {
    const saved = localStorage.getItem('docs-theme') || 'dark';
    document.documentElement.setAttribute('data-theme', saved);
  }

  function toggleTheme() {
    const current = document.documentElement.getAttribute('data-theme');
    const next = current === 'dark' ? 'light' : 'dark';
    document.documentElement.setAttribute('data-theme', next);
    localStorage.setItem('docs-theme', next);
  }

  // ========================================
  // Event Listeners
  // ========================================
  function setupEventListeners() {
    // Theme toggle
    themeToggle.addEventListener('click', toggleTheme);

    // Hamburger menu
    hamburger.addEventListener('click', () => {
      sidebar.classList.toggle('open');
      sidebarOverlay.classList.toggle('active');
    });

    sidebarOverlay.addEventListener('click', () => {
      sidebar.classList.remove('open');
      sidebarOverlay.classList.remove('active');
    });

    // Search
    searchInput.addEventListener('input', handleSearch);
    searchInput.addEventListener('focus', () => {
      if (searchInput.value.trim().length >= 2) {
        searchResults.classList.add('active');
      }
    });

    // Close search results on click outside
    document.addEventListener('click', (e) => {
      if (!e.target.closest('.search-container')) {
        searchResults.classList.remove('active');
      }
    });

    // Keyboard shortcut (Ctrl/Cmd+K)
    document.addEventListener('keydown', (e) => {
      if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
        e.preventDefault();
        searchInput.focus();
        searchInput.select();
      }
      if (e.key === 'Escape') {
        searchResults.classList.remove('active');
        searchInput.blur();
      }
    });

    // Scroll to top
    btnScrollTop.addEventListener('click', () => {
      contentArea.scrollTo({ top: 0, behavior: 'smooth' });
    });

    // Reading progress
    contentArea.addEventListener('scroll', updateReadingProgress);

    // Hash change
    window.addEventListener('hashchange', () => {
      const path = decodeURIComponent(window.location.hash.slice(1));
      if (path && path !== currentPath) {
        loadContent(path);
      }
    });
  }

  // ========================================
  // Tree Loading & Rendering
  // ========================================
  async function loadTree() {
    try {
      const res = await fetch('/api/tree');
      treeData = await res.json();
      renderTree(treeData);
    } catch (err) {
      navTree.innerHTML = `<div class="nav-loading" style="color:var(--danger)">Failed to load docs</div>`;
    }
  }

  function renderTree(items) {
    navTree.innerHTML = '';
    const fragment = document.createDocumentFragment();
    renderTreeItems(items, fragment, 0);
    navTree.appendChild(fragment);
  }

  function renderTreeItems(items, container, depth) {
    for (const item of items) {
      if (item.type === 'directory') {
        const section = createSection(item, depth);
        container.appendChild(section);
      } else {
        const navItem = createNavItem(item);
        container.appendChild(navItem);
      }
    }
  }

  function createSection(item, depth) {
    const section = document.createElement('div');
    section.className = 'nav-section';

    const header = document.createElement('div');
    header.className = 'nav-section-header';
    header.innerHTML = `
      <svg class="chevron" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <polyline points="9 18 15 12 9 6"/>
      </svg>
      <span class="folder-icon">${getFolderIcon(item.rawName)}</span>
      <span class="section-name">${item.name}</span>
      <span class="item-count">${countFiles(item.children)}</span>
    `;

    const children = document.createElement('div');
    children.className = 'nav-section-children';

    renderTreeItems(item.children, children, depth + 1);

    header.addEventListener('click', () => {
      header.classList.toggle('expanded');
      children.classList.toggle('expanded');
    });

    section.appendChild(header);
    section.appendChild(children);

    return section;
  }

  function createNavItem(item) {
    const el = document.createElement('div');
    el.className = 'nav-item';
    el.dataset.path = item.path;
    el.innerHTML = `
      <span class="file-icon">${getFileIcon(item.rawName)}</span>
      <span class="item-name">${item.name}</span>
    `;

    el.addEventListener('click', () => {
      window.location.hash = encodeURIComponent(item.path);
      loadContent(item.path);
      // Close mobile sidebar
      sidebar.classList.remove('open');
      sidebarOverlay.classList.remove('active');
    });

    return el;
  }

  function countFiles(items) {
    let count = 0;
    for (const item of items) {
      if (item.type === 'file') count++;
      if (item.children) count += countFiles(item.children);
    }
    return count;
  }

  function getFolderIcon(name) {
    const icons = {
      'dsa': '🧮',
      'sorting': '🔢',
      'searching': '🔍',
      'graph': '🕸️',
      'dynamic-programming': '📊',
      'important-algorithms': '⭐',
      'glosaries': '📖',
      'goroutines': '⚡',
      'go-orm': '🗄️',
      'gin': '🍸',
      'k8s': '☸️',
      'linux-command': '🐧',
      'prompts': '💬',
      'sql-optimizer': '🚀',
      'guidelines': '📋',
      'features': '✨',
    };
    return icons[name] || '📁';
  }

  function getFileIcon(name) {
    if (name === 'README.md') return '📄';
    return '📝';
  }

  // ========================================
  // Content Loading
  // ========================================
  async function loadContent(filePath) {
    if (currentPath === filePath) return;
    currentPath = filePath;

    // Update active state in sidebar
    document.querySelectorAll('.nav-item').forEach(el => {
      el.classList.toggle('active', el.dataset.path === filePath);
    });

    // Expand parent sections
    expandToPath(filePath);

    // Show loading state
    markdownBody.classList.remove('hidden');
    welcomeScreen.classList.add('hidden');
    markdownBody.innerHTML = `
      <div style="display:flex;align-items:center;gap:12px;padding:40px;color:var(--text-tertiary)">
        <div class="spinner"></div> Loading...
      </div>
    `;

    try {
      const res = await fetch(`/api/content?path=${encodeURIComponent(filePath)}`);
      const data = await res.json();

      if (!res.ok) {
        markdownBody.innerHTML = `<div style="color:var(--danger);padding:40px">Error: ${data.error}</div>`;
        return;
      }

      // Render content
      markdownBody.innerHTML = data.html;

      // Post-process: add copy buttons to code blocks
      addCopyButtons();

      // Post-process: add heading IDs for TOC
      processHeadings();

      // Update breadcrumb
      updateBreadcrumb(filePath);

      // Update TOC
      updateTOC();

      // Scroll to top
      contentArea.scrollTo({ top: 0 });

      // Update reading progress
      updateReadingProgress();

    } catch (err) {
      markdownBody.innerHTML = `<div style="color:var(--danger);padding:40px">Failed to load: ${err.message}</div>`;
    }
  }

  function expandToPath(filePath) {
    // Find all nav items and expand their parent sections
    const parts = filePath.split('/');
    let accumulated = '';

    for (let i = 0; i < parts.length - 1; i++) {
      accumulated += (i > 0 ? '/' : '') + parts[i];

      // Find the section header that corresponds to this path
      document.querySelectorAll('.nav-section-header').forEach(header => {
        const section = header.parentElement;
        const sectionChildren = section.querySelector('.nav-section-children');
        const sectionName = header.querySelector('.section-name').textContent;

        // Check if any child matches our path
        const childItems = sectionChildren.querySelectorAll('.nav-item');
        for (const child of childItems) {
          if (child.dataset.path === filePath) {
            header.classList.add('expanded');
            sectionChildren.classList.add('expanded');
          }
        }

        // Also check nested sections
        const nestedSections = sectionChildren.querySelectorAll('.nav-section');
        for (const nested of nestedSections) {
          const nestedItems = nested.querySelectorAll('.nav-item');
          for (const ni of nestedItems) {
            if (ni.dataset.path === filePath) {
              header.classList.add('expanded');
              sectionChildren.classList.add('expanded');
            }
          }
        }
      });
    }
  }

  function addCopyButtons() {
    const codeBlocks = markdownBody.querySelectorAll('pre');
    codeBlocks.forEach(pre => {
      const btn = document.createElement('button');
      btn.className = 'copy-btn';
      btn.textContent = 'Copy';
      btn.addEventListener('click', () => {
        const code = pre.querySelector('code');
        navigator.clipboard.writeText(code.textContent).then(() => {
          btn.textContent = 'Copied!';
          btn.classList.add('copied');
          setTimeout(() => {
            btn.textContent = 'Copy';
            btn.classList.remove('copied');
          }, 2000);
        });
      });
      pre.style.position = 'relative';
      pre.appendChild(btn);
    });
  }

  function processHeadings() {
    const headings = markdownBody.querySelectorAll('h1, h2, h3, h4');
    headings.forEach((h, i) => {
      const id = 'heading-' + i + '-' + slugify(h.textContent);
      h.id = id;

      // Add anchor link
      h.style.cursor = 'pointer';
      h.addEventListener('click', (e) => {
        e.preventDefault();
        e.stopPropagation();
        // Scroll within the content-area container, not the window
        const containerRect = contentArea.getBoundingClientRect();
        const headingRect = h.getBoundingClientRect();
        const offsetTop = headingRect.top - containerRect.top + contentArea.scrollTop;
        contentArea.scrollTo({ top: offsetTop - 20, behavior: 'smooth' });
        h.classList.add('heading-highlight');
        setTimeout(() => h.classList.remove('heading-highlight'), 2000);
      });
    });
  }

  function slugify(text) {
    return text.toLowerCase()
      .replace(/[^\w\s-]/g, '')
      .replace(/\s+/g, '-')
      .replace(/-+/g, '-')
      .substring(0, 60);
  }

  // ========================================
  // Breadcrumb
  // ========================================
  function updateBreadcrumb(filePath) {
    const parts = filePath.split('/');
    breadcrumb.innerHTML = '';

    parts.forEach((part, i) => {
      if (i > 0) {
        const sep = document.createElement('span');
        sep.className = 'breadcrumb-sep';
        sep.textContent = '/';
        breadcrumb.appendChild(sep);
      }

      const item = document.createElement('span');
      item.className = 'breadcrumb-item';
      item.textContent = part.replace('.md', '').replace(/[-_]/g, ' ');
      breadcrumb.appendChild(item);
    });
  }

  // ========================================
  // Table of Contents
  // ========================================
  function updateTOC() {
    // Disconnect previous observer to prevent stale references
    if (tocObserver) {
      tocObserver.disconnect();
      tocObserver = null;
    }

    tocNav.innerHTML = '';
    const headings = markdownBody.querySelectorAll('h2, h3, h4');

    if (headings.length === 0) {
      tocNav.innerHTML = '<div style="padding:12px 20px;font-size:12px;color:var(--text-tertiary)">No headings found</div>';
      return;
    }

    headings.forEach(h => {
      const link = document.createElement('div');
      link.className = `toc-link toc-${h.tagName.toLowerCase()}`;
      link.textContent = h.textContent;
      link.addEventListener('click', () => {
        // Scroll within the content-area container
        const containerRect = contentArea.getBoundingClientRect();
        const headingRect = h.getBoundingClientRect();
        const offsetTop = headingRect.top - containerRect.top + contentArea.scrollTop;
        contentArea.scrollTo({ top: offsetTop - 20, behavior: 'smooth' });
        h.classList.add('heading-highlight');
        setTimeout(() => h.classList.remove('heading-highlight'), 2000);
      });
      tocNav.appendChild(link);
    });

    // Observe headings for active state
    setupTOCObserver(headings);
  }

  function setupTOCObserver(headings) {
    tocObserver = new IntersectionObserver(
      (entries) => {
        entries.forEach(entry => {
          if (entry.isIntersecting) {
            document.querySelectorAll('.toc-link').forEach(link => {
              link.classList.remove('active');
            });

            // Find matching TOC link
            const idx = Array.from(headings).indexOf(entry.target);
            const tocLinks = tocNav.querySelectorAll('.toc-link');
            if (tocLinks[idx]) {
              tocLinks[idx].classList.add('active');
            }
          }
        });
      },
      { root: contentArea, rootMargin: '-80px 0px -60% 0px', threshold: 0 }
    );

    headings.forEach(h => tocObserver.observe(h));
  }

  // ========================================
  // Search
  // ========================================
  function handleSearch() {
    const query = searchInput.value.trim();

    if (query.length < 2) {
      searchResults.classList.remove('active');
      searchResults.innerHTML = '';
      return;
    }

    clearTimeout(searchTimeout);
    searchTimeout = setTimeout(async () => {
      try {
        const res = await fetch(`/api/search?q=${encodeURIComponent(query)}`);
        const results = await res.json();
        renderSearchResults(results, query);
      } catch (err) {
        console.error('Search error:', err);
      }
    }, 250);
  }

  function renderSearchResults(results, query) {
    if (results.length === 0) {
      searchResults.innerHTML = `
        <div style="padding:16px;text-align:center;color:var(--text-tertiary);font-size:13px">
          No results for "${query}"
        </div>
      `;
      searchResults.classList.add('active');
      return;
    }

    searchResults.innerHTML = results.map(r => {
      // Highlight query in snippet
      const regex = new RegExp(`(${escapeRegex(query)})`, 'gi');
      const highlighted = r.snippet.replace(regex, '<mark>$1</mark>');

      return `
        <div class="search-result-item" data-path="${r.path}">
          <div class="result-name">${r.name}</div>
          <div class="result-path">${r.path}</div>
          <div class="result-snippet">${highlighted}</div>
        </div>
      `;
    }).join('');

    // Add click handlers
    searchResults.querySelectorAll('.search-result-item').forEach(el => {
      el.addEventListener('click', () => {
        const path = el.dataset.path;
        window.location.hash = encodeURIComponent(path);
        loadContent(path);
        searchResults.classList.remove('active');
        searchInput.value = '';
        sidebar.classList.remove('open');
        sidebarOverlay.classList.remove('active');
      });
    });

    searchResults.classList.add('active');
  }

  function escapeRegex(str) {
    return str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  }

  // ========================================
  // Reading Progress
  // ========================================
  function updateReadingProgress() {
    const scrollTop = contentArea.scrollTop;
    const scrollHeight = contentArea.scrollHeight - contentArea.clientHeight;
    const progress = scrollHeight > 0 ? (scrollTop / scrollHeight) * 100 : 0;
    readingProgress.style.setProperty('--progress', `${Math.min(progress, 100)}%`);
  }

  // ========================================
  // Welcome Screen
  // ========================================
  function renderWelcome() {
    // Make sure welcome is shown, markdownBody hidden
    welcomeScreen.classList.remove('hidden');
    markdownBody.classList.add('hidden');
    let totalFiles = 0;
    let totalFolders = 0;

    function countItems(items) {
      for (const item of items) {
        if (item.type === 'file') totalFiles++;
        if (item.type === 'directory') {
          totalFolders++;
          countItems(item.children);
        }
      }
    }
    countItems(treeData);

    welcomeStats.innerHTML = `
      <div class="stat-card">
        <div class="stat-value">${totalFiles}</div>
        <div class="stat-label">Documents</div>
      </div>
      <div class="stat-card">
        <div class="stat-value">${totalFolders}</div>
        <div class="stat-label">Categories</div>
      </div>
    `;

    // Quick links from top-level directories
    const links = treeData
      .filter(item => item.type === 'directory')
      .map(item => `
        <div class="quick-link" data-section="${item.rawName}">
          <span class="quick-link-icon">${getFolderIcon(item.rawName)}</span>
          <span class="quick-link-text">${item.name}</span>
        </div>
      `).join('');

    quickLinks.innerHTML = links;

    // Handle quick link clicks: expand the section
    quickLinks.querySelectorAll('.quick-link').forEach(el => {
      el.addEventListener('click', () => {
        const sectionName = el.dataset.section;
        // Find the first file in this section and navigate to it
        const section = treeData.find(d => d.rawName === sectionName);
        if (section) {
          const firstFile = findFirstFile(section);
          if (firstFile) {
            window.location.hash = encodeURIComponent(firstFile.path);
            loadContent(firstFile.path);
          }
        }
      });
    });
  }

  function findFirstFile(item) {
    if (item.type === 'file') return item;
    if (item.children) {
      for (const child of item.children) {
        const found = findFirstFile(child);
        if (found) return found;
      }
    }
    return null;
  }

  // ========================================
  // Start
  // ========================================
  document.addEventListener('DOMContentLoaded', init);

})();
