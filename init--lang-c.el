;;; -*- lexical-binding: t; byte-compile-warnings: (not docstrings docstrings-wide) -*-

;;; ===
;;; ==============================================
;;; ===== C LANGUAGE, C PROGRAMMING LANGUAGE =====
;;; ==============================================

(my-init--with-duration-measured-section 
 t
 "C programming language"

 ;; === gcc in path
 
 (if *my-init--windows-p*
     ;; Windows: add gcc to PATH
     (if (my-init--directory-exists-p *gcc-path*)
         (my-init--add-to-path-and-exec-path "gcc" *gcc-path*)
       (my-init--warning "!! *gcc-path* is nil or does not exist: %s" *gcc-path*))
   ;; Linux: gcc expected in PATH
   (unless (executable-find "gcc")
     (my-init--warning "!! gcc not found in PATH")))

 ;; Note: I have noticed that it is better to avoid space in the path leading to gcc
 
 ;; === Display line number
 
 (dolist (mode '(c-mode-hook c-ts-mode-hook))
   (add-hook mode (lambda () (display-line-numbers-mode 1))))

 ;; === Disable auto-fill in C++ mode (to avoid break lines @ 70)

 (when nil
   (add-hook 'c++-mode-hook
             (lambda ()
               (auto-fill-mode -1)
               (setq fill-column 120))))
 ;; actually handled by eglot/clangd

 ;; === Babel

 (defun my--org-babel-load-C (&rest _args)
   (message "Preparing org-mode babel for C...")
   (add-to-list 'org-babel-load-languages '(C . t))
   (org-babel-do-load-languages 'org-babel-load-languages org-babel-load-languages)
   (advice-remove 'org-babel-execute-src-block #'my--org-babel-load-C))

 (advice-add 'org-babel-execute-src-block
             :before #'my--org-babel-load-C)

 ;; === let compilation window auto-scroll

 (setq compilation-scroll-output t)

 ;; === switch/toggle among source, header and test files

 (defun my/toggle-c-h ()
   "Toggle between C/C++ source and header files in the same directory.
Supports: .c <-> .h and .cpp <-> .hpp
Creates the file if it doesn't exist."
   (interactive)
   (let* ((filename (buffer-file-name))
          (extension (file-name-extension filename))
          (base (file-name-sans-extension filename))
          (new-file nil))
     (cond
      ((string= extension "c")
       (setq new-file (concat base ".h")))
      ((string= extension "h")
       (setq new-file (concat base ".c")))
      ((string= extension "cpp")
       (setq new-file (concat base ".hpp")))
      ((string= extension "hpp")
       (setq new-file (concat base ".cpp")))
      (t
       (message "Current file is not a .c/.h or .cpp/.hpp file")))
     (when new-file
       (if (file-exists-p new-file)
           (find-file new-file)
         (find-file new-file)
         (message "Created new file: %s" new-file)))))

 (defun my/toggle-source-test ()
   "Toggle between C/C++ source files in src/ and test files in tests/.
  Test files are named test_<filename> and located in tests/ directory.
  Creates the file if it doesn't exist, but errors if the directory doesn't exist."
   (interactive)
   (let* ((filename (buffer-file-name))
          (basename (file-name-nondirectory filename))
          (extension (file-name-extension filename))
          (dir (file-name-directory filename))
          (project-root (locate-dominating-file dir "src"))
          (new-file nil))
     (unless project-root
       (error "Cannot find project root (no src/ directory found)"))
     (cond
      ;; Current file is in src/ -> go to tests/
      ((string-match "/src/" filename)
       (setq new-file (concat project-root "tests/test_" basename)))
      ;; Current file is in tests/ and starts with test_ -> go to src/
      ((and (string-match "/tests/" filename)
            (string-prefix-p "test_" basename))
       (let ((source-name (substring basename 5))) ; Remove "test_" prefix
         (setq new-file (concat project-root "src/" source-name))))
      (t
       (message "Current file is not in src/ or tests/ directory")))
     (when new-file
       ;; Check if directory exists
       (let ((new-dir (file-name-directory new-file)))
         (unless (file-exists-p new-dir)
           (message "Directory does not exist: %s" new-dir)))
       ;; Open the file (creates it if doesn't exist)
       (find-file new-file)
       (unless (file-exists-p new-file)
         (message "Created new file: %s" new-file)))))

 ;;; === jump to main

 (defun my/jump-to-c-main ()
   "Jump to main.c or main.cpp based on current file extension.
  .c or .h files jump to main.c
  .cpp or .hpp files jump to main.cpp
  Errors if the file doesn't exist or extension is not recognized."
   (interactive)
   (let* ((current-file (buffer-file-name))
          (current-dir (file-name-directory current-file))
          (extension (file-name-extension current-file))
          (main-file nil))
     (cond
      ((member extension '("c" "h"))
       (setq main-file (concat current-dir "main.c")))
      ((member extension '("cpp" "hpp"))
       (setq main-file (concat current-dir "main.cpp")))
      (t
       (error "Unsupported file extension: .%s (expected .c, .h, .cpp, or .hpp)" extension)))
     (if (file-exists-p main-file)
         (find-file main-file)
       (error "File does not exist: %s" main-file))))

 (add-hook 'c-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c m") #'my/jump-to-c-main)))

 (add-hook 'c-ts-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c m") #'my/jump-to-c-main)))

 ;; === add h header guard

 (defun my/insert-cpp-header-guard ()
   "Insert C++ header guard based on current buffer's file name.
If filename begins with a digit, prefix with X_."
   (interactive)
   (let* ((filename (file-name-nondirectory (buffer-file-name)))
          (guard-base (upcase (replace-regexp-in-string "[.-]" "_" filename)))
          (guard-name (if (string-match "^[0-9]" guard-base)
                          (concat "X_" guard-base)
                        guard-base)))
     (save-excursion
       (goto-char (point-min))
       (insert (format "#ifndef %s\n" guard-name))
       (insert (format "#define %s\n\n" guard-name))
       (goto-char (point-max))
       (insert (format "\n\n#endif // %s\n" guard-name)))
     (goto-char (point-min))
     (forward-line 2)))

 (add-hook 'c-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c h") #'my/insert-cpp-header-guard)))

 (add-hook 'c-ts-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c h") #'my/insert-cpp-header-guard)))

 ;; === stand-alone & compile

 (defun my/c-save-compile-and-run-c-file ()
   "Compile and execute the current C file using gcc."
   (interactive)
   (let* ((flags "-Wall -Wextra -Werror -O3 -std=c2x -pedantic")
          (source-file (buffer-file-name))
          (file-name (file-name-nondirectory source-file))
          (exe-file (concat (file-name-sans-extension file-name) (if *my-init--windows-p* ".exe" "")))
          (run-cmd (if *my-init--windows-p* exe-file (concat "./" exe-file)))
          (compile-command (format "gcc %s -o %s %s && %s"
                                   flags
                                   exe-file
                                   file-name
                                   run-cmd)))
     (if source-file
         (progn
           (save-buffer)
           (compile compile-command))
       (message "Buffer is not visiting a file!"))))

 ;; (add-hook 'c-mode-hook
 ;;           (lambda ()
 ;;             (local-set-key (kbd "C-c C-r") #'my/c-save-compile-and-run-c-file)))
 ;; (add-hook 'c-ts-mode-hook
 ;;           (lambda ()
 ;;             (local-set-key (kbd "C-c C-r") #'my/c-save-compile-and-run-c-file)))

 ;; === stand-alone & shell

 (defun my/create-shell-window ()
   "Delete other windows, split right, open eshell on right, return to left."
   (interactive)
   (delete-other-windows)
   (split-window-right)
   (other-window 1)
   (eshell)
   (other-window -1))

 (defun my/compile-and-execute-current-c-buffer-in-eshell ()
   "Save and compile current C file in eshell"
   (interactive)
   (save-buffer)
   (my--eshell-cd-to-directory-of-current-buffer-if-not-the-case)
   (let* (
          ;; (eshell-buffer (get-buffer "*eshell*"))
          (flags "-Wall -Wextra -Werror -O3 -std=c2x -pedantic")
          (file-name (file-name-nondirectory buffer-file-name))
          (file-name-without-extension (file-name-sans-extension file-name))
          (exe-ext (if *my-init--windows-p* ".exe" ""))
          (cmd (concat "gcc " file-name " " flags " -o " file-name-without-extension exe-ext " && time ./" file-name-without-extension exe-ext)))
     (my--eshell-send-cmd cmd)))

 ;; === project & compile

 (defun compile-makefile-project ()
   "Compile using make the executable specified in the Makefile."
   (interactive)
   (let* ((makefile-dir (locate-dominating-file default-directory "Makefile"))
          (default-directory (or makefile-dir default-directory))
          (compile-command "make"))
     (if makefile-dir
         (progn
           (save-some-buffers t)
           (compile compile-command))
       (message "No Makefile found in current or parent directories!"))))

 (add-hook 'c-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c C-c") #'compile-makefile-project)))
 (add-hook 'c-ts-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c C-c") #'compile-makefile-project)))

 (defun my/compile-and-run-makefile-project ()
   "Compile using make and run the executable specified in the Makefile."
   (interactive)
   (let* ((makefile-dir (locate-dominating-file default-directory "Makefile"))
          (default-directory (or makefile-dir default-directory))
          (compile-command "make && make run"))
     (if makefile-dir
         (progn
           (save-some-buffers t)
           (compile compile-command))
       (message "No Makefile found in current or parent directories!"))))

 ;; (add-hook 'c-mode-hook
 ;;           (lambda ()
 ;;             (local-set-key (kbd "C-c C-m") #'my/compile-and-run-makefile-project)))
 ;; (add-hook 'c-ts-mode-hook
 ;;           (lambda ()
 ;;             (local-set-key (kbd "C-c C-m") #'my/compile-and-run-makefile-project)))

 (defun my/test-makefile-project ()
   "Test using the Makefile."
   (interactive)
   (let* ((makefile-dir (locate-dominating-file default-directory "Makefile"))
          (default-directory (or makefile-dir default-directory))
          (compile-command "make test"))
     (if makefile-dir
         (progn
           (save-some-buffers t)
           (compile compile-command))
       (message "No Makefile found in current or parent directories!"))))

 ;; (add-hook 'c-mode-hook
 ;;           (lambda ()
 ;;             (local-set-key (kbd "C-c C-t") #'my/test-makefile-project)))
 ;; (add-hook 'c-ts-mode-hook
 ;;           (lambda ()
 ;;             (local-set-key (kbd "C-c C-t") #'my/test-makefile-project)))

 ;; === projectile and command

 (defun my/c-projectile-make ()
   "Run 'make' in the project root."
   (interactive)
   (projectile-with-default-dir (projectile-project-root)
     (projectile-run-compilation "make")))
 (add-hook 'c-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c C-m") #'my/c-projectile-make)))
 (add-hook 'c-ts-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c C-m") #'my/c-projectile-make)))

 (defun my/c-projectile-make-run ()
   "Run 'make run' in the project root."
   (interactive)
   (projectile-with-default-dir (projectile-project-root)
     (projectile-run-compilation "make run")))
 (add-hook 'c-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c C-r") #'my/c-projectile-make-run)))
 (add-hook 'c-ts-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c C-r") #'my/c-projectile-make-run)))

 (defun my/c-projectile-make-test ()
   "Run 'make test' in the project root."
   (interactive)
   (projectile-with-default-dir (projectile-project-root)
     (projectile-run-compilation "make test")))
 (add-hook 'c-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c C-t") #'my/c-projectile-make-test)))
 (add-hook 'c-ts-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c C-t") #'my/c-projectile-make-test)))

 (defun my/c-projectile-make-clean ()
   "Run 'make clean' in the project root."
   (interactive)
   (projectile-with-default-dir (projectile-project-root)
     (projectile-run-compilation "make clean")))
 (add-hook 'c-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c C-l") #'my/c-projectile-make-clean)))
 (add-hook 'c-ts-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c C-l") #'my/c-projectile-make-clean)))

 ;; === my/dired-clean-build-artifacts

 ;; defined above
 
 ;; === Abbrev for C

 (defun my-init--c-abbrev ()

   (abbrev-mode 1)

   (define-skeleton c-main-skeleton 
     "C main skeleton"
     nil
     "int main(void)\n{\n" > _ "\n" > "return EXIT_SUCCESS;\n" > "}\n")

   
   (define-skeleton c-while-loop-skeleton
     "Insert a while loop structure"
     nil
     > "while (" _ ") {" \n
     > \n
     "}" >)

   
   (define-skeleton c-for-loop-skeleton
     "Insert a for loop structure"
     nil
     > "for (" _ "; ; ) {" \n
     > \n
     "}" >)

   (define-skeleton c-include-skeleton
     "Insert includes"
     nil
     "#include <stdlib.h>\n#include <stdio.h>\n#include <string.h>\n\n")
   
   (define-skeleton c-if-skeleton
     "Insert an if structure"
     nil
     > "if (" _ ") {" \n > \n "}" >)

   (define-skeleton c-if-else-skeleton
     "Insert an if structure"
     nil
     > "if (" _ ") {" \n > \n > "} else {" \n \n "}" >)

   (define-skeleton c-err-skeleton
     "Insert an error message"
     nil
     > "fprintf(stderr, \"" _ "\\n\");" >)

   (define-skeleton c-flush-skeleton
     "Insert a flush instruction"
     nil
     > "fflush(stdout);\n" >))

 

 (add-hook 'c-mode-hook
           (lambda ()
             (my-init--c-abbrev)
             (define-abbrev c-mode-abbrev-table "cmain" "" 'c-main-skeleton)
             (define-abbrev c-mode-abbrev-table "cwhile" "" 'c-while-loop-skeleton)
             (define-abbrev c-mode-abbrev-table "cfor" "" 'c-for-loop-skeleton)
             (define-abbrev c-mode-abbrev-table "cinclude" "" 'c-include-skeleton)
             (define-abbrev c-mode-abbrev-table "cif" "" 'c-if-skeleton)
             (define-abbrev c-mode-abbrev-table "cifelse" "" 'c-if-else-skeleton)
             (define-abbrev c-mode-abbrev-table "cerr" "" 'c-err-skeleton)
             (define-abbrev c-mode-abbrev-table "cflush" "" 'c-flush-skeleton)
             ))
 
 (add-hook 'c-ts-mode-hook
           (lambda ()
             (my-init--c-abbrev)
             (define-abbrev c-ts-mode-abbrev-table "cmain" "" 'c-main-skeleton)
             (define-abbrev c-ts-mode-abbrev-table "cwhile" "" 'c-while-loop-skeleton)
             (define-abbrev c-ts-mode-abbrev-table "cfor" "" 'c-for-loop-skeleton)
             (define-abbrev c-ts-mode-abbrev-table "cinclude" "" 'c-include-skeleton)
             (define-abbrev c-ts-mode-abbrev-table "cif" "" 'c-if-skeleton)
             (define-abbrev c-ts-mode-abbrev-table "cifelse" "" 'c-if-else-skeleton)
             (define-abbrev c-ts-mode-abbrev-table "cerr" "" 'c-err-skeleton)
             (define-abbrev c-ts-mode-abbrev-table "cflush" "" 'c-flush-skeleton)
             ))
 
 ;; === Occur

 (defun my-c-occur ()
   (interactive)
   (occur "^[A-Za-z]\\|// ===")
   (other-window 1))

 ;; === clangd

 ;; clangd will use both files for projects
 ;;     (i) .clangd
 ;;    (ii) compile_commands.json
 ;; The second file is generated from Makefile by this cmd line
 ;;    C:\portable-programs\Python\Python314\Scripts\compiledb --overwrite make

 ;; It requires compiledb to be available.
 ;; Python shall be available on the system
 ;; To install compiledb:
 ;;   (1) download from https://github.com/nickdiego/compiledb
 ;;   (2) [cmd] cd C:\portable-programs\Python\Python314\Scripts
 ;;   (3) [cmd] pip install compiledb
 ;;   (4) test: [cmd] compiledb -h

 (if *my-init--windows-p*
     ;; Windows: add portable clangd to PATH
     (if (my-init--directory-exists-p *clangd-path*)
         (my-init--add-to-path-and-exec-path "clangd" *clangd-path*)
       (my-init--warning "!! *clangd-path* is nil or does not exist: %s" *clangd-path*))
   ;; Linux: clangd expected in PATH
   (unless (executable-find "clangd")
     (my-init--warning "!! clangd not found in PATH")))

 ;; Treat all .h files as C by default
 (add-to-list 'auto-mode-alist '("\\.h\\'" . c-mode))

 ;; === treesitter installation

 ;; (treesit-library-abi-version) --> 14 ; expects version 14

 (unless (boundp 'treesit-language-source-alist)
   (setq treesit-language-source-alist '()))
 
 (add-to-list 'treesit-language-source-alist
              '(c "https://github.com/tree-sitter/tree-sitter-c" "v0.20.6"))
 ;; "v0.20.6" corresponds to v14 ; if ommitted, v15 is installed

 ;; M-x treesit-install-language-grammar RET c RET
 ;; and c++
 ;; to compile and install
 
 (if (my-init--file-exists-p *c-tree-sitter-dll*)
     ;; Remap c-mode to c-ts-mode (Tree-sitter version):
     (add-to-list 'major-mode-remap-alist '(c-mode . c-ts-mode))
   (my-init--warning "!! c tree-sitter dll not found: %s" *c-tree-sitter-dll*))

 ;; === lsp (alternative to eglot)

 (when nil
   (use-package lsp-mode
     ;; :ensure t is usually implied if you use package management, but explicit is fine
     :commands (lsp lsp-deferred)
     :init
     ;; Set the key prefix for all lsp commands (e.g., C-c l f for format)
     (setq lsp-keymap-prefix "C-c l")

     :config
     ;; Optional: Better error highlighting with flycheck (instead of default flymake)
     ;; Requires installing the flycheck package separately.
     (setq lsp-diagnostics-provider :flycheck)
     ;; Optional: Enable Which-Key integration for better command discovery
     (lsp-enable-which-key-integration t)
     (my-init--message-package-loaded "lsp-mode")

     :hook
     ;; Start lsp-mode (specifically `lsp-deferred`) for C and C++ major modes.
     ;; `lsp-deferred` waits a moment before starting, preventing Emacs from hanging.
     ((c-mode c-ts-mode) . lsp-deferred)))

 (when nil
   (use-package lsp-ui
     :ensure t
     :hook
     ;; Enable lsp-ui-mode whenever lsp-mode is active
     (lsp-mode . lsp-ui-mode)

     :config
     (my-init--message-package-loaded "lsp-ui")

     :custom
     ;; Display documentation pop-ups at the bottom of the window
     (lsp-ui-doc-position 'bottom)
     ;; Make the pop-up documentation a bit faster
     (lsp-ui-doc-delay 0.8)
     ;; Show lsp-ui-sideline only when the cursor is on the diagnostic
     (lsp-ui-sideline-show-hover nil)))

 ;; Note: lsp-mode automatically registers itself as a company backend,
 ;; so you don't need a separate `company-lsp` package.
 
 ;; === Eglot (alternative to lsp)

 (when t
   
   (add-hook 'c-mode-hook 'eglot-ensure)
   (add-hook 'c-ts-mode-hook 'eglot-ensure)
   
   (use-package eglot
     :defer t           ; Load Eglot only when one of the hooks is run
     :hook
     ;; This is the main line: start Eglot for C/C++ modes
     ((c-mode c-ts-mode c++-mode c++-ts-mode) . eglot-ensure)

     :config
     ;; Optional: Add clangd to the server list explicitly if Emacs doesn't find it.
     ;; If clangd is in your PATH, this may not be strictly necessary.
     (add-to-list 'eglot-server-programs
                  '((c-mode c-ts-mode) . ("clangd"
                                          ;; the following to avoid "too many errors emitted, stopping now"
                                          "--limit-diagnostics=0"
                                          ;; the 3 following lines for cppcheck:
                                          "--background-index"
                                          "--clang-tidy"
                                          "--completion-style=detailed"
                                          )))

     ;; Optional: Enable snippet completion (requires yasnippet to be active)
     (when nil
       (when (featurep 'yasnippet)
         (setq eglot-snippet-insertion 'yasnippet)))
     (my-init--message-package-loaded "eglot")

     (define-key eglot-mode-map (kbd "C-c a") #'eglot-code-actions))

   ;; normally already loaded:
   (use-package company
     :ensure t
     :hook (eglot-managed-mode . company-mode)
     :config (my-init--message-package-loaded "company")))

 ;; === cppcheck

 ;; to be added in .clang:
 ;; Diagnostics:
 ;;  ClangTidy:
 ;;    Add: cppcheck

 (use-package flycheck
   :ensure t
   :config
   ;; Configure cppcheck for C
   (add-hook 'c-mode-hook
             (lambda ()
               (setq flycheck-checker 'c/c++-cppcheck)
               (flycheck-mode)))
   (add-hook 'c-ts-mode-hook
             (lambda ()
               (setq flycheck-checker 'c/c++-cppcheck)
               (flycheck-mode))))

 ;; === Indentation
 
 (add-hook 'c-mode-hook
           (lambda ()
             (setq c-default-style "gnu" ; "linux, "gnu", "k&r", "bsd", "stroustrup"
                   c-basic-offset 4)     ; tab width
             ))       
 
 ;; already stated elsewhere in this file:
 ;; (setq-default indent-tabs-mode nil)

 ;; normally default:
 ;; (global-font-lock-mode t)

 (defun my/indent-eglot-buffer ()
   "Indent eglot buffer (C/C++)."
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
       (let ((window-start (window-start))
             (point (point)))
         (eglot-format-buffer)       ; <-- the actual function
         (goto-char point)
         (set-window-start nil window-start t))
       ;; all the above to avoid a jump in viewport, but does not work
       
       (recenter-top-bottom))))

 ;; === hideshow

 (when t
   (add-hook 'c-ts-mode-hook 'hs-minor-mode)
   (add-hook 'c-mode-hook 'hs-minor-mode)
   
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

 ;; === C hydra
 
 (defhydra hydra-c (:exit t :hint nil)
   "
^C hydra:
^--------
FILES: [h]: switch between source and header files | [t]: switch between source and test files
       C-c m jump to main | C-c h insert h/hpp header guard
MOVEMENT :
   move among top-level expressions + select: C-M-a, C-M-e C-M-h
   forward/backward expression: C-M-f, C-M-b
   next/previous sibling C-M-n, C-M-p
   up/down in tree C-M-u C-M-d
JUMP TO TOP-LEVEL EXP: [c] : occur | M-x imenu (M-g i) | C-' (list in sidebar)
MANIPULATE EXP: [...]
SELECT: select sexp: C-= (expand-region)
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
   ONE FILE with compile: my/c-save-compile-and-run-c-file = save, compile and run (gcc ...)
   ONE FILE with shell: [s] : show eshell
                        [x] : compile & execute in shell (gcc ...)
   PROJECT with compile: C-c C-c, compile project
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
   ("x" #'my/compile-and-execute-current-c-buffer-in-eshell)
   ) ; end of hydra
 ) ; end of init section



;;; end of init--lang-c.el
