;;; -*- lexical-binding: t; byte-compile-warnings: (not docstrings docstrings-wide) -*-

;;; ===
;;; =================
;;; ===== LATEX =====
;;; =================

(my-init--with-duration-measured-section 
 t
 "LaTeX"

 ;; Sumatra: see above

 (if *my-init--windows-p*
     ;; Windows: MiKTeX portable
     (if (my-init--directory-exists-p *miktex-directory*)
         (my-init--add-to-path "MiKTeX" *miktex-directory*)
       (my-init--warning "!! *miktex-directory* is nil or does not exist: %s" *miktex-directory*))
   ;; Linux: TeX Live expected in PATH
   (my-init--message2 "LaTeX: assuming TeX Live is available in PATH"))

 
 ;; also below, but does not seem to work, at least after the installation of a more recent version of Emacs

 (unless (my-init--directory-exists-p *latex-preview-pics-directory*)
   (my-init--warning "!! *latex-preview-pics-directory* is nil or does not exist: %s" *latex-preview-pics-directory*))

 ;; coding system (1/2):
 (setq previous-coding-system-for-read coding-system-for-read)
 (setq coding-system-for-read nil) ; otherwise problem in auctex installation

 (if (>= emacs-major-version 28)
     (use-package tex ;; le package 'auctex' utilise des noms de fichiers en tex-...
       :mode ("\\.tex\\'" . latex-mode)     ; new as of 2023-08-15
       ;; :mode ("\\.tex\\'" . plain-tex-mode)
       :ensure auctex
       :config (my-init--message-package-loaded "tex"))
   (my-init--warning "Could not use package tex/auctex since emacs version is not >= 28"))
 
                                        ; end of tex use-package

 (when (null *pdf-viewer-program*)
   (my-init--warning "!! *pdf-viewer-program* is nil: %s" *pdf-viewer-program*))
 (if (>= emacs-major-version 28)
     (use-package latex 
       :ensure auctex
       :mode ("\\.tex\\'" . latex-mode)
       ;; :mode ("\\.tex\\'" . plain-tex-mode)
       ;; :mode ( "\\.(la)?tex\\'" . latex-mode )
       :config
       (my-init--message-package-loaded "latex")
       (setq TeX-save-query nil)            ; autosave before compiling
       (setq TeX-error-overview-open-after-TeX-run t) ; errors and warnings overview
       ;; (setq TeX-auto-save t)
       ;; (setq TeX-parse-self t)
       (setq TeX-PDF-mode t)                ; PDF output by default
       (setq TeX-view-program-list *pdf-viewer-program*)
       (setq TeX-view-program-selection
             (if *my-init--windows-p*
                 '(((output-dvi style-pstricks) "dvips and start")
                   (output-dvi "Yap")
                   (output-pdf "Sumatra PDF")
                   (output-html "start"))
               '((output-pdf "Evince")
                 (output-html "xdg-open"))))
       ;; RefTeX:
       (add-hook 'LaTeX-mode-hook 'turn-on-reftex)
       (setq reftex-plug-into-auctex t)
       ;; to allow preview on dark background:
       (when (my-init--dark-background-p)
         (custom-set-faces 
          '(preview-reference-face ((t (:background "#ebdbb2" :foreground "black")))))))
   (my-init--warning "Could not use package latex/auctex since emacs version is not >= 28")) ; end of latex use-package

 ;; coding system (2/2):
 (setq coding-system-for-read previous-coding-system-for-read)

 (defun my-tex-occur ()
   (interactive)
   (occur "^% ===\\|^\\\\def\\\\")
   (other-window 1))

 (defun my-latex-occur ()
   (interactive)
   (occur "^% \\*\\*\\*")
   (other-window 1))

 ;; babel for LaTeX:
 (defun my--org-babel-load-latex (&rest _args)
   (message "Preparing org-mode babel for latex...")
   (add-to-list 'org-babel-load-languages '(latex . t))
   (org-babel-do-load-languages 'org-babel-load-languages org-babel-load-languages)
   (advice-remove 'org-babel-execute-src-block #'my--org-babel-load-latex))

 (advice-add 'org-babel-execute-src-block
             :before #'my--org-babel-load-latex)
 
 (setq org-latex-pdf-process
       '("pdflatex -interaction nonstopmode -output-directory %o %f"))
 
 (defhydra hydra-tex (:exit t :hint nil)
   "
^Tex hydra:
^------------
c : occur
"
   ("c" #'my-tex-occur))

 (defhydra hydra-latex (:exit t :hint nil)
   "
^LaTeX hydra:
^------------
c : occur
"
   ("c" #'my-latex-occur))
 
 ) ; end of init section



;;; end of init--lang-latex.el
