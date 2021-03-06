(in-package :cl-user)

(defpackage :mwiki-asd
  (:use :cl :asdf))

(in-package :mwiki-asd)

(defsystem mwiki
  :name "mwiki"
  :version "0.1"
  :author "Jesse Alama <jesse.alama@gmail.com> and Josef Urban <josef.urban@gmail.com>"
  :maintainer "Jesse Alama <jesse.alama@gmail.com> and Josef Urban <josef.urban@gmail.com>"
  :license "GPL"
  :description "A collaborative web site for working with mizar articles"
  :long-description ""
  :components ((:file "packages")
	       (:file "xhtml-utils" :depends-on ("packages"))
	       (:file "user" :depends-on ("packages"))
	       (:file "mizar-article" :depends-on ("article"))
	       (:file "coq-article" :depends-on ("article"))
	       (:file "repo" :depends-on ("packages"))
	       (:file "notebook" :depends-on ("repo"))
	       (:file "mizar-notebook" :depends-on ("notebook"))
	       (:file "mizar-library" :depends-on ("packages"))
	       (:file "article" :depends-on ("packages"))
	       (:file "site" :depends-on ("packages"
					  "xhtml-utils"
					  "mizar-library")))
  :depends-on (:cl-fad
	       :bordeaux-threads
	       :cl-who
	       :parenscript
	       :usocket
	       :hunchentoot))
