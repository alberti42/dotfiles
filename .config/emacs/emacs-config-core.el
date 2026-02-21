;;; emacs-config-core.el --- Bootstrap helpers, Customize, and packages -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; This file contains the "core" wiring for this Emacs configuration:
;; - Find the real config directory even when init.el is symlinked.
;; - Provide a small module loader helper used by init.el.
;; - Redirect Emacs Customize UI writes into custom.el (but do not auto-load it).
;; - Bootstrap straight.el and install/configure use-package.
;;
;; init.el is intentionally kept small and readable; it loads this file early.
;;

;;; Code:

;; Local modules loader
;;
;; This config is symlinked into ~/.config/emacs. To make local modules work
;; without extra symlinks, resolve the real location of this init file.
(defconst emacs-config-dir
  (file-name-directory (file-truename (or load-file-name user-init-file user-emacs-directory)))
  "Directory containing this Emacs configuration.")

(defun emacs-config-load-module (module warning)
  "Load local MODULE from `emacs-config-dir`.

MODULE is a symbol or string (e.g. 'zac-theme-autodetection).
If loading fails, emit WARNING via `display-warning` and return nil.
On success, return non-nil." 
  (let* ((name (if (symbolp module) (symbol-name module) module))
         (path (expand-file-name name emacs-config-dir)))
    (if (load path t 'nomessage)
        t
      (display-warning 'init warning :warning)
      nil)))

;; Keep Emacs Customize UI writes out of init.el.
;;
;; "Customize" (a built-in Emacs feature) lets you change options/faces via
;; interactive buffers like M-x customize-variable / M-x customize-face.
;; If you press "Save", Emacs persists those settings by writing Elisp forms.
;; We redirect those writes into `custom-file` to keep init.el readable.
;;
;; This config intentionally does NOT auto-load custom.el. Treat it as
;; optional, machine-written state:
;; - Prefer editing init.el / modules directly for permanent configuration.
;; - If you did save something via Customize and want it enabled, load it
;;   explicitly: M-x load-file RET custom.el, or evaluate (load custom-file).
(setq custom-file (expand-file-name "custom.el" emacs-config-dir))

;; Packages: straight.el + use-package
;; straight is not on ELPA/MELPA; it bootstraps itself from GitHub.
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

;; Install and configure use-package via straight.
;;
;; straight.el is our package manager: it can install packages from ELPA/MELPA
;; and also directly from Git repos (e.g. GitHub) via recipes.
;; use-package provides a declarative way to configure those packages.
(straight-use-package 'use-package)
(setq straight-use-package-by-default t)

(provide 'emacs-config-core)

;;; emacs-config-core.el ends here
