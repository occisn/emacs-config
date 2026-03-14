;;; -*- lexical-binding: t; byte-compile-warnings: (not docstrings docstrings-wide) -*-

;;; ===
;;; ===========================
;;; ===== MAXIMA LANGUAGE =====
;;; ===========================

(my-init--with-duration-measured-section 
 t
 "Maxima language"

 (when *my-init--windows-p*
   (if (my-init--directory-exists-p *maxima-directory*)
       (my-init--add-to-path-and-exec-path "Maxima" *maxima-directory*)
     (my-init--warning "!! *maxima-directory* is nil or does not exist: %s" *maxima-directory*)))

 ;; reference: https://orgmode.org/worg/org-contrib/babel/languages/ob-doc-maxima.html

 ;; Babel:
 (defun my--org-babel-load-maxima (&rest _args)
   (message "Preparing org-mode babel for maxima...")
   (add-to-list 'org-babel-load-languages '(maxima . t))
   (org-babel-do-load-languages 'org-babel-load-languages org-babel-load-languages)
   (advice-remove 'org-babel-execute-src-block #'my--org-babel-load-maxima))

 (advice-add 'org-babel-execute-src-block
             :before #'my--org-babel-load-maxima)

 ) ; end of init section



;;; end of init--lang-maxima.el
