;;; -*- lexical-binding: t; byte-compile-warnings: (not docstrings docstrings-wide) -*-

;;; ===
;;; ============================
;;; ===== EMACS AS LISP IDE ====
;;; ============================

(my-init--with-duration-measured-section 
 t
 "Emacs as Lisp IDE"

 ;; ===
 ;; === (EL) interpretor in mini-buffer
 
 ;; ~M-:~
 ;; ~C-u M-:~ insert the result into current buffer instead of printing it in the echo area.

 ;; ===
 ;; === (EL) C-x C-e anywhere
 
 ;; C-x C-e
 ;;
 ;; in scratch, we can type lisp and interpret with C-j

 ;; ==
 ;; == (CL) Choice of Common Lisp flavour
 
 (setq *common-lisp-flavor* "sbcl")
 
 ;; ==
 ;; == (CL) Assignments subsequent to the choice of Lisp flavour

 (cond ((string= *common-lisp-flavor* "sbcl")
        (progn
          (setq *inferior-lisp-program* *sbcl--inferior-lisp-program*)
          (setq *common-lisp-directory* *sbcl--common-lisp-directory*)
          (setq *common-lisp-program* *sbcl--common-lisp-program*)))
       ((string= *common-lisp-flavor* "clisp")
        (progn
          (setq *inferior-lisp-program* *clisp--inferior-lisp-program*)
          (setq *common-lisp-directory* *clisp--common-lisp-directory*)
          (setq *common-lisp-program* *clisp--common-lisp-program*)))
       ((string= *common-lisp-flavor* "ccl")
        (progn
          (setq *inferior-lisp-program* *ccl--inferior-lisp-program*)
          (setq *common-lisp-directory* *ccl--common-lisp-directory*)
          (setq *common-lisp-program* *ccl--common-lisp-program*)))
       ((string= *common-lisp-flavor* "abcl")
        (progn
          (setq *inferior-lisp-program* *abcl--inferior-lisp-program*)
          (setq *common-lisp-directory* *abcl--common-lisp-directory*)
          (setq *common-lisp-program* *abcl--common-lisp-program*)))
       (t (my-init--warning "Lisp flavour not recognized: %s" *common-lisp-flavor*))) ; end of cond

 ;; set directory is valid and set path:
 (if (my-init--directory-exists-p *common-lisp-directory*)
     (my-init--add-to-path-and-exec-path "Common Lisp" *common-lisp-directory*)
   (if *my-init--linux-p*
       ;; On Linux, Common Lisp may be in PATH without a dedicated directory
       (my-init--message2 "Common Lisp: no dedicated directory, assuming in PATH")
     (my-init--warning "Common Lisp directory nil or not valid: %s" *common-lisp-directory*)))

 ;; check program is valid:
 (unless (or (my-init--file-exists-p *common-lisp-program*)
             (and *my-init--linux-p* *common-lisp-program* (executable-find *common-lisp-program*)))
   (my-init--warning "Common Lisp program nil or not valid: %s" *common-lisp-program*))

 ;; ===
 ;; === (CL) Start Common Lisp without slime ===

 (defun my/start-external-common-lisp ()
   "Starts external Common Lisp."
   (interactive)
   (let ((cmd (concat "\"" (my-init--replace-linux-slash-with-two-windows-slashes *common-lisp-program*) "\"")))
     (if *my-init--windows-p*
         (w32-shell-execute "open" cmd)
       (start-process "common-lisp" nil *common-lisp-program*))
     (message "External Common Lisp opened.")))
 ;; available in hydra      

 (defun my/start-common-lisp-as-buffer ()
   "Starts Common Lisp within a buffer"
   (interactive)
   (let ((cmd (concat "\"" (my-init--replace-linux-slash-with-two-windows-slashes *common-lisp-program*) "\"")))
     (async-shell-command cmd nil nil)))

 ;; ==
 ;; == (CL) Slime

 ;; M-x slime should work

 (with-eval-after-load 'slime

   ;; Always show compilation notes buffer
   (setq slime-compilation-finished-hook 'slime-maybe-show-compilation-log)

   ;; Show compilation buffer even with no errors
   (setq slime-display-compilation-output t)

   (setq slime-compilation-hints-level 'all)

   (setq slime-show-compilation-buffer t)

   ;; see also:
   ;; (setq slime-popup-on-compile-notes t)
   ;; M-x slime-show-compilation-log to bring up the buffer
   ;; C-c M-c to list compiler notes

   ;; Display compilation notes in the REPL window
   (setq slime-display-compilation-output t))

 ;; Configure display-buffer to reuse REPL window for compilation notes
 (add-to-list 'display-buffer-alist
              '("\\*slime-compilation\\*"
                (display-buffer-reuse-window display-buffer-same-window)
                (reusable-frames . t)
                (inhibit-same-window . nil)))

 ;; if necessary:
 ;; M-x slime-show-compilation-log

 ;; ==
 ;; === (EL+CL) Babel
 
 (defun my--org-babel-load-lisp (&rest _args)
   (message "Preparing org-mode babel for lisp...")
   (add-to-list 'org-babel-load-languages '(lisp . t))
   (org-babel-do-load-languages 'org-babel-load-languages org-babel-load-languages)
   (advice-remove 'org-babel-execute-src-block #'my--org-babel-load-lisp))

 (advice-add 'org-babel-execute-src-block
             :before #'my--org-babel-load-lisp)

 (defun my--org-babel-load-emacs-lisp (&rest _args)
   (message "Preparing org-mode babel for emacs-lisp...")
   (add-to-list 'org-babel-load-languages '(emacs-lisp . t))
   (org-babel-do-load-languages 'org-babel-load-languages org-babel-load-languages)
   (advice-remove 'org-babel-execute-src-block #'my--org-babel-load-emacs-lisp))

 (advice-add 'org-babel-execute-src-block
             :before #'my--org-babel-load-emacs-lisp)
 
 ;; ===
 ;; === (EL+CL) Show line number on the left

 (dolist (mode '(emacs-lisp-mode-hook lisp-mode-hook))
   (add-hook mode (lambda () (display-line-numbers-mode 1))))
 
 ;; ===
 ;; === (EL+CL) Indentation

 ;; (1) Emacs Lisp

 (setq lisp-indent-function 'lisp-indent-function)
 ;; (setq lisp-indent-function 'common-lisp-indent-function)
 ;; indent : http://ergoemacs.org/emacs/emacs_indentation.html
 ;;   http://ergoemacs.org/emacs/emacs_tabs_space_indentation_setup.html

 ;; (2) Common Lisp

 ;; CL indentation instead of Emacs Lisp indentation :
 (add-hook 'lisp-mode-hook
           (lambda ()
             (set (make-local-variable lisp-indent-function)
                  'common-lisp-indent-function)))
 ;; see https://lispcookbook.github.io/cl-cookbook/emacs-ide.html

 ;; (3) Common:

 (dolist (mode '(emacs-lisp-mode-hook lisp-mode-hook))
   (add-hook mode (lambda () (electric-indent-local-mode 1))))

 (defun my/indent-lisp-buffer ()
   "Indent Lisp buffer."
   (interactive)
   (save-excursion
     (let ((nb-tabs (count-matches "\t")))

       ;; (1) untabify if necessary:
       (when (> nb-tabs 0)
         (if (= nb-tabs 1)
             (message "1 tab identified... untabifying buffer")
           (message "%d tabs identified... untabifying buffer" nb-tabs))
         (goto-char (point-min))
         (push-mark)
         (goto-char (point-max))
         (untabify (point) (mark))
         (pop-mark))

       ;; (2) indent:       
       (indent-region (point-min) (point-max))

       (recenter-top-bottom))))

 (when nil
   (use-package aggressive-indent
     ;; defer
     :config
     (add-hook 'emacs-lisp-mode-hook #'aggressive-indent-mode)
     (add-hook 'lisp-mode-hook #'aggressive-indent-mode)
     (my-init--message-package-loaded "aggressive-indent")))

 ;; ===
 ;; === (EL+CL) Extra font (for bound variables and quoted expressions)

 ;; This package highlights the location where local variables is created (bound, for example by let) as well as quoted and backquoted constant expressions.
 (use-package lisp-extra-font-lock
   :defer nil
   :mode ("\\.el\\'" . emacs-lisp-mode)
   ("\\.lisp\\'" . lisp-mode)
   :hook ((emacs-lisp-mode lisp-mode slime-repl-mode) . lisp-extra-font-lock-global-mode)
   :config
   (my-init--message-package-loaded "lisp-extra-font-lock")
   ;; (lisp-extra-font-lock-global-mode 1)
   )
 ;; see also: (font-lock-add-keywords 'lisp-mode '(("(\\(\\(define-\\|do-\\|with-\\)\\(\\s_\\|\\w\\)*\\)" 1 font-lock-keyword-face)))

 ;; ===
 ;; === (EL+CL) Code folding (hs-minor-mode)

 (add-hook 'emacs-lisp-mode-hook #'hs-minor-mode)
 (add-hook 'lisp-mode-hook #'hs-minor-mode)

 ;; ===
 ;; === (EL+CL) my occur

 (defun my-elisp-occur ()
   (interactive)
   (occur "\\s-*(defhydra [^%]\\|\\s-*(use-\\package [^%]\\|\\s-*(defun [^%]\\|\\s-*(cl\\-defun [^%]\\|\\s-*(defvar [^%]\\|\\s-*(defface [^%]\\|\\s-*(defcustom [^%]\\|\\s-*(defmacro [^%]\\|\\s-*(cl-\\defmacro [^%]\\|\\s-*(defparameter [^%]\\|\\s-*(global-set-key[^%]\\|\\s-*;;*\\s-===\\|\\s-*(ert-deftest [^%]"))
 ;; ^ = beginning of line
 ;; \s-* = Zero or more whitespace characters (spaces, tabs, etc.); to be preceded by an additional \
 ;; \s- = one whitespace character; to be preceded by an additional \
 ;; ;;* = 3 or more ;

 (defun my-cl-occur ()
   (interactive)
   (occur "\\s-*(defparameter [^%]\\|\\s-*(deftype [^%]\\|\\s-*(defstruct [^%]\\|\\s-*(defun [^%]\\|\\s-*(defmacro [^%]\\|\\s-*;;*\\s-===\\|\\s-*(define-test [^%]\\|\\s-*(parachute:define-test [^%]")
   (other-window 1))
 ;; ^ = beginning of line
 ;; \s-* = Zero or more whitespace characters (spaces, tabs, etc.); to be preceded by an additional \
 ;; \s- = one whitespace character; to be preceded by an additional \
 ;; ;;* = 3 or more ;

 ;; ===
 ;; === (EL+CL) Expand region with C-=

 (use-package expand-region
   ;; :defer nil
   :config (my-init--message-package-loaded "expand-region")
   :bind ("C-=". er/expand-region))

 ;; ===
 ;; === (EL+CL) Completion (company & ac-slime)

 ;; C-M-i, C-:

 ;; (1) Emacs Lisp: company

 ;; Company is a text completion framework for Emacs. The name stands for "complete anything".
 ;; It uses pluggable back-ends and front-ends to retrieve and display completion candidates.

 (use-package company                   ; company-mode
   :defer nil
   :hook ((emacs-lisp-mode lisp-mode) . company-mode) 
   :config
   ;; (add-hook 'after-init-hook 'global-company-mode)
   ;; (add-hook 'after-init-hook 'global-company-mode)
   ;; (setq company-idle-delay 0) ; no delay in showing suggestions
   ;; (setq company-minimum-prefix-length 1) ; show suggestions after entering one character
   ;; (setq company-selection-wrap-around t)
   ;; (company-tng-configure-default) ; use tab key to cycle through suggestions ('tng' means 'tab and go')
   (setq company-idle-delay nil)        ; no automatic start
   (define-key emacs-lisp-mode-map (kbd "C-M-i") #'company-complete)
   (define-key lisp-mode-map (kbd "C-M-i") #'company-complete)
   (my-init--message-package-loaded "company-mode"))
 ;; C-: associated with counsel-company

 ;; (2) Common Lisp with company and slime-company

 ;; above 'use-package company' already proposes configuration for lisp-mode

 (use-package slime-company
   :after (slime company)
   :config 
   (setq slime-company-completion 'fuzzy
         slime-company-after-completion 'slime-company-just-one-space)
   (define-key company-active-map (kbd "\C-d") 'company-show-doc-buffer)
   (define-key company-active-map (kbd "M-.") 'company-show-location)
   (when nil
     (defun slime-show-description (string package)
       "source: https://github.com/digikar99/emacs-noob/blob/slime-company/init.el"
       (let ((bufname (slime-buffer-name :description)))
         (slime-with-popup-buffer (bufname :package package
                                           :connection t
                                           :select slime-description-autofocus)
                                  (when (string= bufname "*slime-description*")
                                    (with-current-buffer bufname (slime-company-doc-mode)))
                                  (princ string)
                                  (goto-char (point-min))))))
   (my-init--message-package-loaded "slime-company"))

 ;; and activate slime-company in slime below

 (defun ora-slime-completion-in-region (_fn completions start end)
   ""
   (funcall completion-in-region-function start end completions))

 (advice-add
  'slime-display-or-scroll-completions
  :around #'ora-slime-completion-in-region)
 ;; reference: https://www.reddit.com/r/emacs/comments/dkz7tm/using_ivy_w_slime/

 ;; To complete in buffer: (mini-buffer?)
 (define-key lisp-mode-map (kbd "C-M-i") #'complete-symbol) ; counsel-cl is deprecated
 ;; (define-key slime-repl-mode-map (kbd "C-M-i") #'complete-symbol) 

 ;; (3) NOT USED Common Lisp : ac-slime

 (when nil
   (use-package auto-complete
     :config
     (setq-default ac-sources '(ac-source-abbrev ac-source-dictionary ac-source-words-in-same-mode-buffers))
     (add-hook 'auto-complete-mode-hook 'ac-common-setup)
     ;; (global-auto-complete-mode t)
     (add-to-list 'ac-modes 'lisp-mode)
     (setq ac-auto-start 2)
     (my-init--message-package-loaded "auto-complete"))

   (use-package ac-slime
     :after (slime auto-complete)
     :config
     (add-hook 'slime-mode-hook 'set-up-slime-ac)
     (add-hook 'slime-repl-mode-hook 'set-up-slime-ac)
     (eval-after-load "auto-complete"
       '(add-to-list 'ac-modes 'slime-repl-mode))
     (setq ac-auto-show-menu 0.3)
     (my-init--message-package-loaded "ac-slime")
     ;; (define-key ac-mode-map (kbd "C-M-i") 'ac-complete)
     )) ; end of when nil

 ;;; ===
 ;;; === (EL) Jump to REPL (IELM) and variants
 ;;; ===

 (defun my/toggle-ielm ()
   "If another window shows `*ielm*`, switch to it.
Otherwise, split vertically and start (or show) ielm in the other window."
   (interactive)
   (let* ((ielm-buffer (get-buffer "*ielm*"))
          (other-win (when (> (count-windows) 1)
                       (next-window))))
     (if (and other-win
              (eq (window-buffer other-win) ielm-buffer))
         ;; Case 1: ielm is already in the other window
         (other-window 1)
       ;; Case 2: no other window with ielm
       (unless (> (count-windows) 1)
         (split-window-right))
       (other-window 1)
       (if ielm-buffer
           (switch-to-buffer ielm-buffer)
         (ielm)))))

 (define-key emacs-lisp-mode-map (kbd "C-c C-z")  #'my/toggle-ielm)

 (defun my/ielm-insert-defun-name ()
   "Insert the name of the current defun into the *ielm* buffer."
   (interactive)
   (let ((defun-name (add-log-current-defun))
         (ielm-buffer (get-buffer "*ielm*")))
     (if (not defun-name)
         (message "Not inside a defun")
       (my/toggle-ielm)
       (goto-char (point-max))
       (insert "(")
       (insert defun-name)
       (insert ")"))))

 (define-key emacs-lisp-mode-map (kbd "C-c C-y")  #'my/ielm-insert-defun-name)

 (defun my/ielm-insert-defun-name-with-time-measurement ()
   "Insert the name of the current defun into the *ielm* buffer, with time measurement."
   (interactive)
   (let ((defun-name (add-log-current-defun))
         (ielm-buffer (get-buffer "*ielm*")))
     (if (not defun-name)
         (message "Not inside a defun")
       (my/toggle-ielm)
       (goto-char (point-max))
       (insert (format "(let ((start-time (current-time)))
  (prog1
      (%s)
    (print (format \"Elapsed: %s s\" (float-time (time-since start-time))))))" defun-name "%.06f")))))

 (define-key emacs-lisp-mode-map (kbd "C-c C-x")  #'my/ielm-insert-defun-name-with-time-measurement)

 (defun my/elisp-execute-defun ()
   "Execute the defun at point."
   (interactive)
   (save-excursion
     ;; Move to the beginning of the defun
     (beginning-of-defun)
     ;; Evaluate the defun
     ;; (eval-defun nil)
     ;; Get the function name by parsing the defun form
     (let ((func-name (save-excursion
                        (down-list)
                        (forward-sexp)
                        (skip-chars-forward " \t\n")
                        (thing-at-point 'symbol t))))
       (if func-name
           (progn
             (message "Executing: %s" func-name)
             ;; Execute the function interactively
             (call-interactively (intern func-name)))
         (error "Could not determine function name: %s" func-name)))))

 (define-key emacs-lisp-mode-map (kbd "C-c M-x")  #'my/elisp-execute-defun)

 ;; ===
 ;; === (CL) Slime, including arguments ala eldoc
 ;; ===      C-c C-x pour time monitoring

 (defun his-tracing-function (orig-fun &rest args)
   (message "fn called with args %S" args)
   (let ((res (apply orig-fun args)))
     (message "fn returned %S" res)
     res))

 (advice-add 'slime-retrieve-arglist :around #'his-tracing-function)

 (use-package slime
   ;; :defer nil

   :commands (slime slime-connect)
   
   :config
   
   (my-init--message-package-loaded "slime")
   
   (setq slime-contribs '(slime-cl-indent
                          slime-autodoc ; to propose arguments
                          slime-fancy
                          slime-asdf
                          slime-quicklisp
                          ))
   
   (setq inferior-lisp-program *inferior-lisp-program*)
   ;; --dynamic-space-size 2048" ; 1024 by default ; otherwis "sbcl --dynamic-space-size 2048" ; "nohup sbcl"?
   ;; (setq inferior-lisp-program "sbcl --dynamic-space-size 16GB")
   
   (when nil
     (setf asdf:*compile-file-warnings-behaviour* :error))
   ;; ... so that the compilation notes goes foreground
   ;; source : http://hectorhon.blogspot.com/2020/02/getting-compilation-output-of-asdfload.html
   
   ;; (setq slime-auto-connect 'ask)
   ;; Byte-compile warning:
   ;;    ‘slime-auto-connect’ is an obsolete variable (as of 2.5)
   ;;    use ‘slime-auto-start’ instead.
   (setq slime-auto-start 'ask)

   (when nil
     (setq slime-compilation-finished-hook 'slime-show-compilation-log)) ; end of when nil
   ;; see https://github.com/slime/slime/blob/master/slime.el

   ;; Removing the compilation error prompt
   ;; "If the Common Lisp implementation fails to compile the file,
   ;; SLIME will ask the user if they want to load the fasl file
   ;; (i.e. the compiled form of the file) anyway.
   ;; I cannot find a reason why one would want to load the ouput
   ;; of a file that failed to compile, and having to decline every time
   ;; is quite annoying."
   (setq slime-load-failed-fasl 'never)
   ;; see https://www.n16f.net/blog/slime-compilation-tips/

   ;; Custom command to execute a function in REPL surrounded by (time...)   
   ;; C-c C-x
   (defvar slime-repl-input-start-mark) ; to avoid compilation warning
   (declare-function slime-parse-toplevel-form "slime-parse.el") ; to avoid compilation warning
   (declare-function slime-switch-to-output-buffer "slime.el") ; to avoid compilation warning
   (declare-function slime-lisp-package "slime-repl.el") ; to avoid compilation warning
   (defun my/slime-call-defun--with-time-monitoring ()
     "Insert a call to the toplevel form defined around point into the REPL, surrounded by (time...).
Modified from official 'slime-call-defun'"
     (interactive)
     (cl-labels ((insert-call
                   (name &key (function t)
                         defclass)
                   (let* ((setf (and function
                                     (consp name)
                                     (= (length name) 2)
                                     (eql (car name) 'setf)))
                          (symbol (if setf
                                      (cadr name)
                                    name))
                          (qualified-symbol-name
                           (slime-qualify-cl-symbol-name symbol))
                          (symbol-name (slime-cl-symbol-name qualified-symbol-name))
                          (symbol-package (slime-cl-symbol-package
                                           qualified-symbol-name))
                          (call (if (cl-equalp (slime-lisp-package) symbol-package)
                                    symbol-name
                                  qualified-symbol-name)))
                     (slime-switch-to-output-buffer)
                     (goto-char slime-repl-input-start-mark)
                     (insert (if function
                                 "(time (" ; my modification
                               " "))
                     (when setf
                       (insert "setf ("))
                     (if defclass
                         (insert "make-instance '"))
                     (insert call)
                     (cond (setf
                            (insert " ")
                            (save-excursion (insert ") )")))
                           (function
                            (insert " ")
                            (save-excursion (insert "))")))) ; my modification
                     (unless function
                       (goto-char slime-repl-input-start-mark)))))
       (let ((toplevel (slime-parse-toplevel-form)))
         (if (symbolp toplevel)
             (error "Not in a function definition")
           (slime-dcase toplevel
                        (((:defun :defgeneric :defmacro :define-compiler-macro) symbol)
                         (insert-call symbol))
                        ((:defmethod symbol &rest args)
                         ;; (declare (ignore args))
                         (insert-call symbol))
                        (((:defparameter :defvar :defconstant) symbol)
                         (insert-call symbol :function nil))
                        (((:defclass) symbol)
                         (insert-call symbol :defclass t))
                        (t
                         (error "Not in a function definition")))))))

   (define-key slime-mode-map (kbd "C-c C-x")  #'my/slime-call-defun--with-time-monitoring)

   ;; Custom command to test a function in REPL
   ;; C-c SPC
   
   (defun my/slime-test ()
     "Test the current test by sending to the REPL something similar to
(parachute:test 'toolbox-tests::floor-to-power-of-10-same-results-2)"
     (interactive)
     (cl-labels ((split-string-at-first-delimiter (s)
                   "Split string S at the first occurrence of either a space or a line return.
For instance: 'aa bb cc' --> ('aa' 'bb cc')
(v1, available in occisn/elisp-utils GitHub repository)"
                   (if (string-match "\\( \\|\n\\)" s)
                       (list (substring s 0 (match-beginning 0))
                             (substring s (match-end 0)))
                     (list s))))        ; end of labels definitions
       (let* ((all-toplevel-sexp (slime-defun-at-point))
              (toplevel-sexp-without-defxxx (cadr (split-string-at-first-delimiter all-toplevel-sexp)))
              (defun-name (car (split-string-at-first-delimiter toplevel-sexp-without-defxxx)))
              (package-name (substring (slime-current-package) 1 nil)) ; substring to delete initial ':'
              (cmd (concat "("
                           "parachute:test "
                           "'"
                           package-name
                           "-tests::test-"
                           defun-name
                           ")"
                           )))
         (slime-switch-to-output-buffer)
         (goto-char slime-repl-input-start-mark)
         (insert cmd))))

   (define-key slime-mode-map (kbd "C-c SPC")  #'my/slime-test)

   ) ; end of use-package slime

 ;; ===
 ;; === (EL+CL) paredit: structured editing of sexps;
 ;; ===                  parenthesis management       

 (use-package paredit
   :hook ((emacs-lisp-mode lisp-mode slime-repl-mode) . paredit-mode)
   :config
   (my-init--message-package-loaded "paredit"))
 ;; paredit animated documentation: http://danmidwood.com/content/2014/11/21/animated-paredit.html


 ;; check parens before saving:
 (add-hook 'emacs-lisp-mode-hook 
           (lambda () 
             (add-hook 'after-save-hook #'check-parens nil 'make-it-local)))
 (add-hook 'lisp-mode-hook 
           (lambda () 
             (add-hook 'after-save-hook #'check-parens nil 'make-it-local)))

 ;; Paren mode (by default since Emacs 28.1) + fix for echo of beginning of sexp:
 (show-paren-mode t)                    ; by default since Emac 28.1
 ;; video: https://web.archive.org/web/20121024123050/http://img8.imageshack.us/img8/9479/openparen.gif

 ;; problem: paredit disables paren-mode: (let ((show-paren-mode nil))
 ;; so we no longer have access to the echo in the mini-buffer
 ;; of the beginning of closing parentheses
 ;; we need to specifically launch this paren-mode function
 ;; from paredit:
 (defun my-echo-paren-matching-line-2 (orig-fun &rest args)
   "If a matching paren is off-screen, echo the matching line."
   (prog1 (apply orig-fun args)
     (when (char-equal (char-syntax (char-before (point))) ?\))
       (let ((_matching-text (blink-matching-open)))
         (when nil (message "hello")) ; to avoid compilation warning: ‘let’ with empty body
         ;; (when _matching-text
         ;;   (message _matching-text))
         ))))
 (advice-add 'paredit-blink-paren-match :around #'my-echo-paren-matching-line-2)
 ;; inspiration: https://stackoverflow.com/questions/13575554/display-line-of-matching-bracket-in-the-minibuffer

 ;; === 
 ;; === (CL) Paredit in REPL

 (add-hook 'slime-repl-mode-hook 'enable-paredit-mode)

 ;; Stop SLIME's REPL from grabbing DEL,
 ;; which is annoying when backspacing over a '('
 (defvar slime-repl-mode-map) ; to avoid compilation warning
 (defun override-slime-repl-bindings-with-paredit ()
   (define-key slime-repl-mode-map
               (read-kbd-macro paredit-backward-delete-key)
               nil))
 (add-hook 'slime-repl-mode-hook 'override-slime-repl-bindings-with-paredit)
 ;; source: https://wikemacs.org/wiki/Paredit-mode

 ;; ===
 ;; === Electric return to add a line when RETURN before )

 (dolist (mode '(emacs-lisp-mode-hook lisp-mode-hook))
   (add-hook mode
             (lambda ()
               
               (defvar electrify-return-match
                 "[\]}\)\"]"
                 "If this regexp matches the text after the cursor, do an \"electric\"
  return.")

               ;; we write again the function to add a line:
               (defun paredit-RET ()
                 "Default key binding for RET in Paredit Mode.
Normally, inserts a newline, like traditional Emacs RET.
With Electric Indent Mode enabled, inserts a newline and indents
  the new line, as well as any subexpressions of it on subsequent
  lines; see `paredit-newline' for details and examples."
                 (interactive)
                 (if (paredit-electric-indent-mode-p)
                     (progn
                       ;; (message "** paredit-electric-indent-mode-p = t")
                       (let ((electric-indent-mode nil))
                         (if (looking-at electrify-return-match)
                             (progn
                               ;; (message "** add one line")
                               (save-excursion (paredit-newline))))
                         (paredit-newline)))
                   (newline)))))) ; end of dolist

 ;; ===
 ;; === (EL) Evaluation : eval-defun (C-c C-c)and eval-buffer (C-c C-k)

 ;; C-c C-c to eval defun

 (add-hook 'emacs-lisp-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c C-c") 'eval-defun)))

 ;; C-c C-k to eval buffer

 (defun my-save-buffer-if-modified (&rest _args)
   "Propose to save the current buffer if it has been modified."
   (interactive)
   (when (and (buffer-file-name)
              (string-suffix-p ".el" (buffer-file-name))
              (buffer-modified-p))
     (if (y-or-n-p (format "Emacs Lisp buffer %s will be evaluated (eval-buffer), but has been modified; save it? " (buffer-name)))
         (save-buffer)
       (message "Buffer not saved"))))

 (advice-add 'eval-buffer :before #'my-save-buffer-if-modified)
 ;; to have similar behaviour with C-c C-k for Common Lisp
 
 (defun my-eval-buffer-advice2 (&rest _args)
   "Print a message when eval-buffer is called."
   (message "Buffer %s has been evaluated (eval-buffer)" 
            (buffer-name)))
 ;; (note: apparently, 'eval-buffer' is also called for the first
 ;; opening of an org-file in the session.)
 
 (advice-add 'eval-buffer :after #'my-eval-buffer-advice2)

 (define-key emacs-lisp-mode-map (kbd "C-c C-k") 'eval-buffer)

 ;; ===
 ;; === (EL) Byte-compilation (C-c C-b)

 (defun my/byte-compile-elisp ()
   "Delete .elc and .eln files if they exist and byte-compile current elisp buffer."
   (interactive)
   (let* ((el-file (buffer-file-name))
          (elc-file (concat el-file "c"))
          (eln-file (concat el-file "n")))
     
     ;; Delete .elc file if it exists
     (when (file-exists-p elc-file)
       (delete-file elc-file)
       (message "Deleted %s" elc-file))
     
     ;; Delete .eln file if it exists
     (when (file-exists-p eln-file)
       (delete-file eln-file)
       (message "Deleted %s" eln-file))

     ;; Clear *Compile-Log* buffer
     (let ((buf (get-buffer "*Compile-Log*")))
       (when buf
         (with-current-buffer buf
           (let ((inhibit-read-only t))
             (erase-buffer)))))
     
     ;; Compile
     (message "Byte-compiling %s..." el-file)
     (save-buffer)
     (byte-compile-file el-file)))

 ;; Bind it to C-c C-b only in emacs-lisp-mode
 (define-key emacs-lisp-mode-map (kbd "C-c C-b") 'my/byte-compile-elisp)
 ;; previous binding of C-c C-b: elisp-byte-compile-buffer

 ;; ===
 ;; === (EL) native compilation

 (defun my/native-compile-elisp ()
   "Delete .elc and .eln files if they exist and native-compile current elisp buffer."
   (interactive)

   (if (native-comp-available-p)
       (let* ((el-file (buffer-file-name))
              (elc-file (concat el-file "c"))
              (eln-file (concat el-file "n")))
         
         ;; Delete .elc file if it exists
         (when (file-exists-p elc-file)
           (delete-file elc-file)
           (message "Deleted %s" elc-file))
         
         ;; Delete .eln file if it exists
         (when (file-exists-p eln-file)
           (delete-file eln-file)
           (message "Deleted %s" eln-file))

         ;; Clear *Compile-Log* buffer
         (let ((buf (get-buffer "*Compile-Log*")))
           (when buf
             (with-current-buffer buf
               (let ((inhibit-read-only t))
                 (erase-buffer)))))
         
         ;; Compile
         (message "Native-compiling %s..." el-file)
         (save-buffer)
         (native-compile el-file)) ; end of 'then'
     
     (message "Native compilation not available.")))


 ;; Bind it to C-c C-n only in emacs-lisp-mode
 (define-key emacs-lisp-mode-map (kbd "C-c C-n") 'my/native-compile-elisp)
 
 ;; ===
 ;; === (EL) Documentation

 (when nil
   (use-package suggest
     ;; :mode ("\\.el\\'" . emacs-lisp-mode)
     :commands suggest
     :config (my-init--message-package-loaded "suggest")))

 ;; ===
 ;; === (EL) Propose function arguments: eldoc

 ;; EL : by default
 ;; CL : slime-autodoc

 ;; (add-hook 'slime-mode-hook 'eldoc-mode)
 ;; (add-hook 'slime-repl-mode-hook 'eldoc-mode)

 ;; suggestion of arglist does not work with (speed 3),
 ;; since this information is not kept
 
 ;; ===
 ;; === (EL) Goto defun

 (use-package elisp-slime-nav
   :defer t
   ;; :mode ("\\.el\\'" . emacs-lisp-mode)
   ;; :demand t ; to force
   :hook ((emacs-lisp-mode ielm-mode slime-repl-mode) . elisp-slime-nav-mode)
   :config 
   ;;(dolist (hook '(emacs-lisp-mode-hook ielm-mode-hook))
   ;;  (add-hook hook 'elisp-slime-nav-mode))
   (my-init--message-package-loaded "elisp-slime-nav"))
 ;; source: http://emacsredux.com/blog/2014/06/18/quickly-find-emacs-lisp-sources/
 ;; this enables M-. and M-, as in Slime for Common Lisp
 ;; --
 ;; This package provides Slime's convenient "M-." and "M-," navigation
 ;; in `emacs-lisp-mode', together with an elisp equivalent of
 ;; `slime-describe-symbol', bound by default to `C-c C-d d`.
 ;;
 ;;   When navigating into Emacs' C source, "M-," will not be bound to
 ;;   the same command, but "M-*" will typically do the trick.


 ;; ===
 ;; === (EL+CL) Find defun: imenu

 (add-hook 'emacs-lisp-mode-hook #'imenu-add-menubar-index)
 (add-hook 'lisp-mode-hook #'imenu-add-menubar-index)

 ;; ===
 ;; === (EL+CL) Find defun: imenu-list (sidebar)

 (use-package imenu-list
   :bind ((:map c-mode-map
                ("C-'" . imenu-list-smart-toggle))
          (:map c-ts-mode-map
                ("C-'" . imenu-list-smart-toggle))
          (:map lisp-mode-map
                ("C-'" . imenu-list-smart-toggle))
          (:map emacs-lisp-mode-map
                ("C-'" . imenu-list-smart-toggle)))
   :config
   (my-init--message-package-loaded "imenu-list"))

 ;; ===
 ;; === (EL+CL) Outline

 (add-hook 'emacs-lisp-mode-hook 
           (lambda ()
             (setq outline-regexp ";; === ")
             (outline-minor-mode)))
 (add-hook 'lisp-mode-hook 
           (lambda ()
             (setq outline-regexp ";; === ")
             (outline-minor-mode)))


 ;; ===
 ;; === (CL) abbrev

 (defun my-init--cl-abbrev ()

   (define-skeleton cl-muffle-skeleton 
     "CL muffle skeleton"
     nil
     "(declare (sb-ext:muffle-conditions sb-ext:compiler-note))\n")

   (define-skeleton cl-defun-skeleton 
     "CL defun skeleton"
     nil
     "(defun (" _ ")\n" > "\"\"\n" > "\n" > ")\n")) ; end of defun my-init--cl-abbrev

 (add-hook 'lisp-mode-hook
           (lambda ()
             (my-init--cl-abbrev)
             (define-abbrev lisp-mode-abbrev-table "clmuffle" "" 'cl-muffle-skeleton)
             (define-abbrev lisp-mode-abbrev-table "cldefun" "" 'cl-defun-skeleton)
             ))
 
 ;; ===
 ;; === (EL) Emacs C sources

 (if (my-init--directory-exists-p *emacs-c-source*)
     (setq find-function-C-source-directory (my-init--replace-linux-slash-with-two-windows-slashes *emacs-c-source*))
   (my-init--warning "!! Emacs C sources directory is not valid: %s" *emacs-c-source*))
 ;; sources downloaded from https://ftp.gnu.org/pub/gnu/emacs/
 ;; or rather: http://git.savannah.gnu.org/cgit/emacs.git

 ;; example of use: M-. on (defmacro

 ;; ===
 ;; === (EL) Macro expander

 ;; (1) macro expander 1 for Emacs Lisp

 (use-package macrostep
   :bind (:map emacs-lisp-mode-map ("C-c e" . macrostep-expand))
   :config (my-init--message-package-loaded "macrostep"))

 ;; (2) macro expander 2 for Emacs Lisp

 ;; source: https://github.com/marcoheisig/.emacs.d
 ;; The language Emacs Lisp is a fine blend of Maclisp, Common Lisp and some language for editing text. Unsurprisingly Emacs is well suited for editing Emacs Lisp. The only worthwhile addition provided here is a simple Macro stepper called `macroexpand-point’.

 (define-derived-mode emacs-lisp-macroexpand-mode emacs-lisp-mode
   "Macro Expansion"
   "Major mode for displaying Emacs Lisp macro expansions."
   (setf buffer-read-only t))

 (define-key emacs-lisp-mode-map
             (kbd "C-c m") 'macroexpand-point)

 (defun macroexpand-point (arg)
   "Apply `macroexpand' to the S-expression at point and show
the result in a temporary buffer. If already in such a buffer,
expand the expression in place.

With a prefix argument, perform `macroexpand-all' instead."
   (interactive "P")
   (let ((bufname "*emacs-lisp-macroexpansion*")
         (bounds (bounds-of-thing-at-point 'sexp))
         (expand (if arg #'macroexpand-all #'macroexpand)))
     (unless bounds
       (error "No S-expression at point."))
     (let* ((beg (car bounds))
            (end (cdr bounds))
            (expansion
             (funcall expand
                      (first
                       (read-from-string
                        (buffer-substring beg end))))))
       (if (eq major-mode 'emacs-lisp-macroexpand-mode)
           (let ((inhibit-read-only t)
                 (full-sexp
                  (car (read-from-string
                        (concat
                         (buffer-substring (point-min) beg)
                         (prin1-to-string expansion)
                         (buffer-substring end (point-max)))))))
             (delete-region (point-min) (point-max))
             (save-excursion
               (pp full-sexp (current-buffer)))
             (goto-char beg))
         (let ((temp-buffer-show-hook '(emacs-lisp-macroexpand-mode)))
           (with-output-to-temp-buffer bufname
             (pp expansion)))))))

 ;; ===
 ;; === (CL) Navigate between source and test files

 (defun my/switch-between-src-and-tests ()
   "When in code buffer, switch between src and test files.
If the target test file does not exist, create it and report via a message."
   (interactive)
   (let* ((buffer-file-name1 (buffer-file-name)) ; c:/.../abc.lisp
          (directory (file-name-directory buffer-file-name1))
          (file-name (file-name-nondirectory buffer-file-name1)) ; abc.lisp
          (file-name-base1 (file-name-base buffer-file-name1))   ; abc
          (len (length file-name-base1))
          (test-file-p
           (and (> len 6)
                (string= "-tests" (substring file-name-base1 (- len 6) (- len 0)))))
          (target
           (if test-file-p
               (concat directory "../src/" (substring file-name-base1 0 (- len 6)) ".lisp")
             (concat directory "../tests/" file-name-base1 "-tests.lisp"))))
     (if (file-exists-p target)
         (progn
           (message "Switching to %s file" (if test-file-p "source" "test"))
           (find-file target))
       ;; File doesn't exist
       (if test-file-p
           (message "No source file for %s" file-name)
         ;; It's a test file that doesn't exist; create it
         (make-directory (file-name-directory target) t) ; ensure directory exists
         (with-temp-buffer
           (write-file target))
         (message "Created new test file: %s" (file-name-nondirectory target))
         (find-file target)))))


 ;; (defun my/go-to-asd ()
 ;;   "Open unique .asd file in parent directory."
 ;;   (interactive)
 ;;   (let* ((directory (file-name-directory (buffer-file-name)))
 ;;          (asd-files (directory-files (concat directory "../") nil "\\.asd$")))
 ;;     (when (null asd-files) (error "No .asd file in parent directory"))
 ;;     (if (> (length asd-files) 1)
 ;;         (progn
 ;;           (message "More than one .asd file in parent directory, jumping to directory")
 ;;           (dired (concat directory "../")))
 ;;       (progn
 ;;         (message "Opening asd file")
 ;;         (find-file (concat directory "../" (car asd-files)))))))

 (defun my/go-to-asd ()
   "Find and open .asd file, searching current directory and upwards."
   (interactive)
   (let* ((start-directory (file-name-directory (buffer-file-name)))
          (directory (expand-file-name start-directory))
          (asd-files nil)
          (found-dir nil))
     ;; Search upward until we find .asd files or reach root
     (while (and (not asd-files) directory)
       (setq asd-files (sort (directory-files directory nil "\\.asd$") #'string<))
       (if asd-files
           (setq found-dir directory)
         ;; Move to parent directory
         (let ((parent (file-name-directory (directory-file-name directory))))
           ;; Stop if we've reached the root (parent equals current)
           (if (string= parent directory)
               (setq directory nil)
             (setq directory parent)))))
     
     (when (null asd-files) 
       (error "No .asd file found in current or parent directories"))
     
     (if (> (length asd-files) 1)
         (progn
           (let ((shortest-asd (car (sort (copy-sequence asd-files) 
                                          (lambda (a b) (< (length a) (length b)))))))
             (message "More than one .asd file in %s, jumping to directory" found-dir)
             (dired found-dir)
             (dired-goto-file (expand-file-name shortest-asd found-dir))))
       (progn
         (message "Opening asd file in %s" found-dir)
         (find-file (expand-file-name (car asd-files) found-dir))))))
 
 (defun my/go-to-package ()
   "Open unique package file in the parent directory."
   (interactive)
   (let* ((current-dir (file-name-directory (buffer-file-name)))
          (parent-dir  (file-name-directory
                        (directory-file-name current-dir)))
          (package-files (directory-files parent-dir nil "^package")))
     (when (null package-files)
       (error "No package file in parent directory"))
     (when (> (length package-files) 1)
       (error "More than one package file in parent directory"))
     (find-file (expand-file-name (car package-files) parent-dir))))

 ;; ===
 ;; === (CL) delete fasl files

 (defun my/delete-fasl-files ()
   "Delete all FASL files in the current dired directory.
(v1 as of 2025-10-31)"
   (interactive)
   (let ((files (directory-files default-directory t "\\.\\(fasl\\|fasl\\)$")))
     (if files
         (progn
           (dolist (file files)
             (delete-file file))
           (revert-buffer)
           (message "Deleted %d fasl file(s)" (length files)))
       (message "No fasl file identfied."))))

 ;; ===
 ;; === (CL) show *slime-compilation* buffer

 (defun my/jump-to-slime-compilation ()
   "Show *slime-compilation* buffer in the same window as the SLIME REPL if possible.
Otherwise, open in another window. Shows an error if compilation buffer does not exist. (2025-12-30)"
   (interactive)
   (let ((comp-buffer (get-buffer "*slime-compilation*"))
         (repl-buffer (get-buffer "*slime-repl sbcl*")))
     (if (not (buffer-live-p comp-buffer))
         (message "Buffer *slime-compilation* does not exist")
       (if (and (buffer-live-p repl-buffer)
                (get-buffer-window repl-buffer))
           ;; show compilation buffer in the same window as the REPL
           (let ((win (get-buffer-window repl-buffer)))
             (select-window win)
             (switch-to-buffer comp-buffer))
         ;; fallback: other window
         (switch-to-buffer-other-window comp-buffer)))))
 
 (with-eval-after-load 'slime
   (define-key slime-mode-map (kbd "C-c C-n")
               #'my/jump-to-slime-compilation))
 ;; ===
 ;; === (CL) filter compilation report

 ;; (defun my/slime-compilation-delete-float-coercion-notes ()
 ;;    "Remove sections containing 'float to pointer coercion' from *slime-compilation* buffer.
 ;; (v1 as of 2025-11-01)"
 ;;    (interactive)
 ;;    (with-current-buffer "*slime-compilation*"
 ;;      (let ((inhibit-read-only t)
 ;;            (filter-string "float to pointer coercion")
 ;;            (nb-deletions 0))
 ;;        (save-excursion
 ;;          (goto-char (point-min))
 ;;          (while (re-search-forward (regexp-quote filter-string) nil t)
 ;;            (setq nb-deletions (1+ nb-deletions))
 ;;            ;; Find the start of this warning/note section
 ;;            (let ((end (line-end-position)))
 ;;              (beginning-of-line)
 ;;              ;; Search backward for the section start (typically a blank line or buffer start)
 ;;              (while (and (not (bobp))
 ;;                          (not (looking-at "^$"))
 ;;                          (looking-at "^[; ]"))
 ;;                (forward-line -1))
 ;;              (when (looking-at "^$")
 ;;                (forward-line 1))
 ;;              (let ((start (point)))
 ;;                ;; Search forward for section end (blank line or end of buffer)
 ;;                (goto-char end)
 ;;                (while (and (not (eobp))
 ;;                            (not (looking-at "^$")))
 ;;                  (forward-line 1))
 ;;                (delete-region start (point))))))
 ;;        (beginning-of-buffer)
 ;;        (cond ((= 0 nb-deletions)
 ;;               (message "No deletion performed."))
 ;;              ((= 1 nb-deletions)
 ;;               (message "1 deletion performed."))
 ;;              (t
 ;;               (message "%s deletions performed" nb-deletions))))))

 (defun my/slime-compilation-delete-some-compilation-notes ()
   "Remove sections containing certain compiler warnings from *slime-compilation* buffer.
Removes:
  - \"float to pointer coercion\"
  - \"convert to multiplication by reciprocal\"
(v2 as of 2026-02-16)"
   (interactive)
   (with-current-buffer "*slime-compilation*"
     (let ((inhibit-read-only t)
           (filter-strings '("float to pointer coercion"
                             "convert to multiplication by reciprocal"))
           (nb-deletions 0))
       (save-excursion
         (goto-char (point-min))
         (let ((regexp (regexp-opt filter-strings)))
           (while (re-search-forward regexp nil t)
             (setq nb-deletions (1+ nb-deletions))
             ;; Find the start of this warning/note section
             (let ((end (line-end-position)))
               (beginning-of-line)
               ;; Search backward for the section start
               (while (and (not (bobp))
                           (not (looking-at "^$"))
                           (looking-at "^[; ]"))
                 (forward-line -1))
               (when (looking-at "^$")
                 (forward-line 1))
               (let ((start (point)))
                 ;; Search forward for section end
                 (goto-char end)
                 (while (and (not (eobp))
                             (not (looking-at "^$")))
                   (forward-line 1))
                 (delete-region start (point))))))))
     (goto-char (point-min))
     (cond ((= 0 nb-deletions)
            (message "No deletion performed."))
           ((= 1 nb-deletions)
            (message "1 deletion performed."))
           (t
            (message "%s deletions performed" nb-deletions)))))


 ;; ===
 ;; === (CL) ASDF

 ;; if we launch
 ;;   (swank:operate-on-system-for-emacs "cl-utils" 'load-op :force t)
 ;; from the REPL, it works, but *slime-compilation* does not update
 ;; For *slime-compilation* to update, we have to launch the command
 ;; from slime:

 (defun my/asdf-system-name-from-buffer ()
   "Return the ASDF system name associated with the current buffer (file or dired).
Ignores any .asd files whose names contain 'test' (case-insensitive).
Return NIL if no system found.
(v1, as of 2025-11-02)"
   (interactive)
   (let* ((start-dir
           (cond
            ((derived-mode-p 'dired-mode)
             (dired-current-directory))
            ((buffer-file-name)
             (file-name-directory (buffer-file-name)))
            (t nil)))
          (asdf-system-name nil))
     (when start-dir
       (when-let* ((dir
                    (locate-dominating-file
                     start-dir
                     (lambda (d)
                       (seq-some
                        (lambda (f)
                          (and (string-match-p "\\.asd\\'" f)
                               (let ((case-fold-search t))
                                 (not (string-match-p "test" f)))))
                        (directory-files d))))))
         (when-let ((asd
                     (car (seq-filter
                           (lambda (f)
                             (and (string-match-p "\\.asd\\'" f)
                                  (let ((case-fold-search t))
                                    (not (string-match-p "test" f)))))
                           (directory-files dir t)))))
           
           (setq asdf-system-name (file-name-base asd)))))
     asdf-system-name))

 ;; Alternative:
 (defun my/asdf-system-shortest-name ()
   "Return the ASDF system name with the shortest .asd filename."
   (interactive)
   (when buffer-file-name
     (let* ((asd-dir
             (locate-dominating-file
              buffer-file-name
              (lambda (dir)
                (directory-files dir nil "\\.asd\\'")))))
       (when asd-dir
         (car
          (sort
           (mapcar #'file-name-base
                   (directory-files asd-dir nil "\\.asd\\'"))
           (lambda (a b)
             (< (length a) (length b)))))))))

 (defun my/asdf-force-reload-system-corresponding-to-current-buffer ()
   "Force reload current ASDF system.
(v1, as of 2025-11-02)"
   (interactive)
   (let ((asdf-system-name (my/asdf-system-name-from-buffer)))
     (if (null asdf-system-name)
         (message "No ASDF system found.")
       (slime-eval-async `(asdf:load-system ,asdf-system-name :force t)
                         (lambda (_result)
                           (message "System %s has been force-reloaded" asdf-system-name))))))

 ;; Alternative:
 (defun my/slime-force-reload-current-system ()
   "Force reload the ASDF system associated with the current buffer."
   (interactive)
   (let ((system (my/asdf-system-shortest-name)))
     (unless system
       (error "No ASDF system associated with this buffer"))
     (slime-oos system 'load-op :force t)))

 (with-eval-after-load 'slime
   (define-key slime-mode-map (kbd "C-c C-l")
               #'my/slime-force-reload-current-system))

 (with-eval-after-load 'slime
   (define-key slime-mode-map (kbd "C-c C-r")
               (lambda ()
                 (interactive)
                 (slime-switch-to-output-buffer)
                 (slime-restart-inferior-lisp))))
 
 (defun my/asdf-force-test-system-corresponding-to-current-buffer ()
   "Force test current ASDF system.
(v1, as of 2025-11-02)
"
   (interactive)
   (let ((asdf-system-name (my/asdf-system-name-from-buffer)))
     (if (null asdf-system-name)
         (message "No ASDF system found.")
       (slime-eval-async `(asdf:test-system ,asdf-system-name :force t)
                         (lambda (_result)
                           (message "System %s has been force-tested" asdf-system-name))))))

 ;; Alternative:
 (defun my/slime-force-test-current-system ()
   "Force test the ASDF system associated with the current buffer."
   (interactive)
   (let ((system (my/asdf-system-shortest-name)))
     (unless system
       (error "No ASDF system associated with this buffer"))
     (slime-oos system 'test-op :force t)))

 (with-eval-after-load 'slime
   (define-key slime-mode-map (kbd "C-c C-t")
               #'my/slime-force-test-current-system))

 (defun my/slime-call-main ()
   "Clear REPL, insert (package::main ), and execute immediately."
   (interactive)
   (let* ((raw-pkg (slime-current-package))
          (pkg-name (if raw-pkg 
                        (replace-regexp-in-string "^:" "" raw-pkg) 
                      "cl-user"))
          (call-string (format "(%s::main)" pkg-name)))
     ;; Switch to REPL
     (slime-switch-to-output-buffer)
     (goto-char (point-max))
     
     ;; Clear any half-typed input
     (slime-repl-delete-current-input)
     
     ;; Insert the call (for visual feedback)
     (insert call-string)
     
     ;; Force display update
     (redisplay t)
     
     ;; Now evaluate it
     (slime-repl-send-input t)))

 (with-eval-after-load 'slime
   (define-key slime-mode-map (kbd "C-c C-m")
               #'my/slime-call-main))

 ;; ===
 ;; === my/dired-clean-build-artifacts

 (defun my/delete-to-recycle-bin (file)
   "Move FILE to trash. On Windows, uses the Recycle Bin via PowerShell.
On Linux, uses trash-put (from trash-cli package) or move-file-to-trash as fallback.
Returns t on success, nil on failure.
Note: (setq delete-by-moving-to-trash t) does not seem enough on Windows.
(v1, available in occisn/emacs-utils GitHub repository, 2025-12-27)"
   (condition-case err
       (if *my-init--windows-p*
           (let* ((file-path (convert-standard-filename file))
                  (ps-command (format
                               "Add-Type -AssemblyName Microsoft.VisualBasic; [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile('%s', 'OnlyErrorDialogs', 'SendToRecycleBin')"
                               file-path)))
             (call-process "powershell.exe" nil nil nil
                           "-NoProfile" "-NonInteractive" "-Command" ps-command)
             (not (file-exists-p file)))
         ;; Linux: use trash-put from trash-cli
         (call-process "trash-put" nil nil nil (expand-file-name file))
         (not (file-exists-p file)))
     (error nil)))


 (defun dired-clean--find-files-recursively (dir extensions exceptions)
   "Recursively find files with EXTENSIONS in DIR, excluding EXCEPTIONS.
Returns a flat list of matching files."
   (let ((result '()))
     (dolist (file (directory-files dir t))
       (let ((basename (file-name-nondirectory file)))
         (unless (member basename '("." ".."))
           (cond
            ;; If it's a directory, recurse into it
            ((file-directory-p file)
             (setq result (append (dired-clean--find-files-recursively file extensions exceptions) result)))
            
            ;; If it's a regular file matching our criteria
            ((and (file-regular-p file)
                  (member (file-name-extension file) extensions)
                  (not (member basename exceptions)))
             (push file result))))))
     result))

 (defun dired-clean--get-immediate-subdir (file root-dir)
   "Get the immediate subdirectory of ROOT-DIR that contains FILE.
Returns the immediate subdirectory path, or nil if FILE is directly in ROOT-DIR."
   (let* ((relative (file-relative-name file root-dir))
          (parts (split-string relative "/")))
     (when (> (length parts) 1)
       (expand-file-name (car parts) root-dir))))

 (defun my/dired-clean-build-artifacts ()
   "Delete .o, .fasl, and .exe files recursively in subdirectories.
Shows files first, then deletes with a progress bar.
Files are moved to Windows Recycle Bin."
   (interactive)
   (let* ((dir (dired-current-directory))
          (extensions '("o" "fasl" "exe"))
          (exception-list '("cloc-2.06.exe" "scc.exe"
                            ;; T. Masters
                            "CONVNET.exe" "DataMine.exe" "DEEP.exe" "BLOCKS.exe" "EXECUTE.CPP" "JULIA.exe" "LIN.exe" "VORTEX.exe" "MULT.exe" "PAIRED.exe" "ROC.exe" "SINGLE.exe" "VarScreen_4_4.exe"
                            ))
          (deleted-files '())
          (failed-files '())
          (buffer-name "*Deleted Build Artifacts*"))

     ;; Validate we're in a dired buffer
     (unless (derived-mode-p 'dired-mode)
       (error "This command must be run from a dired buffer"))

     ;; Find all matching files first
     (let* ((all-files
             (dired-clean--find-files-recursively dir extensions exception-list))
            (total (length all-files))
            (preview-groups '()))

       (dolist (file all-files)
         (let ((subdir (dired-clean--get-immediate-subdir file dir)))
           (when subdir
             (let ((existing (assoc subdir preview-groups)))
               (if existing
                   (setcdr existing (cons file (cdr existing)))
                 (push (cons subdir (list file)) preview-groups))))))
       
       (if (zerop total)
           (message "No build artifact files found to delete.")

         ;; ---- PREVIEW PHASE (GROUPED) ----
         (with-current-buffer (get-buffer-create "*Build Artifacts Preview*")
           (erase-buffer)
           (insert "Build Artifacts Deletion Preview\n")
           (insert (format "Directory: %s\n" dir))
           (insert (make-string 70 ?=) "\n\n")

           (dolist (subdir-entry
                    (sort preview-groups
                          (lambda (a b)
                            (string< (car a) (car b)))))
             (let* ((subdir (car subdir-entry))
                    (files (cdr subdir-entry))
                    (subdir-name
                     (file-name-nondirectory
                      (directory-file-name subdir))))
               (insert (format "\n%s/ (%d files):\n"
                               subdir-name (length files)))
               (dolist (file (sort files #'string<))
                 (insert (format "  • %s\n"
                                 (file-relative-name file dir))))))

           (goto-char (point-min))
           (display-buffer (current-buffer)))

         ;; Ask for confirmation
         (unless (y-or-n-p
                  (format "Delete %d build artifact files (move to Recycle Bin)? "
                          total))
           (user-error "Aborted"))

         ;; ---- DELETE PHASE WITH PROGRESS BAR ----
         (let ((count 0)
               (bar-width 30))
           (dolist (file all-files)
             (setq count (1+ count))

             ;; Progress bar
             (let* ((percent (/ (* 100.0 count) total))
                    (filled (/ (* bar-width count) total))
                    (bar (concat
                          "[" (make-string filled ?#)
                          (make-string (- bar-width filled) ?-)
                          "]")))
               (message "Deleting %s %3.0f%% (%d/%d)"
                        bar percent count total))

             ;; Delete
             (let ((immediate-subdir
                    (dired-clean--get-immediate-subdir file dir)))
               (if (my/delete-to-recycle-bin file)
                   (let ((existing (assoc immediate-subdir deleted-files)))
                     (if existing
                         (setcdr existing (cons file (cdr existing)))
                       (push (cons immediate-subdir (list file))
                             deleted-files)))
                 (push file failed-files))))

           (message "Deletion complete."))))

     ;; ---- REPORT PHASE (unchanged logic) ----
     (with-current-buffer (get-buffer-create buffer-name)
       (erase-buffer)
       (insert "Build Artifacts Cleanup Report\n")
       (insert (format "Directory: %s\n" dir))
       (insert (format "Time: %s\n" (current-time-string)))
       (insert (make-string 70 ?=) "\n\n")

       (if deleted-files
           (progn
             (insert (format
                      "Successfully moved to Recycle Bin (%d files):\n\n"
                      (apply #'+
                             (mapcar (lambda (x) (length (cdr x)))
                                     deleted-files))))
             (dolist (subdir-entry
                      (sort deleted-files
                            (lambda (a b)
                              (string< (car a) (car b)))))
               (let ((subdir (car subdir-entry))
                     (files (cdr subdir-entry)))
                 (insert (format "\n%s/ (%d files):\n"
                                 (file-name-nondirectory
                                  (directory-file-name subdir))
                                 (length files)))
                 (dolist (file (sort files #'string<))
                   (insert (format "  ✓ %s\n"
                                   (file-relative-name file dir)))))))
         (insert "No files were deleted.\n"))

       (when failed-files
         (insert (format "\nFailed to move (%d files):\n"
                         (length failed-files)))
         (dolist (file failed-files)
           (insert (format "  ✗ %s\n"
                           (file-relative-name file dir)))))

       (goto-char (point-min))
       (display-buffer (current-buffer)))

     (message "Build artifact cleanup finished.")))

 ;; ===
 ;; === abbrev

 (dolist (hook '(lisp-mode-hook
                 emacs-lisp-mode-hook))
   (add-hook hook #'abbrev-mode))

 ;; ===
 ;; === sidebar

 ;; speedbar
 ;; alternative to speedbar: treemacs, neotree, dired-sidebar

 ;; ===
 ;; === tests

 ;; Emacs Lisp : ERT

 ;; ===
 ;; === project management

 ;; including find, grep, search & replace --> see projectile

 ;; ===
 ;; === find usage of a function

 ;; ...
 
 ;; ===
 ;; === debugger

 ;; ...
 
 ;; ===
 ;; === profiler

 ;; ...

 ;; ===
 ;; === Hydra compilation

 (defhydra hydra-compilation (:exit t :hint nil)
   "
^Compilation hydra:
^------------------

Common Lisp :
   M-n, M-p to navigate
   RET to follow link
   _f_ilter some compilation notes

C and C++:
   C-c C-k to interrupt compilation or run

{end}
"

   ("f" #'my/slime-compilation-delete-some-compilation-notes))

 ;; ===
 ;; === Hydra Emacs Lisp

 (defhydra hydra-emacs-lisp (:exit t :hint nil)
   "
^Emacs Lisp hydra:
^-----------------
FILES: n/a
MOVEMENT:
   Navigate top-level sexp : C-UP and C-DOWN to move within top-level sexps
                             C-M-a/e to move to beginning/end of current or preceding defun (beginning-of-defun, end-of-defun)
   Navigate sexp: M-LEFT ou -RIGHT navigate
                  C-M-f/b          navigate among sexp siblings
                  C-M-up           go to beginning of (...) or higher one
                  C-M-f            go to closing parenthesis
                  C-M-down         go to inner (...)
JUMP TO TOP-LEVEL EXP: _m_: i_m_enu (M-g i) || M-x occur (M-s o) || _c_ : my occur || C-' (list in sidebar)
SELECT: C-= to expand region (expand-region) || C-M-h to put region around whole current or following defun (mark-defun)
MANIPULATE EXP: M-(              wrap an sexp (paredit)
                M-UP             splice (remove delimiter of current sexp) and kill previous
                M-r              raise and delete siblings
                M-s              splice (remove delimiter of current sexp)
                C-q ) or C-u DEL force add/delete parenthesis
                C-LEFT or C-}    barf out (force a closing parenthesis) ; (a b|c d e f) --> (a b) c d e f
                C-RIGHT or C-)   slurp in next sexp (paredit) ; (a b|c) d --> (a b c d)
                C-M-t            transpose sexps or make them circulate
COLLAPSE: [Outline: _o_utline-hide-body vs outline-show-_a_ll ; collapse/expand: _h_ide vs _s_how]
MACROS: Macro expander: C-c m ou C-c e || q
INDENT: C-M-q on current sexp || _i_: _i_ndent-buffer (M-x my/indent-lisp-buffer)
COMMENT: region M-; to comment/uncomment (paredit)
DOCUMENTATION: 'C-h i m elisp' or 'C-h r TAB ENT' elisp manual, then 'i' for index -- 'or M-x elisp-index-search'
               'M-x info-apropos' search in all info documents || M-x elisp-index-search
               C-h f {incl. under cursor}, C-h v, C-h S (symbol in doc), M-x suggest
REFERENCES: M-. and M-, to navigate to definition and come back (elisp-slime-nav)
            [who calls, etc.]
ABBREV: M-x unexpand-abbrev
COMPLETE: C-: counsel-company (mini-buffer)
          C-M-i company-complete (at point) ; C-d to see doc ; M-. to jump to source ; q to come back
REFACTOR: [...]
EXECUTE: 
   Eval: C-M-x to eval defun (M-x eval-defun) || C-x C-e to eval last sexp || C-c C-k = M-x eval-buffer
   REPL (IELM): C-c C-z (jump to REPL) | C-c C-y (send function to REPL) | C-c C-x (idem with time measurement) | C-c M-x to execute (M-x)
DEBUG: (1) unexpected : c(ontinue), e(val), q(uit) (2) edebug: C-u C-M-x --> SPACE, h, f, o i, ? (3) (debug) within code
{end}"
   ("a" #'outline-show-all)
   ("c" #'my-elisp-occur)
   ("h" #'hs-hide-all)
   ("i" #'my/indent-lisp-buffer)
   ("m" #'imenu)
   ("o" #'outline-hide-body)
   ("s" #'hs-show-all)
   ("t" #'hs-toggle-hiding))

 ;; ===
 ;; === Hydra Common Lisp

 (defhydra hydra-common-lisp (:exit t :hint nil)
   "
^Common Lisp hydra:
^------------------
FILES: _s_witch between src and tests | go to _a_sd | go to _p_ackage
MOVEMENT:
   Navigate top-level sexp : C-UP and C-DOWN to move within top-level sexps
                             C-M-a/e to move to beginning/end of current or preceding defun (beginning-of-defun, end-of-defun)
   Navigate sexp: M-LEFT ou -RIGHT navigate
                  C-M-f/b          navigate among sexp siblings
                  C-M-up           go to beginning of (...) or higher one
                  C-M-f            go to closing parenthesis
                  C-M-down         go to inner (...)
JUMP TO TOP-LEVEL EXP: _m_: i_m_enu (M-g i) || M-x occur (M-s o) ||  _c_ : my occur || C-' (list in sidebar) 
SELECT: C-= to expand region (expand-region) || C-M-h to put region around whole current or following defun (mark-defun)
MANIPULATE EXP: M-(              wrap an sexp (paredit)
                M-UP             splice (remove delimiter of current sexp) and kill previous
                M-r              raise and delete siblings
                M-s              splice (remove delimiter of current sexp)
                C-q ) ou C-u DEL force add/delete parenthesis
                C-LEFT or C-}    barf out (force closing parenthesis) ; (a b|c d e f) --> (a b) c d e f
                C-RIGHT or C-)   slurp in next sexp (paredit) ; (a b|c) d --> (a b c d)
                C-M-t            transpose sexps or make them circulate
COLLAPSE: _o_utline-hide-body vs outline-show-all ; collapse/expand: _h_ide vs hs-show-all | hs-toggle-hiding
MACROS: Macro expander: C-c RETURN || C-c C-m || C-c M-m to fully expand
INDENT: C-M-q on current sexp || _i_: _i_ndent-buffer (M-x my/indent-lisp-buffer)
COMMENT: region M-; to comment/uncomment (paredit)
DOCUMENTATION: docstring global var: C-c C-d d, (describe var) || fields (inspect var), q || hyperspec C-c C-d h || (apropos 'ts-get') || C-h m [l to go back]
               C-c I (add ') to inspect a symbol
REFERENCES: M-. and M-, to navigate to definition and come back
            who calls a fn : C-c < ; who is called C-c > ; who refers global var C-c C-w r 
ABBREV: M-x unexpand-abbrev
COMPLETE: C-:     counsel-company (mini-buffer)       || arglist is proposed if (debug 3) (speed 0)
          C-M-i   company-complete, replacing complete-symbol ; C-d to see doc ; M-. to jump to source ; q to come back
          C-c M-i  fuzzy   ||   C-c TAB completion at point
REFACTOR: [projectile]
EXECUTE: 
   Eval: C-c C-c compile defun || C-M-x eval defun || C-x C-e to eval last sexp || C-c C-y to send to REPL || C-c C-x idem with (time...)
   ONE FILE: C-c C-k
   REPL: C-c C-z to jump in REPL || C-c C-j to execute in REPL || M-n || M-p || *,** || /,// || (foo M-
   ASDF: ,load-system etc from REPL (but *slime-compilation* does not update) | C-c C-c to recompile function
   SLIME: C-c C-l force load [equivalent of relevant , in REPL] | C-c C-t force test [idem] | C-c C-n show compilation notes
          C-c C-r to restart inferior lisp [equivalent of relevant , in REPL] | C-c C-m to execute main
          M-x slime-compile-system (compiles an ASDF system)
          C-c C-c to recompile function | avoid C-c C-k | ,q to stop slime
   Test in REPL: C-c SPC || delete fasl (from dired): M-x my/delete-fasl-files
   Clear screen: C-c M-o              ||   q to hide compilation window
DEBUG: Debug: q || v to jump into code, RETURN, M-., i, e, r
       Disassemble : C-c M-d | Inspect : C-c I 'foo ; l to go back   | Trace: C-c C-t on the symbol | Navigate within warnings/errors: M-n, M-p
CLEAN: my/dired-clean-build-artifacts
SPECIFIC: Slime: _e_ : slime || M-x slime || ,quit
{end}"
   ("a" #'my/go-to-asd)
   ("c" #'my-cl-occur)
   ("e" #'slime)
   ;; ("f" (lambda () 
   ;;        (interactive)
   ;;        (let ((key (read-char "l (force-reload) or t (force-test): ")))
   ;;          (cond 
   ;;           ((eq key ?l) (my/asdf-force-reload-system-corresponding-to-current-buffer))
   ;;           ((eq key ?t) (my/asdf-force-test-system-corresponding-to-current-buffer)))))
   ;;  "submenu f")
   ("h" #'hs-hide-all)
   ("i" #'my/indent-lisp-buffer)
   ("m" #'imenu)
   ("o" #'outline-hide-body)
   ("p" #'my/go-to-package)
   ("s" #'my/switch-between-src-and-tests))            ; end of hydra

 ;; ===
 ;; === Hydra REPL

 (defhydra hydra-slime-repl (:exit t :hint nil)
   "
^Common Lisp Slime REPL hydra:
^-----------------------------

C-j to start a new line

M-p : previous command

to come back to last prompt: M-> (with shift), which jumps to the end of buffer

,restart-inferior-lisp
,q to stop slime

C-c I to inspect a symbol (add ')

(end)"
   ;; ("e" #'a-function)
   ) 

 ;; === Hydra SLDB

 (defhydra hydra-sldb (:exit t :hint nil)
   "
^Common Lisp SLDB hydra:
^-----------------------

Should be (debug 3) (speed 0)
v to view code
n, p to navigate frames
M-n, M-p to navigate frames while giving details and showing code 
t or RET to toggle details of the frame
e to evaluate in that frame (setq n 5), then:
r to restart frame
q to abort

(end)"
   ;; ("e" #'a-function)
   )
 
 ) ; end of init section


;;; ===
;;; ================
;;; ===== IELM =====
;;; ================

(my-init--with-duration-measured-section 
 t
 "IELM"

 ;; ~M-x ielm~

 ;; about IELM : https://www.reddit.com/r/lisp/comments/mz94vu/whats_the_value_in_using_a_repl_for_elisp/

 ;; ielm = i(nteractif) el(isp)m(ode)

 (when nil
   (defun ielm-auto-complete ()
     "Enables `auto-complete' support in \\[ielm]."
     (setq ac-sources '(ac-source-functions
                        ac-source-variables
                        ac-source-features
                        ac-source-symbols
                        ac-source-words-in-same-mode-buffers))
     (add-to-list 'ac-modes 'inferior-emacs-lisp-mode)
     (auto-complete-mode 1)
     (add-hook 'ielm-mode-hook 'ielm-auto-complete)))

 ;; https://www.masteringemacs.org/article/evaluating-elisp-emacs

 (defhydra hydra-ielm (:exit t :hint nil)
   "
^IELM hydra:
^-----------
RET to insert newline or evaluate
M-RET to evaluate without printing
TAB [ielm-tab] || C-M-i to complete
M-p to access previous command
*, **, *** to access previous results
C-c C-b to define current working buffer
"
   )) ; end of init section



;;; end of init--lang-lisp.el
