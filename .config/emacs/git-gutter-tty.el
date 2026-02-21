;;; git-gutter-tty.el --- Git gutter in terminal Emacs -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; This module enables a "source control gutter" for terminal Emacs.
;;
;; Notes on UI constraints:
;; - In GUI Emacs, packages can draw indicators in the fringe (a bitmap area
;;   outside the text). Terminal frames have no fringe; indicators must be
;;   rendered as ordinary characters.
;; - The goal here is a clean, low-noise TTY gutter: one thin glyph, colored by
;;   face, with stable layout (reserve the column in Git buffers).
;;
;; `git-gutter` is used instead of fringe-only variants like git-gutter-fringe.

;;; Code:

(use-package git-gutter
  :if (not window-system)
  :config
  ;; Live-ish updates (idle timer). Increase if it feels too chatty.
  (setq git-gutter:update-interval 0.5)

  ;; One glyph, colored by face.
  (setq git-gutter:modified-sign "▎")
  (setq git-gutter:added-sign "▎")
  (setq git-gutter:deleted-sign "▎")
  (setq git-gutter:window-width 1)

  ;; Keep the gutter column reserved in Git buffers to avoid text shifting.
  (setq git-gutter:separator-sign "│")
  (setq git-gutter:always-show-separator t)

  ;; Faces: keep simple; theme can override if desired.
  (set-face-foreground 'git-gutter:added "green")
  (set-face-foreground 'git-gutter:modified "yellow")
  (set-face-foreground 'git-gutter:deleted "red")
  (set-face-foreground 'git-gutter:separator "brightblack")

  (global-git-gutter-mode 1)

  ;; Keep gutter in sync after Magit refreshes.
  (with-eval-after-load 'magit
    (add-hook 'magit-post-refresh-hook #'git-gutter:update-all-windows)))

(provide 'git-gutter-tty)

;;; git-gutter-tty.el ends here
