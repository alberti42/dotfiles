;;; search-config.el --- Fast project search defaults -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Prefer ripgrep for project/xref search commands such as `project-find-regexp`.
;; This makes `C-x p g` behave closer to editor-native "Find in Files".
;;

;;; Code:

(use-package xref
  :straight nil
  :init
  ;; `project-find-regexp' uses the xref search backend.
  ;; Force ripgrep when available for dramatically better performance.
  (setq xref-search-program 'ripgrep))

(provide 'search-config)
;;; search-config.el ends here
