(in-package :ecocyc)

;; replace-pwys.lisp
;;
;; This Common Lisp code allows you to provide a list of MetaCyc
;; pathways as a text file, which will be used to replace the set of
;; pathways in the specified PGDB.
;; First, the list is scanned, and it prints a warning message if any
;; of the provided pathways are not in the current version of MetaCyc
;; (the one available to the pathway-tools executable). Then, it
;; deletes all of the current Pathway instances. Then, it imports all
;; of the specified pathways from the input file that are present in
;; the current version of MetaCyc. Finally, it saves the changes to the
;; PGDB, and then exits.

;; Usage example:
;; time pathway-tools -no-patch-download -lisp -load /input/inputs/replace-pwys.lisp -eval "(replace-pathways \"/input/inputs/MG1655/pathway/pathway.txt\" 'mg1655)"

;; Import symbols from text file
(defun load-pwy-symbols (pwy-filepath)
  (with-open-file (pwy-stream pwy-filepath)
		  ;; First, fix the encoding:
		  (setf (excl:eol-convention pwy-stream) :anynl)
		     ;; Read pathway file line-by-line, and collect symbols that are in the current MetaCyc:
		     (loop for line = (read-line pwy-stream nil 'eof)
			   until (eq line 'eof)
			   with symbol
			   do (setf symbol (intern line))
			   ;;do (format t "Symbol: !~a!~%" symbol)
			   when (coercible-to-frame-p symbol
						      :kb (find-org 'meta))
			   collect symbol ;; (push symbol new-pwys)
			   else do (format t "Not in MetaCyc: ~a~%" line)) 
		     ))


;; Delete existing Pathway instances:
(defun delete-existing-pathways ()
  (loop for pwy in (get-class-all-instances '|Pathways|)
	do (format t "Deleting pathway instance ~a~%"
		   (get-frame-name pwy))))

;; Import list of pathways from MetaCyc to target PGDB:
(defun replace-pathways (pathway-filename orgid)
  (let ((pwy-list (load-pwy-symbols pathway-filename)))
    (select-organism :org-id orgid)
    (delete-existing-pathways)
    (import-pathways pwy-list (find-org 'meta) (find-org orgid))
    (save-kb)
    (exit)))
