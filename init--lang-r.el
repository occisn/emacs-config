;;; -*- lexical-binding: t; byte-compile-warnings: (not docstrings docstrings-wide) -*-

;;; ===
;;; ======================
;;; ===== R LANGUAGE =====
;;; ======================

(my-init--with-duration-measured-section 
 t
 "R language"

 ;; M-x R to launch REPL
 ;; open a .R file then C-c C-c to execute within REPL
 ;; also work in org-mode source block (Babel)

 (unless (or (my-init--file-exists-p *R-executable*)
             (and *my-init--linux-p* *R-executable* (executable-find *R-executable*)))
   (my-init--warning "!! *R-executable* is nil or does not exist: %s" *R-executable*))

 (unless (or (my-init--file-exists-p *Rterm-executable*)
             (and *my-init--linux-p* *Rterm-executable* (executable-find *Rterm-executable*)))
   (my-init--warning "!! *Rterm-executable* is nil or does not exist: %s" *Rterm-executable*))

 ;; Babel:
 (defun my--org-babel-load-R (&rest _args)
   (message "Preparing org-mode babel for R...")
   (add-to-list 'org-babel-load-languages '(R . t))
   (org-babel-do-load-languages 'org-babel-load-languages org-babel-load-languages)
   (advice-remove 'org-babel-execute-src-block #'my--org-babel-load-R))

 (advice-add 'org-babel-execute-src-block
             :before #'my--org-babel-load-R)

 ;; Babl complement:
 (setq org-babel-R-command (format "\"%s\" --slave --no-save" *R-executable* ))

 ;; ESS for R integration:
 (use-package ess
   :mode ("\\.R\\'" . R-mode)
   :ensure t
   :config (my-init--message-package-loaded "ess"))

 ;; Setting R executable:
 ;; (setq inferior-R-program-name *Rterm-executable*)
 ;; Byte-compile warning:
 ;;    ‘inferior-R-program-name’ is an obsolete variable (as of ESS 18.10)
 ;;    use ‘inferior-ess-r-program’ instead.
 (setq inferior-ess-r-program *Rterm-executable*)

 ;; Syntax highlighting for R mode, in particular in src blocks:

 (setq R--keywords
       '("%in%"
         ))

 (setq R--types '("tobefilled12345"))

 (setq R--constants
       '(
         "tobefilled12345"
         ))

 (setq R--events '("tobefilled12345"))

 (setq R--functions
       '("aes"
         "c"
         "data.frame"
         "element_blank"
         "element_line"
         "element_rect"
         "element_text"
         "facet_wrap"
         "geom_bar"
         "geom_line"
         "geom_point"
         "geom_smooth"
         "geom_text"
         "ggplot"
         "gsub"
         "library"
         "max"
         "min"
         "options"
         "option"
         "require"
         "rgb"
         "round"
         "scale_y_continuous"
         "theme"
         "unique"
         ))

 (setq R--font-lock-keywords
       (let* (
              ;; generate regex string for each category of keywords
              (x-keywords-regexp (regexp-opt R--keywords 'words))
              (x-types-regexp (regexp-opt R--types 'words))
              (x-constants-regexp (regexp-opt R--constants 'words))
              (x-events-regexp (regexp-opt R--events 'words))
              (x-functions-regexp (regexp-opt R--functions 'words)))

         `(
           (,x-types-regexp . font-lock-type-face)
           (,x-constants-regexp . font-lock-constant-face)
           (,x-events-regexp . font-lock-builtin-face)
           (,x-functions-regexp . font-lock-function-name-face)
           (,x-keywords-regexp . font-lock-keyword-face)
           ;; note: order above matters, because once colored, that part won't change.
           ;; in general, put longer words first
           )))

 (define-derived-mode R-mode fundamental-mode "R mode"
   "Major mode for editing R"
   (setq font-lock-defaults '((R--font-lock-keywords))))

 ) ; end of init section



;;; end of init--lang-r.el
