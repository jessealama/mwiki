;;; mwiki.asd ASDF system definition for mwiki

(in-package :cl-user)

(defpackage :mwiki-asd
  (:use :cl :asdf))

(in-package :mwiki-asd)

(defsystem :mwiki
  :description "Tools for interacting with the mizar wiki"
  :long-description ""
  :author "Jesse Alama <jesse.alama@gmail.com>"
  :maintainer "Jesse Alama <jesse.alama@gmail.com>"
  :serial t
  :depends-on ("hunchentoot" "alexandria" "cl-ppcre" "com.gigamonkeys.pathnames")
  :components ((:file "packages")
	       (:file "parse-article")))

;;; mwiki.asd ends here