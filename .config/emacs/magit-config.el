;;; magit-config.el --- Magit and Git forge configuration -*- lexical-binding: t; -*-

;;; Code:

(use-package magit
  :config
  ;; Show fine-grained word-level diffs within a hunk.
  (setq magit-diff-refine-hunk 'all)

  ;; Ask before saving modified repository buffers.
  (setq magit-save-repository-buffers t)

  ;; Open the status buffer in a dedicated full-frame window.
  (setq magit-display-buffer-function #'magit-display-buffer-fullframe-status-v1)

  ;; Nerd icons for file entries (native support since magit 223461b).
  (when (fboundp 'magit-format-file-nerd-icons)
    (setq magit-format-file-function #'magit-format-file-nerd-icons))

  ;; Show the unpushed commits section expanded by default.
  (setf (alist-get 'unpushed magit-section-initial-visibility-alist) 'show))

;; Forge: GitHub/GitLab integration (PRs, issues, reviews).
(use-package forge
  :after magit)

(provide 'magit-config)
;;; magit-config.el ends here
