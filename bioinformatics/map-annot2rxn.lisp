(in-package :ec)
;; The above puts the file in the correct Common Lisp package

;; The following switches the current organism to MetaCyc,
;; and builds the enzyme matching table.
(progn (so 'meta)
       (build-enzyme-2-rxn-lookup-table))

;; Utility function to read in a list from a file:
(define read-file-list (file-path)
  (with-open-file (in
		   file-path
		   :direction :input)
		  (loop for line = (read-line in nil)			    
			while line 
			collect line)))

;; Read in three lists:

;; 1. Unique functional descriptors:
(setf unique-functions (read-file-list "unique_funcs.txt"))

;; 2. Unique EC numbers:
(setf unique-ecs (read-file-list "unique_ecs.txt" ))

;; 3. Unique GO Terms:
(setf unique-go-terms (read-file-list "unique_go_terms.txt"))

;; Check each unique function for name matches
;; If a match, collect the function description and the matches in a list:
(defun get-function-matches ()
  (loop for function in unique-functions
	for matches = (find-enzyme-name-match (list function)) 
	when matches 
	collect (list function matches)))

;; Check each unique EC number for name matches
;; If a match, collect the EC number and the matches in a list:
(defun get-ec-matches ()
  (loop for ec in unique-ecs
	for matches = (frame-list-to-names (find-rxn-by-ec ec))
	when matches 
	collect (list ec matches)))

;; Check each unique GO term for name matches
;; If a match, collect the GO term and the matches in a list:
(defun get-go-term-matches ()
  (loop for go-term in unique-go-terms
	for go-term-symbol = (intern go-term :ecocyc)
	for go-term-frame = (when (coercible-to-frame-p go-term-symbol) (coerce-to-frame go-term-symbol))
	for matches = (when go-term-frame (frame-list-to-names (go-term-reactions go-term-frame) ))
	when matches 
	collect (list go-term matches)))

;; Collect a list of name matches that were ambiguous, and thus not
;; uniquely matched.
;; These should be reviwed at some point:
(defun ambiguous-function-matches (function-matches)
  (loop for (func matches) in function-matches
	for ambi-matches = (loop for (rxns ambi? enz-name-var) in matches 
				when (eq ambi? 't)
				collect (list rxns ambi? enz-name-var))
	when ambi-matches
        collect (list func ambi-matches))) 


;; (defun print-ec-go-annot-metacyc-rxn-table (mappings)
;;   (loop for (annot rxn-list) in mappings	
;; 	do (loop for rxn in rxn-list		 
;; 		 do (format t "~A~C~A~%" annot #\Tab rxn))))

;; Print a tab-delimited table of the annotation (whether functional
;; description, EC or GO term), and the matching reaction ID:
(defun print-func-annot-metacyc-rxn-table (mappings)
  (loop for (annot match-list) in mappings	
	do (loop for (rxns ambi? nil) in match-list
		 when (not ambi?)
		 do (loop for rxn in rxns
			  do (format t "~A~C~A~%" annot #\Tab rxn)))))


;; Transport inference

;; Scan all functional descriptions, and return names that the Transport
;; Inference Parser seems to like:

(defun find-probable-transport-names ()
  (loop for name in unique-functions
	;for (name count) = (tokenize-string raw-name
	;				    :separators '(#\Tab))

	when (lisputils::msearch *TRANSPORT-INDICATORS* name)
	collect name into names
;	and sum (parse-integer count) into counts

	finally
	(return names)))
