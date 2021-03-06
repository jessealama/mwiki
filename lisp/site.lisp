
(in-package :mwiki)

;;; Initial mizar configuration: 7.11.

;; MML 4.137.1092

(defvar initial-mizar-library
  (make-instance 'mizar-library
    :articles '(hidden tarski xboole_0 boole xboole_1 enumset1
    zfmisc_1 subset_1 subset setfam_1 relat_1 funct_1 grfunc_1 relat_2
    ordinal1 wellord1 relset_1 partfun1 mcart_1 wellord2 funct_2
    binop_1 domain_1 funct_3 funcop_1 funct_4 numerals ordinal2
    ordinal3 wellset1 multop_1 mcart_2 schems_1 sysrel gate_1 gate_2
    gate_3 gate_4 gate_5 finset_1 finsub_1 orders_1 setwiseo fraenkel
    card_1 funct_5 partfun2 arytm_3 arytm_2 arytm_1 numbers arytm_0
    xcmplx_0 arithm xxreal_0 xreal_0 real xcmplx_1 xreal_1 axioms
    real_1 square_1 nat_1 int_1 rat_1 membered valued_0 complex1
    absvalue int_2 nat_d binop_2 xxreal_1 classes1 card_2 xxreal_2
    xxreal_3 member_1 supinf_1 quin_1 card_3 realset1 classes2
    ordinal4 finseq_1 recdef_1 valued_1 finseq_2 seq_1 xboolean
    eqrel_1 seq_2 finseqop finseq_3 margrel1 toler_1 trees_1 finseq_4
    finsop_1 setwop_2 rfunct_1 rvsum_1 pboole newton card_4 card_5
    trees_2 valued_2 seqm_3 rfinseq seq_4 rcomp_1 comseq_1 comseq_2
    rfunct_2 cfunct_1 fcont_1 fcont_2 fdiff_1 rolle prepower finseq_5
    rewrite1 funct_7 scheme1 abian power polyeq_1 series_1 comseq_3
    cfcont_1 cfdiff_1 rpr_1 funct_6 supinf_2 trees_a pre_ff trees_3
    partit1 trees_4 card_fil binarith pre_circ finseq_6 mboolean
    wsierp_1 glib_000 pzfmisc1 genealg1 binari_2 trees_9 mssubfam
    relset_2 recdef_2 prob_1 prob_2 limfunc1 limfunc2 seqfunc limfunc3
    fcont_3 limfunc4 l_hospit fdiff_2 fdiff_3 measure1 measure2
    measure3 measure4 rfunct_3 measure5 rearran1 measure6 extreal1
    measure7 rfunct_4 mesfunc1 extreal2 sin_cos mesfunc2 sin_cos2
    sin_cos3 sin_cos4 sin_cos5 asympt_0 comptrig complex2 polyeq_2
    polyeq_3 polyeq_4 polyeq_5 sin_cos6 euler_1 euler_2 asympt_1
    series_3 series_4 series_5 quaterni afinsq_1 nat_2 pepin irrat_1
    taylor_1 holder_1 fdiff_4 fdiff_5 fdiff_6 fdiff_7 fdiff_8 sin_cos7
    sin_cos8 bvfunc_1 binari_5 bvfunc_2 taylor_2 catalan1 pythtrip
    series_2 fib_num partit_2 bvfunc_3 bvfunc_4 bvfunc_5 bvfunc_6
    bvfunc_7 bvfunc_8 bvfunc_9 bvfunc10 bvfunc11 bvfunc13 bvfunc14
    bvfunc25 bvfunc26 finseq_7 prgcor_1 fdiff_9 arrow real_3 fdiff_10
    hfdiff_1 pre_poly prgcor_2 sin_cos9 sincos10 mesfunc3 mesfunc4
    rvsum_2 finseq_8 integra1 integra2 rfinseq2 integra3 integra4
    integra5 integr12 zf_lang zf_model zf_colla zfmodel1 zf_lang1
    zf_refle zfrefle1 qc_lang1 qc_lang2 qc_lang3 cqc_lang cqc_the1
    valuat_1 zfmodel2 lukasi_1 procal_1 zf_fund1 intpro_1 cqc_the2
    zf_fund2 hilbert1 cqc_sim1 modal_1 cqc_the3 card_lar qc_lang4
    substut1 sublemma substut2 calcul_1 calcul_2 henmodel goedelcp
    struct_0 algstr_0 incsp_1 pre_topc orders_2 graph_1 cat_1 net_1
    lattices tops_1 connsp_1 tops_2 rlvect_1 rlsub_1 group_1 vectsp_1
    algstr_1 complfld parsp_1 symsp_1 ortsp_1 compts_1 rlsub_2 midsp_1
    funcsdom vectsp_2 filter_0 lattice2 realset2 robbins1 qmax_1
    parsp_2 rlvect_2 analoaf metric_1 diraf aff_1 aff_2 aff_3 collsp
    pasch real_lat tdgroup transgeo cat_2 translac anproj_1 anproj_2
    rlvect_3 vectsp_3 group_2 vectsp_4 vectsp_5 vectsp_6 vectsp_7
    analmetr group_3 projdes1 group_4 connsp_2 normsp_1 algseq_1
    homothet afvect0 complsp1 realset3 algstr_2 metric_3 sub_metr
    metric_2 hessenbe incproj afvect01 normform o_ring_1 algstr_3
    projred1 lmod_5 rmod_2 rmod_3 rmod_4 geomtrap projred2 conaffm
    conmetr papdesaf pardepap semi_af1 aff_4 afproj heyting1 prelamb
    oppcat_1 euclmetr filter_1 conmetr1 nat_lat group_5 nattra_1
    matrix_1 pcomps_1 midsp_2 metric_4 ali2 bhsp_1 bhsp_2 bhsp_3 ens_1
    borsuk_1 tbsp_1 grcat_1 group_6 matrix_2 fvsum_1 matrix_3 gr_cy_1
    monoid_0 rusub_1 rusub_2 rlvect_4 rusub_3 rlvect_5 rusub_4
    t_0topsp cantor_1 tsep_1 tdlat_1 lattice3 tdlat_2 tdlat_3 tops_3
    urysohn1 unialg_1 unialg_2 lang1 dtconstr pralg_1 yellow_0 cat_5
    altcat_1 orders_3 yellow_1 waybel_0 quantal1 yellow_2 waybel_1
    yellow_3 yellow_4 tmap_1 tex_1 waybel_2 waybel_3 tex_2 tex_4 tsp_1
    yellow_8 topmetr heine treal_1 borsuk_2 yellow_6 msualg_1 pralg_2
    msualg_2 msualg_3 waybel_5 yellow_5 yellow_7 alg_1 waybel_4
    waybel_6 waybel_7 waybel_8 waybel_9 waybel11 yellow_9 topgrp_1
    rusub_5 convex1 msafree msualg_4 cat_3 msafree1 msafree2 msualg_5
    hahnban closure2 lattice4 waybel12 waybel14 yellow12 lattice5
    yellow11 yellow13 rltopsp1 rsspace euclid topmetr2 topreal1
    topreal3 topreal2 topreal4 goboard1 goboard2 sppol_1 sppol_2
    jordan1 goboard5 goboard6 goboard7 pscomp_1 rsspace2 rsspace3
    lopban_1 mod_2 matrlin vectsp_9 ranknull mod_3 analort prvect_1
    vectsp_8 msualg_7 t_1topsp borsuk_3 toprns_1 isocat_1 ringcat1
    modcat_1 metric_6 ff_siec e_siec commacat bhsp_4 midsp_3 gr_cy_2
    isocat_2 lmod_6 dirort mod_4 pcomps_2 goboard3 goboard4 cat_4
    vfunct_1 tsep_2 petri fin_topo coh_sp monoid_1 lmod_7 hahnban1
    openlatt lopclset boolmark freealg tex_3 bintree1 boolealg
    autgroup tsp_2 projpl_1 sgraph1 grsolv_1 filter_2 fsm_1 msaterm
    decomp_1 msuhom_1 autalg_1 circuit1 extens_1 circuit2 circcomb
    graph_2 latsubgr unialg_3 index_1 weierstr facirc_1 cohsp_1
    pua2mss1 endalg goboard8 triang_1 goboard9 altcat_2 connsp_3
    closure1 msualg_6 msscyc_1 msualg_8 msscyc_2 functor0 functor1
    pralg_3 gobrd10 msalimit msualg_9 msinst_1 gobrd11 gobrd12 knaster
    twoscomp jordan3 instalg1 waybel10 catalg_1 altcat_3 wellfnd1
    waybel13 jordan4 substlat equation msafree3 functor2 yoneda_1
    gcd_1 birkhoff closure3 graph_3 jordan5a jordan5b jordan5c
    altcat_4 waybel15 jordan2b topreal5 uniform1 sprect_1 sprect_2
    jordan6 functor3 waybel16 waybel17 binari_3 bintree2 yellow10
    waybel18 quofield frechet jordan5d group_7 jordan7 waybel19
    waybel20 waybel21 waybel22 graph_4 jgraph_1 idea_1 mssublat
    conlat_1 taxonom1 taxonom2 sprect_3 vectmetr waybel23 heyting2
    jordan2c euclid_2 revrot_1 sprect_4 int_3 frechet2 topreal6
    jgraph_2 jgraph_3 jgraph_4 jgraph_5 topmetr3 topreal7 fscirc_1
    urysohn2 jct_misc borsuk_4 borsuk_5 topgen_2 hilbert2 hilbert3
    jordan1k hausdorf jordan16 jordan17 jordan20 jordan21 jgraph_6
    jgraph_7 borsuk_6 urysohn3 topalg_1 topalg_2 topalg_3 topalg_4
    topreal9 topreala toprealb rcomp_3 partfun3 topalg_5 brouwer
    tietze jgraph_8 jordan24 jordan jordan8 gobrd13 gobrd14 lattice6
    waybel24 yellow14 topreal8 jordan9 yellow15 jordan10 waybel25
    conlat_2 radix_1 yellow16 algspec1 polynom1 waybel26 waybel27
    waybel28 waybel29 waybel30 waybel31 lattice7 radix_2 polynom2
    polynom3 fuzzy_1 fuzzy_2 yellow17 waybel32 pencil_1 polynom4
    orders_4 lattice8 heyting3 polynom5 jordan1a jordan1b fintopo2
    jordan1c sprect_5 jordan1d binom ideal_1 hilbasis dynkin yellow18
    polyalg1 circtrm1 fuzzy_4 comput_1 turing_1 yellow19 waybel33
    yellow20 yellow21 waybel34 jordan1e polynom6 pencil_2 jordan1f
    jordan1g jordan1h polynom7 fsm_2 jordan1i dickson bagorder
    circcmb2 facirc_2 jordan1j jordan11 jordan12 jordan13 jordan14
    circcmb3 jordan15 jordan18 osalg_1 osalg_2 osalg_3 osalg_4 osafree
    armstrng vectsp10 bilinear hermitan necklace termord polyred
    pnproc_1 radix_3 radix_4 graph_5 chain_1 bhsp_5 binari_4 waybel35
    oposet_1 bhsp_6 fscirc_2 graphsp convex2 bhsp_7 euclid_3 neckla_2
    groeb_1 groeb_2 kurato_1 convex3 robbins2 convfun1 abcmiz_0
    euclid_4 euclid_5 matrix_4 lfuzzy_0 kurato_2 jordan_a jordan19
    radix_5 radix_6 lfuzzy_1 roughs_1 uproots uniroots weddwitt
    rsspace4 clvect_1 lopban_2 csspace fintopo3 lopban_3 neckla_3
    clvect_2 lopban_4 nat_3 csspace2 csspace3 clopban1 csspace4
    clvect_3 cfuncdom clopban2 nfcont_1 nfcont_2 clopban3 clopban4
    fib_num2 hallmar1 ndiff_1 fib_num3 latsum_1 nagata_1 group_8
    sheffer1 sheffer2 ndiff_2 fintopo4 nagata_2 vfunct_2 ncfcont1
    lp_space jordan22 ncfcont2 pencil_3 pencil_4 topgen_1 groeb_3
    matrix_5 topgen_3 robbins3 mathmorp jordan23 setlim_1 isomichi
    complsp2 rinfsup1 euclidlp setlim_2 fintopo5 prob_3 filerec1
    circled1 topgen_4 matrixc1 topgen_5 prob_4 matrix_6 gfacirc1
    ring_1 real_ns1 matrix_7 afinsq_2 stirl2_1 card_fin matrix_8
    matrix_9 matrixr1 glib_001 glib_002 glib_003 glib_004 glib_005
    moebius1 nat_4 mesfunc5 chord fintopo6 matrprob diff_1 polynom8
    matrix10 hurwitz mesfunc6 catalan2 modelc_1 lexbfs integra6
    normsp_2 bcialg_1 flang_1 matrix11 combgras group_9 flang_2
    integra7 pdiff_1 prvect_2 aofa_000 entropy1 rewrite2 matrixr2
    laplace matrix12 group_10 compact1 bcialg_2 int_4 integra8
    matrix13 pcs_0 rinfsup2 bcialg_3 bspace polyform lopban_5 int_5
    flang_3 compl_sp diff_2 mesfunc7 mesfunc8 bcialg_4 gfacirc2
    matrix15 helly euclid_6 int_7 bciideal c0sp1 convex4 quatern2
    mesfunc9 aofa_i00 matrix14 ramsey_1 abcmiz_1 modelc_2 int_6
    bcialg_5 matrixj1 matrlin2 robbins4 numeral1 vectsp11 matrixj2
    mesfun10 integr10 mesfun6c matroid0 pdiff_2 modelc_3 matrix16
    lpspace1 bcialg_6 ftacell1 fdiff_11 lopban_6 euclid_7 integra9
    integr11 quatern3 petri_2 kolmog01 pdiff_3 mesfun7c nat_5 random_1
    mesfun9c metrizts gr_cy_3 cfdiff_2 measure8 rewrite3 dist_1
    integr15 funct_8 fsm_3 topdim_1 group_11 topdim_2 ami_2 scmfsa_1
    scmpds_1 scmring1 ami_1 amistd_1 amistd_2 ami_7 amistd_3 scmnorm
    ami_3 ami_4 scm_1 fib_fusc ami_5 scm_comp reloc scmfsa_2 scmfsa_3
    scmfsa_4 scmfsa_5 scmfsa_7 scmfsa6a sf_mastr scmfsa6b scmfsa6c
    scmfsa7b scmfsa8a scmfsa8b scmfsa8c scmfsa_9 sfmastr1 scmfsa9a
    sfmastr2 sfmastr3 scm_halt scmbsort scmring2 scmisort scmpds_2
    scmpds_3 scmpds_4 scmpds_5 scmpds_6 scmp_gcd scmpds_7 scmring3
    scmpds_8 scpisort scpqsort scpinvar ami_6 scmfsa10 scmpds_9
    scmring4 dilworth integr1c interva1 funct_9 euclid_8 ordinal5
    c0sp2 algstr_4 pdiff_4 poset_1 grnilp_1 diff_3 abcmiz_a fib_num4
    euclid_9 rlaffin1 simplex0 pdiff_5 integr13 integr14 lpspace2
    tops_4 toprealc rlaffin2 simplex1 cardfin2 integr16 pdiff_6)
    :binary-version "7.11.05"
    :binaries-root "/tmp/mwiki/bin/7.11.05/"
    :mml-version "4.137.1092"
    :articles-root "/tmp/mwiki/mml/4.137.1092"))

