;;; lsp-python.el --- Python LSP configuration -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Python LSP via lsp-pyright (configured to use basedpyright).
;; Requires an external language server available on PATH.
;;

;;; Code:

(use-package lsp-pyright
  :after lsp-mode
  :init
  (setq lsp-pyright-langserver-command "basedpyright")
  :hook
  (python-mode .
               (lambda ()
                 (require 'lsp-pyright)
                 (lsp-deferred))))

(provide 'lsp-python)

;;; lsp-python.el ends here
