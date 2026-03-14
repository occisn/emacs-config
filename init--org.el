;;; -*- lexical-binding: t; byte-compile-warnings: (not docstrings docstrings-wide) -*-

;;; ===
;;; ====================
;;; ===== ORG-MODE =====
;;; ====================

(my-init--with-duration-measured-section
 t
 "org-mode A"

 ;; to unindent :
 ;; unfold then deselect all
 ;; then C-x C-i LEFT LEFT LEFT LEFT...
 ;; see https://stackoverflow.com/questions/22388868/how-can-i-indent-a-paragraph-of-plain-text-in-emacs-org-mode

 (setq org-startup-indented nil)


 (setq org-modules nil) ; Stop Org from loading any default extra modules
 ;; 44% of the org-mode start-up time was spent on org-load-modules-maybe
 ;; org-modules was containig (ol-doi ol-w3m ol-bbdb ol-bibtex ol-docview ol-gnus ol-info ol-irc ol-mhe ol-rmail ol-eww)

 
 ) ; end of init section


(my-init--with-duration-measured-section 
 t
 "org-mode B (require org)"
 
 ;; (require 'org)

 ) ; end of init section


(my-init--with-duration-measured-section 
 t 
 "org-mode C1"
 
 ;; Highlight bold, etc:
 (defvar org-emphasis-alist) ; to avoid compilation warning
 (with-eval-after-load 'org
   (if (my-init--dark-background-p)
       (add-to-list 'org-emphasis-alist '("*" (bold :foreground "yellow")))
     (add-to-list 'org-emphasis-alist '("*" (bold :foreground "blue"))))
   ;; ref: https://github.com/syl20bnr/spacemacs/blob/develop/doc/FAQ.org#why-do-some-of-my-org-related-settings-cause-problems
   )
 
 (when nil
   (with-eval-after-load 'org
     (setq org-emphasis-alist
           '(("*" (bold :foreground "Orange" ))
             ("/" italic)
             ("_" underline)
             ("=" (:background "maroon" :foreground "white"))
             ("~" (:background "deep sky blue" :foreground "MidnightBlue"))
             ("+" (:strike-through t))))))
 ;; source : https://emacs.stackexchange.com/questions/44081/how-to-tweak-org-emphasis-alist-to-put-e-g-neon-yellow-over-bold-or-italic

 ;; hide bold and italics marks in org-mode:
 (when nil
   (setq org-hide-emphasis-markers t))
 ;; source:  https://howardism.org/Technical/Emacs/orgmode-wordprocessor.html

 ;; do not deleted invisible text:
 (setq-default org-catch-invisible-edits 'smart) 

 ;; enable syntax highlighting for powershell source blocks
 (with-eval-after-load 'org
   (add-to-list 'org-src-lang-modes '("powershell" . powershell)))

 ;; disable C-TAB in org-mode so that this key binding could be used
 ;; to change tab
 (with-eval-after-load 'org
   (define-key org-mode-map [(control tab)] nil)
   ;; https://stackoverflow.com/questions/4333467/override-ctrl-tab-in-emacs-org-mode
   )
 
 (declare-function org-occur "org")
 ;; the above to avoid:
 ;;  the function ‘org-occur’ might not be defined at runtime.
 (defun my/org-occur-and-hide-content ()
   "Interactively call `org-occur' and hide body lines after."
   (interactive)
   (call-interactively #'org-occur)
   (outline-hide-body))
 ;; source: https://emacs.stackexchange.com/questions/53208/show-headings-only-in-sparse-tree

 (when nil
   (require 'centered-cursor-mode) ; à transformer en use-package / commands
   (centered-cursor-mode)
   ;; https://davidbosman.fr/tux/post/emacs-typewriter-mode/
   )) ; end of init section

(my-init--with-duration-measured-section 
 t 
 "org-mode C2 (embedded images)"

 ;; C-c C-x C-v to make images appear

 ;; images:
 (setq org-startup-with-inline-images nil)

 (declare-function org-insert-link "org")
 (with-eval-after-load 'org
   (defun my/paste-image-from-clipboard-as-link ()
     "Paste image from clipboard to the current org-mode buffer as link. The image itself is pasted into the directory of the org file."
     (interactive)
     (unless (string= major-mode "org-mode")
       (error "Trying to paste image from clipboard while not in org-mode"))
     (cl-labels ((string-remove-surrounding-quotes (s)
                   "Remove quotes at the beginning and at the end of a string.
(v1, available in occisn/elisp-utils GitHub repository)"
                   (aprogn
                    s
                    (string-remove-prefix "\"" it)
                    (string-remove-suffix "\"" it)))
                 (paste-image-from-clipboard-to-file-with-imagemagick (destination-file-with-path)
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
                       (call-process-shell-command cmd nil 0))))) ; end of labels definitions
       (let* (
              ;; Ask for sub-directory name ; if "pics" already exists, propose it as default
              (subdirectory-name
               (if (file-directory-p (concat default-directory "pics/"))
                   (read-string "Subdirectory: " "pics")
                 (read-string "Subdirectory: ")))
              (subdirectory-path
               (if (string= "" subdirectory-name)
                   default-directory
                 (let ((res (concat default-directory subdirectory-name "/")))
                   (unless (file-directory-p res)
                     (make-directory res)
                     (message "Creating directory \"%s\" within %s" subdirectory-name default-directory))
                   res)))
              ;; Ask for file name:
              (file-short-name (concat
                                (read-string "File name without date-hour completion and suffix (default:pic): " nil nil "pic")
                                (format-time-string "_%Y%m%d_%H%M%S")
                                ".png"))
              ;; Build destination path:
              (destination-file-with-path (concat "\"" subdirectory-path file-short-name "\"")))
         ;; Paste to file:
         (paste-image-from-clipboard-to-file-with-imagemagick destination-file-with-path)
         ;; Add link:
         (org-insert-link t (concat "file:" (string-remove-surrounding-quotes destination-file-with-path)))
         ;; (org-display-inline-images)
         )))) ; end of defun
 ) ; end of init section

(my-init--with-duration-measured-section 
 t 
 "org-mode C3 (embedded LaTeX)"

 ;; Highlight LaTeX:
 ;; (setq org-highlight-latex-and-related '(latex)) ; attention, peut ralentir considérablement org-mode ; see notes
 ;; Then inline latex like $y=mx+c$ will appear in a different colour in an org-mode file to help it stand out.
 ;; Caution
 (when nil
   (setq org-highlight-latex-and-related nil))
 
 ;; LaTeX fragments: change the directory for storage of temporary pics:
 (when nil
   (setq-local org-preview-latex-image-directory *latex-preview-pics-directory*))
 ;; ref : https://emacs.stackexchange.com/questions/16392/rendering-latex-code-inside-begin-latex-end-latex-in-org-mode-8-3-1
 ;; but directory seems empty?
 
 ;; C-c C-x C-l (org-latex-preview) to preview forms as:
 ;;   $\int_a^b x^2\mathrm{d}x$
 ;;   If $a^2=b$ and \( b=2 \), then the solution must be either $$ a=+\sqrt{2} $$ or \[ a=-\sqrt{2} \].
 ;; C-u C-x C-x C-l to cancel preview

 ;; works also with complete LaTeX environments
 ;;    \begin{equation}
 ;;    y=a+b
 ;;    \end{equation}

 ;; In order formulas to be visible as soon as the document is open:
 ;; # + STARTUP: latexpreview

 ;; In order formulas to be visible at each save,
 ;; add at the end of the document with a # and a space before each line:
 ;;    L ocal variables:
 ;;    a fter-save-hook: org-preview-latex-fragment
 ;;    e nd:
 ;; See https://emacs.stackexchange.com/questions/38198/automatically-preview-latex-in-org-mode-as-soon-as-i-finish-typing
 ) ; end of init section

(my-init--with-duration-measured-section 
 t
 "org-mode C4 (agenda)"

 (define-key global-map "\C-ca" 'org-agenda)

 (defun my/org-agenda-switch-to-perso-file ()
   (interactive)
   (find-file *F10-file-perso*))
 
 ) ; end of init section

(my-init--with-duration-measured-section 
 t
 "org-mode D (babel and source blocks)"

 ;; source blocks:
 (declare-function org-babel-mark-block "org") ; to avoid compilation warning
 (declare-function org-babel-goto-src-block-head "org") ; to avoid compilation warning
 (declare-function org-hide-block-toggle "org") ; ; to avoid compilation warning
 (with-eval-after-load 'org
   (defun my/copy-block ()
     (interactive)
     (call-interactively 'set-mark-command) ; sets mark A
     (org-babel-mark-block)  ; mark (select) src block = C-c C-v C-M-h
     (kill-new (buffer-substring (region-beginning) (region-end))) ; copy region
     (deactivate-mark)                      ; suppress highlighting
     (setq current-prefix-arg '(4))         ; C-u
     (call-interactively 'set-mark-command) ; to end of region
     (setq current-prefix-arg '(4))
     (call-interactively 'set-mark-command) ; to mark A
     (org-babel-goto-src-block-head)        ; go to beginning of block
     (org-fold-hide-block-toggle)           ; fold block
     ;; ‘org-hide-block-toggle’ is an obsolete function (as of 9.6); use ‘org-fold-hide-block-toggle’ instead.
     (message "src block copied to clipboard, and folded")))
 ;; ‘org-hide-block-toggle’ is an obsolete function (as
 ;;    of 9.6); use ‘org-fold-hide-block-toggle’ instead.

 ) ; end of init section

(my-init--with-duration-measured-section
 t
 "org-mode E (copy block)"

 (defun my/org-copy-link-or-inline-code-or-verbatim-or-block ()
   "Copy link, inline code between = or ~ signs in org-mode, or content of org block.
Fallback : current word.
(v2, available in occisn/emacs-utils GitHub repository)"
   (interactive)
   (let ((found nil))
     
     ;; (1) inline code?
     (let ((start-pos (point)))
       (save-excursion
         ;; Find the opening = before cursor
         (when (re-search-backward "=" (line-beginning-position) t)
           (let ((open-pos (point)))
             (goto-char start-pos)
             (when (re-search-forward "=" (line-end-position) t)
               (let ((close-pos (point)))
                 (when (and (> start-pos open-pos) (< start-pos close-pos))
                   (let ((content (buffer-substring-no-properties (1+ open-pos) (1- close-pos))))
                     (when (and (> (length content) 0)
                                (not (string-match-p "\n" content)))
                       (kill-new content)
                       (setq found t)
                       (message "Copied inline code: %s" content))))))))))
     
     ;; (2) inline verbatim?
     (unless found
       (let ((start-pos (point)))
         (save-excursion
           ;; Find the opening = before cursor
           (when (re-search-backward "~" (line-beginning-position) t)
             (let ((open-pos (point)))
               (goto-char start-pos)
               (when (re-search-forward "~" (line-end-position) t)
                 (let ((close-pos (point)))
                   (when (and (> start-pos open-pos) (< start-pos close-pos))
                     (let ((content (buffer-substring-no-properties (1+ open-pos) (1- close-pos))))
                       (when (and (> (length content) 0)
                                  (not (string-match-p "\n" content)))
                         (kill-new content)
                         (setq found t)
                         (message "Copied inline verbatim: %s" content)))))))))))
     
     ;; (3) org block?
     (unless found
       (let ((content-begin nil)
             (content-end nil)
             (element (org-element-context)))
         ;; (message "element = %s" element)
         ;; (message "(org-element-type element) = %s" (org-element-type element))
         (while (and element
                     (not (memq (org-element-type element)
                                '(src-block example-block export-block quote-block verse-block center-block special-block comment-block))))
           ;; (message "element = %s" element)
           ;; (message "(org-element-type element) = %s" (org-element-type element))
           (setq element (org-element-property :parent element)))
         (when element
           (save-excursion
             (goto-char (org-element-property :begin element))
             (forward-line 1)
             (setq content-begin (point))
             (re-search-forward "^#\\+END_" (org-element-property :end element) t)
             (beginning-of-line)
             (setq content-end (point))
             (kill-ring-save content-begin content-end)
             (setq found t)
             (message "Org block content copied.")))))

     ;; (4) Link in org-mode ?
     (unless found
       (let ((url (thing-at-point 'url t)))
         (when url
           (setq found t)
           (kill-new url)
           (message "Copied link: %s" url))))

     ;; (5) Word ?
     (unless found
       (set found (my/copy-word)))
     
     (unless found
       (message "No word, link, inline code, verbatim text or block found at point."))))

 (with-eval-after-load 'org
   (define-key org-mode-map (kbd "C-c c") #'my/org-copy-link-or-inline-code-or-verbatim-or-block))

 ) ; end of init section

(my-init--with-duration-measured-section
 t
 "org-mode F (copy to clipboard with format conversion)"

 (when (and *my-init--linux-p* (not (executable-find "xclip")))
   (my-init--warning "!! xclip not found in PATH (needed for org clipboard HTML copy/paste)"))

 (defun my/org-copy-region-ready-to-be-pasted-into-Word-Teams-Thunderbird-Gmail ()
   "Export Org-mode region to Windows CF_HTML clipboard format (including StartHTML, EndHTML, StartFragment, EndFragment markers).
Clipboard can be pasted into Microsoft Word, Microsoft Teams, Thunderbird and Gmail.
(v1 as of 2025-10-28, available in occisn/emacs-utils GitHub repository)"
   (interactive)
   (unless (or *my-init--windows-p* *my-init--linux-p*)
     (user-error "Clipboard export not supported on this platform"))
   (if (not (use-region-p))
       (message "No active region to export")
     (let* ((region-start (region-beginning))
            (region-end (region-end))
            (html-body (org-export-string-as
                        (buffer-substring region-start region-end)
                        'html t '(:with-toc nil
                                            :html-postamble nil
                                            :preserve-breaks t))))

       ;; Extract body content and replace <p> tags with <br>
       (setq html-body
             (with-temp-buffer
               (insert html-body)
               (goto-char (point-min))
               (if (re-search-forward "<body[^>]*>\\(\\(.\\|\n\\)*\\)</body>" nil t)
                   (match-string 1)
                 html-body)))

       ;; Replace paragraph tags with line breaks
       (setq html-body
             (replace-regexp-in-string "<p[^>]*>" "" html-body))
       (setq html-body
             (replace-regexp-in-string "</p>" "<br>" html-body))

       (cond
        ;; === Windows: CF_HTML via PowerShell ===
        (*my-init--windows-p*
         (let* ((html-fragment (concat "<!--StartFragment-->" html-body "<!--EndFragment-->"))
                (html-full (concat "<html>\n<body>\n" html-fragment "\n</body>\n</html>"))
                (header "Version:0.9\nStartHTML:%010d\nEndHTML:%010d\nStartFragment:%010d\nEndFragment:%010d\n")
                (header-length (length (format header 0 0 0 0)))
                (start-html header-length)
                (end-html (+ start-html (string-bytes html-full)))
                (start-fragment (+ start-html
                                   (string-bytes (substring html-full 0 (string-match "<!--StartFragment-->" html-full)))
                                   (string-bytes "<!--StartFragment-->")))
                (end-fragment (+ start-html (string-bytes (substring html-full 0 (string-match "<!--EndFragment-->" html-full)))))
                (cf-html (concat (format header start-html end-html start-fragment end-fragment)
                                 html-full)))
           (let ((temp-file (make-temp-file "cf-html-" nil ".txt")))
             (with-temp-file temp-file
               (set-buffer-file-coding-system 'utf-8-unix)
               (insert cf-html))
             (call-process "powershell.exe" nil nil nil
                           "-Command"
                           (format "$content = Get-Content -Path '%s' -Raw -Encoding UTF8; Add-Type -AssemblyName System.Windows.Forms; $data = New-Object System.Windows.Forms.DataObject; $bytes = [System.Text.Encoding]::UTF8.GetBytes($content); $stream = New-Object System.IO.MemoryStream(,$bytes); $data.SetData('HTML Format', $stream); [System.Windows.Forms.Clipboard]::SetDataObject($data, $true); $stream.Close()"
                                   (replace-regexp-in-string "/" "\\\\" temp-file)))
             (delete-file temp-file)
             (message "Region copied as CF_HTML to clipboard"))))

        ;; === Linux: HTML via xclip ===
        (*my-init--linux-p*
         (unless (executable-find "xclip")
           (user-error "xclip not found — install with: sudo apt install xclip"))
         (let ((html-full (concat "<html><body>" html-body "</body></html>")))
           (with-temp-buffer
             (insert html-full)
             (call-process-region (point-min) (point-max)
                                  "xclip" nil nil nil
                                  "-selection" "clipboard"
                                  "-t" "text/html"))
           (message "Region copied as HTML to clipboard via xclip")))))))
 
 (defun my/PREVIOUS-org-copy-to-clipboard-for-microsoft-word-and-teams ()
   "Copy buffer to clipboard as HTML.
Clipboard can then be pasted to Microsoft Word or Microsoft Teams. 
But pasting to Thunderbird or Gmail does not work.
Requires my/save-region-as-html."
   (unless (my-init--directory-exists-p *temp-directory*)
     (error "Temp directory is not valid: %s" *temp-directory*))
   (let* ((temp-file-name (concat *temp-directory* "org_mode_export_to_outlook_temp.html"))
          (cmd (concat "powershell -Command \"Get-Content '" temp-file-name "' | Set-Clipboard -AsHtml\"")))

     ;; (1) Convert to HTML and save in file
     (my/save-region-as-html temp-file-name)

     ;; (2) copy temporary file to clipboard as HTML: 
     (call-process-shell-command cmd nil 0)
     ;; (message cmd)
     (message "Content of the buffer exported to clipboard as HTML.")))
 
 (defun my/PREVIOUS-org-export-to-html-page-for-thunderbird-outlook-or-gmail ()
   "Convert buffer to html page and open it.
Requires my/save-region-as-html."
   (unless (my-init--directory-exists-p *temp-directory*)
     (error "Temp directory is not valid: %s" *temp-directory*))
   (let* ((temp-file-name (concat *temp-directory* "org_mode_export_to_outlook_temp.html"))
          (cmd (concat "powershell -Command \"& {type '" temp-file-name "' | Set-Clipboard -AsHtml}\"")))

     ;; (1) Convert to HTML and save in file
     (my/save-region-as-html temp-file-name)

     ;; (2) copy temporary file to clipboard as HTML: 
     ;; (w32-shell-execute 1 temp-file-name)
     ))

 ) ; end of init section

(my-init--with-duration-measured-section
 t
 "org-mode G (copy/paste from clipboard with format conversion)"

 (defun my/paste-clipboard-as-raw-html ()
   "Insert raw HTML from clipboard into current buffer, with visible tags.
On Windows uses CF_HTML via PowerShell; on Linux uses xclip.
(v2 as of 2026-03-14, available in occisn/emacs-utils GitHub repository)"
   (interactive)
   (unless (or *my-init--windows-p* *my-init--linux-p*)
     (user-error "Clipboard HTML paste not supported on this platform"))
   (let* ((html-raw
           (cond
            (*my-init--windows-p*
             (with-temp-buffer
               (call-process
                "powershell.exe" nil t nil
                "-NoProfile" "-Command"
                "Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.Clipboard]::GetText([System.Windows.Forms.TextDataFormat]::Html)")
               (buffer-string)))
            (*my-init--linux-p*
             (unless (executable-find "xclip")
               (user-error "xclip not found — install with: sudo apt install xclip"))
             (with-temp-buffer
               (call-process "xclip" nil t nil
                             "-selection" "clipboard"
                             "-t" "text/html" "-o")
               (buffer-string)))))
          ;; Extract fragment between <!--StartFragment--> and <!--EndFragment-->
          (fragment
           (if (string-match "<!--StartFragment-->\\(.*\\)<!--EndFragment-->" html-raw)
               (match-string 1 html-raw)
             html-raw)))
     (insert fragment)))

 (defun my/html-to-org (html)
   "Convert HTML string to org-mode format.
(v1 as of 2025-10-29, available in occisn/emacs-utils GitHub repository)"
   (with-temp-buffer
     (insert html)
     ;; Convert common HTML elements to org-mode
     (goto-char (point-min))
     
     ;; Headers (h1-h6)
     (dolist (level '(6 5 4 3 2 1))
       (goto-char (point-min))
       (let ((stars (make-string level ?*)))
         (while (re-search-forward (format "<h%d[^>]*>\\(.*?\\)</h%d>" level level) nil t)
           (replace-match (format "%s \\1" stars)))))
     
     ;; Bold
     (goto-char (point-min))
     (while (re-search-forward "<\\(b\\|strong\\)[^>]*>\\(.*?\\)</\\(b\\|strong\\)>" nil t)
       (replace-match "*\\2*"))
     
     ;; Italic
     (goto-char (point-min))
     (while (re-search-forward "<\\(i\\|em\\)[^>]*>\\(.*?\\)</\\(i\\|em\\)>" nil t)
       (replace-match "/\\2/"))
     
     ;; Code
     (goto-char (point-min))
     (while (re-search-forward "<code[^>]*>\\(.*?\\)</code>" nil t)
       (replace-match "~\\1~"))
     
     ;; Links
     (goto-char (point-min))
     (while (re-search-forward "<a[^>]*href=\"\\([^\"]+\\)\"[^>]*>\\(.*?\\)</a>" nil t)
       (replace-match "[[\\1][\\2]]"))
     
     ;; Unordered lists
     (goto-char (point-min))
     (while (re-search-forward "<li[^>]*>\\(.*?\\)</li>" nil t)
       (replace-match "- \\1"))
     
     ;; Paragraphs (add newlines)
     (goto-char (point-min))
     (while (re-search-forward "<p[^>]*>\\(.*?\\)</p>" nil t)
       (replace-match "\\1\n"))
     
     ;; Line breaks
     (goto-char (point-min))
     (while (re-search-forward "<br[^>]*>" nil t)
       (replace-match "\n"))
     
     ;; Remove remaining HTML tags
     (goto-char (point-min))
     (while (re-search-forward "<[^>]+>" nil t)
       (replace-match ""))
     
     ;; Decode HTML entities
     (goto-char (point-min))
     (while (re-search-forward "&nbsp;" nil t)
       (replace-match " "))
     (goto-char (point-min))
     (while (re-search-forward "&amp;" nil t)
       (replace-match "&"))
     (goto-char (point-min))
     (while (re-search-forward "&lt;" nil t)
       (replace-match "<"))
     (goto-char (point-min))
     (while (re-search-forward "&gt;" nil t)
       (replace-match ">"))
     (goto-char (point-min))
     (while (re-search-forward "&quot;" nil t)
       (replace-match "\""))
     
     ;; Clean up extra whitespace
     (goto-char (point-min))
     (while (re-search-forward "\n\n\n+" nil t)
       (replace-match "\n\n"))
     
     (string-trim (buffer-string))))

 (defun my/org-paste-from-Teams-Word-as-org ()
   "Paste from clipboard and convert to org-mode format.
Content of the clipboard may come from Microsoft Teams, Word, or any HTML source.
On Windows uses CF_HTML via PowerShell; on Linux uses xclip.
Requires my/html-to-org.
(v2 as of 2026-03-14, available in occisn/emacs-utils GitHub repository)"
   (interactive)
   (unless (or *my-init--windows-p* *my-init--linux-p*)
     (user-error "Clipboard HTML paste not supported on this platform"))
   (let* ((html-content
           (cond
            (*my-init--windows-p*
             (let ((powershell-cmd "Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.Clipboard]::GetText([System.Windows.Forms.TextDataFormat]::Html)"))
               (shell-command-to-string
                (format "powershell.exe -Command \"%s\"" powershell-cmd))))
            (*my-init--linux-p*
             (unless (executable-find "xclip")
               (user-error "xclip not found — install with: sudo apt install xclip"))
             (shell-command-to-string
              "xclip -selection clipboard -t text/html -o 2>/dev/null")))))
     (if (string-empty-p (string-trim html-content))
         (message "No HTML content in clipboard")
       ;; Extract the actual HTML fragment (Windows clipboard includes metadata)
       (let* ((fragment-start (string-match "<!--StartFragment-->" html-content))
              (fragment-end (string-match "<!--EndFragment-->" html-content))
              (html (if (and fragment-start fragment-end)
                        (substring html-content
                                   (+ fragment-start (length "<!--StartFragment-->"))
                                   fragment-end)
                      html-content))
              (org-content (my/html-to-org html)))
         (insert org-content)))))

 (cl-defun my/org-region-to-markdown-clipboard ()
   "Convert Org-mode region to Markdown and copy to clipboard.
With prefix argument NO-TOC, suppress table of contents."
   (interactive)
   (if (use-region-p)
       (let* ((region-start (region-beginning))
              (region-end (region-end))
              (org-content (buffer-substring-no-properties region-start region-end))
              (no-toc t)
              (markdown-content
               (with-temp-buffer
                 (insert org-content)
                 (org-mode)
                 (let ((org-export-with-toc (not no-toc))
                       (org-export-preserve-breaks t)
                       (org-export-show-temporary-export-buffer nil))
                   (org-md-export-as-markdown))
                 (with-current-buffer "*Org MD Export*"
                   (prog1 (buffer-string)
                     (kill-buffer))))))
         (kill-new markdown-content)
         (message "Region converted to Markdown and copied to clipboard%s"
                  (if no-toc " (no TOC)" "")))
     (message "No region selected")))

 (defun my/markdown-region-to-org-clipboard ()
   "Convert Markdown region to Org-mode and copy to clipboard."
   (interactive)
   (if (use-region-p)
       (let* ((region-start (region-beginning))
              (region-end (region-end))
              (markdown-content (buffer-substring-no-properties region-start region-end))
              (mode1 "manually")
              (org-content
               (with-temp-buffer
                 (insert markdown-content)
                 ;; Use pandoc if available, otherwise basic conversion
                 (if (executable-find "pandoc2")
                     
                     (progn
                       (setq mode1 "with pandoc")
                       (shell-command-on-region (point-min) (point-max)
                                                "pandoc -f markdown -t org 2>NUL"
                                                (current-buffer) t)
                       ;; 2>NUL to avoid the warning:
                       ;;    [WARNING] input is not UTF-8 encoded: falling back to latin1.

                       ;; Remove trailing backslashes
                       (goto-char (point-min))
                       (while (re-search-forward "\\\\\\\\$" nil t)
                         (replace-match ""))
                       (buffer-string)) ; end of Pandoc branch

                   
                   ;; Fallback: basic manual conversion


                   (goto-char (point-min))
                   ;; Convert headers
                   (while (re-search-forward "^\\(#+\\) \\(.*\\)$" nil t)
                     (replace-match (concat (make-string (length (match-string 1)) ?*) 
                                            " " (match-string 2))))
                   ;; Convert bold **text** to temporary marker first
                   (goto-char (point-min))
                   (while (re-search-forward "\\*\\*\\([^*]+\\)\\*\\*" nil t)
                     (replace-match "⟨BOLD⟩\\1⟨/BOLD⟩"))
                   ;; Convert italic *text* to /text/
                   (goto-char (point-min))
                   (while (re-search-forward "\\*\\([^*]+\\)\\*" nil t)
                     (replace-match "/\\1/"))
                   ;; Convert italic _text_ to /text/
                   (goto-char (point-min))
                   (while (re-search-forward "_\\([^_]+\\)_" nil t)
                     (replace-match "/\\1/"))
                   ;; Now convert bold markers to org format
                   (goto-char (point-min))
                   (while (re-search-forward "⟨BOLD⟩\\([^⟨]+\\)⟨/BOLD⟩" nil t)
                     (replace-match "*\\1*"))
                   ;; Convert code `text` to =text=
                   (goto-char (point-min))
                   (while (re-search-forward "`\\([^`]+\\)`" nil t)
                     (replace-match "=\\1="))
                   ;; Convert links [text](url) to [[url][text]]
                   (goto-char (point-min))
                   (while (re-search-forward "\\[\\([^]]+\\)\\](\\([^)]+\\))" nil t)
                     (replace-match "[[\\2][\\1]]"))
                   (buffer-string)

                   
                   
                   
                   ))))
         (kill-new org-content)
         (message "Region converted to Org-mode (%s) and copied to clipboard" mode1))
     (message "No region selected")))

 (defun my--markdown-to-org-convert (text)
   "Convert markdown TEXT to org-mode format."
   (with-temp-buffer
     (insert text)
     (goto-char (point-min))
     
     ;; Convert headers (# to *)
     (while (re-search-forward "^\\(#+\\) " nil t)
       (replace-match (make-string (length (match-string 1)) ?*) nil nil nil 1))
     
     ;; Convert code blocks FIRST (```lang to #+BEGIN_SRC lang)
     ;; Track if we're opening or closing blocks
     (goto-char (point-min))
     (let ((in-block nil))
       (while (re-search-forward "^```\\([a-zA-Z0-9_+-]*\\)[ \t]*$" nil t)
         (let ((lang (match-string 1)))
           (if in-block
               (progn
                 (replace-match "#+END_SRC")
                 (setq in-block nil))
             (replace-match (format "#+BEGIN_SRC %s" lang))
             (setq in-block t)))))
     
     ;; Convert bold and italic in one pass to avoid interference
     ;; First handle bold: **text** or __text__ -> use placeholder
     (goto-char (point-min))
     (while (re-search-forward "\\*\\*\\([^*\n]+?\\)\\*\\*" nil t)
       (replace-match "⚿BOLD⚿\\1⚿BOLD⚿"))
     (goto-char (point-min))
     (while (re-search-forward "__\\([^_\n]+?\\)__" nil t)
       (replace-match "⚿BOLD⚿\\1⚿BOLD⚿"))
     
     ;; Now handle italic: *text* or _text_ -> /text/
     (goto-char (point-min))
     (while (re-search-forward "\\*\\([^*\n]+?\\)\\*" nil t)
       (replace-match "/\\1/"))
     (goto-char (point-min))
     (while (re-search-forward "_\\([^_\n]+?\\)_" nil t)
       (replace-match "/\\1/"))
     
     ;; Replace bold placeholders with org-mode bold
     (goto-char (point-min))
     (while (re-search-forward "⚿BOLD⚿\\([^⚿]+?\\)⚿BOLD⚿" nil t)
       (replace-match "*\\1*"))
     
     ;; Convert inline code (`code` to ~code~)
     (goto-char (point-min))
     (while (re-search-forward "`\\([^`]+\\)`" nil t)
       (replace-match "~\\1~"))
     
     ;; Convert links ([text](url) to [[url][text]])
     (goto-char (point-min))
     (while (re-search-forward "\\[\\([^]]+\\)\\](\\([^)]+\\))" nil t)
       (replace-match "[[\\2][\\1]]"))
     
     ;; Convert unordered lists (- or * to -)
     (goto-char (point-min))
     (while (re-search-forward "^\\([ \t]*\\)[*+-] " nil t)
       (replace-match "\\1- "))
     
     ;; Convert images (![alt](url) to [[url]])
     (goto-char (point-min))
     (while (re-search-forward "!\\[\\([^]]*\\)\\](\\([^)]+\\))" nil t)
       (replace-match "[[\\2]]"))
     
     (buffer-string)))

 (defun my/paste-markdown-as-org ()
   "Paste clipboard content, converting from markdown to org-mode format."
   (interactive)
   (let* ((markdown-text (current-kill 0))
          (org-text (my--markdown-to-org-convert markdown-text)))
     (insert org-text)))


 ) ; end of init section

(my-init--with-duration-measured-section 
 t
 "org-mode H (miscellaneous and hydra)"

;;; avoid electric indentation:
 (when (fboundp 'electric-indent-mode) (electric-indent-mode -1))

 (use-package olivetti
   :defer t
   :config (my-init--message-package-loaded "olivetti"))

 (defun my-org-occur ()
   (interactive)
   (occur ";;;\\s-===\\|^;;;\\s-===")
   ;; if "^" at the beginning: beginning of line
   )

 (defun my/switch-between-language-org-files ()
   "When in code buffer, switch between 'en' and 'fr' files. Useful when working on website."
   (interactive)
   (let* ((buffer-file-name1 (buffer-file-name)) ; c:/.../abc.org
          (target
           (cond ((string-match "/en/" buffer-file-name1)
                  (replace-regexp-in-string "/en/" "/fr/" buffer-file-name1))
                 ((string-match "/fr/" buffer-file-name1)
                  (replace-regexp-in-string "/fr/" "/en/" buffer-file-name1))
                 (t (error "Neither '/en/' or '/fr/' found in file path: %s" buffer-file-name1)))))
     (find-file target)))

 (defun my-org-fontify-dollar-words ()
   "Fontify words beginning with $ followed by letters as verbatim in org-mode."
   (font-lock-add-keywords
    nil
    '(("\\$[a-zA-Z]+" 0 'org-verbatim prepend))
    ;; org-code to be displayed as code
    ))

 (add-hook 'org-mode-hook 'my-org-fontify-dollar-words)

 (defhydra hydra-org-mode (:exit t :hint nil)
   "
^Org-mode hydra:
^---------------
[h]: occur in headlines (based on org-occur)
[o]: occur in all document || M-x occur (M-s o) || [c] : my occur
Navigate in text: C-UP or C-DOWN to move by paragraphs | M-h to select paragraph
                  Alt-V to scroll up | C-v to scroll down
                  C-c C-SPC ace jump | C-l to center screen
                  C-SPC to mark | C-u C-SPC to go to previous mark
         in tree: C-c C-n or C-c C-p to move by heading | C-c C-b or C-c C-f same level
                  C-c C-u to move to parent heading
         search in headings : C-s [swiper] * foo | C-M-s > ^*.* foo > C-s or C-r
Blocks: copy src [b]lock || C-(cvu) to go to block header || TAB sur BEGIN ou END || (org-show-all) (org-hide-block-all)
                   #+STARTUP: hideblocks #+STARTUP: nohideblocks
Embedded: C-c C-x C-v = org-toggle-inline-images ; #+ STARTUP: inlineimages
          LaTeX : C-c C-x C-l ; #+ STARTUP: latexpreview
Tree: TAB and Shift-TAB to develop or reduce the current or whole tree
      M-(SHIFT-)LEFT to modify the current level (so Ctrl to move)
      M-UP to move a block
      [n], [w]: narrow (C-x n s or M-x org-narrow-to-subtree) then widen (C-x n w or M-x widen)
      C-c / r : sparse-tree
Links: C-c C-l to create or edit [ [file:abc][name] ], [ [myimage.png] ]
       C-c C-o to follow
Abbrev: C-_, C-q SPACE, M-x unexpand-abbrev
Table: C-c } to see raw/col # | C-c C-c to update (in TBLFM) |  org-table-export pour exporter une table en CSV | M-S-RIGHT to insert column
Appearance : [v] olivetti-mode
[e] : import/export
Agenda: C-c a a || C-c a 1 pour custom ; et C-a t pour tasks
LaTeX fragments: C-c C-x C-l (org-toggle-latex-fragment)
Web site: [s]witch between FR and EN org files"
   ("b" #'my/copy-block)
   ("c" #'my-org-occur)
   ("e" #'hydra-org-export/body)
   ;; ("d" #'my/ispell-show-personal-directories)
   ("h" #'my/org-occur-and-hide-content)
   ("n" #'org-narrow-to-subtree)
   ("o" #'org-occur)
   ("s" #'my/switch-between-language-org-files)
   ("v" #'olivetti-mode)
   ("w" #'widen)
   ("1" #'my/org-agenda-switch-to-perso-file)
   ("<kp-1>" #'my/org-agenda-switch-to-perso-file)) ; end of hydra

 (defhydra hydra-org-export (:exit t :hint nil)
   "
^Org-mode import/export hydra:
^-----------------------------

Copy from org to clipboard, under following format:
   [1] Word / Teams / Thunderbird / Gmail (Windows: CF_HTML, Linux: xclip)
   [2] markdown

Paste into org-mode from clipboard under following format:
   [3] from Word / Teams / HTML into org (Windows: CF_HTML, Linux: xclip)
   [4] from markdown into org
"
   ("1" #'my/org-copy-region-ready-to-be-pasted-into-Word-Teams-Thunderbird-Gmail)
   ("2" #'my/org-region-to-markdown-clipboard)
   ("3" #'my/org-paste-from-Teams-Word-as-org)
   ("4" #'my/paste-markdown-as-org)
   ) ; end of hydra
 
 ) ; end of init section



;;; end of init--org.el
