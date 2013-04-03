;;;; A better extraction method
;;;; Compiler notes: compile cars and cdrs BEFORE C-c C-k.

(require :cl-ppcre)

(defstruct
    (t-matrix
      (:constructor new-t-matrix (tname t11 t12 t22 t23 t33 t3e)))
  "Transition matrix datastore"
  tname t11 t12 t22 t23 t33 t3e)

(defstruct
    (senone :constructor
      (:constructor new-senone (sname means omegas gconst)))
  "A state (senone) struct - means and variances + gconst.
   Also the score of the senone for the current observation"
  sname means omegas gconst score)

(defstruct
    (hmm :constructor
	 (:constructor new-hmm (hname state1 state2 state3 tmatrix word-final word-initial context-left context-right)))
  "An HMM struct - ties everything together"
  hname state1 state2 state3 tmatrix (active t) (h0 0) (h1p 0) (h2p 0) (h3p 0)
  hbest hexit word-final word-initial context-left context-right)

(defstruct oframe
  "Observation frame - 12 MFCCs, 12 Deltas, 1 Delta(C0)"
  components)

;(defstruct wlr
;  time 


;;; Utilities

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

(defun str-to-list (regex string)
  "Returns a list of captured groups, or nil if no regex match"
  (let ((result (multiple-value-list
		 (cl-ppcre:scan-to-strings regex string))))
    (if (null (car result))
	'nil
	(coerce (cadr result) 'list))))

(defun startswith (pattern string)
  (str-to-list (concatenate 'string "^" pattern) string))

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
	     (cons (new-t-matrix tname
				 (read-from-string t11)
				 (read-from-string t12)
				 (read-from-string t22)
				 (read-from-string t23)
				 (read-from-string t33)
				 (read-from-string t3e))
		   t-mats)))

     ;; Read in the states, blockwise
     (:block (("~s \"(.*)\"" sname)
	      (:skipline) (:skipline)	; skip rclass, mean
	      ("^ (.*)$" means)
	      (:skipline)		; skip variance
	      ("^ (.*)$" variances)
	      ("<GCONST> (.*)$" gconst))
       (setf senones
	     (cons (make-senone :sname sname
				:gconst (/ (read-from-string gconst) 2)
				:means
				(mapcar #'(lambda (x) ; to read 1023e-01 etc
					    (read-from-string x))
					(cl-ppcre:split " " means))
				:omegas ; precompute 0.5/sigma^2
				(mapcar #'(lambda (x)
					    (/ 0.5 (read-from-string x)))
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

       (let ((ctx-left (cl-ppcre:split "-" hname)) (ctx-right (cl-ppcre:split "\\+" hname)))
	 (setf hmms
	       (cons (make-hmm :hname hname :active t
			       :word-final (= 0 (count #\+ hname))
			       :word-initial (= 0 (count #\- hname))
			       :context-left (if (= (length ctx-left) 2) (car ctx-left) nil)
			       :context-right (if (= (length ctx-right) 2) (cdr ctx-right) nil)
			       :state1 (get-senone state1 senones)
			       :state2 (get-senone state2 senones)
			       :state3 (get-senone state3 senones)
			       :tmatrix (get-tmatrix tmatrix t-mats))
		     hmms)))))

    ;; Return
    (values hmms senones t-mats)))
;; NOTE: need to manually add iy,ey,er,sp,ax,ay,ow,aa,sil HMMs

(defun parse-input (samples-file)
  (let (samples)
    (with-open-file (fp samples-file :direction :input)
      (dotimes (n 7)
	(read-line fp))
      
      (do ((line (read-line fp nil)
		  (read-line fp nil)))
	  ((null line))
	
	(let ((vars (mapcar #'(lambda (x) (read-from-string x))
			    (subseq
			     (cl-ppcre:split "[ ]+" line) 1 27))))
	  ;; Extract the sample and append to collection
	  (setf samples
		(cons (make-oframe
		       :components (append (subseq vars 0 12)
					   (subseq vars 13 25)
					   (list (nth 25 vars))))
		      samples)))))
    ;; Return the samples
    (reverse samples)))
	 


;; HMM searcher functions

(defmacro def-searcher (name fn &key (multiple 'nil))
  "Create a function to search through lists of structs"
  `(defun ,name (item seq &key (multiple ,multiple))
     (if (null multiple)
	 (find item seq :test #'(lambda (x test)
				  (equal x (funcall ,fn test))))
	 (remove-if-not #'(lambda (x)
			    (equal t (funcall ,fn x)))
			seq))))

(def-searcher get-senone #'senone-sname)
(def-searcher get-tmatrix #'t-matrix-tname)
(def-searcher active-hmms #'hmm-active :multiple t)
(def-searcher word-final-hmms #'hmm-word-final :multiple t)
(def-searcher word-initial-hmms #'hmm-word-initial :multiple t)


(defun test ()
  (format t "Parsing file... ")
  (parse-hmmdefs "hmmdefs"))


;;; Decoding

(defun probability (observation state)
  "Calcs probability that observation came from state"
  (let ((dist (senone-gconst state)))
    ;(* -1 (exp  ; Get the negative prob
	   (+ dist
	       (loop for mean in (senone-means state)
		  and omega in (senone-omegas state)
		  and ocomp in (oframe-components observation)
		    sum (* omega (expt (- ocomp mean) 2))))))


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

(defparameter *neg-inf* -10e10 "Negative infinity representation")

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
	 (h3 (+ s3 (max (+ h3p (t-matrix-t33 tmat))
			(+ h2p (t-matrix-t23 tmat)))))
	 (h2 (+ s2 (max (+ h2p (t-matrix-t22 tmat))
			(+ h1p (t-matrix-t12 tmat)))))
	 (h1 (+ s1 (max (+ h1p (t-matrix-t11 tmat))
			hin))))
    (values
     (max h3 h2 h1)		; Hbest
     (+ h3 (t-matrix-t3e tmat))	; Hexit
     h3 h2 h1)))		; h3-1: node tokens in hmm


(defparameter *beam* 1 "The beam used for pruning")
(defparameter *beam-min* 10 "The min value required to pass prune test")

(defun prune-best (hmms threshold)
  "Performs a beam search elimination on the active hmms"
  (dolist (h hmms)
    ;(setf (hmm-active h) (prune-test h threshold)))))
    (setf (hmm-active h) (> (hmm-hbest h) threshold)))
  (active-hmms t hmms))

;; TODO: The threshold should change each iteration, depending on
;; The current best score. See Sphinx s3-2 doc.
;; Also, Two beams, one for active, one for word exit?
(defun prune-test (hmm threshold)
  "Returns false if the hmm should be pruned"
  (and (> (+ (hmm-hbest hmm) threshold)
	  *beam-min*)
       (> (+ (hmm-hexit hmm) threshold)
	  *beam-min*)))


(defun max-field (hmms fieldfn)
  "Finds the max 'field' from a set of HMMs"
  (labels ((recur (hmms best)
	     (if (null hmms)
		 best
		 (let ((fieldval (funcall fieldfn (car hmms))))
		   (if (> best fieldval)
		       (recur (cdr hmms) best)
		       (recur (cdr hmms) fieldval))))))
    (recur hmms 0)))

(defun insert-new-wlr (hmm)
  (format t "New WLR: ~s ~%" (hmm-hname hmm)))

;; initialise: every hmm, {h1: 0, h2,h3: -inf}
;; loop over all hmms.
;;     -> calc HBest, HExit etc for all of em, and propagate h1-3
;; prune list, based on HBest and HExit
;; give a list of active/inactive hmms to word modeller
;; examine all active HExit scores - find highest score and

;(dolist (h hmms)
;  (multiple-value-list


(defun decode (&key data hmmdefs)
  "Given a set of HMMs and input data (in form MFCC_D_Z_0), decode it!"
  ;; First extract data using various parsers
  (format t "Extracting data... ")
  (let* ((oframes (parse-input data))
	 (statistics (multiple-value-list (parse-hmmdefs hmmdefs)))
	 (hmms (first statistics))
	 (senones (second statistics))
	 (t-mats (third statistics))
	 (wlrs '()))

    (format t "Done. HMMs: ~a, Senones: ~a ~%" (length hmms) (length senones))

    (dolist (h hmms)
      (setf h (reset-hmm h)))

    (let ((smax (list 0)) (omax 0))
      (dolist (o oframes omax)
	(dolist (comp (oframe-components o))
	  (if (> (abs comp) (abs omax))
	      (setf omax comp))))
      (format t "Max observation component: ~a ~%" omax)
      
      (dolist (s senones smax)
	(dolist (x (append (senone-means s) (senone-omegas s) (list (senone-gconst s))))
	  (if (> (abs x) (abs (car smax)))
	      (setf smax (list x s)))))
      (format t "Max senone value: ~a (from ~a) ~%" (car smax) (senone-sname (second smax))))

    ;(break)

    ;; Loop for all observation data!
    (dolist (o (list (car oframes)))

      ;; First calc senone scores
      (dolist (s senones)
	(setf (senone-score s) (probability o s)))

      (let ((pmax 0))
	(dolist (s senones)
	  (if (> (abs (senone-score s)) pmax)
	      (setf pmax (senone-score s))))
	(format t "Max senone score (probability): ~a ~%" pmax))

      (break)

      ;; Loop over all active hmms, each frame. Reset, Propagate "tokens"
      (dolist (h hmms)
	(if (hmm-active h)
	    (let ((s3 (senone-score (hmm-state3 h)))
		  (s2 (senone-score (hmm-state2 h)))
		  (s1 (senone-score (hmm-state1 h)))
		  (hin (hmm-h0 h))) ;; TODO: sort out hin. Propagates from previous...
	      (multiple-value-bind (hbest hexit h3 h2 h1) (propagate h s3 s2 s1
								     (hmm-h3p h)
								     (hmm-h2p h)
								     (hmm-h1p h)
								     hin)
		;; Store results
		(setf (hmm-hbest h) hbest)
		(setf (hmm-hexit h) hexit)
		(setf (hmm-h3p h) h3)
		(setf (hmm-h2p h) h2)
		(setf (hmm-h1p h) h1)))))


      ;; Main control step. First get pruning thresholds
      (let ((prune-thresh (* 0.7 (max-field hmms #'hmm-hbest)))
	    (exit-thresh (* 0.5 (max-field hmms #'hmm-hexit))))
	(dolist (h hmms)
	  (if (and (hmm-active h) (> (hmm-hbest h) prune-thresh))
	      ;; If hmm active and above pruning threshold
	      (progn
		;(format t "HMM is above hbest thresh: ~a (~a) ~%"
		;	(hmm-hname h) (hmm-hbest h))
		(if (hmm-word-final h)  ; If it's a word-final hmm
		    (if (> (hmm-hexit h) exit-thresh)
			(insert-new-wlr h))
		    (let ((context-right (hmm-context-right h))
			  (exit (hmm-hexit h)))
		      (dolist (ht hmms) ; Otherwise, propagate to next hmms
			;; Only prop if greater h0 prob and equal ctx
			(when (and (> exit (hmm-h0 ht))
				   (equal (hmm-context-left ht) context-right))
			  (setf (hmm-h0 ht) exit)
			  (setf (hmm-active ht) t))))))
	      
	      ;; Otherwise, deactivate
	      (setf (hmm-active h) nil)))))))



;; Global vars yay
(defvar statistics (multiple-value-list (parse-hmmdefs "hmmdefs")))

(defvar hmms (first statistics))
(defvar senones (second statistics))
(defvar t-mats (third statistics))

(defvar oframes (parse-input "sample1data.txt"))

;; Find some max values
(let ((smax (list 0)) (omax 0) (omin 0) (smin (list 0)))
      (dolist (o oframes omax)
	(dolist (comp (oframe-components o))
	  (if (> (abs comp) (abs omax))
	      (setf omax comp))
	  (if (< (abs comp) (abs omin))
	      (setf omin comp))))
      (format t "Max observation component: ~a ~%" omax)
      (format t "Min observation component: ~a ~%" omin)
      
      (dolist (s senones smax)
	(dolist (x (append (senone-means s) (senone-omegas s) (list (senone-gconst s))))
	  (if (> (abs x) (abs (car smax)))
	      (setf smax (list x s)))
	  (if (< (abs x) (abs (car smin)))
	      (setf smin (list x s)))))
      (format t "Max senone value: ~a (from ~a) ~%"
	      (car smax)
	      (senone-sname (second smax)))
      (format t "Min senone value: ~a (from ~a) ~%"
	      (car smin)
	      (senone-sname (second smin))))
