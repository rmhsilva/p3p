;;;; A better extraction method

(require :cl-ppcre)

(defstruct
    (t-matrix
      (:constructor new-t-matrix (tname t11 t12 t22 t23 t33 t3e)))
  "Transition matrix datastore"
  tname t11 t12 t22 t23 t33 t3e)

(defstruct
    (senone :constructor
      (:constructor new-senone (sname means variances gconst)))
  "A state (senone) struct - means and variances + gconst"
  sname means variances gconst)

(defstruct
    (ovector)
      ;(:constructor new-ovector ()))
  "An observation vector struct"
  mfccs deltas deltaC0)

(defstruct
    (hmm :constructor
	 (:constructor new-hmm (hname state1 state2 state3 tmatrix)))
  "An HMM struct - ties everything together"
  hname state1 state2 state3 tmatrix active h1p h2p h3p)



;;; Utilities

(defun str-to-list (regex string)
  "Returns a list of captured groups, or nil if no regex match"
  (let ((result (multiple-value-list
		 (cl-ppcre:scan-to-strings regex string))))
    (if (null (car result))
	'nil
	(coerce (cadr result) 'list))))

(defun startswith (pattern string)
  (str-to-list (concatenate 'string "^" pattern) string))

(defun cars (lists)
  "Get a list of the cars of sublists in 'lists'"
  (cond
    ((null lists) 'nil)
    (t (cons (caar lists) (cars (cdr lists))))))

(defun cdrs (lists)
  "Get a list of the cdrs of sublists in 'lists'"
  (cond
    ((null lists) 'nil)
    (t (cons (cdar lists) (cdrs (cdr lists))))))

(defmacro with-named-gsyms ((&rest names) &body body)
  `(let ,(loop for n in names collect `(,n (gensym (symbol-name ',n))))
     ,@body))


;; MACROS

(defmacro with-read-block ((file line linedefs) &body body)
  (with-named-gsyms (line-vars vars regex success result count)
    `(unless (null (startswith ,(caar linedefs) ,line))
       ;; First check if the first line matches. then go
       (let ((,line-vars 'nil) (,count ,(length linedefs)))
	 (if		    ; Only execute the body if all lines match
	  (dolist (,regex ',(cars linedefs) t)
	    (unless (eq ,regex :skipline) ; Scan if not a skipline
	      (let* ((,result (multiple-value-list
			       (cl-ppcre:scan-to-strings ,regex ,line)))
		     (,success (car ,result))
		     (,vars (coerce (cadr ,result) 'list)))
		(if (null ,success)	; If no match, return nil
		    (return 'nil)
		    (unless (null ,vars) ; If no captures, do nothing
		      (setf ,line-vars
			    (append ,line-vars (list ,vars)))))))

	    (if (> ,count 1) ; If we still have lines to do...
		(progn
		  (decf ,count)
		  (setq ,line (read-line ,file))))) ; ...Go to next line
	  ;; Expand out the body form with vars bound 
	  (destructuring-bind ,(remove 'nil (cdrs linedefs))
	      ,line-vars
	    ,@body))))))


(defmacro open-file-blocks ((&rest args) &rest block-forms)
  (with-named-gsyms (file line)
    ;; Open file
    `(with-open-file (,file ,@args)
       (do ((,line (read-line ,file nil)
		   (read-line ,file nil)))
	   ((null ,line))
	 ;; Expand out blocks
	 ,@(mapcar #'(lambda (blk)
		       (case (car blk)
			 (:block
			     `(with-read-block (,file ,line ,(cadr blk))
				,@(cddr blk)))
			 (t 'nil)))
		   block-forms)))))

;;; Parsing
(defun parse-hmmdefs (hmmdefs-file)
  ;; Start with empty lists
  (let (t-mats senones hmms)
    (open-file-blocks
     (hmmdefs-file :direction :input)

     ;; Read in Transition Matrices, blockwise
     (:block (("~t \"(.*)\"" tname)	; starting line
	      ("<TRANSP> [0-9]*")
	      (:skipline)
	      ("^ [^ ]+ ([^ ]+) ([^ ]+)" t11 t12)
	      ("([^ ]+) ([^ ]+) [^ ]*$" t22 t23)
	      ("([^ ]+) ([^ ]+)$" t33 t3e))
       (setf t-mats
	     (cons (new-t-matrix tname t11 t12 t22 t23 t33 t3e) t-mats)))

     ;; Read in the states, blockwise
     (:block (("~s \"(.*)\"" sname)
	      (:skipline) (:skipline)	; skip rclass, mean
	      ("^ (.*)$" means)
	      (:skipline)		; skip variance
	      ("^ (.*)$" variances)
	      ("<GCONST> (.*)$" gconst))
       (setf senones
	     (cons (make-senone :sname sname
				:gconst (read-from-string gconst)
				:means
				(mapcar #'(lambda (x) ; to read 1023e-01 etc
					    (read-from-string x))
					(cl-ppcre:split " " means))
				:variances
				(mapcar #'(lambda (x)
					    (read-from-string x))
					(cl-ppcre:split " " variances)))
		   senones)))

     ;; Read in the HMMs
     (:block (("~h \"(.*)\"" hname)
	      (:skipline)
	      ("<NUMSTATES> .*")
	      ("<STATE> 2") ("~s \"([A-Za-z0-9_]+)\"" state1)
	      (:skipline) ("~s \"([A-Za-z0-9_]+)\"" state2)
	      (:skipline) ("~s \"([A-Za-z0-9_]+)\"" state3)
	      ("~t \"(.*)\"" tmatrix))
       (setf hmms
	     (cons (make-hmm :hname hname :active t
			     :state1 (get-senone state1 senones)
			     :state2 (get-senone state2 senones)
			     :state3 (get-senone state3 senones)
			     :tmatrix (get-tmatrix tmatrix t-mats))
		   hmms))))

    ;; Return
    (values hmms senones t-mats)))
;; NOTE: need to manually add sil and sp HMMs


(defmacro def-searcher (name fn)
  "Create a function to search through lists of structs"
  `(defun ,name (item seq)
     (find item seq :test #'(lambda (x test)
			      (equal x (funcall ,fn test))))))

(def-searcher get-senone #'senone-sname)
(def-searcher get-tmatrix #'t-matrix-tname)


(defun test ()
  (format t "Parsing file... ")
  (parse-hmmdefs "hmmdefs"))


;;; Decoding

(defun probability (observation state)
  "Calcs probability that observation came from state"
  (let ((dist (getf state :gconst)))
    (* -1  ; Get the negative prob
       (exp (+ dist
	       (loop for mean in (getf state :means)
		  and omega in (getf state :omegas)
		  and ocomp in (getf observation :components)
		    sum (* omega (- ocomp mean) (- ocomp mean))))))))


;; step through a list of observation frames
;; for each frame, calc the scores for each state of each hmm
;; for each state calc tokens for every connecting state

;; In the context aware tri-phone hmms, connected HMMs must have
;; matching end / start phones.  Ie if an HMM is a-n, it can only
;; connect to HMMs with names of n-*.  I think.  Lol... See Token Lab

;; In the most basic method, we don't use any pruning at all:
;;  At every frame, the most likely HMM output token is found
;;  This is saved, along with the time that the token entered the HMM
;;    Recording the time allows backtracking through all the redundancy
;;  Backtrack: Get entry time of this token.  Go to that entry time
;;    Find most likely output token at that time.  Etc, until at t=0

;; Each HMM has an 'active' flag which is used to prune them

(defparameter *neg-inf* -10 "Negative infinity representation")

(defun reset-hmm (hmm-old)
  "Writes the reset values to the HMMs tokens (h1-3)"
  (let ((hmm (copy-hmm hmm-old)))
    (setf (hmm-h3p hmm) *neg-inf*)
    (setf (hmm-h2p hmm) *neg-inf*)
    (setf (hmm-h1p hmm) 0)
    hmm))

(defun propagate (hmm s3 s2 s1 h3p h2p h1p hin)
  "Calcs H3,H2,H1, and Hbest, Hexit for a given HMM and senone scores.
   Ie it propagates a 'token', based on the viterbi algo"
  (let* ((tmat (hmm-tmatrix hmm))
	 (h3 (+ s2 (max (+ h3p (t-matrix-t33 tmat))
			(+ h2p (t-matrix-t23 tmat)))))
	 (h2 (+ s1 (max (+ h2p (t-matrix-t22 tmat))
			(+ h1p (t-matrix-t12 tmat)))))
	 (h1 (+ s0 (max (+ h1p (t-matrix-t11 tmat))
			hin))))
    (values
     (max h3 h2 h1)		; Hbest
     (+ h3 (t-matrix-t3e tmat))	; Hexit
     (list h3 h2 h1))))		; h1-3: node tokens in hmm


(defparameter *beam* 1 "The beam used for pruning")
(defparameter *beam-min* 10 "The min value required to pass prune test")

(defun prune-hmm (hmms-all)
  "Performs a beam search elimination on the active hmms"
  (let ((hmms (active-hmms hmms-all)))
    (dolist (h hmms hmms)
      (setf (hmm-active h) (prune-test h)))))

(defun prune-test (hmm)
  "Returns false if the hmm should be pruned"
  (and (> (+ (hmm-hbest hmm) *beam*)
	  *beam-min*)
       (> (+ (hmm-hexit hmm) *beam*)
	  *beam-min*)))

;; initialise: every hmm, {h1: 0, h2,h3: -inf}
;; loop over all hmms.
;;     -> calculate HBest, HExit etc for all of em, and propagate h1-3
;; prune list
;; give a list of active/inactive hmms to word modeller
;; examine all active HExit scores - find highest score and
(dolist (h hmms)
  (multiple-value-list
