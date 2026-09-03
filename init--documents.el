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
   (unless (derived-mode-p 'dired-mode)
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
   (unless (derived-mode-p 'dired-mode)
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
   (unless (derived-mode-p 'dired-mode)
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
   :mode ("\\.epub\\'" . nov-mode)
   :config (my-init--message-package-loaded "nov (for epub)"))
 ;; https://tech.toryanderson.com/2022/11/23/viewing-epub-in-emacs/
 ;; https://lucidmanager.org/productivity/reading-ebooks-with-emacs/

 ;; Pure-Elisp epub (zip) extraction — replaces the external unzip
 ;; process that nov.el spawns.  Two benefits:
 ;; 1. Speed: eliminates process-creation overhead (significant on
 ;;    Windows) and avoids any WSL ↔ Windows filesystem penalty.
 ;; 2. Accents: handles non-ASCII filenames natively, no codepage
 ;;    issues.
 ;; Requires Emacs compiled with zlib support (standard since Emacs 25).
 ;; Falls back to the accent-only workaround if zlib is unavailable.
 ;;
 ;; Function definitions are at startup (cheap); advice-add calls are
 ;; deferred via with-eval-after-load so nov.el is not loaded eagerly.

 (when (fboundp 'zlib-decompress-region)
   (defun my/nov--read-u16 ()
     "Read little-endian unsigned 16-bit integer at point; advance by 2."
     (let ((lo (char-after (point)))
           (hi (char-after (1+ (point)))))
       (forward-char 2)
       (+ lo (ash hi 8))))

   (defun my/nov--read-u32 ()
     "Read little-endian unsigned 32-bit integer at point; advance by 4."
     (let ((b0 (char-after (point)))
           (b1 (char-after (+ (point) 1)))
           (b2 (char-after (+ (point) 2)))
           (b3 (char-after (+ (point) 3))))
       (forward-char 4)
       (+ b0 (ash b1 8) (ash b2 16) (ash b3 24))))

   (defun my/nov--u32-to-bytes (n)
     "Encode N as 4-byte little-endian unibyte string."
     (unibyte-string (logand n #xff)
                     (logand (ash n -8) #xff)
                     (logand (ash n -16) #xff)
                     (logand (ash n -24) #xff)))

   (defun my/nov-unzip-epub-elisp (directory filename)
     "Extract epub/zip FILENAME into DIRECTORY using pure Elisp.
No external process is spawned — decompression uses Emacs's
built-in zlib.  This avoids process-creation overhead and Windows
codepage issues with accented filenames."
     (let ((coding-system-for-write 'no-conversion)
           (inhibit-message t))
       (with-temp-buffer
         (set-buffer-multibyte nil)
         (insert-file-contents-literally filename)
         ;; Locate end-of-central-directory record (PK\005\006)
         (goto-char (max (point-min) (- (point-max) 65557)))
         (unless (search-forward "PK\005\006" nil t)
           (error "Not a valid ZIP/EPUB file: %s" filename))
         (let* ((eocd (- (point) 4))
                (_ (goto-char (+ eocd 10)))
                (n-entries (my/nov--read-u16))
                (_ (goto-char (+ eocd 16)))
                (cd-offset (my/nov--read-u32)))
           (goto-char (+ (point-min) cd-offset))
           (dotimes (_ n-entries)
             (unless (looking-at-p "PK\001\002")
               (error "Corrupt central directory in %s" filename))
             (let* ((e (point))
                    (_ (goto-char (+ e 10)))
                    (method (my/nov--read-u16))
                    (_ (goto-char (+ e 16)))
                    (crc32-raw (buffer-substring (point) (+ (point) 4)))
                    (_ (goto-char (+ e 20)))
                    (comp-size (my/nov--read-u32))
                    (uncomp-size (my/nov--read-u32))
                    (_ (goto-char (+ e 28)))
                    (name-len (my/nov--read-u16))
                    (extra-len (my/nov--read-u16))
                    (comment-len (my/nov--read-u16))
                    (_ (goto-char (+ e 42)))
                    (local-off (my/nov--read-u32))
                    (_ (goto-char (+ e 46)))
                    (name (decode-coding-string
                           (buffer-substring (point) (+ (point) name-len))
                           'utf-8))
                    (out (expand-file-name name directory)))
               (goto-char (+ e 46 name-len extra-len comment-len))
               (if (string-suffix-p "/" name)
                   (make-directory out t)
                 (make-directory (file-name-directory out) t)
                 (save-excursion
                   (goto-char (+ (point-min) local-off 26))
                   (let* ((ln (my/nov--read-u16))
                          (le (my/nov--read-u16))
                          (beg (+ (point-min) local-off 30 ln le))
                          (end (+ beg comp-size))
                          (raw (buffer-substring beg end)))
                     (cond
                      ;; STORE (method 0) — raw copy
                      ((= method 0)
                       (with-temp-buffer
                         (set-buffer-multibyte nil)
                         (insert raw)
                         (write-region (point-min) (point-max) out nil 'silent)))
                      ;; DEFLATE (method 8) — wrap in gzip envelope, decompress
                      ((= method 8)
                       (with-temp-buffer
                         (set-buffer-multibyte nil)
                         ;; Minimal gzip header (RFC 1952)
                         (insert "\037\213\010\0\0\0\0\0\0\003")
                         (insert raw)
                         ;; Gzip trailer: CRC32 + original size (both LE)
                         (insert crc32-raw)
                         (insert (my/nov--u32-to-bytes uncomp-size))
                         (unless (zlib-decompress-region (point-min) (point-max))
                           (error "Decompression failed for %s in %s" name filename))
                         (write-region (point-min) (point-max) out nil 'silent)))
                      (t
                       (error "Unsupported ZIP method %d for %s" method name))))))))))
       ;; Post-processing (same as original nov-unzip-epub)
       (let (child)
         (while (setq child (nov-contains-nested-directory-p directory))
           (nov-unnest-directory directory child)))
       (nov-fix-permissions directory))
     0))

 ;; Fix: nov.el's CSS query for the unique identifier ignores
 ;; namespace prefixes (e.g. dc:identifier), causing "Unique
 ;; identifier not found by its name" errors on some epub files.
 ;; Search the full DOM by id, and generate a fallback identifier
 ;; if all lookups fail so the epub always opens.
 (defun my/nov-content-unique-identifier-fix (orig-fun content)
   "Advice around `nov-content-unique-identifier'.
Fall back to searching the full DOM by id attribute when nov's
CSS selector fails to match namespace-prefixed elements.
As a last resort, generate an identifier from the content hash
so the epub still opens (only save-place is affected)."
   (condition-case _
       (funcall orig-fun content)
     (error
      (let* ((name (condition-case nil
                       (nov-content-unique-identifier-name content)
                     (error "unknown")))
             (match (car (dom-by-id content
                                    (concat "\\`" (regexp-quote name) "\\'")))))
        (if (and match (car (dom-children match)))
            (intern (car (dom-children match)))
          (intern (format "nov-%s" (md5 (format "%s" content)))))))))

 ;; Fallback when Emacs lacks zlib: at least fix accented filenames
 ;; on Windows by copying to a temp file with an ASCII-safe name.
 (unless (fboundp 'zlib-decompress-region)
   (when *my-init--windows-p*
     (defun my/nov--copy-to-safe-temp-name (orig-fun path)
       "Advice around `nov--initialize-temp-dir' for accented filenames.
Copy the epub to a temp file with an ASCII name so that the
external unzip process does not choke on Windows codepage issues."
       (if (string-match "[^\x00-\x7f]" path)
           (let* ((ext (file-name-extension path))
                  (tmp (make-temp-file "nov-safe-" nil (concat "." ext))))
             (copy-file path tmp t)
             (funcall orig-fun tmp))
         (funcall orig-fun path)))))

 ;; Advice is installed after nov loads (deferred via use-package :mode)
 (with-eval-after-load 'nov
   (when (fboundp 'my/nov-unzip-epub-elisp)
     (advice-add 'nov-unzip-epub :override #'my/nov-unzip-epub-elisp))
   (advice-add 'nov-content-unique-identifier
               :around #'my/nov-content-unique-identifier-fix)
   (when (fboundp 'my/nov--copy-to-safe-temp-name)
     (advice-add 'nov--initialize-temp-dir
                 :around #'my/nov--copy-to-safe-temp-name)))


 ;; Epub-to-text conversion via pandoc.
 ;; Works from dired (on marked/current epub file) or from a nov buffer.

 (defun my/epub--get-source-file ()
   "Return the epub file path from dired or nov buffer."
   (cond
    ((eq major-mode 'dired-mode)
     (let ((files (dired-get-marked-files)))
       (when (> (length files) 1)
         (error "Select a single epub file"))
       (car files)))
    ((eq major-mode 'nov-mode)
     (or nov-file-name buffer-file-name
         (error "Cannot determine epub file for this nov buffer")))
    (t (error "Not in dired or nov mode"))))

 (defun my/epub-to-format (format ext)
   "Convert epub file to FORMAT (pandoc output format) with extension EXT.
Works from dired or nov buffer."
   (unless (executable-find "pandoc")
     (error "pandoc not found in PATH"))
   (let* ((source (my/epub--get-source-file))
          (output (concat (file-name-sans-extension source) ext)))
     (unless (string-match-p "\\.epub\\'" source)
       (error "Not an epub file: %s" source))
     (message "Converting %s to %s with pandoc ..."
              (file-name-nondirectory source) format)
     (redisplay)
     (let ((exit-code (call-process "pandoc" nil "*pandoc output*" nil
                                    "-f" "epub" "-t" format
                                    "--wrap=none"
                                    "-o" output source)))
       (if (= exit-code 0)
           (progn
             (message "Converted to %s" (file-name-nondirectory output))
             (find-file output))
         (error "pandoc failed with exit code %d (see *pandoc output* buffer)"
                exit-code)))))

 (defun my/epub-to-org ()
   "Convert epub file to org-mode via pandoc. Works from dired or nov buffer."
   (interactive)
   (my/epub-to-format "org" ".org"))

 (defun my/epub-to-markdown ()
   "Convert epub file to markdown via pandoc. Works from dired or nov buffer."
   (interactive)
   (my/epub-to-format "gfm" ".md"))

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

[o] my/epub-to-org        convert epub to org-mode (pandoc)
[m] my/epub-to-markdown   convert epub to markdown (pandoc)
(works from dired or nov buffer)

(end)
"
   ("o" #'my/epub-to-org)
   ("m" #'my/epub-to-markdown))

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
             (add-hook 'before-save-hook #'my/markdown-align-all-tables nil t)
             (when (my-init--dark-background-p)
               (set-face-attribute 'markdown-pre-face nil :foreground "#FF69B4" :weight 'bold)
               (set-face-attribute 'markdown-inline-code-face nil :foreground "#FF69B4" :weight 'bold))))

 (defun my/markdown-copy-inline-code-or-block-or-word ()
   "Copy inline code, fenced code block content, or word at point in markdown.
Markdown counterpart of `my/org-copy-link-or-inline-code-or-verbatim-or-block':
\(1) inline code between backticks, \(2) content of the enclosing ``` block
\(fences excluded), \(3) fallback to `my/copy-word'."
   (interactive)
   (let ((found nil))

     ;; (1) inline code ?
     (when (markdown-inline-code-at-point-p)
       (save-match-data
         (markdown-inline-code-at-point) ; sets match-data; group 2 = content
         (let ((content (match-string-no-properties 2)))
           (when (and content (> (length content) 0))
             (kill-new content)
             (setq found t)
             (message "Copied inline code: %s" content)))))

     ;; (2) fenced code block ?
     (unless found
       (let ((bounds (markdown-get-enclosing-fenced-block-construct)))
         (when bounds
           (let* ((fence-begin (nth 0 bounds))
                  (fence-end   (nth 1 bounds))
                  (begin (save-excursion
                           (goto-char fence-begin)
                           (line-beginning-position 2))) ; line after opening fence
                  (end   (save-excursion
                           (goto-char fence-end)
                           (line-beginning-position 1))) ; start of closing fence
                  (content (buffer-substring-no-properties begin end)))
             (kill-new content)
             (setq found t)
             (message "Markdown code block content copied.")))))

     ;; (3) fallback : word
     (unless found
       (setq found (my/copy-word)))

     (unless found
       (message "No word, inline code, or block found at point."))))

 (with-eval-after-load 'markdown-mode
   (define-key markdown-mode-map (kbd "C-c c")
               #'my/markdown-copy-inline-code-or-block-or-word))

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
