;;; corfu-config.el --- Compatibility shim -*- lexical-binding: t; -*-

;; This file remains for compatibility with older init.el setups.
;; The implementation moved to completions/corfu.el.

(load (expand-file-name
       "completions/corfu"
       (file-name-directory (file-truename (or load-file-name buffer-file-name))))
      nil 'nomessage)

(provide 'corfu-config)
;;; corfu-config.el ends here
