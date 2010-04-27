(in-package :cl-user)

(defpackage :mwiki-asd
  (:use :cl :asdf))

(in-package :mwiki-asd)

(defsystem mwiki
  :name "mwiki"
  :version "0.1"
  :author "Jesse Alama <jesse.alama@gmail.com>"
  :maintainer "Jesse Alama <jesse.alama@gmail.com>"
  :license "GPL"
  :description "A collaborative web site for working with mizar articles"
  :long-description ""
  :components ((:file "packages")
	       (:file "site" :depends-on ("packages")))
  :depends-on (:cl-fad
	       :bordeaux-threads
	       :parenscript
	       :hunchentoot))