;;; init.el -*- lexical-binding: t; tab-width: 2; -*-

(setq backup-inhibited t) ; disable backup
(setq make-backup-files nil) ; stop creating ~ files
(setq auto-save-default nil) ; disable auto-save completely (no #…# files)
(setq create-lockfiles nil) ; stop lock files (.#filename)

(setq vc-follow-symlinks t) ; do not ask confirmation before following symbolic links

;; Bootstrap
;; Keep init.el compact; details live in emacs-config-core.el.
(let ((init-path (or load-file-name
                   user-init-file
                   (expand-file-name "init.el" user-emacs-directory))))
  (load (expand-file-name
          "emacs-config-core"
          (file-name-directory (file-truename init-path)))
    nil 'nomessage))

;; GUI chrome, fonts, frame setup, and TTY mode-line separator.
(emacs-config-load-module
  'gui-config
  "Could not load gui-config.el; GUI/frame settings are disabled.")

;; Built-ins
;; cl-lib: Common Lisp compatibility helpers used by many packages.
(use-package cl-lib
  :straight nil) ; use built-in cl-lib (Emacs 24+), don't fetch via straight

;; Smart auto-revert: silently revert clean buffers on external change,
;; prompt when the buffer has unsaved local edits.
(emacs-config-load-module
  'auto-revert-config
  "Could not load auto-revert-config.el; smart auto-revert is disabled.")

;; UI & Convenience
;; which-key: display available keybindings in popup.
(use-package which-key
  :straight nil  ; use built-in which-key (Emacs 30+), don't fetch via straight
  :config
  (which-key-mode 1))

;; macOS pseudo-daemon
;; Keep Dock icon + menu functional after closing the last GUI frame when using
;; emacs in server/daemon style workflows.
(emacs-config-load-module
  'mac-pseudo-daemon-config
  "Could not load mac-pseudo-daemon-config.el; macOS pseudo-daemon behavior is disabled.")

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
;; Disable line numbers in terminal/shell buffers.
(dolist (hook '(shell-mode-hook eshell-mode-hook term-mode-hook))
  (add-hook hook (lambda () (display-line-numbers-mode -1))))

;; Wrapping helpers (soft wrap, visual only)
(emacs-config-load-module
  'wrap
  "Could not load wrap.el; wrapping helpers are disabled.")

;; Per-syntax indentation settings
(emacs-config-load-module
  'syntaxes
  "Could not load syntaxes.el; per-syntax settings are disabled.")

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

;; Dired and file manager
(emacs-config-load-module
  'dired-config
  "Could not load dired-config.el; dired customizations are disabled.")

;; Development
;; multiple-cursors: Sublime Text-style multiple cursors.
(use-package multiple-cursors
  :bind (("C->" . mc/mark-next-like-this)
         ("C-<" . mc/mark-previous-like-this)))

;; magit: Git porcelain, forge (GitHub/GitLab), and nerd-icons integration.
(emacs-config-load-module
  'magit-config
  "Could not load magit-config.el; Magit is disabled.")

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

;; apropospriate-theme: A Sublime Text-inspired color theme.
;; (use-package apropospriate-theme
;;   :straight (apropospriate-theme
;;               :type git
;;               :host github
;;               :repo "waymondo/apropospriate-theme")
;;   :config
;;   (load-theme 'apropospriate-dark t))

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

;; Scrolling
(emacs-config-load-module
  'scroll-config
  "Could not load scroll-config.el; scrolling settings are disabled.")
