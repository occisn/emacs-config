;;; -*- lexical-binding: t; byte-compile-warnings: (not docstrings docstrings-wide) -*-

;;; ===
;;; ===========
;;; === SQL ===
;;; ===========

(my-init--with-duration-measured-section 
 t
 "SQL"

 (setq sql--new-function-names
       '("replace"
         "use"
         "concat"))

 (font-lock-add-keywords 'sql-mode
                         `((,(regexp-opt sql--new-function-names 'words) . font-lock-function-name-face)))

 (add-hook 'sql-mode-hook 
           (lambda ()
             (setq outline-regexp "-- === ")
             (outline-minor-mode)))

 ;; show line number on the left:
 (dolist (mode '(sql-mode-hook))
   (add-hook mode (lambda () (display-line-numbers-mode 1))))

 (defhydra hydra-sql (:exit t :hint nil)
   "
^SQL hydra:
^----------
outline : _o_ hide & _a_ show-all
"
   ("a" #'outline-show-all)
   ("o" #'outline-hide-body))
 
 ) ; end of init section



;;; end of init--lang-sql.el
