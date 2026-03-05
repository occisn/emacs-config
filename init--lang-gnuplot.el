;;; -*- lexical-binding: t; byte-compile-warnings: (not docstrings docstrings-wide) -*-

;;; ===
;;; ===================
;;; ===== GNUPLOT =====
;;; ===================

(my-init--with-duration-measured-section 
 t
 "Gnuplot"

 (if *my-init--windows-p*
     (progn
       (unless (my-init--directory-exists-p *gnuplot-directory*)
         (my-init--warning "!! *gnuplot-directory* is nil or does not exist: %s" *gnuplot-directory*))
       (unless (my-init--file-exists-p *gnuplot-program*)
         (my-init--warning "!! *gnuplot-program* is nil or does not exist: %s" *gnuplot-program*)))
   ;; Linux: gnuplot expected in PATH
   (unless (executable-find "gnuplot")
     (my-init--warning "!! gnuplot not found in PATH")))

 (use-package gnuplot-mode
   :mode ("\\.[Gg][Pp]\\'" . gnuplot-mode)
   :requires 'gnuplot
   :init
   (setq gnuplot-program *gnuplot-program*)
   (when (my-init--directory-exists-p *gnuplot-directory*)
     (my-init--add-to-path-and-exec-path "Gnuplot" *gnuplot-directory*))
   :config
   (my-init--message-package-loaded "gnuplot-mode")
   ;; (setq auto-mode-alist 
   ;;   (append '(("\\.\\(gp\\|gnuplot\\)$" . gnuplot-mode)) auto-mode-alist))
   )

 ;; babel for Gnuplot:
 (defun my--org-babel-load-gnuplot (&rest _args)
   (message "Preparing org-mode babel for gnuplot...")
   (add-to-list 'org-babel-load-languages '(gnuplot . t))
   (org-babel-do-load-languages 'org-babel-load-languages org-babel-load-languages)
   (advice-remove 'org-babel-execute-src-block #'my--org-babel-load-gnuplot))

 (advice-add 'org-babel-execute-src-block
             :before #'my--org-babel-load-gnuplot)

 ;; ... and Gnuplot package shall be installed
 ;; inspiration: https://emacs.stackexchange.com/questions/59517/org-plot-with-gnuplot-searching-for-program-no-such-file-or-direcotry-aspell 

 (defhydra hydra-gnuplot (:exit t :hint nil)
   "
^Gnuplot hydra:
^--------------

You can run the plot command either directly (by M-x gnuplot-run-buffer), or with the (customizable) shortcut C-c C-c

You can also send commands to gnuplot using C-c C-b (send buffer to gnuplot) or C-c C-r (send region to gnuplot), but the error reporting isn’t as helpful with these functions.

(end)"
   ;; ("e" #'a-function)
   )
 
 ) ; end of init section



;;; end of init--lang-gnuplot.el
