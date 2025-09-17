(setq backup-inhibited t) ; disable backup
(setq make-backup-files nil) ; stop creating ~ files
(menu-bar-mode -1) ; turn off menu bar
(setq vc-follow-symlinks t) ; do not ask confirmation before following symbolic links

;; Emacs packages
;; Any add to list for package-archives (to add marmalade or melpa) goes here
;; MELPA is a popular emacs package loader
(require 'package)
(setq package-archives
      '(("gnu"   . "https://elpa.gnu.org/packages/")
        ("melpa" . "https://melpa.org/packages/")))  ; was http + "MELPA"
(package-initialize)

;; Function installing packages and refreshing cache if needed
(defun install-packages-at-startup (pkgs)
  (let ((refreshed nil))
    (dolist (pkg pkgs)
      (unless (package-installed-p pkg)
        ;; If we don't even see the package in the current metadata, refresh once.
        (unless (assoc pkg package-archive-contents)
          (package-refresh-contents)
          (setq refreshed t))
        (condition-case err
            (package-install pkg)
          ;; If install fails (e.g. stale version URL), refresh once and retry.
          (error
           (unless refreshed
             (package-refresh-contents)
             (setq refreshed t))
           (package-install pkg)))))))

;; Install the listed packages if not already installed
(install-packages-at-startup
 '(use-package magit catppuccin-theme lua-mode ssh-config-mode pbcopy xclip))

;; Configure TAB character’s length
(setq-default tab-width 4)

;; Save minibuffer history
(savehist-mode 1)

;; Catppuccin for Emacs https://github.com/catppuccin/emacs
(setq catppuccin-flavor 'frappe) ; 'frappe, 'latte, 'macchiato. or 'mocha
(load-theme 'catppuccin :no-confirm)
;; (set-face-attribute 'default nil :background "#282935")
;; (set-face-attribute 'mode-line nil :background "#22232e")

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

