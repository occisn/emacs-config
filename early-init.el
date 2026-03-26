;;; -*- lexical-binding: t; -*-

(message "Entering early-init file...")

;; GC: disable during init
(setq gc-cons-threshold most-positive-fixnum)

;; Disable file-name-handler-alist during init
(defvar init--file-name-handler-alist-original file-name-handler-alist)
(setq file-name-handler-alist nil)

;; Don't load packages before init.el runs
(setq package-enable-at-startup nil)

;; Suppress splash screen
(setq inhibit-startup-screen t)
(setq inhibit-startup-message t)

;; Prevent frame resize flicker during font/UI setup
(setq frame-inhibit-implied-resize t)

;; Disable GUI chrome before first frame draws (avoids resize flash)
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)

;;; end
