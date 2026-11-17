;;; -*- lexical-binding: t; byte-compile-warnings: (not docstrings docstrings-wide) -*-

;;; ===
;;; ===============
;;; ===== SES =====
;;; ===============

(my-init--with-duration-measured-section 
 t
 "SES"

 (defhydra hydra-ses (:exit t :hint nil)
   "
^SES hydra:
^----------

C-o to insert row (M-x ses-insert-row)
w   to resize cell
"
   ;; ("e" #'a-function)
   )) ; end of init section


;;; ===
;;; ===============
;;; ===== ZIP =====
;;; ===============

(my-init--with-duration-measured-section 
 t
 "Zip"

 (unless (my-init--path-to-directory-or-file-exists-p *unzip-program*)
   (my-init--warning "!! *unzip-program* is nil or does not exist: %s" *unzip-program*))

 (defun my/unzip ()
   "Unzip file on dired line.
(v1, available in occisn/emacs-utils GitHub repository)"
   (interactive)
   (unless (my-init--file-exists-p *unzip-program*)
     (error "Unable to use unzip since no program defined: %s" *unzip-program*))
   (unless (derived-mode-p 'dired-mode)
     (error "Trying to unzip when not in dired-mode."))
   (when (> (length (dired-get-marked-files)) 1)
     (error "Trying to unzip several files."))
   (cl-labels ((replace-linux-slash-with-two-windows-slashes (path)
                 "Return PATH string after having replaced slashes by two backslashes.
For instance: abc/def --> abc\\def. On Linux, returns PATH unchanged."
                 (my-init--replace-linux-slash-with-two-windows-slashes path)))
     (let* ((files-list (dired-get-marked-files))
            (file-full-name (car files-list))
            (file-full-name-slash-OK-accents-OK (replace-linux-slash-with-two-windows-slashes file-full-name))
            (file-directory (file-name-directory file-full-name))
            (file-name (file-name-nondirectory file-full-name))
            (file-name-without-extension (file-name-base file-full-name))
            (output-directory
             (if (y-or-n-p "Create directory?")
                 (concat file-directory (read-string "create directory: " file-name-without-extension))
               file-directory))
            (output-directory-slash-OK-accents-OK (replace-linux-slash-with-two-windows-slashes output-directory))
            (cmd (concat "\"" *unzip-program* "\""
                         " x " "\"" file-full-name-slash-OK-accents-OK "\""
                         " -aou -y"
                         " -o" "\"" output-directory-slash-OK-accents-OK "\""))
            ;; Example of cmd line: 7z e "C:\Users\...\Downloads\emacs-26.2.tar" -y -o"C:\Users\...\Downloads\emacs-26.2"
            ;; https://info.nrao.edu/computing/guide/file-access-and-archiving/7zip/7z-7za-command-line-guide
            )
       (message "Unzipping %s by %s..." file-name (file-name-nondirectory *unzip-program*))
       (message "%s" (shell-command-to-string cmd))
       ;; (call-process-shell-command cmd nil 0)
       (revert-buffer)
       (message "... unzip finished."))))

 (defun my/zip-content-of-current-directory ()
   "Zip content of current directory into a zip archive.
(v1, available in occisn/emacs-utils GitHub repository)"
   (interactive)
   (unless (my-init--file-exists-p *unzip-program*)
     (error "Unable to use unzip since no program defined: %s" *unzip-program*))
   (unless (derived-mode-p 'dired-mode)
     (error "Trying to zip when not in dired-mode."))
   (cl-labels ((replace-linux-slash-with-two-windows-slashes (path)
                 "Return PATH string after having replaced slashes by two backslashes.
For instance: abc/def --> abc\\def. On Linux, returns PATH unchanged."
                 (my-init--replace-linux-slash-with-two-windows-slashes path)))
     (let* ((current-directory-slash-OK-accents-OK (replace-linux-slash-with-two-windows-slashes default-directory))
            (archive-name (concat (read-string "Archive name (without zip suffix): " "archive") ".zip"))
            (cmd (concat "\"" *unzip-program* "\""
                         " a -tzip "
                         "\"" current-directory-slash-OK-accents-OK archive-name "\""
                         " "
                         "\"" current-directory-slash-OK-accents-OK "*.*\""
                         " -r"))
            ;; Example of cmd line: "c:\Users\...\7-ZipPortable\App\7-Zip64\7z.exe" a -tzip "c:\Users\...\Downloads\test\archive.zip" "c:\Users\...\Downloads\test\*.*" -r
            ;; https://info.nrao.edu/computing/guide/file-access-and-archiving/7zip/7z-7za-command-line-guide
            )
       (message "Zipping %S with %s" current-directory-slash-OK-accents-OK (file-name-nondirectory *unzip-program*))
       ;; (call-process-shell-command cmd nil t)
       (message "%s" (shell-command-to-string cmd))
       (revert-buffer)
       (message "... zip finished."))))

 (defun my/list-zip-content ()
   "List the content of zip file on dired line.
(v1, available in occisn/emacs-utils GitHub repository)"
   (interactive)
   (unless (my-init--file-exists-p *unzip-program*)
     (error "Unable to list content of zip file since no program defined: %s" *unzip-program*))
   (unless (derived-mode-p 'dired-mode)
     (error "Trying to list content of zip file when not in dired-mode."))
   (when (> (length (dired-get-marked-files)) 1)
     (error "Trying to list the content of several files."))
   (cl-labels ((replace-linux-slash-with-two-windows-slashes (path)
                 "Return PATH string after having replaced slashes by two backslashes.
For instance: abc/def --> abc\\def. On Linux, returns PATH unchanged."
                 (my-init--replace-linux-slash-with-two-windows-slashes path)))
     (let* ((files-list (dired-get-marked-files))
            (file-full-name (car files-list))
            (file-full-name-slash-OK-accents-OK (replace-linux-slash-with-two-windows-slashes file-full-name))
            (file-name (file-name-nondirectory file-full-name))
            (cmd (concat "\"" *unzip-program* "\""
                         " l " "\"" file-full-name-slash-OK-accents-OK "\"")))
       (message "Listing content of %s by %s..." file-name (file-name-nondirectory *unzip-program*))
       ;; (shell-command-to-string cmd)
       (shell-command cmd nil nil)
       (revert-buffer)
       (message "... zip content listing finished."))))

 (defun my/zip-add-to-archive-present-in-same-directory () 
   "Add to archive present in same directory.
Attention: overwrite.
(v1, available in occisn/emacs-utils GitHub repository)"
   (interactive)
   (unless (my-init--file-exists-p *unzip-program*)
     (error "Unable to add to zip archive since no program defined: %s" *unzip-program*))
   (unless (derived-mode-p 'dired-mode)
     (error "Trying to add to zip archive when not in dired-mode."))
   (let ((files-to-add (dired-get-marked-files)))
     (message "marked files: %s" files-to-add)
     (when (null files-to-add)
       (error "Trying to add to zip archive but no file selected."))
     (let* ((files-to-add-no-path (mapcar #'file-name-nondirectory files-to-add))
            (all-zip-files (directory-files default-directory nil "\\.zip$"))
            (potential-zip-files (cl-set-difference all-zip-files files-to-add-no-path :test #'string=)))
       (message "files to add: %s" files-to-add-no-path)
       (message "all zip files: %s" all-zip-files)
       (message "potential zip files: %s" potential-zip-files)
       (when (null all-zip-files)
         (error "Impossible to add to archive since no zip file in the directory."))
       (when (null potential-zip-files)
         (error "Impossible to add to archive since all zip files are in the list of files to add."))
       (let* ((chosen-zip-file
               (completing-read
                "Choose archive file: "
                potential-zip-files))
              (target (concat default-directory chosen-zip-file))
              (target-accents-OK target))
         (message "chosen zip file: %s" chosen-zip-file)
         (message "default directory: %s" default-directory)
         (dolist (file-to-add files-to-add)
           (let* ((file-to-add-accents-OK file-to-add)
                  (cmd
                   (concat "\"" *unzip-program* "\""
                           " a -aot "
                           "\"" target-accents-OK "\""
                           " "
                           "\"" file-to-add-accents-OK "\""
                           " -r")))
             (message "- Adding %s to %s" file-to-add target)
             (message "%s" (shell-command-to-string cmd))
             (message "... addition OK.")))
         (revert-buffer)
         (message "All additions finished.")))))

 ) ; end of init section


;;; ===
;;; ======================
;;; ===== IRFAN VIEW =====
;;; ======================

(my-init--with-duration-measured-section 
 t
 "IrfanView"

 (when *my-init--windows-p*
   (unless (my-init--file-exists-p *irfanview-program*)
     (my-init--warning "!! *irfanview-program* is nil or does not exist: %s" *irfanview-program*)))

 (defun my/open-with-Irfan ()           ;  (&optional @fname)
   "Open the current file or dired marked files in an image viewer.
On Windows, uses IrfanView. On Linux, uses xdg-open.
To be called from dired hydra."
   (interactive)
   (if *my-init--windows-p*
       (progn
         (unless (my-init--file-exists-p *irfanview-program*)
           (error "Impossible to launch Irfan View since program path not known: %s" *irfanview-program*))
         (my-init--open-with-external-program
          "Irfan"
          (lambda (file-name)
            (concat "\"" *irfanview-program* "\"" " " "\"" file-name "\""))))
     (my-init--open-with-external-program
      "Image viewer"
      (lambda (file-name)
        (concat "xdg-open " (shell-quote-argument file-name))))))

 (when *my-init--windows-p*
   (defun my/launch-irfan ()
     "Open Irfan"
     (interactive)
     (my-init--open-windows-executable "Irfan" *irfanview-program*)))

 ) ; end of init section


;;; ===
;;; ===============
;;; ===== CMD =====
;;; ===============

(my-init--with-duration-measured-section 
 t
 "cmd"

 (when *my-init--windows-p*
   (defun my/start-cmd ()
     "Open a cmd window from current dired buffer or encompassing current file.
To be called from hydra."
     (interactive)

     (cond ((derived-mode-p 'dired-mode)
            (let ((proc (start-process "cmd" nil "cmd.exe" "/C" "start" "cmd.exe" "/K" "cd" default-directory)))
              (set-process-query-on-exit-flag proc nil)
              (my-init--message2 "Native cmd window opened in %s directory" default-directory)))

           ((not (null (buffer-file-name)))
            (let ((proc (start-process "cmd" nil "cmd.exe" "/C" "start" "cmd.exe" "/K" "cd" (file-name-directory (buffer-file-name)))))
              (set-process-query-on-exit-flag proc nil)
              (my-init--message2 "Native cmd window opened in directory where %S is located " buffer-file-name)))

           (t
            (let ((proc (start-process "cmd" nil "cmd.exe" "/C" "start" "cmd.exe")))
              (set-process-query-on-exit-flag proc nil)
              (my-init--message2 "Native cmd window opened"))))))
 
 ) ; end of init section


;;; ===
;;; =============================================
;;; ===== WINDOWS APPS, WINDOWS EXECUTABLES =====
;;; =============================================

(my-init--with-duration-measured-section 
 t
 "Windows apps, Windows executables"

 (defun my-init--dired-open-directory-if-valid (name path)
   "Open directory PATH (name: NAME) only if non null and valid."
   (if (my-init--directory-exists-p path)
       (progn
         (message "Opening %s: %s" name path)
         (dired path))
     (message "Impossible to open %s directory since path is nil or not valid: %s" name path)))

 (defun my/open-downloads-directory-in-dired ()
   "Open Downloads directory in dired."
   (interactive)
   (my-init--dired-open-directory-if-valid "Downloads" *downloads-directory*))

 (defun my/open-ongoing-directory-in-dired ()
   "Open 'en cours' directory in dired."
   (interactive)
   (my-init--dired-open-directory-if-valid "En cours" *ongoing-directory*))

 (defun my/open-dropbox-directory-in-dired ()
   "Open Dropbox directory in dired."
   (interactive)
   (my-init--dired-open-directory-if-valid "Dropbox" *dropbox-directory*))

 (defun my/open-local-repos-directory-in-dired ()
   "Open 'local repos' directory in dired."
   (interactive)
   (my-init--dired-open-directory-if-valid "local repos" *local-repos-directory*))

 (when nil
   (defun my/open-shared-drives ()
     "Open shared drives M: and S:"
     (interactive)
     (message "Opening shared network drives M: and S: from Emacs")
     (call-process-shell-command "explorer M:" nil 0)
     (call-process-shell-command "explorer S:" nil 0)))

 (when *my-init--windows-p*
   (defhydra hydra-windows-executables (:exit t :hint nil) ;  :columns 1)
     "
^Windows executables:
^--------------------

[w]: Microsoft Word
[e]: Microsoft Excel
[p]: Microsoft Powerpoint
[b]: Thunderbird
[f]: Firefox
[c]: Chrome
[i]: Irfan

Win-1 et Win-t launch applications from task bar
Win-S-s        screenshot (or W-^-S or W-fn-Impr)
Win-d          Desktop
Win-e          Explorer
Win-i          Parameters
Win-r          command
Win-w          news

Firefox: C-w, C-S-t (?)
F11 full screen
Alt-F4 and Alt-TAB

(end)"
     ("b" (my-init--open-windows-executable "Thunderbird" *thunderbird-executable*))
     ("c" (my-init--open-windows-executable "Chrome" *chrome-executable*))
     ("e" (my-init--open-windows-executable "Microsoft Excel" *excel-path*))
     ("f" (my-init--open-windows-executable "Firefox" *firefox-path*))
     ("i" #'my/launch-irfan)
     ("p" (my-init--open-windows-executable "Microsoft Powerpoint" *powerpoint-path*))
     ("t" (my-init--open-windows-executable "Microsoft Teams" *teams-path*))
     ("w" (my-init--open-windows-executable "Microsoft Word" *word-path*))
     ) ; end of hydra

   (global-set-key (kbd "C-c w") #'hydra-windows-executables/body))

 (when *my-init--linux-p*
   (defun my-init--open-linux-program (name program &rest args)
     "Open Linux program PROGRAM (display NAME), checking it exists first."
     (if (executable-find program)
         (let ((proc (apply #'start-process name nil program args)))
           (set-process-query-on-exit-flag proc nil)
           (my-init--message2 "%s launched." name))
       (user-error "%s not found in PATH" program)))

   (defhydra hydra-linux-apps (:exit t :hint nil)
     "
^Linux applications:
^-------------------

[f]: Firefox    [c]: Chrome      [b]: Thunderbird
[w]: Writer     [e]: Calc        [p]: Impress
[i]: Image viewer (xdg-open)

(end)"
     ("b" (my-init--open-linux-program "Thunderbird" "thunderbird"))
     ("c" (my-init--open-linux-program "Chrome" "google-chrome"))
     ("e" (my-init--open-linux-program "LibreOffice Calc" "libreoffice" "--calc"))
     ("f" (my-init--open-linux-program "Firefox" "firefox"))
     ("i" (let ((f (read-file-name "Image: ")))
            (start-process "viewer" nil "xdg-open" f)))
     ("p" (my-init--open-linux-program "LibreOffice Impress" "libreoffice" "--impress"))
     ("w" (my-init--open-linux-program "LibreOffice Writer" "libreoffice" "--writer"))
     ) ; end of hydra

   (global-set-key (kbd "C-c w") #'hydra-linux-apps/body))

 ) ; end of init section


;;; ===
;;; ====================
;;; ===== PRINTING =====
;;; ====================

(my-init--with-duration-measured-section
 t
 "Printing"

 ;; Windows Emacs: buffer -> (pandoc for org/markdown) HTML -> Chrome headless PDF
 ;; -> SumatraPDF silent print, so formatting (bold, headings, tables) is rendered.
 ;; WSL Emacs: raw plain text through PowerShell `Out-Printer'.
 ;; Printer names are never stored here: default printer, or chosen at run time.

 (defun my-init--powershell-quote (string)
   "Return STRING as a single-quoted PowerShell literal."
   (concat "'" (replace-regexp-in-string "'" "''" string t t) "'"))

 (defun my-init--windows-printers ()
   "Return the list of Windows printer names (via PowerShell)."
   (unless (or *my-init--windows-p* *my-init--wsl-p*)
     (error "Windows printers are only reachable from Windows or WSL"))
   (let ((coding-system-for-read 'utf-8))
     (with-temp-buffer
       (unless (zerop (call-process "powershell.exe" nil t nil
                                    "-NoProfile" "-NonInteractive" "-Command"
                                    "[Console]::OutputEncoding=[Text.Encoding]::UTF8; Get-Printer | ForEach-Object Name"))
         (error "Could not list printers: %s" (buffer-string)))
       (split-string (buffer-string) "[\r\n]+" t "[ \t]+"))))

 (when *my-init--windows-p*
   (unless (my-init--file-exists-p *chrome-executable*)
     (my-init--warning "!! *chrome-executable* is nil or does not exist (needed by my/print-buffer): %s" *chrome-executable*))
   (unless (my-init--file-exists-p *sumatra-program*)
     (my-init--warning "!! *sumatra-program* is nil or does not exist (needed by my/print-buffer): %s" *sumatra-program*)))

 (defconst *my-init--print-pdf-preview* "[PDF preview in Sumatra, no printing]"
   "Pseudo-printer name offered by `my/print-buffer' to only preview the PDF.")

 (defconst *my-init--print-plain-css*
   "body { margin: 0; } pre { font-family: Consolas, 'Courier New', monospace; font-size: 10pt; white-space: pre-wrap; overflow-wrap: anywhere; }"
   "CSS used when printing a plain-text buffer.")

 (defun my-init--print-run-steps (steps on-success)
   "Run STEPS sequentially and asynchronously, then call ON-SUCCESS.
Each step is (DESCRIPTION . COMMAND-LIST) for an external process (success =
exit code 0), or (DESCRIPTION . FUNCTION) for a check (success = non-nil).
Stop with a message on failure."
   (let ((step (car steps)))
     (cond
      ((null steps)
       (funcall on-success))
      ((functionp (cdr step))
       (if (funcall (cdr step))
           (my-init--print-run-steps (cdr steps) on-success)
         (message "Printing failed at step '%s' (see buffer \" *my-print*\")" (car step))))
      (t
       (make-process
        :name "my-print"
        :buffer (get-buffer-create " *my-print*")
        :command (cdr step)
        :noquery t
        :sentinel (lambda (proc _event)
                    (unless (process-live-p proc)
                      (if (zerop (process-exit-status proc))
                          (my-init--print-run-steps (cdr steps) on-success)
                        (message "Printing failed at step '%s' (see buffer \" *my-print*\")"
                                 (car step))))))))))

 (defun my-init--print-write-plain-html (text title html-file)
   "Write TEXT as a preformatted HTML page titled TITLE into HTML-FILE."
   (with-temp-buffer
     (insert text)
     (dolist (pair '(("&" . "&amp;") ("<" . "&lt;") (">" . "&gt;")))
       (goto-char (point-min))
       (while (search-forward (car pair) nil t)
         (replace-match (cdr pair) t t)))
     (goto-char (point-min))
     (insert "<!DOCTYPE html>\n<html><head><meta charset=\"utf-8\"><title>"
             title "</title><style>" *my-init--print-plain-css* "</style></head><body><pre>")
     (goto-char (point-max))
     (insert "</pre></body></html>\n")
     (let ((coding-system-for-write 'utf-8))
       (write-region (point-min) (point-max) html-file nil 'silent))))

 (defun my/print-buffer (&optional choose-printer)
   "Print the current buffer on a printer (the region only if active).
Without prefix argument, print on the Windows default printer.
With prefix argument CHOOSE-PRINTER (C-u), choose the printer from the
list of Windows printers, or choose a PDF preview (nothing printed).

On Windows Emacs, the buffer is rendered first: Org and Markdown buffers
through pandoc (bold, italic, headings, tables...), other buffers as
monospace text; then Chrome (headless) makes a PDF, which SumatraPDF
prints silently.

On WSL Emacs, the buffer is printed as raw plain text (no rendering)
through PowerShell `Out-Printer'."
   (interactive "P")
   (if *my-init--windows-p*
       (my-init--print-buffer-rendered choose-printer nil)
     (my-init--print-buffer-plain-text choose-printer)))

 (defun my/print-buffer-as-raw-text (&optional choose-printer)
   "Like `my/print-buffer', but never render Org or Markdown markup.
The buffer (or region) is printed as it is written, in monospace, like a
.txt file.  Prefix argument CHOOSE-PRINTER as in `my/print-buffer'."
   (interactive "P")
   (if *my-init--windows-p*
       (my-init--print-buffer-rendered choose-printer t)
     (my-init--print-buffer-plain-text choose-printer)))

 (defun my-init--print-buffer-rendered (choose-printer raw)
   "Windows: render buffer to PDF and print it.  See `my/print-buffer'.
If RAW is non-nil, do not render Org/Markdown markup (print as monospace text)."
   (unless (my-init--file-exists-p *chrome-executable*)
     (error "Chrome not found (*chrome-executable*): %s" *chrome-executable*))
   (unless (my-init--file-exists-p *sumatra-program*)
     (error "SumatraPDF not found (*sumatra-program*): %s" *sumatra-program*))
   (let* ((printer (when choose-printer
                     (completing-read "Printer: "
                                      (cons *my-init--print-pdf-preview* (my-init--windows-printers))
                                      nil t)))
          (preview-p (equal printer *my-init--print-pdf-preview*))
          (input-format (cond (raw nil)
                              ((derived-mode-p 'org-mode) "org")
                              ((derived-mode-p 'markdown-mode) "markdown")
                              (t nil)))
          (region-p (use-region-p))
          (text (if region-p
                    (buffer-substring-no-properties (region-beginning) (region-end))
                  (buffer-substring-no-properties (point-min) (point-max))))
          (what (format "%s%s" (if region-p "region of " "") (buffer-name)))
          (dir (file-name-as-directory (make-temp-file "emacs-print-" t)))
          (source-file (concat dir "source." (if (equal input-format "org") "org" "md")))
          (html-file (concat dir "page.html"))
          (pdf-file (concat dir (replace-regexp-in-string "[^[:alnum:]._-]" "_" (file-name-sans-extension (buffer-name))) ".pdf"))
          (profile-dir (concat dir "chrome-profile")) ; per run: a shared profile makes concurrent runs silently produce nothing
          (win (lambda (path) (subst-char-in-string ?/ ?\\ path)))
          (steps nil))
     (when input-format
       (unless (and *pandoc-executable-name* (executable-find *pandoc-executable-name*))
         (error "pandoc not found (*pandoc-executable-name*): %s" *pandoc-executable-name*))
       (let ((coding-system-for-write 'utf-8))
         (write-region text nil source-file nil 'silent))
       (push (list "pandoc" (executable-find *pandoc-executable-name*)
                   "-f" input-format "-t" "html5" "-s"
                   "--metadata" (concat "pagetitle=" (buffer-name))
                   "-o" html-file source-file)
             steps))
     (unless input-format
       (my-init--print-write-plain-html text (buffer-name) html-file))
     (push (list "Chrome PDF" *chrome-executable*
                 "--headless" "--disable-gpu" "--no-pdf-header-footer"
                 (concat "--user-data-dir=" (funcall win profile-dir))
                 (concat "--print-to-pdf=" (funcall win pdf-file))
                 (concat "file:///" html-file))
           steps)
     ;; Chrome may exit 0 without writing the PDF: check before going on
     (push (cons "PDF check" (lambda () (file-exists-p pdf-file))) steps)
     (unless preview-p
       (push (append (list "Sumatra print" *sumatra-program*)
                     (if printer (list "-print-to" printer) (list "-print-to-default"))
                     (list "-silent" (funcall win pdf-file)))
             steps))
     (with-current-buffer (get-buffer-create " *my-print*") (erase-buffer))
     (message "%s %s%s..." (if preview-p "Rendering" "Printing") what
              (if preview-p "" (concat " on " (or printer "default printer"))))
     (my-init--print-run-steps
      (nreverse steps)
      (lambda ()
        (ignore-errors (delete-directory profile-dir t))
        (if preview-p
            (progn
              (start-process "my-print-preview" nil *sumatra-program* "-reuse-instance" pdf-file)
              (message "PDF preview of %s: %s" what pdf-file))
          (ignore-errors (delete-directory dir t))
          (message "Printed %s on %s" what (or printer "default printer")))))))

 (defun my-init--print-buffer-plain-text (choose-printer)
   "Print buffer as raw plain text via PowerShell `Out-Printer' (Windows or WSL).
With CHOOSE-PRINTER non-nil, choose the printer.  See `my/print-buffer'."
   (unless (or *my-init--windows-p* *my-init--wsl-p*)
     (error "Printing is only implemented on Windows and WSL"))
   (let* ((printer (when choose-printer
                     (completing-read "Printer: " (my-init--windows-printers) nil t)))
          (region-p (use-region-p))
          (beg (if region-p (region-beginning) (point-min)))
          (end (if region-p (region-end) (point-max)))
          (what (format "%s%s" (if region-p "region of " "") (buffer-name)))
          (temp-file (make-temp-file "emacs-print-" nil ".txt"))
          (windows-file (if *my-init--windows-p*
                            (convert-standard-filename temp-file)
                          (string-trim (shell-command-to-string
                                        (format "wslpath -w %s" (shell-quote-argument temp-file))))))
          (ps-command (format "Get-Content -LiteralPath %s -Encoding UTF8 | Out-Printer%s"
                              (my-init--powershell-quote windows-file)
                              (if printer
                                  (concat " -Name " (my-init--powershell-quote printer))
                                ""))))
     (let ((coding-system-for-write 'utf-8-with-signature))
       (write-region beg end temp-file nil 'silent))
     (message "Printing %s on %s..." what (or printer "default printer"))
     (make-process
      :name "my-print"
      :buffer (get-buffer-create " *my-print*")
      :command (list "powershell.exe" "-NoProfile" "-NonInteractive" "-Command" ps-command)
      :sentinel (lambda (proc _event)
                  (unless (process-live-p proc)
                    (ignore-errors (delete-file temp-file))
                    (if (zerop (process-exit-status proc))
                        (message "Printed %s on %s" what (or printer "default printer"))
                      (message "Printing %s failed (see buffer \" *my-print*\")" what)))))))

 ) ; end of init section


;;; ===
;;; =================
;;; ===== PUTTY =====
;;; =================

;;; void

;;; ===
;;; =================
;;; ===== DITAA =====
;;; =================

(my-init--with-duration-measured-section 
 t
 "DITAA"

 (unless (my-init--file-exists-p *ditaa-jar*)
   (message "!! *ditaa-jar* is nil or does not exist: %s" *ditaa-jar*))

 ;; void
 
 ) ; end of init section


;;; ===
;;; ===============
;;; ===== OCR =====
;;; ===============

(my-init--with-duration-measured-section 
 t
 "OCR"

 (unless (my-init--directory-exists-p *temp-directory*)
   (my-init--warning "!! *temp-directory* is nil or does not exist: %s" *temp-directory*))

 (unless (my-init--file-exists-p *imagemagick-convert-program*)
   (my-init--warning "!! *imagemagick-convert-program* is nil or does not exist: %s" *imagemagick-convert-program*))

 ;; ImageMagick `identify' for my/dired-image-prepend-exif-date-taken
 (if *my-init--windows-p*
     (unless (and (boundp '*imagemagick-identify-program*)
                  (my-init--file-exists-p *imagemagick-identify-program*))
       (my-init--warning "!! *imagemagick-identify-program* is nil or does not exist: %s ; my/dired-image-prepend-exif-date-taken will error at runtime"
                         (and (boundp '*imagemagick-identify-program*)
                              *imagemagick-identify-program*)))
   (unless (executable-find "identify")
     (my-init--warning "!! ImageMagick `identify' not found on PATH ; my/dired-image-prepend-exif-date-taken will error at runtime")))

 (unless (my-init--directory-exists-p *tesseract-tessdata-dir*)
   (my-init--warning "!! *tesseract-tessdata-dir* is nil or does not exist: %s" *tesseract-tessdata-dir*))

 (unless (my-init--file-exists-p *tesseract-exe*)
   (my-init--warning "!! *tesseract.exe* is nil or does not exist: %s" *tesseract-exe*))

 (defun my/insert-ocr-clipboard ()
   "Insert in current buffer the result of OCR performed on clipboard content (which is supposed to be a snapshot of text).
Uses Tesseract and ImageMagick.
(v1, available in occisn/emacs-utils GitHub repository)"
   (interactive)

   (cl-labels ((paste-image-from-clipboard-to-file-with-imagemagick (destination-file-with-path)
                 "Paste image from clipboard fo file DESTINATION-FILE-WITH-PATH with ImageMagick.
(v1, available in occisn/emacs-utils GitHub repository + adaptations)"
                 (if *my-init--windows-p*
                     (progn
                       (unless (my-init--file-exists-p *imagemagick-convert-program*)
                         (error "Unable to paste image from clipboard to file, since *imagemagick-convert-program* does not contain valid content: %s" *imagemagick-convert-program*))
                       (let ((cmd (concat "\"" *imagemagick-convert-program* "\" " "clipboard: " destination-file-with-path)))
                         (message "Pasting image from clipboard to %s with ImageMagick." destination-file-with-path)
                         (call-process-shell-command cmd nil 0)))
                   ;; Linux: use xclip to get image from clipboard
                   (let ((cmd (concat "xclip -selection clipboard -t image/png -o > " (shell-quote-argument destination-file-with-path))))
                     (message "Pasting image from clipboard to %s with xclip." destination-file-with-path)
                     (call-process-shell-command cmd nil 0))))

               (invert-image-if-dark-background (image-file)
                 "Invert IMAGE-FILE in place when it has light text on a dark background.
This guards against a Tesseract 4 defect, and is a no-op on Tesseract 5.

Tesseract 4 binarises assuming dark text on light paper, so a snapshot taken from
a dark-themed editor, terminal or PDF viewer does not fail — it returns confident
garbage (\"TO CEE CCC CEE CCI CEE\"), with the occasional line coming out correct,
which is what makes the failure easy to miss. Measured on French text under
tesseract 4.1.1: 65.9% character error rate before inverting, 0.0% after.

Tesseract 5 handles light-on-dark natively: the same two captures measured 0.0%
either way under 5.0.0-alpha. So on a Windows install pointing at Tesseract 5
this function changes nothing but the cost of one ImageMagick call. It is kept
for the Linux/xclip branch and for older Tesseract builds; drop it if every
machine sharing this config is on 5.

Mean luminance separates the two cases with a wide margin — 0.17-0.18 on dark
captures against 0.72-0.96 on light ones, including a light capture containing a
large dark figure. The threshold is 0.4 rather than the midpoint because the two
errors are not symmetric: under Tesseract 4 inverting a light capture wrecks it
(0% -> 47.6%), whereas failing to invert a dark one is merely the previous
behaviour. A capture on mid-grey (mean 0.56) is correctly left alone."
                 (let* ((mean-cmd (format "\"%s\" \"%s\" -colorspace gray -format \"%%[fx:mean]\" info:"
                                          *imagemagick-convert-program* image-file))
                        (output (shell-command-to-string mean-cmd))
                        ;; ImageMagick warnings share this stream, so read the last
                        ;; line only, and demand a bare number: a failed measurement
                        ;; must never be mistaken for "very dark" and trigger an
                        ;; inversion. Anything unparseable leaves the image as it is.
                        (last-line (string-trim (or (car (last (split-string output "\n" t))) ""))))
                   (if (not (string-match-p "\\`[0-9]*\\.?[0-9]+\\'" last-line))
                       (message "OCR: could not measure luminance (%s), OCR-ing image as-is" last-line)
                     (when (< (string-to-number last-line) 0.4)
                       (message "OCR: dark-background capture (luminance %s), inverting before OCR" last-line)
                       (call-process-shell-command
                        (format "\"%s\" \"%s\" -negate \"%s\""
                                *imagemagick-convert-program* image-file image-file)
                        nil nil))))))  ; end of labels function definitions

     ;; Tesseract parameters here are tuned for SCREEN CAPTURES, not scans, and
     ;; the tuning consists mostly of leaving them alone. A clipboard snapshot is
     ;; a crisp rasterisation: no skew, no paper grain, glyphs already sharp. So
     ;; `-l fra' is the only flag that earns its place (without it Tesseract
     ;; assumes English and drops accents wholesale), and the default page
     ;; segmentation mode 3 is right.
     ;;
     ;; Do NOT copy the `--psm 11' / 300 dpi settings used for scanned documents
     ;; (see askdir/ocr_pass.py): measured on French text at screen size they are
     ;; worse here, not better. Sparse-text mode loses reading order, which costs
     ;; nothing on a scanned form and a great deal on a screenshot — 8.9% CER
     ;; against 0.3% for psm 3 on 11px text. Upsampling the image gains nothing
     ;; either, and the right-aligned figures column that defeats psm 3 on scans
     ;; is read perfectly here at every psm.
     ;;
     ;; The one input on which these defaults collapse — and only under Tesseract
     ;; 4 — is a dark-themed window; see `invert-image-if-dark-background' above.
     ;; A scan never has that problem, and Tesseract 5 no longer has it either.
     (let* ((tmp-file-1 (make-temp-file (concat *temp-directory* "ocr-")))
            (tmp-file-2 (concat (format "%s" tmp-file-1) ".png"))
            (tmp-file-3 (make-temp-file (concat *temp-directory* "ocr-output-")))
            (tmp-file-4 (concat (format "%s" tmp-file-3) ".txt"))
            (cmd (format "\"%s\" --tessdata-dir \"%s\" \"%s\" \"%s\" -l fra" *tesseract-exe* *tesseract-tessdata-dir* tmp-file-2 tmp-file-3)))

       (paste-image-from-clipboard-to-file-with-imagemagick tmp-file-2)
       (unless (file-exists-p tmp-file-2) (sleep-for 0.5))
       (unless (file-exists-p tmp-file-2) (error "File with pasted image does not exist, even after 0.5 s sleep: %s" tmp-file-2))
       (invert-image-if-dark-background tmp-file-2)
       (call-process-shell-command cmd nil t)
       (if (file-exists-p tmp-file-4)
           (insert-file-contents tmp-file-4)
         (error "OCR output file does not exist: %s" tmp-file-4))  
       
       (message "OCR of clipboard via Tesseract")

       (when (file-exists-p tmp-file-1) (delete-file tmp-file-1))
       (when (file-exists-p tmp-file-2) (delete-file tmp-file-2))
       (when (file-exists-p tmp-file-4) (delete-file tmp-file-4)))))

 (defun my/scanned-pdf-to-txt ()
   "Convert scanned PDF file on dired line to text buffer.
Uses Imagemagick and Tesseract.
(v4, available in occisn/emacs-utils GitHub repository)"
   (interactive)
   
   (unless (derived-mode-p 'dired-mode)
     (error "Scanned pdf to txt: not in dired mode."))
   (when (> (length (dired-get-marked-files)) 1)
     (error "Scanned pdf to txt: more than 1 file has been selected."))

   (cl-labels ((replace-linux-slash-with-two-windows-slashes (path)
                 "Return PATH string after having replaced slashes by two backslashes.
For instance: abc/def --> abc\\def. On Linux, returns PATH unchanged."
                 (my-init--replace-linux-slash-with-two-windows-slashes path)))
     
     (let* ((files-list (dired-get-marked-files))
            (file-full-name (car files-list))
            (file-full-name-slash-OK-accents-OK (replace-linux-slash-with-two-windows-slashes file-full-name))
            ;; (file-directory (file-name-directory file-full-name))
            (file-name (file-name-nondirectory file-full-name))
            ;; (file-name-slash-OK-accents-OK (replace-linux-slash-with-two-windows-slashes file-name))
            ;; (file-name-without-extension (file-name-base file-full-name))

            (cmd1 (concat "\"" *imagemagick-convert-program* "\" " "-density 300x300 " "\"" file-full-name-slash-OK-accents-OK "\"" " " *temp-directory* "zabcd-%03d.jpg"))
            )

       ;; Unlike `my/insert-ocr-clipboard', this function really does read scans,
       ;; so the scanned-document settings apply: `-density 300x300' above already
       ;; matches the 300 dpi that askdir/ocr_pass.py settled on for 10-12pt
       ;; scanned text. The one flag not carried over is `--psm 11', which on
       ;; degraded scans of forms and quotes recovered figures in narrow
       ;; right-aligned columns that the default psm 3 missed. Worth trying here,
       ;; but only against real scans of your own: it has not been measured on
       ;; this code path, and on clean input it is a regression.

       ;; Stale pages from a previous run would otherwise be globbed in below and
       ;; silently appended to this document: the JPEGs are named by page number
       ;; only, so a shorter PDF inherits the tail of the longer one before it.
       (dolist (stale (file-expand-wildcards (concat *temp-directory* "zabcd-*.jpg")))
         (delete-file stale))

       ;; step 1: convert pdf to jpg with ImageMagick
       (message "Scanned pdf to txt STEP 1: convert pdf to jpg with ImageMagick")
       ;; Synchronous (DESTINATION nil, not 0). With 0 the conversion is detached
       ;; and the wildcard expansion below runs against a directory ImageMagick is
       ;; still filling, yielding a truncated document — or an empty one — with no
       ;; error raised.
       (call-process-shell-command cmd1 nil nil)

       ;; step 2: convert jpg to txt with Tesseract
       (message "Scanned pdf to txt STEP 2: convert jpg to txt with Tesseract")
       
       (let* ((txt-buffer (generate-new-buffer (format "*Text content of scanned pdf file %s (my/scanned-pdf-to-txt x)*" file-name)))
              (image-files (file-expand-wildcards (concat *temp-directory* "zabcd-*.jpg")))
              (page-count 0))

         ;; No pages means ImageMagick failed (a missing Ghostscript delegate for
         ;; PDF is the usual cause). Say so, rather than opening an empty buffer
         ;; that looks like a PDF with no readable text.
         (unless image-files
           (error "my/scanned-pdf-to-txt: ImageMagick produced no page image from %s" file-name))

         (switch-to-buffer txt-buffer)
         
         (dolist (image-file1 image-files)
           
           (setq page-count (+ page-count 1))
           (insert (format "------ PAGE %s -------\n\n" page-count))
           (let* ((tmp-file-3 (make-temp-file (concat *temp-directory* "ocr-output-")))
                  (tmp-file-4 (concat (format "%s" tmp-file-3) ".txt"))
                  (cmd2 (format "\"%s\" --tessdata-dir \"%s\" \"%s\" \"%s\" -l fra" *tesseract-exe* *tesseract-tessdata-dir* image-file1 tmp-file-3)))

             (call-process-shell-command cmd2 nil t)

             (if (file-exists-p tmp-file-4)
                 (progn
                   (insert-file-contents tmp-file-4)
                   (goto-char (point-max)))
               
               (error "my/scanned-pdf-to-txt: OCR output file does not exist: %s" tmp-file-4))

             (when (file-exists-p tmp-file-4) (delete-file tmp-file-4)))) ; end of dolist
         
         (goto-char (point-min)))))) ; end of defun

 ) ; end of init section


;;; ===
;;; =====================================
;;; ===== THUNDERBIRD AND EML FILES =====
;;; =====================================

(my-init--with-duration-measured-section 
 t
 "Thunderbird and EML files"

 (defun eml-add-date-at-beginning-of-eml-file ()
   "Add date at the beginning of the eml files marked in dired.
Each marked file NAME.eml is renamed into \"YYYY-MM-DD _NAME.eml\",
the date being read from its \"Date:\" header.
Nothing is renamed unless the date of every marked file could be read.
(v3, available in occisn/emacs-utils GitHub repository)"
   (interactive)

   (cl-labels ((eml-date (file)
                 "Return the date of the \"Date:\" header of FILE, as \"YYYY-MM-DD\"."
                 (with-temp-buffer
                   (insert-file-contents file)
                   (goto-char (point-min))
                   (unless (re-search-forward "^Date:[ \t]*" nil t)
                     (error "No 'Date:' line found in file %s" file))
                   (let* ((date-line (buffer-substring (point) (line-end-position)))
                          (parsed (parse-time-string date-line))
                          (day (nth 3 parsed))
                          (month (nth 4 parsed))
                          (year (nth 5 parsed)))
                     (unless (and day month year)
                       (error "Cannot parse 'Date:' line \"%s\" of file %s" date-line file))
                     (format "%04d-%02d-%02d" year month day))))) ; end of labels definitions

     (unless (derived-mode-p 'dired-mode)
       (error "Trying to add dates at the beginning of eml files when not in dired-mode."))

     (let ((files-list (dired-get-marked-files))
           (renamings nil)) ; list of (OLD-FULL-NAME . NEW-FULL-NAME)

       ;; step 1: read the date of every file before renaming anything
       (dolist (file-full-name files-list)
         (unless (member (downcase (or (file-name-extension file-full-name) "")) '("eml"))
           (error "Trying to extract date from a non-EML file: %S" file-full-name))
         (let* ((file-directory (file-name-directory file-full-name))
                (file-name (file-name-nondirectory file-full-name))
                (yyyy-mm-dd (eml-date file-full-name))
                (file-new-full-name (concat file-directory yyyy-mm-dd " _" file-name)))
           (when (file-exists-p file-new-full-name)
             (error "Cannot rename '%s': file '%s' already exists"
                    file-name (file-name-nondirectory file-new-full-name)))
           (push (cons file-full-name file-new-full-name) renamings)))
       (setq renamings (nreverse renamings))

       ;; step 2: rename
       (dolist (renaming renamings)
         (rename-file (car renaming) (cdr renaming))
         (message "Date added at the beginning of file '%s'"
                  (file-name-nondirectory (car renaming))))

       (revert-buffer)
       (when renamings
         (dired-goto-file (cdr (car (last renamings)))))
       (message "Date added at the beginning of %d eml file(s)." (length renamings))))) ; end of defun
 
 ) ; end of init section



;;; end of init--external-tools.el
