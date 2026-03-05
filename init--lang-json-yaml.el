;;; -*- lexical-binding: t; byte-compile-warnings: (not docstrings docstrings-wide) -*-

;;; ===
;;; ================
;;; ===== JSON =====
;;; ================

(my-init--with-duration-measured-section
 t
 "json"

 (use-package json-mode
   :mode ("\\.json\\'" . json-mode)
   :ensure t
   :config (my-init--message-package-loaded "json-mode"))

 ) ; end of init section


;;; ===
;;; ================
;;; ===== YAML =====
;;; ================

(my-init--with-duration-measured-section
 t
 "yaml"

 (use-package yaml-mode
   :mode ("\\.yaml\\'" . yaml-mode)
   :ensure t
   :config (my-init--message-package-loaded "yaml-mode"))
 
 ) ; end of init section



;;; end of init--lang-json-yaml.el
