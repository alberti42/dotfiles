;;; treemacs-config.el --- Treemacs in terminal Emacs -*- lexical-binding: t; -*-

;; Treemacs uses `pfuture` (async helpers) at runtime; ensure it's installed.
(use-package pfuture)

(use-package treemacs
  :after pfuture
  :commands (treemacs treemacs-select-window treemacs-find-file)
  :bind (("C-c t t" . treemacs)
         ("C-c t s" . treemacs-select-window)
         ("C-c t f" . treemacs-find-file))
  :init
  ;; Persist workspaces/projects under XDG cache.
  (let ((cache (or (getenv "XDG_CACHE_HOME") (expand-file-name "~/.cache"))))
    (setq treemacs-persist-file (expand-file-name "emacs/treemacs-persist" cache)
          treemacs-last-error-persist-file (expand-file-name "emacs/treemacs-persist-at-last-error" cache)))
  :config
  ;; Keep this light; avoid enabling optional modes by default.
  (setq treemacs-width 35)
  (setq treemacs-no-png-images t))

(use-package treemacs-nerd-icons
  :after (treemacs nerd-icons)
  :config
  (treemacs-nerd-icons-config))

(provide 'treemacs-config)
;;; treemacs-config.el ends here
