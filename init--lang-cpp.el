;;; -*- lexical-binding: t; byte-compile-warnings: (not docstrings docstrings-wide) -*-

;;; =====================
;;; === C++, CPP, Cpp ===
;;; =====================

(my-init--with-duration-measured-section 
 t
 "C++ programming language"

 ;; === gcc in path
 
 (if *my-init--windows-p*
     ;; Windows: add g++ to PATH
     (if (my-init--directory-exists-p *gpp-path*)
         (my-init--add-to-path-and-exec-path "gpp" *gpp-path*)
       (my-init--warning "!! *gpp-path* is nil or does not exist: %s" *gpp-path*))
   ;; Linux: g++ expected in PATH
   (unless (executable-find "g++")
     (my-init--warning "!! g++ not found in PATH")))

 ;; === Display line number
 
 (dolist (mode '(c++-mode-hook c++-ts-mode-hook))
   (add-hook mode (lambda () (display-line-numbers-mode 1))))

 ;; === Disable auto-fill in C++ mode (to avoid break lines @ 70)

 (when nil
   (add-hook 'c++-mode-hook
             (lambda ()
               (auto-fill-mode -1)
               (setq fill-column 120))))
 ;; actually handled by eglot/clangd
 
 ;; === Babel

 ;; (C . t) is enough for C and C++
 
 ;; === switch/toggle among source, header and test files

 ;; see above (C)

 ;; === jump to main

 ;; function 'my/jump-to-c-main' defined above

 (add-hook 'c++-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c m") #'my/jump-to-c-main)))

 (add-hook 'c++-ts-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c m") #'my/jump-to-c-main)))

 ;; === add hpp header guard

 ;; function 'my/insert-cpp-header-guard' defined above

 (add-hook 'c++-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c h") #'my/insert-cpp-header-guard)))

 (add-hook 'c++-ts-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c h") #'my/insert-cpp-header-guard)))

 ;; === stand-alone & compile

 ;; function 'my/create-shell-window' defined above

 (defun my/cpp-save-compile-and-run-cpp-file ()
   "Compile and execute the current C++ file using g++."
   (interactive)
   (let* ((flags "-Wall -Wextra -std=c++17 -O3")
          (source-file (buffer-file-name))
          (file-name (file-name-nondirectory source-file))
          (exe-file (concat (file-name-sans-extension file-name) (if *my-init--windows-p* ".exe" "")))
          (run-cmd (if *my-init--windows-p* exe-file (concat "./" exe-file)))
          (compile-command (format "g++ %s -o %s %s && %s"
                                   flags
                                   exe-file
                                   file-name
                                   run-cmd)))
     (if source-file
         (progn
           (save-buffer)
           (compile compile-command))
       (message "Buffer is not visiting a file!"))))

 ;; (add-hook 'c++-mode-hook
 ;;           (lambda ()
 ;;             (local-set-key (kbd "C-c C-r") #'my/cpp-save-compile-and-run-cpp-file)))
 ;; (add-hook 'c++-ts-mode-hook
 ;;           (lambda ()
 ;;             (local-set-key (kbd "C-c C-r") #'my/cpp-save-compile-and-run-cpp-file)))

 ;; === stand-alone & shell

 (defun my/compile-and-execute-current-cpp-buffer-in-eshell ()
   "Save and compile current C++ file in eshell"
   (interactive)
   (save-buffer)
   (my--eshell-cd-to-directory-of-current-buffer-if-not-the-case)
   (let* (
          ;; (eshell-buffer (get-buffer "*eshell*"))
          (flags "-Wall -Wextra -std=c++17 -O3")
          (file-name (file-name-nondirectory buffer-file-name))
          (file-name-without-extension (file-name-sans-extension file-name))
          (exe-ext (if *my-init--windows-p* ".exe" ""))
          (cmd (concat "g++ " file-name " " flags " -o " file-name-without-extension exe-ext " && time ./" file-name-without-extension exe-ext)))
     (my--eshell-send-cmd cmd)))

 ;; === project & compile

 ;; function 'compile-makefile-project' defined above

 (add-hook 'c++-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c C-c") #'compile-makefile-project)))
 (add-hook 'c++-ts-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c C-c") #'compile-makefile-project)))

 ;; function 'my/compile-and-run-makefile-project' defined above

 ;; (add-hook 'c++-mode-hook
 ;;           (lambda ()
 ;;             (local-set-key (kbd "C-c C-m") #'my/compile-and-run-makefile-project)))
 ;; (add-hook 'c++-ts-mode-hook
 ;;           (lambda ()
 ;;             (local-set-key (kbd "C-c C-m") #'my/compile-and-run-makefile-project)))

 ;; function 'my/test-makefile-project' defined above
 
 ;; (add-hook 'c++-mode-hook
 ;;           (lambda ()
 ;;             (local-set-key (kbd "C-c C-t") #'my/test-makefile-project)))
 ;; (add-hook 'c++-ts-mode-hook
 ;;           (lambda ()
 ;;             (local-set-key (kbd "C-c C-t") #'my/test-makefile-project)))

 ;; === projectile and commands

 ;; function my/c-projectile-make defined above

 (add-hook 'c++-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c C-m") #'my/c-projectile-make)))
 (add-hook 'c++-ts-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c C-m") #'my/c-projectile-make)))

 ;; function my/c-projectile-make-run defined above

 (add-hook 'c++-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c C-r") #'my/c-projectile-make-run)))
 (add-hook 'c++-ts-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c C-r") #'my/c-projectile-make-run)))

 ;; function my/c-projectile-make-test defined above

 (add-hook 'c++-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c C-t") #'my/c-projectile-make-test)))
 (add-hook 'c++-ts-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c C-t") #'my/c-projectile-make-test)))

 ;; function my/c-projectile-make-clean defined above

 (add-hook 'c++-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c C-l") #'my/c-projectile-make-clean)))
 (add-hook 'c++-ts-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c C-l") #'my/c-projectile-make-clean)))

 ;; === my/dired-clean-build-artifacts

 ;; defined above
 
 ;; === Abbrev for C++

 ;; 'my-init--c-abbrev' is defined above

 (add-hook 'c++-mode-hook
           (lambda ()
             (my-init--c-abbrev)
             (define-abbrev c++-mode-abbrev-table "cmain" "" 'c-main-skeleton)
             (define-abbrev c++-mode-abbrev-table "cwhile" "" 'c-while-loop-skeleton)
             (define-abbrev c++-mode-abbrev-table "cfor" "" 'c-for-loop-skeleton)
             (define-abbrev c++-mode-abbrev-table "cinclude" "" 'c-include-skeleton)
             (define-abbrev c++-mode-abbrev-table "cif" "" 'c-if-skeleton)
             (define-abbrev c++-mode-abbrev-table "cifelse" "" 'c-if-else-skeleton)))
 
 (add-hook 'c++-ts-mode-hook
           (lambda ()
             (my-init--c-abbrev)
             (define-abbrev c++-ts-mode-abbrev-table "cmain" "" 'c-main-skeleton)
             (define-abbrev c++-ts-mode-abbrev-table "cwhile" "" 'c-while-loop-skeleton)
             (define-abbrev c++-ts-mode-abbrev-table "cfor" "" 'c-for-loop-skeleton)
             (define-abbrev c++-ts-mode-abbrev-table "cinclude" "" 'c-include-skeleton)
             (define-abbrev c++-ts-mode-abbrev-table "cif" "" 'c-if-skeleton)
             (define-abbrev c++-ts-mode-abbrev-table "cifelse" "" 'c-if-else-skeleton)))
 
 
 ;; === Occur

 ;; Function 'my-c-occur' is defined above.
 
 ;; === clangd

 (if *my-init--windows-p*
     ;; Windows: add portable clangd to PATH
     (if (my-init--directory-exists-p *clangd-path*)
         (my-init--add-to-path-and-exec-path "clangd" *clangd-path*)
       (my-init--warning "!! *clangd-path* is nil or does not exist: %s" *clangd-path*))
   ;; Linux: clangd expected in PATH
   (unless (executable-find "clangd")
     (my-init--warning "!! clangd not found in PATH")))

 ;; === treesitter installation

 ;; (treesit-library-abi-version) --> 14 ; expects version 14

 (unless (boundp 'treesit-language-source-alist)
   (setq treesit-language-source-alist '()))
 
 (add-to-list 'treesit-language-source-alist
              '(cpp "https://github.com/tree-sitter/tree-sitter-cpp"))

 ;; M-x treesit-install-language-grammar RET c RET
 ;; and c++
 ;; to compile and install
 
 (if (my-init--file-exists-p *cpp-tree-sitter-dll*)
     ;; Remap c++-mode to c++-ts-mode (Tree-sitter version):
     (add-to-list 'major-mode-remap-alist '(c++-mode . c++-ts-mode))
   (my-init--warning "!! cpp tree-sitter dll not found: %s" *cpp-tree-sitter-dll*))
 
 ;; === lsp (alternative to eglot)

 ;; void
 
 ;; === Eglot (alternative to lsp)

 (let ((gpp-found (or (my-init--file-exists-p *gpp-exe*)
                      (and *my-init--linux-p* *gpp-exe* (executable-find *gpp-exe*)))))
   (if gpp-found
       (with-eval-after-load 'eglot
         (add-to-list
          'eglot-server-programs
          `((c++-mode c-mode)
            "clangd"
            ,(concat "--query-driver=" *gpp-exe*))))
     (my-init--warning "!! g++ not found: %s" *gpp-exe*)))

 (add-hook 'c++-mode-hook 'eglot-ensure)
 (add-hook 'c++-ts-mode-hook 'eglot-ensure)

 ;; use-package eglot
 ;; see C above
 
 ;; use-package company
 ;; see C above
 
 ;; === Indentation
 
 (add-hook 'c++-mode-hook
           (lambda ()
             (c-set-style "stroustrup")
             (setq c-basic-offset 4)))

 ;; already stated elsewhere in this file:
 ;; (setq-default indent-tabs-mode nil)

 ;; normally default:
 ;; (global-font-lock-mode t)

 ;; function my/indent-eglot-buffer defined above

 ;; === hideshow

 (when t
   (add-hook 'c++-ts-mode-hook 'hs-minor-mode)
   (add-hook 'c++-mode-hook 'hs-minor-mode)
   
   (setq hs-hide-comments-when-hiding-all t)
   (setq hs-isearch-open t) ; Automatically open folded code during isearch

   ;; Key bindings
   (global-set-key (kbd "C-c f t") 'hs-toggle-hiding)
   (global-set-key (kbd "C-c f r") 'hs-hide-level-recursive)
   (global-set-key (kbd "C-c f s") 'hs-show-block)
   (global-set-key (kbd "C-c f h") 'hs-hide-block)
   (global-set-key (kbd "C-c f S") 'hs-show-all)
   (global-set-key (kbd "C-c f H") 'hs-hide-all))

 ;; === alternative: ts-fold (not available with use-package)

 ;; void
 
 ;; === expand-region

 ;; expand-region package already loaded in lisp section

 ;; === imenu list in side bar

 ;; imenu-list package already loaded in lisp section
 
 ;; === yasnippet... no since abbrev

 (when nil
   (use-package yasnippet
     :ensure t
     :config
     (yas-global-mode 1)))

 ;; === C++ hydra
 
 (defhydra hydra-cpp (:exit t :hint nil)
   "
^C++ hydra:
^----------
FILES: [h]: switch between source and header files | [t]: switch between source and test files
       C-c m jump to main | C-c h insert h/hpp header guard
MOVEMENT:
   move among top-level expressions + select: C-M-a, C-M-e C-M-h
   forward/backward expression: C-M-f, C-M-b
   next/previous sibling C-M-n, C-M-p
   up/down in tree C-M-u C-M-d
JUMP TO TOP-LEVEL EXP: [c] : occur | M-x imenu (M-g i) | C-' (list in sidebar)
SELECT: select sexp: C-= (expand-region)
MANIPULATE EXP: [...]
COLLAPSE: hideshow : C-c f h / s / t : hide / show / toggle current block
                     C-c f H / S     : hide / show all
MACROS: [...]
INDENT: [i]ndent (eglot-format-buffer)
COMMENT: M-; for end of line or selection | C-x C-; for line | M-x comment-region | M-x uncomment-region
DOCUMENTATION: bottom of screen (automatic) and more with [d] (M-x eldoc-doc-buffer) or C-h .
REFERENCES: M-. M-, : goto function/variable definition, and back (xref-find-definitions via eglot)
            M-? : find all references (xref-find-references via eglot)
ABBREV: [...]
COMPLETE: C-M-i   completion (eglot)
REFACTOR: [r]efactor symbol at point (eglot-rename) | [projectile]
EXECUTE:
   ONE FILE with compile: my/cpp-save-compile-and-run-cpp-file = save, compile and run (g++ ...)
   ONE FILE with shell: [s] : show eshell
                        [x] : compile & execute in shell (g++ ...)
   PROJECT with M-x compile: C-c C-c, compile project
                             my/compile-and-run-makefile-project = save compile and run (M-x compile > make && make run)
                             (M-x compile > make test) or my/test-makefile-project
   PROJECT with projectile: C-c C-l to clean (C-c p c c > make clean)
                            C-c C-m to make (C-c p c c > make clean)
                            C-c C-r to run (C-c p c c > make run) (or C-c p u ?)
                            C-c C-t to test (C-c p c c > make test)
DEBUG: C-c a to implement eglot proposed action / correction (eglot-code-actions) | C-h . to access to overlaid eglot/clangd warning
CLEAN: my/dired-clean-build-artifacts (before resynchronization of Dropbox)
SPECIFIC: M-x eglot-shutdown | M-x eglot-reconnect
"
   ("c" #'my-c-occur)
   ("d" #'eldoc-doc-buffer)
   ("h" #'my/toggle-c-h)
   ("i" #'my/indent-eglot-buffer)
   ("r" #'eglot-rename)
   ("s" #'my/create-shell-window)
   ("t" #'my/toggle-source-test)
   ("x" #'my/compile-and-execute-current-cpp-buffer-in-eshell)
   
   ) ; end of hydra
 ) ; end of init section


;;; end of init--lang-cpp.el
