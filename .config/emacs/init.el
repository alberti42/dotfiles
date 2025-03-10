(setq backup-inhibited t) ; disable backup
(setq make-backup-files nil) ; stop creating ~ files
(menu-bar-mode -1) ; turn off menu ba
(setq vc-follow-symlinks t) ; do not ask confirmation before following symbolic links

;; Emacs packages
;; Any add to list for package-archives (to add marmalade or melpa) goes here
;; MELPA is a popular emacs package loader
(require 'package)
(add-to-list 'package-archives 
    '("MELPA" .
      "http://melpa.org/packages/"))
(package-initialize)

;; Configure TAB character’s length
(setq-default tab-width 4)

;; Catppuccin for Emacs https://github.com/catppuccin/emacs
(setq catppuccin-flavor 'frappe) ; or 'latte, 'macchiato, or 'mocha
(load-theme 'catppuccin :no-confirm)
(set-face-attribute 'default nil :background "#282935")
(set-face-attribute 'mode-line nil :background "#22232e")

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
 '(package-selected-packages '(ssh-config-mode catppuccin-theme)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )


