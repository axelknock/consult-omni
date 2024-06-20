;;; consult-omni-duckduckgo.el --- Consulting DuckDuckGo -*- lexical-binding: t -*-

;; Copyright (C) 2024 Armin Darvish

;; Author: Armin Darvish
;; Maintainer: Armin Darvish
;; Created: 2024
;; Version: 0.1
;; Package-Requires: ((emacs "28.1") (consult "1.1") (consult-omni "0.2"))
;; Homepage: https://github.com/armindarvish/consult-omni
;; Keywords: convenience

;;; Commentary:

;;; Code:

(require 'consult-omni)

(defvar consult-omni-duckduckgo-api-url "http://api.duckduckgo.com/")

(defvar consult-omni-duckduckgo-search-url "https://duckduckgo.com/")

(cl-defun consult-omni--duckduckgoapi-fetch-results (input &rest args &key callback &allow-other-keys)
  "Fetch search results got INPUT from DuckDuckGo limited API.

See URL `https://duckduckgo.com/duckduckgo-help-pages/settings/params/'
for some limited documentation"
  (pcase-let* ((`(,query . ,opts) (consult-omni--split-command input))
               (opts (car-safe opts))
               (count (plist-get opts :count))
               (page (plist-get opts :page))
               (extra-args (seq-difference (append opts args) '(:count count :page page)))
               (count (or (and count (integerp (read count)) (string-to-number count))
                          consult-omni-default-count))
               (page (or (and page (integerp (read page)) (string-to-number page))
                         consult-omni-default-page))
               (count (min count 10))
               (page (+ (* page count) 1))
               (params `(("q" . ,input)
                   ("format" . "json")))
               (headers `(("Accept" . "application/json"))))
    (consult-omni--fetch-url consult-omni-duckduckgo-api-url consult-omni-http-retrieve-backend
                            :encoding 'utf-8
                            :params params
                            :headers headers
                            :parser #'consult-omni--json-parse-buffer
                            :callback
                            (lambda (attrs)
                              (let* ((raw-results (gethash "RelatedTopics" attrs))
                                     (annotated-results
                                           (mapcar (lambda (item)
                                                     (let*
                                                         ((source "DuckDuckGo API")
                                                          (url (gethash "FirstURL" item))
                                                          (title (gethash "Result" item))
                                                          (title (if (string-match "<a href=.*>\\(?1:.*\\)</a>.*" title) (match-string 1 title) ""))
                                                          (snippet (format "%s" (gethash "Text" item)))

                                                          (search-url (consult-omni--make-url-string consult-omni-duckduckgo-search-url params '("format")))

                                                          (decorated (funcall consult-omni-default-format-candidate :source source :query query :url url :search-url search-url :title title :snippet snippet)))
                                                       (propertize decorated
                                                                   :source source
                                                                   :title title
                                                                   :url url
                                                                   :search-url search-url
                                                                   :query query
                                                                   )))

                                                   raw-results)))
                                (when annotated-results
                                  (funcall callback annotated-results))
                                annotated-results)))))

(consult-omni-define-source "DuckDuckGo API"
                           :narrow-char ?d
                           :type 'dynamic
                           :face 'consult-omni-engine-source-face
                           :request #'consult-omni--duckduckgoapi-fetch-results
                           :preview-key consult-omni-preview-key
                           :search-history 'consult-omni--search-history
                           :selection-history 'consult-omni--selection-history
                           :enabled (lambda () (bound-and-true-p consult-omni-duckduckgo-search-url))
                           :group #'consult-omni--group-function
                           :sort t
                           :static nil
                           :annotate nil
                           )

;;; provide `consult-omni-duckduckgo' module

(provide 'consult-omni-duckduckgo)

(add-to-list 'consult-omni-sources-modules-to-load 'consult-omni-duckduckgo)
;;; consult-omni-duckduckgo.el ends here