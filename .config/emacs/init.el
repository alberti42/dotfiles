(setq backup-inhibited t) ; disable backup
(setq make-backup-files nil) ; stop creating ~ files
(setq auto-save-default nil) ; disable auto-save completely (no #…# files)
(setq create-lockfiles nil) ; stop lock files (.#filename)
(menu-bar-mode -1) ; turn off menu bar
(setq vc-follow-symlinks t) ; do not ask confirmation before following symbolic links

;; Packages: straight.el + use-package
;; straight is not on MELPA; it bootstraps itself from GitHub.
(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el" user-emacs-directory))
      (bootstrap-version 7))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

;; Install and configure use-package via straight
(straight-use-package 'use-package)
(setq straight-use-package-by-default t)

;; Install packages (straight will install them if missing)
(use-package magit)
(use-package catppuccin-theme)
(use-package lua-mode)
(use-package ssh-config-mode)
(use-package pbcopy)
(use-package xclip)

;; Example for a GitHub-only package (uncomment if needed):
;; (use-package vim-modeline
;;   :straight (vim-modeline :type git :host github :repo "cinsk/emacs-vim-modeline"))

(use-package vim-file-locals
  :straight (vim-file-locals
             :type git
             :host github
             :repo "abougouffa/emacs-vim-file-locals")
  :config
  (vim-file-locals-mode 1))

;; Configure TAB character’s length
(setq-default tab-width 4)

;; Save minibuffer history
(savehist-mode 1)

;; Catppuccin for Emacs https://github.com/catppuccin/emacs
(setq catppuccin-flavor 'frappe) ; 'frappe, 'latte, 'macchiato. or 'mocha
(load-theme 'catppuccin :no-confirm)
(set-face-attribute 'default nil :background "unspecified-bg")
(set-face-attribute 'mode-line nil :background "unspecified-bg")
(set-face-attribute 'mode-line-inactive nil :background "unspecified-bg")

;; Set default font for Emacs
(set-face-attribute 'default nil :font "MesloLGS NF" :height 120)

;; Customize the mode line font
(set-face-attribute 'mode-line nil :font "MesloLGS NF" :height 120 :weight 'bold)
(set-face-attribute 'mode-line-inactive nil :font "MesloLGS NF" :height 120)

;; Set syntax for ssh config file
; (add-to-list 'auto-mode-alist '("/.ssh/config" . ssh-config-mode))
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages nil))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

;; Always sync kill ring <-> system clipboard
(setq select-enable-clipboard t)
(setq select-enable-primary t)   ; use the X11 primary selection too (Linux/Unix)
(cond
 ;; macOS: use pbcopy in terminal
 ((eq system-type 'darwin)
  (use-package pbcopy
    :ensure t
    :config
    (turn-on-pbcopy)))

 ;; GNU/Linux: use xclip in terminal
 ((eq system-type 'gnu/linux)
  (use-package xclip
    :ensure t
    :config
    (xclip-mode 1))))

;; Enable mouse support
(unless window-system
  (require 'mouse)
  (xterm-mouse-mode 1)
  (global-set-key [wheel-up] (lambda ()
                               (interactive)
                               (scroll-down 1)))
  (global-set-key [wheel-down] (lambda ()
                                 (interactive)
                                 (scroll-up 1)))
  ;; Optional: support shift/ctrl modifiers
  (global-set-key [double-wheel-up] 'scroll-down-command)
  (global-set-key [double-wheel-down] 'scroll-up-command)
  (defun track-mouse (e))
  (setq mouse-sel-mode t))

;; Prevent sudden recentering / keep point away from window edges
(setq scroll-margin 2)
(setq scroll-conservatively 101)
(setq scroll-step 1)

;; Smoother horizontal scrolling too
(setq hscroll-margin 2)
(setq hscroll-step 1)

;; vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2 :
