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
   (unless (string= major-mode "dired-mode")
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
   (unless (string= major-mode "dired-mode")
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
   (unless (string= major-mode "dired-mode")
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
   (unless (string= major-mode "dired-mode")
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

     (cond ((string= major-mode "dired-mode")
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
                     (call-process-shell-command cmd nil 0))))) ; end of labels function definitions

     (let* ((tmp-file-1 (make-temp-file (concat *temp-directory* "ocr-")))
            (tmp-file-2 (concat (format "%s" tmp-file-1) ".png"))
            (tmp-file-3 (make-temp-file (concat *temp-directory* "ocr-output-")))
            (tmp-file-4 (concat (format "%s" tmp-file-3) ".txt"))
            (cmd (format "\"%s\" --tessdata-dir \"%s\" \"%s\" \"%s\" -l fra" *tesseract-exe* *tesseract-tessdata-dir* tmp-file-2 tmp-file-3)))

       (paste-image-from-clipboard-to-file-with-imagemagick tmp-file-2)
       (unless (file-exists-p tmp-file-2) (sleep-for 0.5))
       (unless (file-exists-p tmp-file-2) (error "File with pasted image does not exist, even after 0.5 s sleep: %s" tmp-file-2))
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
   
   (unless (string= major-mode "dired-mode")
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

       ;; step 1: convert pdf to jpg with ImageMagick
       (message "Scanned pdf to txt STEP 1: convert pdf to jpg with ImageMagick")
       (call-process-shell-command cmd1 nil 0)

       ;; step 2: convert jpg to txt with Tesseract
       (message "Scanned pdf to txt STEP 2: convert jpg to txt with Tesseract")
       
       (let* ((txt-buffer (generate-new-buffer (format "*Text content of scanned pdf file %s (my/scanned-pdf-to-txt x)*" file-name)))
              (image-files (file-expand-wildcards (concat *temp-directory* "zabcd-*.jpg")))
              (page-count 0))

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
   "Add date at the beginning of eml file in dired.
(v2, available in occisn/emacs-utils GitHub repository)"
   (interactive)

   (cl-labels ((replace-linux-slash-with-two-windows-slashes (path)
                 "Return PATH string after having replaced slashes by two backslashes.
For instance: abc/def --> abc\\def"
                 (replace-regexp-in-string  "/" "\\\\" path))
               (english-month-to-number (month)
                 "Jan --> 1, Dec --> 12"
                 (cond ((equal "Jan" month) 1)
                       ((equal "Feb" month) 2)
                       ((equal "Mar" month) 3)
                       ((equal "Apr" month) 4)
                       ((equal "May" month) 5)
                       ((equal "Jun" month) 6)
                       ((equal "Jul" month) 7)
                       ((equal "Aug" month) 8)
                       ((equal "Sep" month) 9)
                       ((equal "Oct" month) 10)
                       ((equal "Nov" month) 11)
                       ((equal "Dec" month) 12)
                       (t (error "Month not recognized: %s" month))))) ; end of labels definitions
     
     (unless (string= major-mode "dired-mode")
       (error "Trying to burst a PDF file when not in dired-mode."))
     (when (> (length (dired-get-marked-files)) 1)
       (error "Trying to add dates at the beginning of several files."))
     
     (let* ((files-list (dired-get-marked-files))
            (file-full-name (car files-list))
            (file-full-name-slash-OK-accents-OK (replace-linux-slash-with-two-windows-slashes file-full-name))
            (file-directory (file-name-directory file-full-name))
            (file-name (file-name-nondirectory file-full-name))
            (file-name-slash-OK-accents-OK (replace-linux-slash-with-two-windows-slashes file-name))
            ;; (file-name-without-extension (file-name-base file-full-name))
            (date-line nil))
       (unless (or (string= (file-name-extension file-full-name) "eml") (string= (file-name-extension file-full-name) "EML") )
         (error "Trying to extract date from a non-EML fil: %S" file-full-name))
       (with-temp-buffer
         (insert-file-contents file-full-name-slash-OK-accents-OK)
         (goto-char (point-min))
         (search-forward "Date:")
         (set-mark-command nil)
         (end-of-line)
         (setq date-line (buffer-substring (region-beginning) (region-end))))
       (when (null date-line)
         (error "No 'Date:' line found in file %s" file-name-slash-OK-accents-OK))
       (let ((elements (split-string date-line)))
         (when (< (length elements) 4)
           (message "Not enough elements on DATE-LINE: %s" date-line)
           (message "   New attempt...")
           (with-temp-buffer
             (insert-file-contents file-full-name-slash-OK-accents-OK)
             (goto-char (point-min))
             (search-forward "Date:")
             (search-forward "Date:")
             (set-mark-command nil)
             (end-of-line)
             (setq date-line (buffer-substring (region-beginning) (region-end))))
           (when (null date-line)
             (error "No *2nd* 'Date:' line found in file %s" file-name-slash-OK-accents-OK))
           (setq elements (split-string date-line))
           (when (< (length elements) 4)
             (error "On 2nd attemp, not enough elements on DATE-LINE: %s" date-line)))
         (let* ((day (string-to-number (nth 1 elements)))
                (month (nth 2 elements))                 ; Jan...Dec
                (month2 (english-month-to-number month)) ; 1...12
                (year (string-to-number (nth 3 elements)))
                (yyyy-mm-dd (format "%04d-%02d-%02d" year month2 day))
                (file1-old-name file-name)
                (file1-new-name (concat file-directory yyyy-mm-dd " _" file1-old-name)))
           
           (rename-file file1-old-name file1-new-name)
           (message "Date (%s) added at the beginning of file '%s'" yyyy-mm-dd file1-old-name)
           (revert-buffer)
           (dired-goto-file file1-new-name)))))) ; end of defun
 
 ) ; end of init section



;;; end of init--external-tools.el
