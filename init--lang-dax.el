;;; -*- lexical-binding: t; byte-compile-warnings: (not docstrings docstrings-wide) -*-

;;; ===
;;; ===============
;;; ===== DAX =====
;;; ===============

(my-init--with-duration-measured-section 
 t
 "DAX"

 ;; DAX mode
 ;; useful for syntax highlighting in src block

 (setq dax--keywords
       '("RETURN"
         "VAR" ))

 (setq dax--types '("tobefilled12345"))

 (setq dax--constants
       '(
         "DAY"
         ))

 (setq dax--events '("tobefilled12345"))

 (setq dax--functions
       '("ALLSELECTED"
         "ALL"
         "BLANK"
         "CALCULATE"
         "DISTINCTCOUNT"
         "DATEDIFF"
         ;; "DATE"
         "COUNT"
         "DIVIDE"
         "EVALUATE"
         "FILTER"
         "FORMAT"
         "IF"
         "ISBLANK"
         "KEEPFILTERS"
         "left"
         "LEN"
         "MAX"
         "MIN"
         "MOD"
         "ORDER BY"
         "QUOTIENT"
         "RELATED"
         "REMOVEFILTERS"
         "right"
         "SUMX"
         "USERELATIONSHIP"
         "SUMMARIZECOLUMNS"
         "SUMMARIZE"
         "SUM"
         "SWITCH"
         "TODAY"
         "TOPN"
         ))

 (setq dax--font-lock-keywords
       (let* (
              ;; generate regex string for each category of keywords
              (x-keywords-regexp (regexp-opt dax--keywords 'words))
              (x-types-regexp (regexp-opt dax--types 'words))
              (x-constants-regexp (regexp-opt dax--constants 'words))
              (x-events-regexp (regexp-opt dax--events 'words))
              (x-functions-regexp (regexp-opt dax--functions 'words)))

         `(
           (,x-types-regexp . font-lock-type-face)
           (,x-constants-regexp . font-lock-constant-face)
           (,x-events-regexp . font-lock-builtin-face)
           (,x-functions-regexp . font-lock-function-name-face)
           (,x-keywords-regexp . font-lock-keyword-face)
           ;; note: order above matters, because once colored, that part won't change.
           ;; in general, put longer words first
           )))

 (defconst dax--mode-syntax-table
   (let ((table (make-syntax-table)))
     ;; ' is a string delimiter
     ;; (modify-syntax-entry ?' "\"" table)
     ;; " is a string delimiter too
     (modify-syntax-entry ?\" "\"" table)

     ;; / is punctuation, but // is a comment starter
     (modify-syntax-entry ?/ ". 12" table)
     ;; \n is a comment ender
     (modify-syntax-entry ?\n ">" table)
     table))

 (define-derived-mode DAX-mode fundamental-mode "DAX mode"
   "Major mode for editing Power BI DAX"
   :syntax-table dax--mode-syntax-table
   (setq font-lock-defaults '((dax--font-lock-keywords)))
   (setq font-lock-defaults `(dax--font-lock-keywords nil t))

   ;; (font-lock-fontify-buffer)
   ;; not needed in a mode definition because font-lock will be activated automatically?

   (setq font-lock-keywords-case-fold-search t))

 ) ; end of init section



;;; end of init--lang-dax.el