;;; Hunchentoot configuration

;; Dispatch table

;; Logging

(setf *message-log-pathname* "/tmp/mwiki/logs/messages")
(setf *access-log-pathname* "/tmp/mwiki/logs/access")
(setf *log-lisp-errors-p* t)
(setf *log-lisp-backtraces-p* t)

;; (X)HTML output

; double quotes around attributes rather than single quotes (the default)
(setq *attribute-quote-char* #\")

; XHTML 1.1, for full RDF support
(setq *prologue*
      "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.1//EN\" \"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd\">")

;; Initialization and cleanup

(defvar current-acceptor nil
  "The most recently created hunchentoot acceptor object.")

(defvar dispatch-table
  `(,(create-prefix-dispatcher "/" 'initial-page)))

(defun mwiki-request-dispatcher (request)
  "The default request dispatcher which selects a request handler
based on a list of individual request dispatchers all of which can
either return a handler or neglect by returning NIL."
  (loop for dispatcher in dispatch-table
        for action = (funcall dispatcher request)
        when action return (funcall action)
        finally (setf (return-code *reply*) +http-not-found+)))

(defun update-dispatch-table ()
  (setf (acceptor-request-dispatcher current-acceptor)
	dispatch-table))

(defun startup (&optional (port 8080))
  (handler-case (progn
		  (setf current-acceptor 
			(make-instance 
			 'acceptor 
			 :port port
			 :request-dispatcher 'mwiki-request-dispatcher))
		  (values t (start current-acceptor)))
    (usocket:address-in-use-error () 
      (values nil (format nil "Port ~A is already taken" port)))))

(defun shutdown ()
  (stop current-acceptor)
  (setf current-acceptor nil))

(defun present-article (article)
  (let ((short-name (article-name article))
	(description (article-description article)))
    (htm
     (:a :href (fmt "~A.html" short-name) (fmt "~A: ~A" short-name description))
     "by " (str (article-author article)))))

(defun present-article-list ()
  (htm
   (:ul
    (dolist (article (articles initial-mizar-library))
      (htm
       (:li (present-article article)))))))

(defvar frontend-sandbox-root "/tmp/mwiki/public/mml")

(defun initialize-article-html-handlers ()
  (dolist (article (articles initial-mizar-library))
    (let ((name (article-name article)))
      (push (create-static-file-dispatcher-and-handler 
	     (format nil "/~A.html" name)
	     (pathname (format nil "~A/~A.html" frontend-sandbox-root name)))
	    dispatch-table)))
  (update-dispatch-table))

(define-xml-handler initial-page ()
  (with-title "Welcome to the Mizar wiki!"
    (:p "Thanks for visiting.")
    (present-article-list)))
     


;;; site.lisp ends here