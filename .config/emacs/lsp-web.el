;;; lsp-web.el --- TypeScript/JavaScript LSP configuration -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; TypeScript/JavaScript LSP client setup.
;; Requires external servers: typescript-language-server + tsserver.
;;

;;; Code:

(use-package typescript-mode
  :mode "\\.ts\\'"
  :mode "\\.tsx\\'"
  :hook (typescript-mode . lsp-deferred))

(use-package js
  :straight nil
  :hook (js-mode . lsp-deferred))

(provide 'lsp-web)

;;; lsp-web.el ends here
