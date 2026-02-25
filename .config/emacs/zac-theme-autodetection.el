;;; zac-theme-autodetection.el --- Auto-switch Catppuccin via zsh-appearance-control -*- lexical-binding: t; -*-

;; This module integrates Emacs with zsh-appearance-control:
;; https://github.com/alberti42/zsh-appearance-control
;;
;; zsh-appearance-control writes a single-character state file named
;; "appearance" in a cache directory:
;; - "1" => dark
;; - "0" => light
;;
;; We watch that file via Emacs file notifications, and when it changes we
;; reload the Catppuccin theme with the corresponding flavour:
;; - dark  => macchiato
;; - light => frappe

;;; Commentary:
;;
;; Usage:
;; - Load this file from init.el.
;; - Ensure the Catppuccin theme package is installed.
;; - The watcher starts automatically on load.
;;
;; Environment:
;; - If $ZAC_CACHE_DIR is set, we read "$ZAC_CACHE_DIR/appearance".
;; - Otherwise we read "$XDG_CACHE_HOME/zac/appearance" or "~/.cache/zac/appearance".

;;; Code:

(require 'subr-x)

(defvar zac--watch nil)
(defvar zac--last-catppuccin-flavor nil)

(defun zac--appearance-file ()
  (expand-file-name
   "appearance"
   (or (getenv "ZAC_CACHE_DIR")
       (expand-file-name "zac" (or (getenv "XDG_CACHE_HOME")
                                   (expand-file-name "~/.cache"))))))

(defun zac--read-appearance ()
  (when (file-readable-p (zac--appearance-file))
    (string-trim
     (with-temp-buffer
       (insert-file-contents (zac--appearance-file))
       (buffer-string)))))

(defun zac--apply-cursor-color ()
  "Set cursor color for GUI frames. Safe to call from hooks."
  (when (display-graphic-p)
    (set-cursor-color "#cad3f5")))

(defun zac--apply-appearance ()
  (let* ((v (zac--read-appearance))
         (flavor (if (string= v "1") 'macchiato 'frappe)))
    (unless (eq zac--last-catppuccin-flavor flavor)
      (setq zac--last-catppuccin-flavor flavor)
      (setq catppuccin-flavor flavor)
      (mapc #'disable-theme custom-enabled-themes)
      (load-theme 'catppuccin t)

      ;; Cursor color override (GUI only).
      (zac--apply-cursor-color)

      ;; Keep background transparent/unspecified for terminal + GUI consistency.
      ;; IMPORTANT: use the symbol `unspecified` (not the string "unspecified-bg").
      ;; In GUI frames the string is treated as a color name and errors.
      (set-face-attribute 'default nil :background 'unspecified)
      (set-face-attribute 'mode-line nil :background 'unspecified)
      (set-face-attribute 'mode-line-inactive nil :background 'unspecified))))

(defun zac-watch-start ()
  "Start watching zsh-appearance-control's appearance file."
  (interactive)
  (unless (fboundp 'file-notify-add-watch)
    (message "zac: file notifications not supported; applying once")
    (setq zac--watch nil)
    (zac--apply-appearance)
    nil)
  (zac--apply-appearance)
  ;; Re-apply cursor color after the initial frame is fully set up (GUI
  ;; startup: display-graphic-p may be nil or frame parameters not yet
  ;; final when init.el runs).
  (add-hook 'window-setup-hook #'zac--apply-cursor-color)
  ;; Re-apply cursor color for any new frame (emacsclient / daemon mode).
  (add-hook 'after-make-frame-functions
            (lambda (frame)
              (with-selected-frame frame
                (zac--apply-cursor-color))))
  (when (fboundp 'file-notify-add-watch)
    (unless zac--watch
      (setq zac--watch
            (file-notify-add-watch
             (zac--appearance-file)
             '(change)
             (lambda (_event)
               (zac--apply-appearance))))))
  nil)

(defun zac-watch-stop ()
  "Stop watching zsh-appearance-control's appearance file."
  (interactive)
  (when zac--watch
    (file-notify-rm-watch zac--watch)
    (setq zac--watch nil)))

;; Start watcher automatically.
(zac-watch-start)

(provide 'zac-theme-autodetection)

;;; zac-theme-autodetection.el ends here
