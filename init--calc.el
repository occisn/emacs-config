;;; -*- lexical-binding: t; byte-compile-warnings: (not docstrings docstrings-wide) -*-

;;; ===
;;; ============
;;; === CALC ===
;;; ============

(my-init--with-duration-measured-section 
 t
 "Calc"

 ;; launch: M-x calc or C-x * c
 ;; exit: q

 ;; Some references:
 ;; https://www.emacswiki.org/emacs/Calc_Tutorials_by_Andrew_Hyatt
 ;; https://www.johndcook.com/blog/2010/10/11/emacs-calc/
 ;; http://nullprogram.com/blog/2009/06/23/
 ;; https://news.ycombinator.com/item?id=15939165
 ;; https://www.gnu.org/software/emacs/manual/html_node/calc/index.html#Top

 (defvar org-babel-load-languages)      ; to avoid compilation warning

 (defun my--org-babel-load-calc (&rest _args)
   (message "Preparing org-mode babel for calc...")
   (add-to-list 'org-babel-load-languages '(calc . t))
   (org-babel-do-load-languages 'org-babel-load-languages org-babel-load-languages)
   (advice-remove 'org-babel-execute-src-block #'my--org-babel-load-calc))

 (advice-add 'org-babel-execute-src-block
             :before #'my--org-babel-load-calc)
 ;; https://www.reddit.com/r/emacs/comments/i6zuau/calc_source_blocks_in_orgmode_best_practices/
 ;; https://github.com/dfeich/org-babel-examples/blob/master/calc/calc.org
 
 (defun my/calc-read-macro ()
   "Interpret selected region as a Calc macro and jump to Calc stack, where the macro can be executed by pressing X.
(v2 as of 2024-01-27, v1 as of 2024-01-23)"
   (interactive)
   (if (use-region-p)
       (let* ((region-as-string (buffer-substring-no-properties (region-beginning) (region-end))))
         (read-kbd-macro (region-beginning) (region-end))
         (message "Ready to execute (X): %s ... %s"
                  (substring region-as-string 0 10)
                  (substring region-as-string -10 nil))
         (let ((w (get-buffer-window "*Calculator*")))
           (if (null w)
               (message "No window is displaying Calc!")
             (select-window w))))
     (message "No region selected!")))

 (declare-function calc-call-last-kbd-macro "calc") ; to avoid compilation warning
 (with-eval-after-load 'calc
   (defun my/calc-read-and-execute-macro ()
     "Interpret selected region as a Calc macro, jump to Calc stack, and execute it while printing execution duration as a message.
(v1 as of 2025-01-12)"
     (interactive)
     (if (use-region-p)
         (let* ((region-as-string (buffer-substring-no-properties (region-beginning) (region-end))))
           (read-kbd-macro (region-beginning) (region-end))
           (message "Ready to execute (X): %s ... %s"
                    (substring region-as-string 0 10)
                    (substring region-as-string -10 nil))
           (let ((w (get-buffer-window "*Calculator*")))
             (if (null w)
                 (message "No window is displaying Calc!")
               (progn
                 (select-window w)
                 (let ((beginning-time2 (float-time)))
                   (calc-call-last-kbd-macro nil) ; equivalent of X
                   (let* ((end-time2 (float-time))
                          (duration2 (* 1000 (float-time
                                              (time-subtract end-time2 beginning-time2)))))
                     (message "Calc macro executed in %.0f ms." duration2)))))))
       (message "No region selected!")))

   (defun my/calc-select-markdown-code-read-and-execute-calc-macro ()
     "Select markdown code block surrounding the cursor, interpret it as a Calc macro, jump to Calc stack and execute it while printing execution duration as a message.
(v1 as of 2025-01-12)"
     (interactive)
     (search-backward "```")
     (forward-line)
     (beginning-of-line)
     (call-interactively 'set-mark-command)
     (search-forward "```")
     (beginning-of-line)
     (my/calc-read-and-execute-macro)))

 (defun my/calc-select-markdown-code-and-read-calc-macro ()
   "Select markdown code block surrounding the cursor, interpret it as a Calc macro and jump to Calc stack, where the macro can be executed by pressing X.
(v2 as of 2024-01-27, v1 as of 2024-01-23)"
   (interactive)
   (search-backward "```")
   (forward-line)
   (beginning-of-line)
   (call-interactively 'set-mark-command)
   (search-forward "```")
   (beginning-of-line)
   (my/calc-read-macro))

 (defun my/calc-compact-to-clipboard (beg end)
   "Compact the current region between BEG and END.
For each line in the region:
1. Delete occurrences of ';;' and everything following them.
2. Remove line breaks so the whole region becomes a single line.
3. Replace TAB characters with single spaces.
4. Replace any sequence of multiple spaces with a single space.
The result is copied to the clipboard without modifying the buffer."
   (interactive "r")
   (let ((text (buffer-substring-no-properties beg end)))
     ;; 1. Remove ;; comments
     (setq text (replace-regexp-in-string ";;.*$" "" text))
     ;; 2. Remove line breaks
     (setq text (replace-regexp-in-string "[\r\n]+" " " text))
     ;; 3. Replace tabs with spaces
     (setq text (replace-regexp-in-string "\t" " " text))
     ;; 4. Collapse multiple spaces into one
     (setq text (replace-regexp-in-string " +" " " text))
     ;; Copy to clipboard
     (kill-new (string-trim text))
     (message "Compacted text copied to clipboard")))

 (declare-function calc-push "calc")    ; to avoid compilation warning
 (with-eval-after-load 'calc
   (defun calc-push-time-in-milliseconds ()
     "Push time expressed in milliseconds into Calc stack."
     (interactive)
     (calc-push (round (* (float-time (current-time)) 1000)))))

 (add-hook 'calc-mode-hook
           (lambda ()
             (local-set-key (kbd "d") 'calc-push-time-in-milliseconds)))

 (defhydra hydra-calc (:exit t :hint nil)
   "
^Calc hydra:
^-----------

Start and stop :
   M-x calc
   C-x * *
   q

Digit grouping: 'd g' to activate | d , SPC to set separator

Empty stack: C-u 0 DEL

Toggle algebraic mode on/off : m a 

Copy the stack (to past in another window) : M-w

` to edit top element of the stack

Compact instructions (to be called on source file): my/calc-compact-to-clipboard

Macros :
   C-x (   |   C-x ) 
   X sinon C-x e
   Z `  ...  Z ' to protect registers
   Z K 3 then z 3 to store and execute macro
   Z E to edit
   M-x read kbd macro to read a macro from text file

F6 M-x my/calc-read-macro
F7 M-x my/calc-select-markdown-code-and-read-calc-macro

reset: M-x calc-reset

{end}
" 
   ;; ("e" #'a-function)
   )                                    ; end of hydra

 ) ; end of init section



;;; end of init--calc.el
