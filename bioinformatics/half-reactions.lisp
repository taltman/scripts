;; Copyright (C) Tomer Altman, 2015

(in-package :ec)

;;;; Half Reactions

;; This package provides the following:
;; * Construction of half-reactions of molecules containing only C, H, O, and N.
;; * A library of selected half-reactions from the literature
;; * A library of selected half-reactions of mixed products with fixed proportions:
;; * Construction of weighted-sums of half-reactions
;; * A means of computing the \delta_r G^{\o'} of half reactions.
;; * Determination of f_e and f_s
;; * Balancing of half-reaction sums
;;   (this is for simulation)


(setf fully-oxidized-cpds
      '(CARBON-DIOXIDE))

(defun chon-molecule? (cpd)
  (null (fset-difference (fremove-duplicates (mapcar #'first (get-slot-values cpd 'chemical-formula)))
			 '(C H O N))))

(defun num-atoms-in-formula (atom formula)
  (let ((atom-entry (fassoc atom formula)))
    (if atom-entry
	(second atom-entry)
	0)))


;; Create a custom half-reaction for an organic molecule with only C, H, O, and N molecules:
;; Based on formula from Environmental Biotechnology by Rittmann and McCarty

(defun custom-chon-organic-half-reaction (cpd)

  (when (slot-has-value-p cpd 'atom-charges)
    (error "Function wasn't designed to handle charged organic molecules"))

  (when (not (has-structure-p cpd))
    (error "cpd does not have structure"))


  (when (not (chon-molecule? cpd))
    (error "Unable to create organic half-reaction for molecule, has atoms beyond C, H, O, and N."))

  (let* ((num-C (num-atoms-in-formula 'C (get-slot-values cpd 'chemical-formula)))
	 (num-H (num-atoms-in-formula 'H (get-slot-values cpd 'chemical-formula)))
	 (num-O (num-atoms-in-formula 'O (get-slot-values cpd 'chemical-formula)))
	 (num-N (num-atoms-in-formula 'N (get-slot-values cpd 'chemical-formula)))
	 (d     (+ (* 4 num-C)
		   num-H 
		   (- (* 2 num-O))
		   (- (* 3 num-N))))
	 (coef-co2 (/ (- num-C num-N) d))
	 (coef-nh4 (/ num-N d))
	 (coef-cpd (/ 1 d))
	 (coef-h2o (/ (+ (* 2 num-C) (- num-O) num-N) d)))

    ;; Create half-reaction list
    (list (remove-if (lambda (x) (= (first x) 0))
		     (list (list coef-co2 'CARBON-DIOXIDE)
			   (list coef-nh4 'AMMONIUM)
			   (list coef-nh4 'HCO3)
			   (list 1 'PROTON)
			   (list 1 'e-)))
	  (remove-if (lambda (x) (= (first x) 0))
		     (list (list coef-cpd (get-frame-name cpd))
			   ;; (list (list coef-biomass (list 'empirical-formula
			   ;; 				 num-C
			   ;; 				 num-H
			   ;; 				 num-O
			   ;; 				 num-N))
			   (list coef-h2o 'water))))))

(defun custom-charged-chon-organic-half-reaction (cpd)
  
  (when (not (has-structure-p cpd))
    (error "cpd does not have structure"))

  (when (not (chon-molecule? cpd))
    (error "Unable to create organic half-reaction for molecule, has atoms beyond C, H, O, and N."))

  (let* ((num-C  (num-atoms-in-formula 'C (get-slot-values cpd 'chemical-formula)))
	 (num-H  (num-atoms-in-formula 'H (get-slot-values cpd 'chemical-formula)))
	 (num-O  (num-atoms-in-formula 'O (get-slot-values cpd 'chemical-formula)))
	 (num-N  (num-atoms-in-formula 'N (get-slot-values cpd 'chemical-formula)))
	 (num-charge (apply #'+ (mapcar #'second (get-slot-values cpd 'atom-charges))))
	 (e-coef (+ (* 4 num-C)
		    num-H 
		    (- (* 2 num-O))
		    (- (* 7 num-N))
		    ;; I think this needs to be signed, not abs(x):
		    (- num-charge)))
	 (coef-co2 (/ (- num-C num-N) e-coef))
	 (coef-nh4 (/ num-N e-coef))
	 (coef-cpd (/ 1 e-coef))
	 (coef-h+ ( / (+ (* 4 num-C) num-H (- (* 2 num-O)) (- (* 7 num-N))) e-coef))
	 (coef-h2o (/ (+ (* 2 num-C) (- num-O) num-N) e-coef)))

    ;; Create half-reaction list
    (list (remove-if (lambda (x) (= (first x) 0))
		     (list (list coef-co2 'CARBON-DIOXIDE)
			   (list coef-nh4 'AMMONIUM)
			   (list coef-nh4 'HCO3)
			   (list coef-h+ 'PROTON)
			   (list 1 'e-)))
	  (remove-if (lambda (x) (= (first x) 0))
		     (list (list coef-cpd (get-frame-name cpd))
		     ;; (list (list coef-biomass (list 'biomass
		     ;; 				    num-C
		     ;; 				    num-H
		     ;; 				    num-O
		     ;; 				    num-N))
			   (list coef-h2o 'water))))))


(defun generate-simple-chon-half-reaction (cpd)
  (when (not (chon-molecule? cpd))
    (error "Not a chon molecule!"))

  (if (slot-has-value-p cpd 'atom-charges)
      (custom-charged-chon-organic-half-reaction cpd)
      (custom-chon-organic-half-reaction cpd)))


;; Currently only works for chon substrates

;; (defun combine-half-reactions-by-ratio (substrate-ratio-list)
;;   (let ((electron-sum
;; 	 (loop for (coef cpd) in substrate-ratio-list
;; 	    for half-rxn = (generate-simple-chon-half-reaction cpd)
;; 	    for num-e = (loop for (reduced-coef reduced-cpd) in (second half-rxn)
;; 			   when (fequal reduced-cpd cpd)
;; 			   return (* coef (expt reduced-coef -1)))
;; 	    sum num-e))
;; 	(oxidized-hash (make-hash-table))
;; 	(reduced-hash  (make-hash-table)))


;;     (loop for (coef cpd) in substrate-ratio-list
;;        for half-rxn = (generate-simple-chon-half-reaction cpd)
;;        for num-e = (loop for (reduced-coef reduced-cpd) in (second half-rxn)
;; 		      when (fequal reduced-cpd cpd)
;; 		      return (* coef (expt reduced-coef -1)))
;;        for frac = (/ num-e electron-sum)

;;        do (loop for (oxidized-coef oxidized-cpd) in (first half-rxn)
;; 	     when (gethash oxidized-cpd oxidized-hash)
;; 	     do (setf (gethash oxidized-cpd oxidized-hash)
;; 		      (+ (gethash oxidized-cpd oxidized-hash)
;; 			 (* frac oxidized-coef)))
;; 	     else
;; 	     do (setf (gethash oxidized-cpd oxidized-hash)
;; 		      (* frac oxidized-coef)))
;; 	 (loop for (reduced-coef reduced-cpd) in (second half-rxn)
;; 	    when (gethash reduced-cpd reduced-hash)
;; 	    do (setf (gethash reduced-cpd reduced-hash)
;; 		     (+ (gethash reduced-cpd reduced-hash)
;; 			(* frac reduced-coef)))
;; 	    else
;; 	    do (setf (gethash reduced-cpd reduced-hash)
;; 		      (* frac reduced-coef))))

;;     (list (loop for cpd being the hash-keys of oxidized-hash
;; 	       using (hash-value coef)
;; 	       collect (list coef cpd))
;; 	  (loop for cpd being the hash-keys of reduced-hash
;; 	     using (hash-value coef)
;; 	     collect (list coef cpd)))))
	 

(defun combine-half-reactions-by-ratio (substrate-ratio-list)
  (let ((electron-sum
	 (loop for (coef cpd) in substrate-ratio-list
	    for half-rxn = (generate-simple-chon-half-reaction cpd)
	    for num-e = (loop for (reduced-coef reduced-cpd) in (second half-rxn)
			   when (fequal reduced-cpd cpd)
			   return (* coef (expt reduced-coef -1)))
	    sum num-e)))

    
    (sum-half-reactions 
     (loop for (coef cpd) in substrate-ratio-list
	for half-rxn = (generate-simple-chon-half-reaction cpd)
	for num-e = (loop for (reduced-coef reduced-cpd) in (second half-rxn)
		       when (fequal reduced-cpd cpd)
		       return (* coef (expt reduced-coef -1)))
	for frac = (/ num-e electron-sum)
	  
	collect (scale-half-reaction half-rxn frac)))))

(defun create-mixed-fermentation-half-reaction (pwy reduced-cpds)
  (if (fassoc pwy mixed-fermentation-ratios)
      (combine-half-reactions-by-ratio (second (fassoc pwy mixed-fermentation-ratios)))
      (combine-half-reactions-by-ratio (loop for cpd in reduced-cpds
					  collect (list 1 cpd)))))

;;; List of mixed fermentation pathways with non-1:1 product ratios:

(setf mixed-fermentation-ratios
      '((P124-PWY ((2 ACET) (1 L-LACTATE)))))

;;; List of defined half-reactions:

(setf defined-half-reactions
      '(((PWY-4601 PWY-4521 PWY-7429)
	  (((1/2 ARSENATE)
		    (3/2 PROTON)
		    (1 E-))
		   ((1/2 CPD-763)
		    (1/2 WATER))))
	(PWY-6529 (((1/2 CHLORATE)
		    (1 PROTON)
		    (1 E-))
		   ((1/2 CHLORITE)
		    (1/2 WATER))))
	;; Perchlorate:
	(PWY-6530 (((1/4 CPD0-1385)
		     (3/4 PROTON)
		     (1 E-))
		    ((1/4 CHLORITE)
		     (1/2 WATER))))
	;; Dimethyl Sulfoxide
	(PWY-6059 (((1/2 DMSO)
		    (1 PROTON)
		    (1 E-))
		   ((1/2 CPD-7670)
		    (1/2 WATER))))
	;; HS -> |Elemental-Sulfur|
	(P222-PWY (((1/2 |Elemental-Sulfur|)
		    (1 PROTON)
		    (1 E-))
		   ((1/2 HS))))
	;; HS -> SULFATE
	((PWY-5285 DISSULFRED-PWY)
           	  (((1/8 SULFATE)
		    (10/8 PROTON)
		    (1 E-))
		   ((1/8 HS)
		    (1/2 WATER))))
	;; S2O3 --> SULFATE
	((PWY-5277 P224-PWY)
	          (((1/4 SULFATE)
		    (5/4 PROTON)
		    (1 E-))
		   ((1/8 S2O3)
		    (5/8 WATER))))
	;; SO3 -> SULFATE
	(PWY-5278 (((1/2 SULFATE)
		    (1 PROTON)
		    (1 E-))
		   ((1/2 SO3)
		    (1/2 WATER))))
	;; SULFATE -> |Elemental-Sulfur|
	((SULFUROX-PWY FESULFOX-PWY)
	              (((1/6 SULFATE)
			(4/3 PROTON)
			(1 E-))
		       ((1/6 |Elemental-Sulfur|)
			(2/3 WATER))))
	;; Custom half-reaction:
	(P203-PWY (((1 SO3)
		    (2 PROTON)
		    (2 HS)
		    (1 E-))
		   ((3 |Elemental-Sulfur|)
		    (3 WATER))))
	;; Mn+2
	((PWY-6591 PWY-6592)
	          (((1/2 CPD-12610)
		    (2 PROTON)
		    (1 E-))
		   ((1/2 MN+2)
		    (1 WATER))))
	;; CYS, custom:
	(LCYSDEG-PWY (((1/10 HS)
		       (1/5 CARBON-DIOXIDE)
		       (1/10 AMMONIUM)
		       (1/10 HCO3)
		       (1 PROTON)
		       (1 E-))
		      ((1/10 CYS)
		       (1/2 WATER))))
	;; MET, custom:
	((METHIONINE-DEG1-PWY PWY-701)
	             (((1/22 HS)
		       (2/11 CARBON-DIOXIDE)
		       (1/22 AMMONIUM)
		       (1/22 HCO3)
		       (1 PROTON)
		       (1 E-))
		      ((1/22 MET)
		       (9/22 WATER))))
	;; tetrathionate -> S, S2O3, SULFATE
	(PWY-6327 (((1 CPD-14)
		    (1 WATER)
		    (1 E-))
		   ((1 |Elemental-Sulfur|)
		    (1 S2O3)
		    (1 SULFATE)
		    (1 PROTON))))
	;; thiosulfate oxidation to tetrathionate:
	(THIOSULFOX-PWY (((1 CPD-14)
			  (2 PROTON)
			  (1 E-))
			 ((2 S2O3))))
	;; Intra-aerobic nitrite reduction:
	(PWY-6523 (((2/3 NITRITE)
		    (4/3 PROTON)
		    (1 E-))
		   ((1/3 OXYGEN-MOLECULE)
		    (1/3 NITROGEN-MOLECULE)
		    (2/3 WATER))))
	;; Hydrogen molecule:
	(NIL
	 (((1 PROTON)
	   (1 E-))
	  ((1/2 HYDROGEN-MOLECULE))))
	;; Water-oxygen:
	(NIL
	 (((1/4 OXYGEN-MOLECULE)
	   (1 PROTON)
	   (1 E-))
	  ((1/2 WATER))))
	;;; Nitrogenous compound half-reactions:
	;; Ammonium-nitrate:
	(NIL
	 (((1/8 NITRATE)
	   (5/4 PROTON)
	   (1 E-))
	  ((1/8 AMMONIUM)
	   (3/8 WATER))))
	;; Ammonium-nitrite
	(NIL
	 (((1/6 NITRITE)
	   (4/3 PROTON)
	   (1 E-))
	  ((1/6 AMMONIUM)
	   (1/3 WATER))))
	;; Ammonium-nitrogen:
	(NIL
	 (((1/6 NITROGEN-MOLECULE)
	   (4/3 PROTON)
	   (1 E-))
	  ((1/3 AMMONIUM))))
	;; Nitrite-nitrate:
	(NIL
	 (((1/2 NITRATE)
	   (1 PROTON)
	   (1 E-))
	  ((1/2 NITRITE)
	   (1/2 WATER))))
	;; Nitrogen- nitrate
	(NIL
	 (((1/5 NITRATE)
	   (6/5 PROTON)
	   (1 E-))
	  ((1/10 NITROGEN-MOLECULE)
	   (3/5 WATER))))
	;; Nitrogen- nitrite
	(P303-PWY
	 (((1/3 NITRITE)
	   (4/3 PROTON)
	   (1 E-))
	  ((1/6 NITROGEN-MOLECULE)
	   (2/3 WATER))))))

	

;; Given oxidized and reduced cpds, and the pathway, see if there is a match in the manual half-reaction list:

(defun find-matching-half-reactions (oxidized-cpds reduced-cpds pwy half-rxn-list)
  (let (matching-half-rxns-by-pwy
	matching-half-rxns-by-cpds-two-sides
	matching-half-rxns)
    
  (loop for (pwy-list half-rxn) in half-rxn-list
     when (or (and (listp pwy-list)
		   (fmember pwy pwy-list))
	      (and (not (listp pwy-list))
		   (fequal pwy pwy-list)))
     do (push half-rxn matching-half-rxns-by-pwy))

  
  (loop for (pwy-list half-rxn) in half-rxn-list
     when (and (null pwy-list)
	       (null matching-half-rxns-by-pwy)
	       oxidized-cpds
	       reduced-cpds
	       (null (fset-difference oxidized-cpds
				      (mapcar #'second (first half-rxn))))
	       (null (fset-difference reduced-cpds
				      (mapcar #'second (second half-rxn)))))
     do (push half-rxn matching-half-rxns-by-cpds-two-sides))


  (loop for (pwy-list half-rxn) in half-rxn-list
     when (or (and (null pwy-list)
		   (null matching-half-rxns-by-pwy)
		   (null matching-half-rxns-by-cpds-two-sides)
		   oxidized-cpds 		    
		   (null reduced-cpds)
		   (null (fset-difference oxidized-cpds
					  (mapcar #'second (first half-rxn)))))
	      (and (null pwy-list)
		   (null matching-half-rxns-by-pwy)
		   (null matching-half-rxns-by-cpds-two-sides)
		   reduced-cpds 
		   (null oxidized-cpds)
		   (null (fset-difference reduced-cpds
					  (mapcar #'second (first half-rxn))))))

     do (push half-rxn matching-half-rxns))

  (remove-duplicates (append matching-half-rxns-by-pwy
			     matching-half-rxns-by-cpds-two-sides
			     matching-half-rxns)
		     :test #'equalp)))

		    
(defun create-half-reaction (cpd)



(defun generate-half-reactions (guild-data defined-half-reactions)
  (loop for (tclass oxidized-cpds reduced-cpds pwy) in guild-data
       for matches = (find-matching-half-reactions oxidized-cpds
						   reduced-cpds
						   pwy
						   defined-half-reactions)
     ;; Has a defined half reaction:
     when matches
     collect (list pwy (first matches))

     ;; Fermentation products:
     else when (and (eq tclass 'Electron_Acceptor)
		    (> (length reduced-cpds) 1))
     collect (list pwy (create-mixed-fermentation-half-reaction pwy
								reduced-cpds))

     ;; Try to make a half reaction from the reduced cpd:
     else when (and reduced-cpds 
		    (= (length reduced-cpds) 1)
		    (not (fmember (first reduced-cpds) '(CELLULOSE |Starch|)))
		    (chon-molecule? (first reduced-cpds))
		    (not (fmember (first oxidized-cpds) fully-oxidized-cpds)))
     collect (list pwy (generate-simple-chon-half-reaction (first reduced-cpds)))

     ;; Try to make a half reaction from the oxidized cpd:
     else when (and oxidized-cpds 
		    (= (length oxidized-cpds) 1)
		    (chon-molecule? (first oxidized-cpds))
		    (not (fmember (first oxidized-cpds) fully-oxidized-cpds)))
     collect (list pwy (generate-simple-chon-half-reaction (first oxidized-cpds)))))


;;;; ::::::::: Thermodynamics :::::::::::::

(defun compute-delta-g-of-half-reaction (half-rxn)
  (- (loop for (coef cpd) in (second half-rxn)
	  when (not (fmember cpd '(E-)))
	sum (* coef (get-slot-value cpd 'gibbs-0)))
     (loop for (coef cpd) in (first half-rxn)
	when (not (fmember cpd '(E-)))
	sum (* coef (get-slot-value cpd 'gibbs-0)))))


;; This currently doesn't work for non-chon substrates
;; This needs to be more flexible to pick electron acceptor half reactions, too.
;; Todo: make transfer efficiency a parameter
;; This function should take half-reactions as arguments, so we're not searching for half-reactions twice. 
;; 
(defun compute-yield-parameters (electron-donor carbon-source nitrogen-source electron-acceptor autotroph?)
  (let* ((delta-Gr-pyruvate (compute-delta-g-of-half-reaction (generate-simple-chon-half-reaction 'pyruvate)))
	 (delta-Gr-carbon-source (compute-delta-g-of-half-reaction (generate-simple-chon-half-reaction carbon-source)))
	 (delta-Gr-autotrophs (compute-delta-g-of-half-reaction (generate-simple-chon-half-reaction 'oxygen-molecule)))

	 ;; This is currently assuming ammonium as carbon source:
	 (delta-Gp (if autotroph?
		       (- delta-Gr-pyruvate
			  delta-Gr-autotrophs)
		       (- delta-Gr-pyruvate
			  delta-Gr-carbon-source)))

	 ;; We get 0.80 from: 3.33 kJ/ gram cells converted to kcal with 4.184 kJ per kcal
	 ;; We get 113/20 as the biomass expression from the synthesis half reaction that assumes ammonium:
	 ;; electron equivalents are from Table 2.4 of Environmental Biotechnology
	 (electron-equivalents-biomass
	  (cond ((fequal nitrogen-source 'ammonium)
		 20)
		((fequal nitrogen-source 'nitrate)
		 28)
		((fequal nitrogen-source 'nitrite)
		 26)
		((fequal nitrogen-source 'nitrogen-molecule)
		 23)))
	 (delta-Gpc (* 0.80 (/ 113 electron-equivalents-biomass)))

	 ;; Estimate from McCarty as safe assumption (actually range of values from 55 to 70 %):
	 (transfer-efficiency 0.65)
	 (delta-Gs (if (< delta-Gp 0)
		       (+ (/ delta-Gp
			     (expt transfer-efficiency -1))
			  (/ delta-Gpc transfer-efficiency))
		       (+ (/ delta-Gp
			     transfer-efficiency)
			  (/ delta-Gpc transfer-efficiency))))
	 
	 (delta-Gr-electron-donor (compute-delta-g-of-half-reaction (generate-simple-chon-half-reaction electron-donor)))
	 (delta-Gr-electron-acceptor (compute-delta-g-of-half-reaction (generate-simple-chon-half-reaction electron-acceptor)))
	 (delta-Gr-cell-energy (- delta-Gr-electron-acceptor
				  delta-Gr-electron-donor))
	 (A (- (/ delta-Gs 
		  (* transfer-efficiency 
		     delta-Gr-cell-energy))))
	 (fs0 (/ 1 (+ 1 A)))
	 (fe0 (/ A (+ 1 A))))

    (values fs0 fe0 delta-Gs A 
	    delta-Gr-pyruvate
	    delta-Gr-carbon-source
	    delta-Gp
	    delta-Gpc
	    delta-Gr-electron-donor)))

(defun reverse-half-reaction (half-reaction)
  (list (second half-reaction)
	(first half-reaction)))
	   
(defun scale-half-reaction (half-reaction factor)
  (list (loop for (coef cpd) in (first half-reaction)
	     collect (list (* coef factor) cpd))
	(loop for (coef cpd) in (second half-reaction)
	   collect (list (* coef factor) cpd))))




(defun sum-half-reactions (half-reactions-list)
  ;; oxidized is meant to mean "left side", and 
  ;; reduced to mean "right side", since we might be using
  ;; this function to generate balanced microbial growth equations.
  (let ((oxidized-hash (make-hash-table))
	(reduced-hash  (make-hash-table)))

    (loop for half-rxn in half-reactions-list
       do (loop for (oxidized-coef oxidized-cpd) in (first half-rxn)
	     when (gethash oxidized-cpd oxidized-hash)
	     do (setf (gethash oxidized-cpd oxidized-hash)
		      (+ (gethash oxidized-cpd oxidized-hash)
			oxidized-coef))
	     else
	     do (setf (gethash oxidized-cpd oxidized-hash)
		      oxidized-coef))
	 (loop for (reduced-coef reduced-cpd) in (second half-rxn)
	    when (gethash reduced-cpd reduced-hash)
	    do (setf (gethash reduced-cpd reduced-hash)
		     (+ (gethash reduced-cpd reduced-hash)
			reduced-coef))
	    else
	    do (setf (gethash reduced-cpd reduced-hash)
		     reduced-coef)))

    (list (loop for cpd being the hash-keys of oxidized-hash
	     using (hash-value coef)
	     collect (list coef cpd))
	  (loop for cpd being the hash-keys of reduced-hash
	     using (hash-value coef)
	     collect (list coef cpd)))))




(defun construct-microbial-growth-equation (electron-donors-half-reaction
					    electron-acceptors-half-reaction
					    cell-synthesis-half-reaction
					    fs)

  (sum-half-reactions (list (scale-half-reaction electron-acceptors-half-reaction
						 (- 1 fs))
			    (scale-half-reaction cell-synthesis-half-reaction
						 fs)
			    (reverse-half-reaction electron-donors-half-reaction))))

