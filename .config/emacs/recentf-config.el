;;; recentf-config.el --- Recent files list -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Enable and persist a list of recently visited files.
;;
;; Note: this config repo is intended to be symlinked into user-emacs-directory
;; (e.g. ~/.config/emacs). To avoid writing state into the git worktree, store
;; the recentf file under XDG cache (or ~/.cache).
;;

;;; Code:

(use-package recentf
  :straight nil
  :init
  (let* ((cache-home (or (getenv "XDG_CACHE_HOME")
                         (expand-file-name "~/.cache")))
         (dir (expand-file-name "emacs" cache-home)))
    (make-directory dir t)
    (setq recentf-save-file (expand-file-name "recentf" dir)))
  (setq recentf-max-saved-items 200
        recentf-max-menu-items 50
        recentf-auto-cleanup 'mode)
  :config
  (recentf-mode 1))

(provide 'recentf-config)
;;; recentf-config.el ends here
