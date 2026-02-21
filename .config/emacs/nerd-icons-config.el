;;; nerd-icons-config.el --- Nerd icons integrations -*- lexical-binding: t; -*-

;; Library
(use-package nerd-icons)

;; Dired
(use-package nerd-icons-dired
  :hook (dired-mode . nerd-icons-dired-mode))

(provide 'nerd-icons-config)
;;; nerd-icons-config.el ends here
