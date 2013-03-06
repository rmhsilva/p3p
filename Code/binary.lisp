;;;; Helpful binary utilities

;;; Utilities

(defun s+ (&rest strings)
  "Because it's shorter"
  (apply #'concatenate 'string strings))

(defmacro mapcarp (function lst)
  "Extension of mapcar that appends the input to each output"
  `(mapcar #'(lambda (x) (cons (funcall ,function x) (list x)))
	   ,lst))

(defun >> (num shift)
  (/ num (expt 2 shift)))

(defun shift (num amount)
  "Shift - amount may be + or -, for left or right shift"
  (* num (expt 2 amount)))

(defun flip (x)
  "Flips the bits in x (in my format)"
  (cond
    ((null x) 'nil)
    (t (cons
	(if (= (car x) 0) 1 0)
	(flip (cdr x))))))


;;; Binary repr stuff
(defparameter +bins+ (makebins 15 11) "My binary format!")

(defun makebins (numbins point)
  "Makes a list of powers for binary positions (4 2 1 0.5 0.25 ...)"
  (cond
    ((= numbins 0) 'nil)
    (t (cons
	(expt 2 (- numbins point))
	(makebins (1- numbins) point)))))

(defun bin2hex (x)
  "Converts bin (my format) to hex representation"
  (if (null x)
      'nil
      (let ((sl (subseq x 0 4)))
	(cons (cond
		((equal sl '(0 0 0 0)) 0)
		((equal sl '(0 0 0 1)) 1)
		((equal sl '(0 0 1 0)) 2)
		((equal sl '(0 0 1 1)) 3)
		((equal sl '(0 1 0 0)) 4)
		((equal sl '(0 1 0 1)) 5)
		((equal sl '(0 1 1 0)) 6)
		((equal sl '(0 1 1 1)) 7)
		((equal sl '(1 0 0 0)) 8)
		((equal sl '(1 0 0 1)) 9)
		((equal sl '(1 0 1 0)) 'A)
		((equal sl '(1 0 1 1)) 'B)
		((equal sl '(1 1 0 0)) 'C)
		((equal sl '(1 1 0 1)) 'D)
		((equal sl '(1 1 1 0)) 'E)
		((equal sl '(1 1 1 1)) 'F))
	      (bin2hex (cddddr x))))))


(defun dec2bin (x &optional (bins +bins+))
  "Converts a decimal number into my binary format"
  (labels ((getbin (nx vals)
	     (cond
	       ((null vals)
		(if (= nx 0)
		    'nil
		    (progn
		      (if (> nx 1e-2)
			  (format t "~d: Not representable! error: ~d~%" x nx))
		      'nil)))
	       ((>= nx (car vals))
		(cons 1 (getbin (- nx (car vals)) (cdr vals))))
	       (t
		(cons 0 (getbin nx (cdr vals)))))))
    (if (< x 0) ; Handle negatives by adding first then flipping 
	(flip (cons 0 (getbin (abs (+ x (car (last bins)))) bins)))
	(cons 0 (getbin x bins)))))
    

(defun bin2dec (x &optional (bins +bins+))
  "Converts bin (my format) to decimal"
  (labels ((getdec (nx vals)
	     (cond
	       ((null nx)
		(if (null vals)
		    0
		    (progn
		      (format t "Wrong number of bins")
		      0)))
	       ((= (car nx) 1)
		(+ (car vals) (getdec (cdr nx) (cdr vals))))
	       (t (getdec (cdr nx) (cdr vals))))))
    (float (if (= (car x) 1)
	       (* -1 (1+ (getdec (flip (cdr x)) bins)))
	       (getdec (cdr x) bins))))) ; Handle negatives by multiplying back


;;; Extra binary things

(defun 2sbin (x &optional (scale 5))
  "Converts x to binary, scaled by amount"
  (dec2bin (shift x scale)))

(defun sbin2dec (x &optional (scale 5))
  "Converts a scaled x back to decimal"
  (shift (bin2dec x) (* -1 scale)))


;;; System Models

(defun gdp ()
  (let ((acc_sum 0))
    (lambda (x k mean omega last_c first_c)
      ((lambda (sum)
	 (if last_c
	     (- k sum)
	     sum))
       (setf acc_sum (+ (* omega (expt (- x mean) 2))
			(if first_c
			    0
			    acc_sum)))))))

(setf my-gdp (gdp))

(defun feed-gdp (x k/8 mean omega last_c first_c &rest more-sets)
  (let ((gdp (gdp)))
    (funcall gdp x (shift k/8 3) mean omega last_c first_c)
    (dolist (d more-sets)
      (let* ((x (car d)) (mean (third d)) (omega (fourth d))
	     (k (shift (second d) 3)) (last_c (nth 5 d)) (first_c (nth 6 d))
	     (result (funcall gdp x k mean omega last_c first_c)))
	(if last_c
	    (format t "Result: ~a ~%" result))))))

;;; Testbench things

(defmacro printl (stream &rest lines)
  "Make the printlines look nicer below :D"
  (let ((res 'nil))
    (dolist (l lines)
      (setf res
	    (append res
		    `((format ,stream ,(s+ "    " (car l) "~%") ,@(cdr l))))))
    `(progn
       ,@res)))
  

(defun print-tests3 (stream &rest tests)
  "Print tests in format (x y z)"
  (let ((xs "x") (ys "y") (zs "theta") (delay 20))
    (dolist (test tests)
      ;;For each test, print out a testbench thing
      (let* ((x (first test)) (y (second test))
	     (a (third test)) (b (fourth test))
	     (res (multiple-value-list (assig3 x y a b))))
	(printl stream
		("~%  #~dns;" delay)
		("x = 16'b~{~a~}; // ~a" (dec2bin x) x)
		("y = 16'b~{~a~}; // ~a" (dec2bin y) y)
		("a = 16'b~{~a~}; // ~a" (dec2bin a) a)
		("b = 16'b~{~a~}; // ~a" (dec2bin b) b)
		("//X: ~a  (~a)" (dec2bin (car res)) (car res))
		("//Y: ~a  (~a)" (dec2bin (cadr res)) (cadr res)))))))

(defun print-tests2 (stream &rest tests)
  "Prints tests for part 1"
  (dolist (test tests)
    (let* ((x (first test)) (y (second test)) (z (2rad (third test)))
	   (res (multiple-value-list (cordic x y (third test) :rot 'nil))))
      (printl stream
	      ("~%   #20ns")
	      ("x = 16'b~{~a~}; // ~a" (dec2bin x) x)
	      ("y = 16'b~{~a~}; // ~a" (dec2bin y) y)
	      ("z = 16'b~{~a~}; // ~a" (dec2bin z) z)
	      ("//sqrt: ~a (~a)" (dec2bin (car res)) (car res))
	      ("//atan: ~a (~a)" (dec2bin (2rad (caddr res)))
				 (2rad (caddr res)))))))


(defun print-to-file (func filepath &rest tests)
  "Outputs the tests to a file instead"
  (with-open-file (fp filepath :direction :output :if-exists :supersede)
    (apply func fp tests)
    (format t "---Done---")))
