;;; mac-pseudo-daemon-config.el --- Pseudo-daemon for macOS GUI frames -*- lexical-binding: t; -*-

;; Problem this solves (macOS GUI + server/daemon workflows)
;;
;; Emacs "real" daemon mode (or a long-lived `emacs --fg-daemon` / `server-start`
;; plus `emacsclient -c`) behaves a bit awkwardly on macOS when you close the
;; last *graphical* frame:
;;
;; - The Emacs app stays running (as expected for a daemon/server).
;; - But without any GUI frames, the Dock icon and menu bar can become
;;   non-functional until a new GUI frame is created.
;; - This is especially annoying when you expect "re-open Emacs" to just raise a
;;   window (Spotlight, Dock click, `open -a Emacs`, etc.).
;;
;; `mac-pseudo-daemon` sidesteps the issue by keeping one hidden GUI frame alive.
;; When the last visible GUI frame is closed, it creates a hidden one; the next
;; time Emacs is activated, that hidden frame is shown again. Net effect: you
;; get daemon-like persistence without the "dead Dock/menu" UX.

(use-package mac-pseudo-daemon
  :if (eq system-type 'darwin)
  :straight (mac-pseudo-daemon
             :type git
             :host github
             :repo "DarwinAwardWinner/mac-pseudo-daemon")
  :demand t
  :config
  (mac-pseudo-daemon-mode 1))

(provide 'mac-pseudo-daemon-config)
;;; mac-pseudo-daemon-config.el ends here
