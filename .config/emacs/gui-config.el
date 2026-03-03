;;; gui-config.el --- GUI frame chrome, fonts, and visual settings -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Visual presentation layer: UI chrome, window dividers, frame chrome,
;; per-frame font/centering setup, and the TTY mode-line separator.
;; Loaded early, right after bootstrap, so frames look right from the start.
;;

;;; Code:

;; UI chrome
;; Keep window UI minimal and consistent across GUI/TTY.
(setq ring-bell-function 'ignore) ; disable all bells
(menu-bar-mode -1) ; turn off menu bar
(when (fboundp 'tool-bar-mode)
  (tool-bar-mode -1)) ; turn off tool bar icons
(when (fboundp 'scroll-bar-mode)
  (scroll-bar-mode -1)) ; turn off scroll bars
(when (fboundp 'tooltip-mode)
  (tooltip-mode -1)) ; turn off tooltips

;; Always use minibuffer prompts (no GUI dialog boxes).
(setq use-dialog-box nil)
;; Also avoid GUI file-picker dialogs
(setq use-file-dialog nil)

;; Window dividers (GUI)
;; The vertical divider between treemacs and the buffer is drawn by Emacs's
;; window-divider-mode (right side).  Enable bottom-only dividers to get a
;; matching 2px bar between the mode-line and the minibuffer.
(setq window-divider-default-places 'bottom-only)
(setq window-divider-default-bottom-width 2)
(window-divider-mode 1)

;; TTY mode-line separator
;; Emacs fills the trailing space of the TTY mode-line via mode-line-end-spaces,
;; which defaults to "%-" (fill with -).  Replace it with ─ (U+2500) by
;; overriding that single variable after all themes have loaded.
;; The :eval guard keeps GUI frames unaffected when running as a daemon.
(defun emacs-config--tty-mode-line-separator ()
  (setq-default mode-line-end-spaces
    '(:eval (unless (display-graphic-p) (make-string 500 ?─)))))
(add-hook 'after-init-hook #'emacs-config--tty-mode-line-separator)

;; Frame chrome
(cond
  ((eq system-type 'darwin)
    ;; On macOS, use a transparent titlebar for a more modern look.
    (add-to-list 'default-frame-alist '(ns-transparent-titlebar . t))
    ;; Forces a light (white-ish) title bar regardless of your theme
    (add-to-list 'default-frame-alist '(ns-appearance . dark))
    )
  (t
    ;; On other GUI builds, fall back to a frameless (undecorated) window.
    (add-to-list 'default-frame-alist '(undecorated . t))
    (add-to-list 'default-frame-alist '(internal-border-width . 10))))

;; Default frame size; TTY frames ignore these.
(add-to-list 'default-frame-alist '(width . 160))
(add-to-list 'default-frame-alist '(height . 80))

;; Ensure GUI Emacs creates/raises a frame.
;; - Some macOS setups can start Emacs without presenting a visible window.
;; - `emacsclient -c` can create a frame without activating the app.
(defun emacs-config--activate-gui-frame (&optional frame)
  "Raise FRAME and give it focus (best-effort)."
  (let ((frame (or frame (selected-frame))))
    (when (display-graphic-p frame)
      (with-selected-frame frame
        (run-at-time
          0 nil
          (lambda (f)
            (when (frame-live-p f)
              (select-frame-set-input-focus f)
              (raise-frame f)))
          frame)))))

;; Per-frame GUI setup: fonts and centering.
;; Hooked to both emacs-startup-hook (direct GUI launch) and
;; after-make-frame-functions (daemon/emacsclient GUI frame).
(defun emacs-config-center-frame (&optional frame)
  "Center FRAME on its current monitor (GUI only)."
  (when (display-graphic-p)
    (let* ((frame (or frame (selected-frame)))
            (wa (and (fboundp 'frame-monitor-workarea)
                  (frame-monitor-workarea frame))))
      (when (and wa (fboundp 'frame-outer-width) (fboundp 'frame-outer-height))
        (let* ((mx (nth 0 wa))
                (my (nth 1 wa))
                (mw (nth 2 wa))
                (mh (nth 3 wa))
                (fw (frame-outer-width frame))
                (fh (frame-outer-height frame)))
          (set-frame-position frame
            (+ mx (/ (- mw fw) 2))
            (+ my (/ (- mh fh) 2))))))))

(defun emacs-config-setup-gui-frame (&optional frame)
  "Apply GUI-only settings (fonts, centering) to FRAME."
  (with-selected-frame (or frame (selected-frame))
    (when (display-graphic-p)
      (set-face-attribute 'default nil :font "JetBrainsMonoNL Nerd Font Mono" :height 160)
      (set-face-attribute 'mode-line nil :font "JetBrainsMonoNL Nerd Font Mono" :height 160 :weight 'bold)
      (set-face-attribute 'mode-line-inactive nil :font "JetBrainsMonoNL Nerd Font Mono" :height 160)
      (blink-cursor-mode 1)
      (set-frame-parameter nil 'cursor-type 'bar)
      (run-at-time 0 nil #'emacs-config-center-frame (selected-frame)))))

(add-hook 'emacs-startup-hook #'emacs-config-setup-gui-frame)
(add-hook 'after-make-frame-functions #'emacs-config-setup-gui-frame)

;; When running as a server, prefer focusing frames created by emacsclient.
;; This is important to ensure that 'emacsclient -a= -n -c' brings emacs in focus.
(with-eval-after-load 'server
  (when (boundp 'server-after-make-frame-hook)
    (add-hook 'server-after-make-frame-hook #'emacs-config--activate-gui-frame)))

(provide 'gui-config)

;;; gui-config.el ends here
