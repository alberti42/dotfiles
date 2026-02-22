;;; init.el -*- lexical-binding: t; -*-

(setq backup-inhibited t) ; disable backup
(setq make-backup-files nil) ; stop creating ~ files
(setq auto-save-default nil) ; disable auto-save completely (no #…# files)
(setq create-lockfiles nil) ; stop lock files (.#filename)

(setq vc-follow-symlinks t) ; do not ask confirmation before following symbolic links

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
  (add-to-list 'default-frame-alist '(ns-transparent-titlebar . t)))
 (t
  ;; On other GUI builds, fall back to a frameless (undecorated) window.
  (add-to-list 'default-frame-alist '(undecorated . t))
  (add-to-list 'default-frame-alist '(internal-border-width . 10))))

;; Default frame size; TTY frames ignore these.
(add-to-list 'default-frame-alist '(width . 160))
(add-to-list 'default-frame-alist '(height . 100))

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
      (set-face-attribute 'default nil :font "MesloLGS NF" :height 160)
      (set-face-attribute 'mode-line nil :font "MesloLGS NF" :height 160 :weight 'bold)
      (set-face-attribute 'mode-line-inactive nil :font "MesloLGS NF" :height 160)
      (run-at-time 0 nil #'emacs-config-center-frame (selected-frame)))))

(add-hook 'emacs-startup-hook #'emacs-config-setup-gui-frame)
(add-hook 'after-make-frame-functions #'emacs-config-setup-gui-frame)

;; Bootstrap
;; Keep init.el compact; details live in emacs-config-core.el.
(let ((init-path (or load-file-name
                     user-init-file
                     (expand-file-name "init.el" user-emacs-directory))))
  (load (expand-file-name
         "emacs-config-core"
         (file-name-directory (file-truename init-path)))
        nil 'nomessage))

;; Built-ins
;; cl-lib: Common Lisp compatibility helpers used by many packages.
(use-package cl-lib
  :straight nil) ; use built-in cl-lib (Emacs 24+), don't fetch via straight

;; UI & Convenience
;; which-key: display available keybindings in popup.
(use-package which-key
  :straight nil  ; use built-in which-key (Emacs 30+), don't fetch via straight
  :config
  (which-key-mode 1))

;; Save minibuffer history
(savehist-mode 1)

;; Recently visited files
(emacs-config-load-module
 'recentf-config
 "Could not load recentf-config.el; recent files list is disabled.")

;; Completion system (minibuffer + in-buffer)
(emacs-config-load-module
 'completion
 "Could not load completion.el; using default completion behavior.")

;; Nerd icons (Nerd Fonts)
(emacs-config-load-module
 'nerd-icons-config
 "Could not load nerd-icons-config.el; nerd icons are disabled.")

;; Line numbers
(setq display-line-numbers-type 'relative)
;; Keep current line absolute while others are relative.
(setq display-line-numbers-current-absolute t)
(global-display-line-numbers-mode 1)

;; Editing Defaults
;; Use spaces for indentation (never literal \t)
(setq-default indent-tabs-mode nil)
;; Configure indentation defaults
(setq-default tab-width 4)
(setq-default standard-indent 4)
;; Indent/unindent region by tab-width (like Sublime's option-[ / option-])
(defun emacs-config-indent-left ()
  "Shift selected lines (or current line) left by `tab-width' columns."
  (interactive)
  (let ((beg (if (use-region-p) (region-beginning) (line-beginning-position)))
        (end (if (use-region-p) (region-end) (line-end-position))))
    (indent-rigidly beg end (- tab-width))
    (setq deactivate-mark nil)))

(defun emacs-config-indent-right ()
  "Shift selected lines (or current line) right by `tab-width' columns."
  (interactive)
  (let ((beg (if (use-region-p) (region-beginning) (line-beginning-position)))
        (end (if (use-region-p) (region-end) (line-end-position))))
    (indent-rigidly beg end tab-width)
    (setq deactivate-mark nil)))

(bind-key* "C-," #'emacs-config-indent-left)
(bind-key* "C-." #'emacs-config-indent-right)

;; External file change detection
;; When Emacs regains focus, check all file-visiting buffers for external
;; modifications and prompt whether to reload each one.
;; revert-buffer adapts its prompt to the buffer state:
;;   clean buffer → "Revert buffer from file foo? (y or n)"
;;   dirty buffer → "Buffer foo modified; revert anyway? (y or n)"
(defun emacs-config--handle-external-changes ()
  "On focus, prompt to reload any file-visiting buffer changed on disk."
  (dolist (buf (buffer-list))
    (with-current-buffer buf
      (when (and buffer-file-name
                 (file-exists-p buffer-file-name)
                 (not (verify-visited-file-modtime buf)))
        (revert-buffer :ignore-auto)
        ;; Whether the user accepted or declined, record the current disk
        ;; modtime so we don't re-prompt on every subsequent focus event.
        (set-visited-file-modtime)))))

(add-function :after after-focus-change-function
              #'emacs-config--handle-external-changes)

;; Terminal key decoding (CSI u).
(emacs-config-load-module
 'csi-u-keys
 "Could not load csi-u-keys.el; CSI-u key decoding is disabled.")

;; vim-file-locals: parse Vim modelines/file-local settings in files.
(use-package vim-file-locals
  :straight (vim-file-locals
             :type git
             :host github
             :repo "abougouffa/emacs-vim-file-locals")
  ;; Enable globally after startup; it adds `vim-file-locals-apply` to
  ;; `find-file-hook` for newly opened files.
  :hook (after-init . vim-file-locals-mode))

;; Clipboard
;; Always sync kill ring <-> system clipboard
(setq select-enable-clipboard t)
(setq select-enable-primary t)   ; use the X11 primary selection too (Linux/Unix)

;; pbcopy: sync clipboard in terminal on macOS.
;; Only needed when running Emacs in a terminal on macOS.
(use-package pbcopy
  :if (and (eq system-type 'darwin) (not window-system))
  :config
  (turn-on-pbcopy))

;; xclip: sync clipboard in terminal on Linux.
;; Only needed when running Emacs in a terminal on Linux.
(use-package xclip
  :if (and (eq system-type 'gnu/linux) (not window-system))
  :config
  (xclip-mode 1))

;; Development
;; magit: Git porcelain inside Emacs.
(use-package magit)

;; Fast project search (prefer ripgrep)
(emacs-config-load-module
 'search-config
 "Could not load search-config.el; using default project search backend.")

;; Project tree (TTY-friendly)
(emacs-config-load-module
 'treemacs-config
 "Could not load treemacs-config.el; Treemacs is disabled.")

;; LSP modules
(emacs-config-load-module
 'lsp-core
 "Could not load lsp-core.el; LSP is disabled.")

(emacs-config-load-module
 'lsp-python
 "Could not load lsp-python.el; Python LSP is disabled.")

(emacs-config-load-module
 'lsp-web
 "Could not load lsp-web.el; TypeScript/JavaScript LSP is disabled.")

(emacs-config-load-module
 'lsp-ltex-plus-config
 "Could not load lsp-ltex-plus-config.el; LTEX+ is disabled.")

;; VCS gutter (TTY)
(emacs-config-load-module
 'git-gutter-tty
 "Could not load git-gutter-tty.el; VCS gutter is disabled.")

;; Languages
;; lua-mode: major mode for editing Lua.
(use-package lua-mode)

;; ssh-config-mode: major mode for ~/.ssh/config.
(use-package ssh-config-mode)

;; Theme
;; catppuccin-theme: Catppuccin theme collection.
(use-package catppuccin-theme)

;; Theme auto-detection via zsh-appearance-control.
(emacs-config-load-module
 'zac-theme-autodetection
 "Could not load zac-theme-autodetection.el; theme auto-switching is disabled.")

;; Terminal UX
;; Mouse support in terminal Emacs.
;; `xterm-mouse-mode` enables mouse events in terminal emulators that support it.
(use-package mouse
  :straight nil
  :if (not window-system)
  :preface
  (defun emacs-config--scroll-down-1 ()
    (interactive)
    (scroll-down 1))

  (defun emacs-config--scroll-up-1 ()
    (interactive)
    (scroll-up 1))
  :config
  (xterm-mouse-mode 1)
  ;; Wheel events in terminals are usually mouse-4/mouse-5.
  ;; Keep wheel-up/wheel-down bindings too (some builds/terminals use them).
  (global-set-key [mouse-4] #'emacs-config--scroll-down-1)
  (global-set-key [mouse-5] #'emacs-config--scroll-up-1)
  (global-set-key [wheel-up] #'emacs-config--scroll-down-1)
  (global-set-key [wheel-down] #'emacs-config--scroll-up-1))

;; Prevent sudden recentering / keep point away from window edges
(setq scroll-margin 2)
(setq scroll-conservatively 101)
(setq scroll-step 1)

;; Smoother horizontal scrolling too
(setq hscroll-margin 2)
(setq hscroll-step 1)

;; Pixel-precise scrolling (Emacs 29+); improves trackpad momentum on macOS.
(when (>= emacs-major-version 29)
  (pixel-scroll-precision-mode 1))

;; Disable ctrl+scroll zoom (too fast; use keyboard to change font size instead).
(global-set-key (kbd "<C-wheel-up>") 'ignore)
(global-set-key (kbd "<C-wheel-down>") 'ignore)
(global-set-key (kbd "<C-mouse-4>") 'ignore)
(global-set-key (kbd "<C-mouse-5>") 'ignore)

;; vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2 :
