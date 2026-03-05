;;; -*- lexical-binding: t; byte-compile-warnings: (not docstrings docstrings-wide) -*-

;;; ===
;;; ================
;;; ===== HTML =====
;;; ================

(my-init--with-duration-measured-section 
 t 
 "HTML"

 (defun my/save-region-as-html (temp-file-name)
   "Save region, otherwise buffer to HTML file.
(v1, available in occisn/emacs-utils GitHub repository)"
   (cl-labels ((replace-regexp (a b)
                 ""
                 (while (re-search-forward a nil t)
                   (replace-match b)))

               (html-add-b-u-i-br-tags ()
                 "Within an existing buffer, add <b></b> <u></u> <i></i> and <br/> tags."
                 (let ((p nil))
                   (goto-char 1)
                   (setq p (point))
                   (replace-regexp "’" "'")
                   (goto-char p)
                   (replace-regexp "\\*\\(.*?\\)\\*" "<b>\\1</b>")
                   (goto-char p)
                   (replace-regexp "_\\(.*?\\)_" "<u>\\1</u>")
                   (goto-char p)
                   (replace-regexp "\\([^<]\\)\\/\\([^ ].*?[^ ]\\)\\/" "\\1<i>\\2</i>")
                   (goto-char p)
                   (while (search-forward "\n" nil t) (replace-match "<br/>" nil t)) ; \r\n
                   ;; for line above, refer to https://stackoverflow.com/questions/5194294/how-to-remove-all-newlines-from-selected-region-in-emacs
                   (goto-char p)))) ; end of labels definitions
     
     (let* ((regionp (region-active-p))
            (beg (and regionp (region-beginning)))
            (end (and regionp (region-end)))
            (buf (current-buffer)))
       (when (file-exists-p temp-file-name) (delete-file temp-file-name))
       (with-temp-buffer
         (insert-buffer-substring buf beg end)
         (html-add-b-u-i-br-tags)
         (insert "<?xml version=\"1.0\" encoding=\"utf-8\"?>")
         (insert "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\"
\"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">")
         (insert "<html xmlns=\"http://www.w3.org/1999/xhtml\" lang=\"en\" xml:lang=\"en\">")
         (insert "<html>")
         (insert "<head>")
         (insert "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\"/>")
         (insert "</head>")
         (insert "<body>")
         ;;(insert "<pre white-space=\"-moz-pre-wrap\">")
         (insert "<font face='Calibri'>") ; size=\"-1\" 
         (insert "<div style=\"white-space: pre-wrap;\">")
         (insert "<div style=\"font-size:14.5px\">") ; to have Calibri 11
         (goto-char (point-max))
         (insert "</div>")            ; font-size
         (insert "</div>")            ; white-space
         (insert "</font>")
         ;;(insert "</pre>")
         (insert "</body>")
         (insert "</html>")
         ;; (set-buffer-file-coding-system 'utf-8)

         ;; (2) Save buffer as temporary HTML file
         (write-file temp-file-name)
         (kill-buffer)))))

 ;; https://www.html.am/reference/html-special-characters.cfm

 ) ; end of init section


;;; ===
;;; ===============
;;; ===== IRC =====
;;; ===============

;; M-x erc
;; (do not forget to indicate password)
;; /join #lisp
;; or #emacs

;;; ===
;;; ===============
;;; ===== FTP =====
;;; ===============

;; void

;;; ===
;;; ==============================
;;; ===== REST GET POST HTTP =====
;;; ==============================

;; (require 'restclient)
;; M-x restclient-mode
;; then C-c C-c

;;; ===
;;; =================
;;; ===== TRAMP =====
;;; =================

;;; void


;;; end of init--network.el
