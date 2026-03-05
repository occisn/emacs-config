;;; -*- lexical-binding: t; byte-compile-warnings: (not docstrings docstrings-wide) -*-

;;; ===
;;; ===========================
;;; ===== PYTHON LANGUAGE =====
;;; ===========================

(my-init--with-duration-measured-section 
 t
 "Python language"

 ;; see "PYTHON IN PATH" above
 
 (use-package elpy
   :mode ("\\.py\\'" . python-mode)
   :config (elpy-enable)
   (my-init--message-package-loaded "elpy"))

 ;; === Display line number

 (dolist (mode '(python-mode-hook python-ts-mode-hook))
   (add-hook mode (lambda () (display-line-numbers-mode 1))))

 ;; Babel:
 (defun my--org-babel-load-python (&rest _args)
   (message "Preparing org-mode babel for python...")
   (add-to-list 'org-babel-load-languages '(python . t))
   (org-babel-do-load-languages 'org-babel-load-languages org-babel-load-languages)
   (advice-remove 'org-babel-execute-src-block #'my--org-babel-load-python))

 (advice-add 'org-babel-execute-src-block
             :before #'my--org-babel-load-python)

 ;; \/\/ or choose 'main' Python
 (if *my-init--windows-p*
     ;; Windows: use Python from LibreOffice portable
     (if (my-init--file-exists-p *python-executable--in-libreoffice-for-unoconv*)
         (progn
           (setq python-shell-interpreter *python-executable--in-libreoffice-for-unoconv*)
           (setq org-babel-python-command (format "\"%s\"" *python-executable--in-libreoffice-for-unoconv*)))
       (my-init--warning "!! *python-executable--in-libreoffice-for-unoconv* is nil or does not exist: %s" *python-executable--in-libreoffice-for-unoconv*))
   ;; Linux: use system python3
   (if (executable-find "python3")
       (progn
         (setq python-shell-interpreter "python3")
         (setq org-babel-python-command "python3"))
     (my-init--warning "!! python3 not found in PATH")))
 
 (defhydra hydra-python (:exit t :hint nil)
   "
^Python hydra:
^-------------

C-c C-p to launch REPL
C-c C-c to compile and execute within REPL

(end)
"
   ;; ("d" #'a-function)
   )
 
 ) ; end of init section



;;; end of init--lang-python.el
