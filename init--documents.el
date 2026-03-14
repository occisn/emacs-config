;;; -*- lexical-binding: t; byte-compile-warnings: (not docstrings docstrings-wide) -*-

;;; ===
;;; ======================================================================
;;; === PYTHON IN PATH (FOR UNOCONV USED BY DOCVIEW AND PYTHON ITSELF) ===
;;; ======================================================================

(my-init--with-duration-measured-section
 t
 "Python in PATH"

 ;; Personal note:
 ;;
 ;; Download LibreOffice from PortableApps
 ;;
 ;; It’s possible that python.exe is being hidden by a Windows 10 prompt to download it from the Microsoft Store.
 ;; The Store opens automatically when you type python in the command line.
 ;; Solution: go to “App execution aliases” (French: "Alias d'exécution d'application") and disable Python.

 ;; For unoconv, we shall use the Python provided by LibreOffice (Windows only)

 (when *my-init--windows-p*
   (unless (my-init--file-exists-p *python-executable--in-libreoffice-for-unoconv*)
     (my-init--warning "!! *python-executable--in-libreoffice-for-unoconv* is nil or does not exist: %s" *python-executable--in-libreoffice-for-unoconv*))

   (if (my-init--directory-exists-p *python-path-1--in-libreoffice-for-unoconv*)
       (progn
         (my-init--add-to-path "Python path (1) [in Libre Office, for unoconv]" *python-path-1--in-libreoffice-for-unoconv*)
         (my-init--add-to-exec-path "Python path (1) [in Libre Office, for unoconv]" *python-path-1--in-libreoffice-for-unoconv*))
     (my-init--warning "!! *python-path-1--in-libreoffice-for-unoconv* is nil or does not exist: %s" *python-path-1--in-libreoffice-for-unoconv*))

   (if (my-init--directory-exists-p *python-path-2--in-libreoffice-for-unoconv*)
       (progn
         (my-init--add-to-path "Python path (2) [in Libre Office, for unoconv]" *python-path-2--in-libreoffice-for-unoconv*)
         (my-init--add-to-exec-path "Python path (2) [in Libre Office, for unoconv]" *python-path-2--in-libreoffice-for-unoconv*))
     (my-init--warning "!! *python-path-2--in-libreoffice-for-unoconv* is nil or does not exist: %s" *python-path-2--in-libreoffice-for-unoconv*)))
 
 ) ; end of init section


;;; ===
;;; ============================
;;; ===== DOCVIEW AND PEEP =====
;;; ============================

