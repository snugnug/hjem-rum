self.onmessage = function(e) {
  const { messageId, type, data } = e.data;

  const respond = (type, data) => {
    self.postMessage({ messageId, type, data });
  };

  const respondError = (error) => {
    self.postMessage({ messageId, type: 'error', error: error.message || String(error) });
  };

  try {
    if (type === 'tokenize') {
      const tokens = (typeof data === 'string' ? data : '')
        .toLowerCase()
        .match(/\b[a-zA-Z0-9_-]+\b/g) || []
        .filter(word => word.length > 2);
      
      const uniqueTokens = Array.from(new Set(tokens));
      respond('tokens', uniqueTokens);
    }

    if (type === 'search') {
      const { documents, query, limit } = data;
      const searchTerms = (typeof query === 'string' ? query : '')
        .toLowerCase()
        .match(/\b[a-zA-Z0-9_-]+\b/g) || []
        .filter(word => word.length > 2);

      const pageMatches = new Map();
      
      // Pre-compute lower-case terms once
      const lowerSearchTerms = searchTerms.map(term => term.toLowerCase());

      // Pre-compute lower-case strings for each document
      const processedDocs = documents.map((doc, docId) => ({
        docId,
        doc,
        lowerTitle: doc.title.toLowerCase(),
        lowerContent: doc.content.toLowerCase()
      }));

      // First pass: Score pages
      lowerSearchTerms.forEach(lowerTerm => {
        processedDocs.forEach(({ docId, doc, lowerTitle, lowerContent }) => {
          let match = pageMatches.get(docId);
          if (!match) {
            match = { doc, pageScore: 0, matchingAnchors: [] };
            pageMatches.set(docId, match);
          }

          if (lowerTitle.includes(lowerTerm)) {
            match.pageScore += lowerTitle === lowerTerm ? 20 : 10;
          }
          if (lowerContent.includes(lowerTerm)) {
            match.pageScore += 2;
          }
        });
      });

      // Second pass: Find matching anchors
      pageMatches.forEach((match) => {
        const doc = match.doc;
        if (!doc.anchors || doc.anchors.length === 0) return;

        doc.anchors.forEach(anchor => {
          const anchorText = anchor.text.toLowerCase();
          let anchorMatches = false;

          lowerSearchTerms.forEach(term => {
            if (anchorText.includes(term)) {
              anchorMatches = true;
            }
          });

          if (anchorMatches) {
            match.matchingAnchors.push(anchor);
          }
        });
      });

      const results = Array.from(pageMatches.values())
        .sort((a, b) => b.pageScore - a.pageScore)
        .slice(0, limit);

      respond('results', results);
    }
  } catch (error) {
    respondError(error);
  }
};