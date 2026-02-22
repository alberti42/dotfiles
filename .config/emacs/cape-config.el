;;; cape-config.el --- Compatibility shim -*- lexical-binding: t; -*-

;; This file remains for compatibility with older init.el setups.
;; The implementation moved to completions/cape.el.

(load (expand-file-name
       "completions/cape"
       (file-name-directory (file-truename (or load-file-name buffer-file-name))))
      nil 'nomessage)

(provide 'cape-config)
;;; cape-config.el ends here
