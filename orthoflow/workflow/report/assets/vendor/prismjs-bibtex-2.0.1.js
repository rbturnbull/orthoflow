(function (Prism) {
    var macro = {
      pattern: /\\(?:\W|[a-z]+\*?(?=\s*{?))/mi,
      alias: 'keyword'
    }
  
    var latex = {
      'equation': {
        pattern: /(\$\$?)[^\$]+\1/mi,
        alias: 'function',
        inside: {
          'macro': macro
        }
      },
      'macro': macro
    };
  
    Prism.languages.bib = {
      'comment': /%.*/,
      'special': {
        pattern: /(^\s*)@(?:preamble|string|comment(?=\s*[({]))/mi,
        lookbehind: true,
        alias: 'important'
      },
      'class-name': {
        pattern: /(^\s*)@[a-z]+(?=\s*{)/mi,
        lookbehind: true
      },
      'key': {
        pattern: /([,{]\s*)[^,={}'"\s]+(?=\s*[,}])/mi,
        lookbehind: true,
        alias: 'regex'
      },
      'property': {
        pattern: /([,{(]\s*)[^,={}'"\s]+(?=\s*=)/mi,
        lookbehind: true
      },
      'string': {
        /* properly quoted strings | numbers | content with braces balanced up to depth 4 */
        pattern: /([=#{]\s*)("|')(?:(?!\2)[^\\]|\\\W|\\[a-z]+)*\2|([=#]\s*)(?:\d+|{(?:[^{}]*|{(?:[^{}]*|{(?:[^{}]*|{[^}]*})*})*})*})/mi,
        lookbehind: true,
        greedy: true,
        inside: latex
      },
      'constant': {
        pattern: /([=#]\s*)[^,={}'"\s]+(?=\s*[#,}])/mi,
        lookbehind: true
      },
      'symbol': /#/,
      'punctuation': /[=,{}()]/
    };
  
    Prism.languages.bibtex = Prism.languages.bib;
  }(Prism));