(my-init--with-duration-measured-section 
 t
 "Docview and peep"
 
 ;; ghostscript:
 (if *my-init--windows-p*
     ;; Windows: Ghostscript portable with explicit paths
     (progn
       (if (my-init--file-exists-p *gs-program*)
           (setq doc-view-ghostscript-program *gs-program*)
         (my-init--warning "!! *gs-program* is nil or does not exist: %s" *gs-program*))
       ;; for .ps :
       (if (my-init--directory-exists-p *gs-bin-directory*)
           (my-init--add-to-path "Ghostscript" *gs-bin-directory*)
         (my-init--warning "!! *gs-bin-directory* is nil or does not exist: %s" *gs-bin-directory*))
       ;; for .dvi :
       ;; in below directory, rename dvipdf into dvipdf.bat
       (if (my-init--directory-exists-p *gs-lib-directory*)
           (my-init--add-to-exec-path "dvipdf" (my-init--replace-linux-slash-with-two-windows-slashes *gs-lib-directory*))
         (my-init--warning "!! *gs-lib-directory* is nil or does not exist: %s" *gs-lib-directory*)))
   ;; Linux: Ghostscript expected in PATH
   (if (executable-find "gs")
       (setq doc-view-ghostscript-program "gs")
     (my-init--warning "!! gs (Ghostscript) not found in PATH")))
 ;; To check: (executable-find doc-view-dvipdf-program)
 ;; do not seem to work on pro1 computer (2025-12-07)
 
 ;; Python:
 ;; It is necessary for unoconv
 ;; See "PYTHON IN PATH" section above

 ;; Unoconv:
 ;; Zip can be downloaded from Github
 ;;
 (when *my-init--windows-p*
   (if (my-init--directory-exists-p *libreoffice-directory*)
       (let ((prog-name "LibreOffice for unoconv")
             (directory (my-init--replace-linux-slash-with-two-windows-slashes *libreoffice-directory*))
             (path-env (getenv "UNOPATH"))
             (separator ";"))
         (if (cl-search directory path-env)
             (my-init--message2 "No need to add %s to UNOPATH since already in: %s" prog-name directory)
           (setenv "UNOPATH" (concat directory separator (getenv "UNOPATH")))
           (my-init--message2 "%s is added to UNOPATH." prog-name)))
     (my-init--warning "!! *libreoffice-directory* is nil or does not exist: %s" *libreoffice-directory*)))
 ;;
 ;; test 1: "python unoconv -h" on command line shall give the list of possible unoconv arguments
 ;; test 2 : put a test file next to unoconv
 ;;     "python unoconv -f pdf test_powerpoint_pptx.pptx"
 ;;     on command line shall convert the file into pdf

 ;; doc-view... shall work
 ;;
 ;; M-x doc-view-dired-cache leads to doc-view cache in dired
 ;; (doc-view-clear-cache)
 ;;
 ;; tutorial : https://emacsnotes.wordpress.com/2018/08/09/222/

 ;; Addition of links:
 ;;
 ;; see https://emacs.stackexchange.com/questions/73017/how-to-associate-pdf-file-extension-with-pdf-tools
 ;;
 ;; .doc :
 (add-to-list 'auto-mode-alist '("\\.[dD][oO][cC]\\'" . doc-view-mode-maybe))
 ;; .odt :
 (add-to-list 'auto-mode-alist '("\\.[oO][dD][tT]\\'" . doc-view-mode-maybe))

 ;; preview with peep-dired:
 (use-package peep-dired
   ;; :defer t
   ;; :after (dired)
   :bind (:map dired-mode-map ("P" . peep-dired))
   :config (my-init--message-package-loaded "peep-dired"))
 
 ;; hydra:
 (defhydra hydra-docview (:exit t :hint nil)
   "
^Docview hydra:
^--------------

n, p     change page
M-<, M-> go to the top or bottom of the document
W        fit width
H        see all height
P        see all page
C-s C-s  search
q        quit
C-c C-c  change mode
C-c C-t  underlying text

doc-view-cache-directory
M-x doc-view-dired-cache   leads to doc-view cache into [d]ired
M-x doc-view-clear-cache   [c]lears cache

(end)
"
   ("c" #'doc-view-clear-cache)
   ("d" #'doc-view-dired-cache))) ; end of init section


;;; ===
;;; ===============
;;; ===== CSV =====
;;; ===============

(my-init--with-duration-measured-section 
 t
 "CSV"

 (use-package csv-mode
   :mode ("\\.[Cc][Ss][Vv]\\'" . csv-mode)
   :config
   ;; (setq csv-separators '("," ";" "|" " "))
   (setq csv-separators (append '(";") csv-separators))
   (my-init--message-package-loaded "csv-mode")
   
   ;; C-c C-M-a: align only visible part
   (add-hook 'csv-mode-hook
             (lambda ()
               "source: https://stackoverflow.com/questions/10616525/is-there-a-good-emacs-mode-for-displaying-and-editing-huge-delimiter-separated-f"
               (define-key csv-mode-map (kbd "C-c C-M-a")
                           (defun csv-align-visible (&optional _arg)
                             "Align visible fields"
                             (interactive "P")
                             (csv-align-fields nil (window-start) (window-end)))))))

 (defhydra hydra-csv (:exit t :hint nil)
   "
^CSV hydra:
^----------

C-c C-s (csv-sort-fields)         sorts lexicographically on a specified filed or column
C-c C-n (csv-sort-numeric-fields) sorts numerically on a specified filed or column
C-c C-r (csv-reverse-region)      reverses the order
C-c C-a (csv-align-fields)        aligns fields into columns and C-c C-u (csv-unalign-fields) undoes such alignment
C-c C-t (csv-transpose)           interchanges rows and columns.

C-c C-M-a align only visible part
(end)"
   ;; ("e" #'a-function)
   ) ; end of hydra
 
 ) ; end of init section


;;; ===
;;; =======================
;;; ===== SUMATRA PDF =====
;;; =======================

(my-init--with-duration-measured-section 
 t
 "Sumatra PDF"

 (setq *pdf-viewer-program* nil)

 (if *my-init--windows-p*
     ;; Windows: use SumatraPDF
     (if (my-init--file-exists-p *sumatra-program*)
         (setq *pdf-viewer-program*
               (list (list
                      "Sumatra PDF"
                      (concat "\"" *sumatra-program* "\" -reuse-instance %o"))))
       (my-init--warning "!! *sumatra-program* is nil or does not exist: %s" *sumatra-program*))
   ;; Linux: use evince
   (setq *pdf-viewer-program*
         (list (list "Evince" "evince %o"))))

 (when (null *pdf-viewer-program*)
   (my-init--warning "!! *pdf-viewer-program* is nil: %s" *pdf-viewer-program*))

 (defun my/open-pdf-externally ()
   "Open the current file or dired marked files in the system PDF viewer."
   (interactive)
   (if *my-init--windows-p*
       (progn
         (unless (my-init--file-exists-p *sumatra-program*)
           (error "Impossible to launch Sumatra since program path not known: %s" *sumatra-program*))
         (my-init--open-with-external-program
          "Sumatra"
          (lambda (file-name)
            (concat "\"" *sumatra-program* "\"" " -reuse-instance " "\"" file-name "\""))))
     (my-init--open-with-external-program
      "PDF viewer"
      (lambda (file-name)
        (concat "evince " (shell-quote-argument file-name))))))

 (defalias 'my/open-with-Sumatra #'my/open-pdf-externally)

 ) ; end of init section


;;; ===
;;; =================
;;; ===== PDFTK =====
;;; =================

(my-init--with-duration-measured-section 
 t
 "pdftk"

 (when (null *pdftk-program-name*)
   (message "!! *pdftk-program-name* is nil: %s" *pdftk-program-name*))

 (unless (my-init--file-exists-p *pdftk-program*)
   (my-init--warning "!! *pdftk-program* is nil or does not exist: %s" *pdftk-program*))

 (defun my/pdf-burst ()
   "Bursts PDF file on dired line.
(v2, available in occisn/emacs-utils GitHub repository)"
   (interactive)
   (when (null *pdftk-program*)
     (error "No PDFTK program is defined."))
   (unless (string= major-mode "dired-mode")
     (error "Trying to burst a PDF file when not in dired-mode."))
   (when (> (length (dired-get-marked-files)) 1)
     (error "Trying to burst several files."))
   (cl-labels ((replace-linux-slash-with-two-windows-slashes (path)
                 "Return PATH string after having replaced slashes by two backslashes.
For instance: abc/def --> abc\\def. On Linux, returns PATH unchanged."
                 (my-init--replace-linux-slash-with-two-windows-slashes path)))
     (let* ((files-list (dired-get-marked-files))
            (file-full-name (car files-list))
            (file-full-name-slash-OK-accents-OK (replace-linux-slash-with-two-windows-slashes file-full-name))
            (file-directory (file-name-directory file-full-name))
            (file-name (file-name-nondirectory file-full-name))
            (file-name-slash-OK-accents-OK (replace-linux-slash-with-two-windows-slashes file-name))
            ;; (file-name-without-extension (file-name-base file-full-name))
            (output-directory file-directory)
            (output-directory-slash-OK-accents-OK (replace-linux-slash-with-two-windows-slashes output-directory))
            (cmd (concat "\"" *pdftk-program* "\""
                         " "
                         "\"" file-full-name-slash-OK-accents-OK "\""
                         " burst output "
                         "\"" output-directory-slash-OK-accents-OK "page_%03d_of_" file-name-slash-OK-accents-OK "\""))
            ;; Example of cmd line: "c:/Users/.../PDFTKBuilderPortable/App/pdftkbuilder/pdftk.exe" "c:/Users/.../Downloads/test.pdf" burst output "c:/Users/.../Downloads/page_%03d_of_XYZ.pdf"
            )
       (unless (or (string= (file-name-extension file-full-name) "pdf")
                   (string= (file-name-extension file-full-name) "PDF"))
         (error "Trying to burst a non-PDF file: %S" file-full-name))
       (message "Bursting (splitting) PDF file %S with %s" file-name *pdftk-program-name*)
       (call-process-shell-command cmd nil t)
       (revert-buffer))))

 (defun my/pdf-extract ()
   "Extracts pages from a PDF file on dired line.
(v2, available in occisn/emacs-utils GitHub repository)"
   (interactive)
   (when (null *pdftk-program*)
     (error "No PDFTK program is defined."))
   (unless (string= major-mode "dired-mode")
     (error "Trying to extract from a PDF file when not in dired-mode."))
   (when (> (length (dired-get-marked-files)) 1)
     (error "Trying to extract from several files."))
   (cl-labels ((replace-linux-slash-with-two-windows-slashes (path)
                 "Return PATH string after having replaced slashes by two backslashes.
For instance: abc/def --> abc\\def. On Linux, returns PATH unchanged."
                 (my-init--replace-linux-slash-with-two-windows-slashes path)))
     (let* ((first-page (read-string "First page: "))
            (last-page (read-string "Last page: "))
            (files-list (dired-get-marked-files))
            (file-full-name (car files-list))
            (file-full-name-slash-OK-accents-OK (replace-linux-slash-with-two-windows-slashes file-full-name))
            (file-directory (file-name-directory file-full-name))
            (file-name (file-name-nondirectory file-full-name))
            (file-name-slash-OK-accents-OK (replace-linux-slash-with-two-windows-slashes file-name))
            ;; (file-name-without-extension (file-name-base file-full-name))
            (output-directory file-directory)
            (output-directory-slash-OK-accents-OK (replace-linux-slash-with-two-windows-slashes output-directory))
            (cmd (concat "\"" *pdftk-program* "\""
                         " "
                         "A=\"" file-full-name-slash-OK-accents-OK "\""
                         " cat A" first-page "-" last-page " output "
                         "\"" output-directory-slash-OK-accents-OK "page_" first-page "_to_" last-page "_of_" file-name-slash-OK-accents-OK "\""))
            ;; Example of cmd line: "c:/Users/.../PDFTKBuilderPortable/App/pdftkbuilder/pdftk.exe" A="c:/Users/.../Downloads/test.pdf" cat A2-4 output "c:/Users/.../Downloads/page_2_to_4_of_XYZ.pdf"
            )
       (unless (or (string= (file-name-extension file-full-name) "pdf")
                   (string= (file-name-extension file-full-name) "PDF"))
         (error "Trying to extract pages from a non-PDF file: %S" file-full-name))
       (message "Extracting page(s) %s to %s of PDF file %S with %s" first-page last-page file-name *pdftk-program-name*)
       (call-process-shell-command cmd nil t)
       (revert-buffer))))

 (defun my/pdf-join ()
   "Concatenates PDF files
Caution: no accent in file names
If necessary : M-x read-only-mode
(v1, available in occisn/emacs-utils GitHub repository)"
   (interactive)
   (when (null *pdftk-program*)
     (error "No PDFTK program is defined."))
   (unless (string= major-mode "dired-mode")
     (error "Trying to extract from a PDF file when not in dired-mode."))
   (cl-labels ((replace-linux-slash-with-two-windows-slashes (path)
                 "Return PATH string after having replaced slashes by two backslashes.
For instance: abc/def --> abc\\def. On Linux, returns PATH unchanged."
                 (my-init--replace-linux-slash-with-two-windows-slashes path)))
     (let* ((output-file (read-string "Output file (default: output.pdf): " nil nil "output.pdf"))
            (files-list (cl-sort (dired-get-marked-files) 'string-lessp))
            (first-file-full-name (car files-list))
            (files-directory (file-name-directory first-file-full-name))
            (output-directory files-directory)
            (output-directory-slash-OK-accents-OK (replace-linux-slash-with-two-windows-slashes output-directory))
            (cmd (concat "\"" *pdftk-program* "\""))
            ;; Example of cmd line: "c:/Users/.../PDFTKBuilderPortable/App/pdftkbuilder/pdftk.exe" "c:/Users/.../Downloads/1.pdf" "c:/Users/.../Downloads/2.pdf" cat output "c:/Users/.../Downloads/output.pdf"
            )
       (dolist (file-full-name files-list)
         (unless (or (string= (file-name-extension file-full-name) "pdf")
                     (string= (file-name-extension file-full-name) "PDF"))
           (error "Trying to join a non-PDF file: %S" file-full-name))
         (let ((file-full-name-slash-OK-accents-OK (replace-linux-slash-with-two-windows-slashes file-full-name)))
           (setq cmd (concat cmd " " "\"" file-full-name-slash-OK-accents-OK "\""))))
       (setq cmd (concat cmd " cat output " "\"" output-directory-slash-OK-accents-OK output-file "\""))
       ;;(message "cmd: %s" cmd)
       (message "Joining PDF files with %s" *pdftk-program-name*)
       (call-process-shell-command cmd nil t)
       (revert-buffer))))
 
 ) ; end of init section


;;; ===
;;; ================
;;; ===== EPUB =====
;;; ================

(my-init--with-duration-measured-section 
 t
 "epub"

 (use-package nov
   ;; :mode ("\\.epub\\'" . nov-mode)
   :hook (nov-mode . nov-mode)
   :init (add-to-list 'auto-mode-alist '("\\.epub\\'" . nov-mode))
   :config (my-init--message-package-loaded "nov (for epub)"))
 ;; https://tech.toryanderson.com/2022/11/23/viewing-epub-in-emacs/
 ;; https://lucidmanager.org/productivity/reading-ebooks-with-emacs/


 (defhydra hydra-nov (:exit t :hint nil)
   "
^Nov (epub) hydra:
^-----------------

t: go Table of contents
n and p or [ and ]: Next or previous chapter
q: Quit the ebook reader
?: Help file with list of other keyboard shortcuts

To increase or decrease the text, use the C-x C-+ and C-c C-- shortcuts. To reset the length of the lines, press g to re-render the document.

Opening the file as an archive with the a key shows the document's structure.
From here, you can also copy images from the book with the C keyboard shortcut
"
   )

 ;; ??? https://www.gnu.org/software/emacs/manual/html_node/emacs/Document-View.html

 ) ; end of init section


;;; ===
;;; ====================
;;; ===== MARKDOWN =====
;;; ====================

(my-init--with-duration-measured-section 
 t
 "markdown"

 ;; https://jblevins.org/projects/markdown-mode/

 (if *my-init--windows-p*
     ;; Windows: add portable Pandoc to PATH
     (if (my-init--directory-exists-p *pandoc-directory*)
         (my-init--add-to-path-and-exec-path "Pandoc" *pandoc-directory*)
       (my-init--warning "!! pandoc directory is nil or does not exist: %s" *pandoc-directory*))
   ;; Linux: pandoc expected in PATH
   (unless (executable-find "pandoc")
     (my-init--warning "!! pandoc not found in PATH")))
 
 (if (>= emacs-major-version 28)
     (use-package markdown-mode
       :mode ("\\.md\\'" . markdown-mode)
       :config
       (my-init--message-package-loaded "markdown-mode")
       (setq markdown-command *pandoc-executable-name*))
   (my-init--warning "Could not use package markdown since emacs version is not >= 28"))

 (defun my/markdown-align-all-tables ()
   "Align all markdown tables in the buffer."
   (interactive)
   (save-excursion
     (goto-char (point-min))
     (while (re-search-forward "^|" nil t)
       (markdown-table-align)
       (forward-paragraph))))

 (add-hook 'markdown-mode-hook
           (lambda ()
             (add-hook 'before-save-hook #'my/markdown-align-all-tables nil t)))

 (defun my/md-convert-region-to-anchor-and-kill ()
   "Convert current '## a b c' headline into #a-b-c anchor ready to be pasted."
   (interactive)
   (aprogn
    (beginning-of-line)
    (call-interactively 'set-mark-command)
    (end-of-line)
    (buffer-substring-no-properties (region-beginning) (region-end))
    (substring it 3)                    ; delete '## '
    (downcase it)
    (string-replace ":" "" it)
    (string-replace " " "-" it)
    (concat "#" it) 
    (progn
      (call-interactively 'set-mark-command)
      (kill-new it)
      (message "Ready to be yanked: %s" it))))

 (defhydra hydra-markdown (:exit t :hint nil)
   "
^Markdown hydra:
^--------------

preview in emacs (eww) : C-c C-c l
preview in browser : C-c C-c p

M-x my/md-convert-region-to-anchor-and-kill 

[3] : copy from markdown to clipboard, under org-mode format

M-x markdown-table-align (modifies buffer)

(end)
"
   ("3" #'my/markdown-region-to-org-clipboard)
   )
 
 ) ; end of init section


;;; ===
;;; ==================
;;; ===== IMAGES =====
;;; ==================

;;; void



;;; end of init--documents.el
