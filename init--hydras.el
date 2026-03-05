;;; -*- lexical-binding: t; byte-compile-warnings: (not docstrings docstrings-wide) -*-


;;; ===
;;; ============================
;;; === THREE GENERAL HYDRAS ===
;;; ============================

(my-init--with-duration-measured-section 
 t
 "Three general hydras"

 ;; (1) General hydra

 (defhydra hydra-general (:exit t :hint nil)
   "
^General hydra:
^---------------
Go: _d_: open _d_ownloads directory        | _e_: open _e_n-cours (on-going) directory
    _x_: open Dropbo_x_ directory in dired | _m_: ielm
    _s_: open pro1 App1                    | _l_: local-repos
Speedbar: M-x speedbar (b/f = buffers/files, U to go up, SPC)
Recent files : C-x C-r | recent directories : C-u C-x C-r | frequent files with function keys
Frame: C-x 5 c to clone current frame in another | C-x 5 2 or 'M-x make-frame' for new frame | C-x 5 0 to close frame
Window: C-x + to equalize windows | C-x - to swap 
Buffers: _f_: (_f_rom) open dired buffer corresponding to Windows path copied to clipboard
         C-x 3 | C-x o                      C-l to center buffer
         C-x C-j: dired-jump (dired-x) | C-x C-h: kill buffer and dired jump
         C-x m: kill buffer on other window    |||   C-x LEFT et C-x RIGHT to cycle among buffers
         C-h e displays *Messages* buffer      |||   C-x C-b then d and x to close some
         my/kill-all-file-buffers ; my/kill-all-buffers-except-stars
Find and grep --> dired hydra or _P_roject hydra
Mini-buffer : C-q C-j to go to a new line | ivy : ~C-M-j~ to force
Text: _k_: show kill ring (xah-show-kill-ring) | To search and insert Unicode: C-x 8 RET or M-x counsel-unicode-char
      M-LEFT et M-RIGHT to move by word (except in org-mode : C-LEFT et C-RIGHT) | C-DEL (M-d) et C-BACKSPACE (M-DEL) to delete words
      C-c C-SPACE ace jump         | M-< ou M-> [shift] to go to beginning/end of buffer
      search in file: C-s or M-x occur [ C-u C-s for native search ]
      M-x replace-regexp (example: ^abc.*$) 
      get rid of strange highlighting: Alt-'mouse left clic' | problem read-only : M-x read-only-mode
Repeat command: M-x M-p | C-x z | C-x M-:     History of commands: C-h l
Macros : F3 and F4 | M-x kmacro-name-last-macro gives a name to the last defined macro | M-x insert-kbd-macro inserts its definition at point
         repeat macro until error (M-0 C-x e) = my/repeat-macro-until-error | register store C-x C-k x r (kmacro-to-register) | call C-x r j r
Packages: M-x package-install                 | C-x M-: repeat last M-x
Tests: ERT _t_ests associated with init files (my/launch-tests)
Other hydras: _A_ppearance, _F_onts, _T_hemes, _H_elp & documentation, _M_ode-dependent (C-c d), _P_roject (C-c p h), _W_indows (C-c w),, _I_=professional _S_hells, Mails (C-c m)
Undo : C-j to cut undo chain? {end}
"
   ;; ("c" #'my/ready-to-calc) ;; to remove
   ("d" #'my/open-downloads-directory-in-dired) ; ?
   ("e" #'my/open-ongoing-directory-in-dired)
   ("f" #'my/dired-open-path-in-clipboard)
   ("k" #'xah-show-kill-ring)
   ("l" #'my/open-local-repos-directory-in-dired)
   ("m" #'ielm)
   ("p" #'package-list-packages) 
   ;; ("r" #'my/ready-to-move-from-downloads)
   ("s" #'pro1/open-app1)
   ("t" #'my/launch-tests)
   ("x" #'my/open-dropbox-directory-in-dired)
   ;; --
   ("A" #'hydra-appearance/body)
   ("F" #'my/generate-personal-font-buffer)
   ("H" #'hydra-help/body)
   ("I" #'hydra-professional/body)
   ("M" #'context-hydra-launcher)
   ("P" #'hydra-project/body)
   ("S" #'hydra-shells/body)
   ("T" #'my/generate-personal-theme-buffer)
   ("W" (if (fboundp 'hydra-windows-executables/body) #'hydra-windows-executables/body (lambda () (interactive) (message "Windows executables hydra not available on this platform")))))

 (global-set-key (kbd "C-c g") #'hydra-general/body)

 ;; (2) no-specific-hydra hydra

 (defhydra hydra-no-specific-hydra (:exit t :hint nil) ;  :columns 1)
   "
^No hydra associated with this mode
"
   )

 ;; (3) mode-dependent hydra launcher

 (defun context-hydra-launcher ()
   "Launch hydra according to context."
   (interactive)
   (cond
    ((eql major-mode 'c-mode) (hydra-c/body))
    ((eql major-mode 'c-ts-mode) (hydra-c/body))
    ((eql major-mode 'c++-mode) (hydra-cpp/body))
    ((eql major-mode 'c++-ts-mode) (hydra-cpp/body))
    ((eql major-mode 'calc-mode) (hydra-calc/body))
    ((eql major-mode 'compilation-mode) (hydra-compilation/body))
    ((eql major-mode 'csv-mode) (hydra-csv/body))
    ((eql major-mode 'dired-mode) (hydra-dired/body))
    ((eql major-mode 'doc-view-mode) (hydra-docview/body))
    ((eql major-mode 'emacs-lisp-mode) (hydra-emacs-lisp/body))
    ((eql major-mode 'gnuplot-mode) (hydra-gnuplot/body))
    ((eql major-mode 'ielm-mode) (hydra-ielm/body))
    ((eql major-mode 'latex-mode) (hydra-latex/body))
    ((eql major-mode 'lisp-mode) (hydra-common-lisp/body))
    ((eql major-mode 'magit-diff-mode) (hydra-magit-diff/body))
    ((eql major-mode 'magit-status-mode) (hydra-magit-status/body))
    ((eql major-mode 'markdown-mode) (hydra-markdown/body))
    ((eql major-mode 'nov-mode) (hydra-nov/body))
    ((eql major-mode 'org-mode) (hydra-org-mode/body))
    ((eql major-mode 'plain-tex-mode) (hydra-tex/body))
    ((eql major-mode 'python-mode) (hydra-python/body))
    ((eql major-mode 'sldb-mode) (hydra-sldb/body))
    ((eql major-mode 'slime-repl-mode) (hydra-slime-repl/body))
    ((eql major-mode 'ses-mode) (hydra-ses/body))
    ((eql major-mode 'sql-mode) (hydra-sql/body))
    ((eql major-mode 'tex-mode) (hydra-latex/body))
    (t (hydra-no-specific-hydra/body))))
 ;; Inspired by https://dfeich.github.io/www/org-mode/emacs/2018/05/10/context-hydra.html

 (global-set-key (kbd "C-c d") #'context-hydra-launcher)
 
 ) ; end of init section



;;; end of init--hydras.el
