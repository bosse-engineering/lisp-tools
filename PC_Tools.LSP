;;;Bosse-engineering                                                                                       
;;;Dipl.-Ing. Jörn Bosse                                                                                   
;;;Am Klei 5                                                                                               
;;;38458 Velpke                                                                                            
;;;Tel. 05364 / 989 677                                                                                    
;;;mobil. 0176 / 282 323 51                                                                                
;;;bosse@bosse-engineering.com                                                                             
;;;                                                                                                        
;;;--------------------------------------------------------------------------------------------------------
;;; PC_Tools			 						   	           	   
;;; Pointcab-Funktionen											   
;;;- PC_LINIE: es können folgende Linienaktionen durchgeführt werden.					   
;;; - Linie, Polylinie										    	   
;;;    Es wird der Linie oder Plinie-Befehl gestartet, automatisch wird jedes 2 Segement ausgelassen und   
;;;    anstelle dessen eine Verschneidung vom vorhergehenden und nachfolgenden Segment erzeugt.            
;;; - Linie Mehrfach (z von A u. B jeweils aus Punkt A),						   
;;; - Linie Mehrfach (z aus gepickten Punkten)                   					   
;;;    Es wird ein Liniensegment von Punkt A nach B gezeichnet, danach wird in Schleife sofort wieder der  
;;;    nächste Punkt A und B abgefragt, solange, bis der  Benutzer mit ENTER oder ESC die Schleife beendet.
;;;- PC_BLOCK: es können Blöcke in die Zeichnung eingefügt werden. Die x,y,z-Koordianten können dabei	   
;;;  optional Attributen zugewiesen werden, eine Ausrichtung an vorhanden Linienelemente (xy) kann	   
;;;  erfolgen, die Blockdefinitionen können von einer Vorlagendatei automatisch übernommen werden.	   
;;;- PC_BKS->WKS											   
;;;    Es werden Objekte im aktiven BKS ausgewählt und in das WKS transformiert. Danach ist das WKS aktiv, 
;;;    das die Ansicht wird vom ursprünglichen BKS übernommen.						   
;;;- PC_PLAETTEN											   
;;;    Es werdem Objekte im BKS mit der CADwiesel-Funktion "Plaetten" bearbeitet. Voraussetzung: die       
;;;    Funktion "c:CADW_Plaetten" aus der Datei "PC_plaetten.lsp" muss mit APPLOAD geladen sein.	   
;;;- PC_FLAECHE												   
;;;   Es werden Punkte in Folge gepickt, ab dem 3. Punkt wird automatisch eine TIN-Oberfläche erzeugt.	   
;;;   Voraussetzung: BricsCAD V21 PRO									   
;;;													   
;;;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;;;                                                                              Jörn Bosse, 27.11.20	   
;;;--------------------------------------------------------------------------------------------------------
;;;Globale Variablen
;;;JB_PC_Tools$$BlockOptionen TRUE/FALSE => FALSE, dann grundsätzlich Starten von PC_Block mit Dialogfenster
;;;JB_PC_Tools$$LoadDwgFiles MEMBER-LIST bereits geladener Vorlagendateien ("Vorlage1.dwg" "Vorlage2.dwg")
;;;JB_PC_Tools$$Supportpfad SUPPORTPFAD für PC_Tools-Programmverzeichnis, wird beim Initialisierung grundsätzlich erstellt

;;;Festlegungen Programmverzeichnis, die zwingend einzuhalten sind!!!
;;;Name ProgrammVerzeichnis: "PC_Tools"
;;;Name Programmdatei: "PC_Tools.lsp"
;;;Name BlockVorlagenverzeichnis: "BlockVorlagen" => diese Verzeichnis ist ein Musterverzeichnis im Programmverzeichnis und kann für Vorlagendateien verwendet werden


;;;V(1.0a) 30.11.20
;;;- PC_LINIE + PC_PLINIE: der Z-Wert des ersten Punktes wird grundsätzlich für alle Elemente des Liniezuges verwendet.
;;;- PC_PLINIE: Bug, es wurden die unrsprünglichen Linienelemente nicht sauber entfernt.
;;;- PC_MLINIE: neue Funktion, Liniensegemente von jeweils von A nach B, mit ENTER oder ESC wird die Schleife abgebrochen

;;;V(1.0b) 04.12.20
;;;- PC_MLINIE (z von A u. B jeweils aus Punkt A)
;;;- PC_MLINIEZ (z aus gepickten Punkten)
;;;- PC_BKS->WKS Objekt vom BKS ins WKS
;;;- PC_PLAETTEN Objekte im BKS mit CADwiesel-Funktion "plaetten" bearbeiten

;;;V(1.0c) 10.12.20
;;;- PC_BLOCK (Blöcke an zu pickenden Punkten einfügen => beim ersten Aufstarten in der Zeichnung geht das Optionen-Fenster auf)
;;;- PC_BLOCKO (Optionen für Blöcke einfügen)

;;;V(1.0d) 17.12.20
;;;- PC_BKS->WKS und PC_PLAETTEN: wenn XREF's mit ausgewählt werden, dann werden diese automatisch aus der Auswahl entfernt.
;;;- PC_BLOCK(O):
;;;    - Einfügewinkel kann über 2 Punkte oder Eingabe bestimmt werden
;;;    - zusätzlich kann ein relativer Winkel addiert werden (in 90°-Schritte eingeteilt)
;;;    - Der Einfügewinkel kann aus einem Linienement übernommen werden, wenn dieses durch den Objektfank Lot erkannt worden ist
;;;    - Objektfänge Lot oder Endpunkt für Linienelement sowie die Eingabe des max. Abstandes

;;;V(1.0e) 29.01.21 - 02.02.21
;;;- PC_LINIE: Zusammenfassung der Befehle PC_LINIE, PC_PLINIE und PC_MLINIE, Auswahl über Dialogfenster.
;;;- PC_BLOCK: Zusammenfassung der Befehle PC_BLOCK und PC_BLOCKO, das Optionenfenster wird grundsätzlich beim ersten Start oder bei ENTER anstelle Punkt picken geöffnet, =>Ende über Dialog.
;;;    - Blöcke können aus DWG-Vorlagendatei geladen werden, die Vorlagendatei muss sich im Verzeichnis .../PC_tools/BlockVorlagen/ befinden
;;;    - Blöcke aus Vorlagendatei: die Blockeinheiten der Vorlagendatei werden automatisch an die aktuelle Zeichnung angepasst.
;;;    - Blocknamefilter: es werden nur Blöcke in der Blockliste angeboten, die dem eingegebenen Filter entsprechen
;;;    - Blöcke aus Vorlagendatei: diese können mit jedem Programmstart automatisch  in die Zeichnung eingefügt werden (wenn noch nicht vorhanden, keine Aktualisierung)
;;;    - Blöcke aus Vorlagendatei: wenn ein Block als Objekt im Modelbereich der Vorlagendatei eingefügt ist, dann wird dieser Einfügelayer automatisch als Einfügelayer
;;;      in der aktuellen DWG-Datei verwendet, andernfalls der aktuelle Layer (getvar "CLAYER")
;;;- allgemein, alle Programme:
;;;    - wenn sich das Programmverzeichnis nicht auf einem Supportpfad befindet, dann wird dieser abgefragt und ins aktuelle BricsCAD-Profil geschrieben
;;;    - das Verzeichnis "BlockVorlagen" wird automatisch erstellt, wenn es nicht im Programmverzeichnis vorhanden ist.
;;;- PC_PLAETTEN -> PC_FLATTEN: anstelle der CADWiesel-Funktion "Plätten" wird die BricsCAD-Funktion "flatten" verwendet.
;;;- PC_FLAECHE: aus in Schleife zu pickender Punkte wird eine TIN-Oberfläche erzeugt, Voraussetzung BricsCAD V21 PRO


;;;Intro
(defun JB_PC_Tools:Intro (str / )
  (princ "\nerstellt durch Bosse-engineering - www.bosse-engineering.com\n")
  (princ "\n--------------------PC_Tools(1.0e), 02.02.21-----------------")
  (princ str)
  (princ "\n-------------------------------------------------------------")
  )

;;;aufrufenden Funktionen
(defun c:PC_Linie ( / )
  (JB_PC_Tools:Linie)
  )

(defun c:PC_BKS->WKS ( / )
  (JB_PC_Tools:BSK->WKS)
  )

(defun c:PC_FLATTEN ( / )
  (JB_PC_Tools:Flatten)
  )

(defun c:PC_Block ( / )
  (JB_PC_Tools:Block)
  )

(defun c:PC_Flaeche ( / )
  (JB_PC_Tools:Flaeche)
  )

;;;Pfad für SIC-Datei
(defun JB_PC_Tools:pfad_ini ( / )
  (strcat (JBf_String:Userpfad
                           "c:\\acad\\" ;;;Hier ändern, wenn anderer Pfad gewünscht
                           )"PC_Tools_sic.lsp")
  )


;;;Variablenliste
(defun JB_PC_Tools:v_liste ( / )
  
  (list
           (cons 1 nil);;;BlockListe => ((BlockName (ATTNAME1 1 "0" "0" "0" "0")(ATTNAME2 0 "0" "0" "0" "0")...)...
           (cons 2 nil);;;Last Blockname
           (cons 3 "0");;;z=0.0
           (cons 4 2);;;Nachkomma
           (cons 5 "0.25");;;Faktor
           )
        
  )

;;;Variableliste, Erweiterung
(defun JB_PC_Tools:v_liste:Erweiterung (v_liste / )
  (if (not(cdr(assoc 6 v_liste)))
    (setq v_liste (append v_liste
                    (list (cons 6 "0.0")
                          (cons 7 0);;;1 = + 100gon, 2 = + 200gon, 3 = +300gon
                          (cons 8 "0.1");;;max. Abstand Objektfang
                          (cons 9 "0");;;Ofang Lot
                          (cons 10 "0");;;Ofang Endpunkt
                          )
                    )
          )
    )
  (if (not(cdr(assoc 11 v_liste)))
    (setq v_liste (append v_liste
                    (list (cons 11 "0");;;Winkel aus Lotrichtung
                          
                          )
                    )
          )
    )
  (if (not(cdr(assoc 12 v_liste)))
    (setq v_liste (append v_liste
                    (list (cons 12 0);;;0 = Linie, 1 = Polylinie, 2 = Mehrfachlinie
                          (cons 13 0);;;Mehrfachlinie: 0 = z von A für A und B, 1 = z von jeweils gepicktem Punkt                   
                          
                          )
                    )
          )
    )

  (if (not(cdr(assoc 14 v_liste)))
    (setq v_liste (append v_liste
                    (list (cons 14 nil);;;Name DWG-Datei Blöcke
                          (cons 15 "0");;;Vorlagen-Blöcke
                          (cons 16 "*");;;Blockname-Filter
                          
                          )
                    )
          )
    )

  (if (not(cdr(assoc 17 v_liste)))
    (setq v_liste (append v_liste
                    (list (cons 17 nil);;;BlockLayerList aus aktuellem DBX-Import
                                                  
                          )
                    )
          )
    )
  v_liste)

;;;JB_PC_Tools, v_liste gecatcht laden mit Hinweis, falls die Datei defekt sein sollte
(defun JB_PC_Tools:v_liste:load:catch (pfad_ini / V_LISTE)
  (if (vl-catch-all-error-p
        (setq v_liste(vl-catch-all-apply 'load (list pfad_ini))))
    (progn
    (alert (strcat "Beim laden der folgenden Datei ist ein Fehler aufgetreten:\n\n"
                   pfad_ini
                   "\n\nSollte der Fehler auch bei einem erneuten Start des Programmes auftreten, dann löschen Sie die Datei und starten das Programm erneut."
                   "\n\nAnmerkung: die Datei enthält die Benutzereinstellungen zu den \"PC_Tools\"."))
    (exit))
    v_liste))


;;;Hauptfunktion Flaeche
(defun JB_PC_Tools:Flaeche ( / )
  
  
  (vla-startundomark (vla-get-activedocument(vlax-get-acad-object)))
  (JBf_init:PC_tools
    '(("CMDECHO" 0)
      ("DIMZIN" 3)
      ))
  
  (JB_PC_Tools:Intro "\nPC_Tools: TIN-Oberfläche aus gepickten Punkten.                   ")

  
  (JB_PC_Tools:Flaeche:exe)

  
  (princ "\nEnde.")
  (JBf_Reinit:PC_Tools)
  (vla-endundomark (vla-get-activedocument(vlax-get-acad-object)))

  (princ)
  
  )

;;;TIN-Oberfläche aus Punkten
(defun JB_PC_Tools:Flaeche:exe ( / DO KOORDS OBJTIN P)
  (JBf_Brics_TIN:Ini)
  (setq Do 'T)
  (while Do
    (if (setq p (getpoint "\nPunkt für TIN-Oberfläche picken (ENTER=Ende):"))
      (setq koords (cons (trans p 1 0)koords))
      (setq Do nil)
    )
    (cond((=(length koords)3)
          (setq objTIN(JBf_Brics_TIN:CreateWithPoints koords))
         )
         ((and(>(length koords)3)objTIN)
          (if (not(tin:addpoint objTIN (car koords)))
            (setq koords (cdr koords))
          )
         )
    )
  )
  )


;;;Haupftfunktion Block einfügen
(defun JB_PC_Tools:Block ( / OSMODEALT PFAD_INI V_LISTE DO ok2)
  
  
  (vla-startundomark (vla-get-activedocument(vlax-get-acad-object)))
  (JBf_init:PC_tools
    '(("CMDECHO" 0)
      ("DIMZIN" 3)
      ))
  
  (JB_PC_Tools:Intro "\nPC_Tools: Blöcke einfügen.                                        ")
  
  
  
  (setq pfad_ini (JB_PC_Tools:pfad_ini))
  (if (not(setq v_liste (if (findfile pfad_ini)
                          (JB_PC_Tools:v_liste:load:catch pfad_ini)nil)))
    (JBf_SIC:sichern
      (setq v_liste (JB_PC_Tools:v_liste))pfad_ini nil))

  (setq v_liste(JB_PC_Tools:v_liste:Erweiterung v_liste))

  (if (not
          (or (and JB_PC_Tools_$DCL$_File(findfile JB_PC_Tools_$DCL$_File))
              (setq JB_PC_Tools_$DCL$_File (JB_PC_Tools:DclWrite))))
      (progn
        (alert "Die DCL-Datei konnte nicht geschrieben werden.")
        (exit)))

  (setq Do 'T)
  (while Do
    (if (not JB_PC_Tools$$BlockOptionen)
      (progn
        (setq ok2(JB_PC_Tools:Block:DBox2 v_liste pfad_ini)
              v_liste(cadr ok2)
              ok2 (car ok2))
        (if (= ok2 99)
          (setq Do nil)
          )
        )
      )
    (if Do(JB_PC_Tools:Block:exe v_liste))
    )


  (setq JB_PC_Tools$$BlockOptionen 'T)
  
     

  (setq OsmodeAlt (getvar "OSMODE"))
  (princ "\nEnde.")
  (JBf_Reinit:PC_Tools)
  (setvar "OSMODE" OsmodeAlt)
  (vla-endundomark (vla-get-activedocument(vlax-get-acad-object)))

  (princ)
  
  )


;;;Status für Vorlagendatei
(defun JB_PC_Tools:Block:DBox2:StatusList ( / )
  (cond ((and(cdr(assoc 14 v_liste))
             (not(findfile (strcat JB_PC_Tools$$Supportpfad "BlockVorlagen\\"(cdr(assoc 14 v_liste))))))
         (list 98 "***nicht vorhanden***"))
        ((and(cdr(assoc 14 v_liste))
             (member(cdr(assoc 14 v_liste))JB_PC_Tools$$LoadDwgFiles))
         (list 1 "geladen"))
        ((and(cdr(assoc 14 v_liste))
             (not(member(cdr(assoc 14 v_liste))JB_PC_Tools$$LoadDwgFiles)))
         (list 99 "***nicht geladen***"))
        ((or(not(cdr(assoc 14 v_liste)))
            (=(cdr(assoc 14 v_liste))""))
         (list 0 "")))
  )
  


;;;DBox2, setten
(defun JB_PC_Tools:Block:DBox2:set (v_liste / X)
  (mapcar '(lambda(X)
             (set_tile(strcat "JB_2_" (car X))(cadr X))
           )
  (list (list "to5" (cdr(assoc 3 v_liste)))
        (list "e1" (itoa(cdr(assoc 4 v_liste))))
        (list "e2" (cdr(assoc 5 v_liste)))
        (list "e3" (cdr(assoc 6 v_liste)))
        (list "e4" (cdr(assoc 8 v_liste)))
        (list "to6" (cdr(assoc 9 v_liste)))
        (list "to7" (cdr(assoc 10 v_liste)))
        (list "to8" (cdr(assoc 11 v_liste)))
        (list "t2" (if(cdr(assoc 14 v_liste))(cdr(assoc 14 v_liste))""))
        (list "to2" (cdr(assoc 15 v_liste)))
        (list "t2a" (cadr (JB_PC_Tools:Block:DBox2:StatusList)))                            
        (list "t3" (cdr(assoc 16 v_liste)))
        (list "t4" (if (assoc (cdr(assoc 2 v_liste))(cdr(assoc 17 v_liste)))
                     (strcat "Layer aus Vorlage: \"" (cadr(assoc (cdr(assoc 2 v_liste))(cdr(assoc 17 v_liste))))"\"")
                     (strcat "aktueller Layer: \"" (getvar "CLAYER")"\"")
                     )
              )
        )
    )

  (start_list "JB_2_p2" 3)
  (mapcar 'add_list (mapcar 'cadr RelAngleList§Dbox2))
  (end_list)
  (set_tile "JB_2_p2" (itoa(-(length RelAngleList§Dbox2)(length(member (cdr(assoc 7 v_liste))(mapcar 'car RelAngleList§Dbox2))))))
  
  (start_list "JB_2_p1" 3)
  (mapcar 'add_list BlockList§Dbox2)
  (end_list)
  (if p1_sel§DBox2
    (set_tile "JB_2_p1" (itoa p1_sel§DBox2))
    (set_tile "JB_2_p1" ""))

  (start_list "JB_2_l1" 3)
  (mapcar 'add_list (mapcar 'car(cadr BlockListSub§DBox2)))
  (end_list)
  (if l1_sel§DBox2
    (set_tile "JB_2_l1" (itoa l1_sel§DBox2))
    (set_tile "JB_2_l1" ""))

  (if (and  BlockListSub§DBox2 l1_sel§DBox2)
    (progn
      (mapcar '(lambda(X)
                 (set_tile(strcat "JB_2_" (car X))(cadr X))
                 )
        (list (list "to1" (caddr (nth l1_sel§DBox2 (cadr BlockListSub§DBox2))))
              (list "r1" (if(=(cadddr (nth l1_sel§DBox2 (cadr BlockListSub§DBox2)))0)"1" "0"))
              (list "r2" (if(=(cadddr (nth l1_sel§DBox2 (cadr BlockListSub§DBox2)))1)"1" "0"))
              (list "r3" (if(=(cadddr (nth l1_sel§DBox2 (cadr BlockListSub§DBox2)))2)"1" "0")))
        )
      )
    (mapcar '(lambda(X)
                 (set_tile(strcat "JB_2_" (car X))(cadr X))
                 )
        (list (list "to1" "0")
              (list "r1" "0")
              (list "r2" "0")
              (list "r3" "1"))
        )
    )
  )

;;;DBox2, moden
(defun JB_PC_Tools:Block:DBox2:mode (error / )
  (if BlockList§Dbox2
    (progn
      (if error
        (progn
          (mode_tile (strcat "JB_2_" error)2)
          (mode_tile "accept" 0))
        (progn
          (mode_tile "accept" 0)
          (mode_tile "accept" 2))
        )
        
      (mode_tile "JB_2_p1" 0)
      
      (if (cadr BlockListSub§DBox2)
        (progn
          (mode_tile "JB_2_l1" 0)
          (if l1_sel§DBox2
            (progn
              (mode_tile "JB_2_to1" 0)
              (if  (=(caddr (nth l1_sel§DBox2 (cadr BlockListSub§DBox2)))"1")
                (progn
                  (mode_tile "JB_2_r1" 0)
                  (mode_tile "JB_2_r2" 0)
                  (mode_tile "JB_2_r3" 0)
                  )
                (progn
                  (mode_tile "JB_2_r1" 1)
                  (mode_tile "JB_2_r2" 1)
                  (mode_tile "JB_2_r3" 1)
                  )
                )
              )
            (progn
              (mode_tile "JB_2_to1" 1)
              (mode_tile "JB_2_r1" 1)
              (mode_tile "JB_2_r2" 1)
              (mode_tile "JB_2_r3" 1)
              )
            )
          )
        (progn
          (mode_tile "JB_2_l1" 1)
          (mode_tile "JB_2_to1" 1)
          (mode_tile "JB_2_r1" 1)
          (mode_tile "JB_2_r2" 1)
          (mode_tile "JB_2_r3" 1)
          )
        )
      )
    (progn
      (mode_tile "accept" 1)
      (mode_tile "JB_2_p1" 1)
      (mode_tile "JB_2_l1" 1)
      (mode_tile "JB_2_to1" 1)
      (mode_tile "JB_2_r1" 1)
      (mode_tile "JB_2_r2" 1)
      (mode_tile "JB_2_r3" 1)
      (alert "In der aktuellen Datei ist kein Block vorhanden.")
      )
    )
  )
        
  

;;;SubListIni
(defun JB_PC_Tools:Block:Lists:Ini ( / X n)
  (setq n -1)
  (list (car BlockListSub§DBox2)
        (mapcar '(lambda(X)
                   (setq n (+ n 1))
                   (list (vla-get-TagString X) (if (= n 0) 1 0) "0" 2)
                   )
          (JBf_list_att_aus_vla-blockdef (car BlockListSub§DBox2))))
  )
  



;;;DBox2, BlockList, BlockSubList => globale Variablen aus aufrufender Funktion
(defun JB_PC_Tools:Block:Lists ( / )
  (if(or BlockList§Dbox2(setq BlockList§Dbox2(JBf_tblFuncs:Get:VlaTblObj:PC_Tools 'blocks (cdr(assoc 16 v_liste)) '("`**" "A$*") nil)))
    (progn
      (if (and (cdr(assoc 2 v_liste))(member (strcase(cdr(assoc 2 v_liste)))(mapcar 'strcase BlockList§Dbox2)))
        (setq p1_sel§DBox2 (- (length BlockList§Dbox2)(length(member (strcase(cdr(assoc 2 v_liste)))(mapcar 'strcase BlockList§Dbox2)))))
        (setq p1_sel§DBox2 0))

      (if (member(strcase(nth p1_sel§DBox2 BlockList§Dbox2))(mapcar 'strcase(mapcar 'car(cdr(assoc 1 v_liste)))))
        (setq BlockListSub§DBox2 (nth (- (length (cdr(assoc 1 v_liste)))(length (member(strcase(nth p1_sel§DBox2 BlockList§Dbox2))
                                                                                       (mapcar 'strcase(mapcar 'car(cdr(assoc 1 v_liste))))))) (cdr(assoc 1 v_liste)))
              l1_sel§DBox2 (if (cadr BlockListSub§DBox2)
                             (-(length (cadr BlockListSub§DBox2))(length (member 1 (mapcar 'cadr(cadr BlockListSub§DBox2)))))
                             )
              )
        (setq BlockListSub§DBox2 (list (nth p1_sel§DBox2 BlockList§Dbox2)nil)
              BlockListSub§DBox2 (JB_PC_Tools:Block:Lists:Ini)
              l1_sel§DBox2 (if (cadr BlockListSub§DBox2)
                             0
                             )
              )
        )
      )
    
    (setq BlockListSub§DBox2 nil
          p1_sel§DBox2 nil
          l1_sel§DBox2 nil)
    )
  )


;;;Winkel aus Punkten
(defun JB_PC_Tools:Block:DBox2:GetAngle ( / P1 P2)
  (if (and (setq p1 (getpoint "\nGeben Sie den ersten Punkt für den Winkel an:"))
           (setq p2 (getpoint p1 "\nGeben Sie den zweiten Punkt für den Winkel an:"))
           (setq p1 p1)
           (setq p2 p2))
    (setq v_liste (JBf_list:subst:gc v_liste (rtos (angle p1 p2)2 12)6))
    )
  )

;;;Laden von Blöcken aus DBX-Datei
(defun JB_PC_Tools:Block:DBox2:TemplateLoad ( / DBX EXITFLAG CopyTempPath)
  (setq FilePath (strcat JB_PC_Tools$$Supportpfad "BlockVorlagen\\"))
  (if (and (and(assoc 14 v_liste)(not (member(cdr(assoc 14 v_liste))JB_PC_Tools$$LoadDwgFiles)))
           (setq DBX(JBf_DBX)))
    (progn
      (setq FilePath (strcat FilePath (cdr(assoc 14 v_liste))))
      (if (JBf_DBX:Open DBX FilePath)
        (if(vl-remove-if '(lambda(X)(= X 'T))
             (list
               (JBF_DBX:Copy:CollectionObjects:PC_tools DBX 'Blocks nil)
               ))
          (alert (strcat "Hinweis: beim Laden von Blöcken aus der Vorlagendatei ist ein Fehler aufgetreten.\n" FilePath))
          (progn
            (setq BlockLayerList (JB_PC_Tools:Block:DBox2:TemplateLoad:BlockLayerList DBX))
            (if(vl-remove-if '(lambda(X)(= X 'T))
                 (list
                   (JBF_DBX:Copy:CollectionObjects:PC_tools DBX 'Layers (mapcar 'cadr BlockLayerList))
                   ))
              (alert (strcat "Hinweis: beim Laden von Layern aus der Vorlagendatei ist ein Fehler aufgetreten.\n" FilePath))
              )
            )
          )
	(progn
	  (setq ExitFlag 'T)
	  (alert (strcat "Die Vorlagen-Datei \"" FilePath "\" konnte nicht geöffnet werden, Schreibschutz?"))
	  )
	)
      (JBf_DBX:Release DBX)
      )
    )
  
  (if (not ExitFlag)
    (setq JB_PC_Tools$$LoadDwgFiles (cons(cdr(assoc 14 v_liste))JB_PC_Tools$$LoadDwgFiles)))
  BlockLayerList)


;;;Block-Einfügelayerliste aus DBX
;;;Objekte aus Modelbereich kopieren
(defun JB_PC_Tools:Block:DBox2:TemplateLoad:BlockLayerList (DBX / BLOCKLAYERLIST)

    
  
  (vlax-for item
         (vla-get-modelSpace DBX)
    (if (= (vla-get-Objectname item) "AcDbBlockReference")
      (if (not(assoc (vla-get-Effectivename item)BlockLayerList))
        (setq BlockLayerList (cons(list(vla-get-Effectivename item)(vla-get-Layer item))BlockLayerList)))
      )
    ) 
  
  BlockLayerList)
    

;;;DBox2, Blöcke einfügen
(defun JB_PC_Tools:Block:DBox2 (v_liste pfad_ini / BlockList§Dbox2 BlockListSub§DBox2 p1_sel§DBox2 l1_sel§DBox2 A DCLID ERROR OK RelAngleList§Dbox2 BlockLayerList)

  (setq RelAngleList§Dbox2 (list (list 0 "0.0" 0.0)
                           (list 1 "+90°" (* pi 0.5))
                           (list 2 "+180°" (* pi 1.0))
                           (list 3 "+270°" (* pi 1.5))))

  
  (if (and(=(cdr(assoc 15 v_liste))"1")
          (not (member(cdr(assoc 14 v_liste))JB_PC_Tools$$LoadDwgFiles))) 
    (setq BlockLayerList(JB_PC_Tools:Block:DBox2:TemplateLoad))
    )

  (if BlockLayerList (setq v_liste (JBf_list:subst:gc v_liste BlockLayerList 17)))
  
  (JB_PC_Tools:Block:Lists)

  (if BlockListSub§DBox2
    (setq v_liste (JBf_list:subst:gc v_liste (car BlockListSub§DBox2)2)))

  
  (while (not(member ok '(1 99)))
    (setq DclId(JBf_Dcl:Load_dialog JB_PC_Tools_$DCL$_File "JB_PC_TOOLS_2" JB_PC_Tools$DCL$_2_po))
    (JB_PC_Tools:Block:DBox2:set v_liste)
    (JB_PC_Tools:Block:DBox2:mode error)
    (setq error nil)
    
    (mapcar '(lambda(A)(action_tile A (strcat "(JB_PC_Tools:Block:DBox2:action \""A"\")")))
      '("JB_2_p1" "JB_2_l1"
        "JB_2_to1" "JB_2_r1" "JB_2_r2" "JB_2_r3" "JB_2_to5" "JB_2_to6" "JB_2_to7" "JB_2_to8" "JB_2_to2"
        "JB_2_p2"
        "JB_2_b1" "JB_2_b2" "JB_2_b3"
        "accept" "cancel"))
    
    (setq ok (start_dialog))
    (unload_dialog DclId)

    (if (and(= ok 1)
            (or(<(cdr(assoc 4 v_liste))0)
               (>(cdr(assoc 4 v_liste))12)))
      (progn
        (setq ok -1
              error "e1")
        (alert "Die Nachkommastellen müssen zwischen 0 und 12 liegen.")))

    (if (and (= ok 1)
             (<= (atof (cdr(assoc 5 v_liste)))0.0))
      (progn
        (setq ok -1
              error "e2")
        (alert "Der Faktor muss größer Null sein.")))

    (if (and(= ok 1)
            (<(atof(cdr(assoc 8 v_liste)))0))
      (progn
        (setq ok -1
              error "e4")
        (alert "Der max. Abstand für den Objektfang muss größergleich Null sein.")))
  
    
    (cond ((= ok 1);;;Einfügen
           (JB_PC_Tools:Block:DBox2:v_liste:purge)
           (JBf_SIC:sichern v_liste pfad_ini nil)
           
           )
          ((= ok 99);;;Ende
           (JB_PC_Tools:Block:DBox2:v_liste:purge)
           (JBf_SIC:sichern v_liste pfad_ini nil)
           
           )
          ((= ok 11)
           (JB_PC_Tools:Block:DBox2:GetAngle)
           )
          )
    )
  (list ok v_liste))

;;;DBox2, getten
(defun JB_PC_Tools:Block:DBox2:get ( / )
  (setq v_liste (JBf_list:subst:gc v_liste (atoi(get_tile "JB_2_e1"))4)
        v_liste (JBf_list:subst:gc v_liste (vl-string-subst "." "," (get_tile "JB_2_e2"))5)
        v_liste (JBf_list:subst:gc v_liste (vl-string-subst "." "," (get_tile "JB_2_e3"))6)
        v_liste (JBf_list:subst:gc v_liste (vl-string-subst "." "," (get_tile "JB_2_e4"))8))
  )


;;;BlockSubList speichern, bevor der Block gewechselt wird, oder wenn das Dialogfenster beendet wird
(defun JB_PC_Tools:Block:DBox2:action:BlockSubList:Save ( / )

  (if (and BlockListSub§DBox2 l1_sel§DBox2)
    (if ;;;wenn auch aktivierte Toggles vorhanden
      (vl-remove-if 'not(mapcar  '(lambda(X)
                                    (if(not(and (=(caddr X)"0")(=(cadddr X)2)))
                                      X)
                                    )
        (cadr BlockListSub§DBox2)))
      (if (assoc (car BlockListSub§DBox2)(cdr(assoc 1 v_liste)))
        (setq v_liste(JBf_list:subst:gc v_liste(subst BlockListSub§DBox2 (assoc (car BlockListSub§DBox2)(cdr(assoc 1 v_liste)))(cdr(assoc 1 v_liste)))1))
        (setq v_liste(JBf_list:subst:gc v_liste(cons BlockListSub§DBox2 (cdr(assoc 1 v_liste)))1)))
      )
    )
  )

;;;v_liste purgen
(defun JB_PC_Tools:Block:DBox2:v_liste:purge ( / X)
  (setq v_liste (JBf_list:subst:gc v_liste
                  (vl-remove-if 'not
                    (mapcar '(lambda(X)
                               (if(not(and (=(caddr X)"0")(=(cadddr X)2)))
                                      X)
                                   )
                    (cdr(assoc 1 v_liste))))1))
  )
                                   
;;;Blockauswahl
(defun JB_PC_Tools:Block:DBox2:action:p1 ( / )
  
  (JB_PC_Tools:Block:DBox2:action:BlockSubList:Save)
  (setq p1_sel§DBox2 (atoi $value))
  (setq v_liste (JBf_list:subst:gc v_liste (nth p1_sel§DBox2 BlockList§Dbox2)2))
  (JB_PC_Tools:Block:Lists)
  (JB_PC_Tools:Block:DBox2:set v_liste)
  (JB_PC_Tools:Block:DBox2:mode error)
  )


;;;Auswahl relativer Winkel
(defun JB_PC_Tools:Block:DBox2:action:p2 ( / )
  (setq v_liste (JBf_list:subst:gc v_liste (car(nth (atoi $value)RelAngleList§Dbox2))7))
  )
  

;;;Attributauswahl
(defun JB_PC_Tools:Block:DBox2:action:l1 ( / ATTLIST N X)
  (setq AttList (cadr BlockListSub§DBox2)
        n -1
        l1_sel§DBox2 (atoi $value))
  (setq AttList (mapcar '(lambda(X)
                           (setq n (+ n 1))
                           (if (= l1_sel§DBox2 n)
                             (JBf_list:nth:change X 1 1)
                             (JBf_list:nth:change X 2 1))
                           )AttList))
  (setq BlockListSub§DBox2 (list (car BlockListSub§DBox2) AttList))
  (JB_PC_Tools:Block:DBox2:set v_liste)
  (JB_PC_Tools:Block:DBox2:mode error)
  )

;;;Attribut-Eigenschaften aktivieren
(defun JB_PC_Tools:Block:DBox2:action:to (toN / ATTLIST N X)
  (setq AttList (cadr BlockListSub§DBox2)
        n -1)
  (setq AttList (mapcar '(lambda(X)
                           (setq n (+ n 1))
                           (if (= l1_sel§DBox2 n)
                             (JBf_list:nth:change X $value toN)
                             X
                             )
                           )AttList))
  (setq BlockListSub§DBox2 (list (car BlockListSub§DBox2) AttList))
  )

;;;Attribut-Eigenschaften ändern
(defun JB_PC_Tools:Block:DBox2:action:r (rN / ATTLIST N X)
  (if (= $value "1")
    (progn
      (setq AttList (cadr BlockListSub§DBox2)
            n -1)
      (setq AttList (mapcar '(lambda(X)
                               (setq n (+ n 1))
                               (if (= l1_sel§DBox2 n)
                                 (JBf_list:nth:change X rN 3)
                                 X
                                 )
                               )AttList))
      (setq BlockListSub§DBox2 (list (car BlockListSub§DBox2) AttList))
      )
    )
  )


;;;Laden von Vorlagendatei durch Toggle
(defun JB_PC_Tools:Block:DBox2:action:to2 ( / ATTLIST N X BlockLayerList)
  (setq status (car(JB_PC_Tools:Block:DBox2:StatusList)))
  (setq v_liste (JBf_list:subst:gc v_liste $value 15))
  (if (= $value "1")
    (cond ((= status 98)
           (alert "Die Vorlagendatei ist nicht vorhanden und kann nicht geladen werden."))
          ((= status 1)
           (alert "Die Vorlagendatei ist bereits geladen."))
          ((= status 99)
           (setq BlockLayerList(JB_PC_Tools:Block:DBox2:TemplateLoad))
           (if BlockLayerList (setq v_liste (JBf_list:subst:gc v_liste BlockLayerList 17)))
           (setq BlockList§Dbox2 nil)
           (JB_PC_Tools:Block:Lists)
           (if BlockListSub§DBox2
             (setq v_liste (JBf_list:subst:gc v_liste (car BlockListSub§DBox2)2)))           
           (JB_PC_Tools:Block:DBox2:set v_liste)
           (JB_PC_Tools:Block:DBox2:mode error)
           )
          ((= status 0)
           (alert "Es ist noch keine Vorlagendatei ausgewählt."))
          )
    )
  )

;;;Auswahl der Vorlagendatei
(defun JB_PC_Tools:Block:DBox2:action:b2 ( / BlockLayerList)

  (if (= 1 (JB_PC_Tools:Block:Dbox5))
    (progn
      (if (and(=(cdr(assoc 15 v_liste))"1")
              (not (member(cdr(assoc 14 v_liste))JB_PC_Tools$$LoadDwgFiles)))
        (setq BlockLayerList(JB_PC_Tools:Block:DBox2:TemplateLoad))
        )
      (if BlockLayerList (setq v_liste (JBf_list:subst:gc v_liste BlockLayerList 17)))
      (setq BlockList§Dbox2 nil)
      (JB_PC_Tools:Block:Lists)
      (if BlockListSub§DBox2
        (setq v_liste (JBf_list:subst:gc v_liste (car BlockListSub§DBox2)2)))
      (JB_PC_Tools:Block:DBox2:set v_liste)
      (JB_PC_Tools:Block:DBox2:mode error)
      )

    )
  )


;;;Filter
(defun JB_PC_Tools:Block:DBox2:action:b3 ( / )

  (if (= 1 (JB_PC_Tools:Block:Dbox4))
    (progn
      (setq BlockList§Dbox2 nil)
      (JB_PC_Tools:Block:Lists)
      (if BlockListSub§DBox2
        (setq v_liste (JBf_list:subst:gc v_liste (car BlockListSub§DBox2)2)))
      (JB_PC_Tools:Block:DBox2:set v_liste)
      (JB_PC_Tools:Block:DBox2:mode error)
      )
    )
  )
    
  
;;;DBox2, action
(defun JB_PC_Tools:Block:DBox2:action (key / )
  (cond

      ((= key "JB_2_p1")
       (JB_PC_Tools:Block:DBox2:action:p1)       
       )
      ((= key "JB_2_p2")
       (JB_PC_Tools:Block:DBox2:action:p2)       
       )
      ((= key "JB_2_l1")
       (JB_PC_Tools:Block:DBox2:action:l1)       
       )
      ((= key "JB_2_to1")
       (JB_PC_Tools:Block:DBox2:action:to 2)
       (JB_PC_Tools:Block:DBox2:mode error)
       )
      ((= key "JB_2_to2")
       (JB_PC_Tools:Block:DBox2:action:to2)       
       )
      ((= key "JB_2_r1")
       (JB_PC_Tools:Block:DBox2:action:r 0)
       )
      ((= key "JB_2_r2")
       (JB_PC_Tools:Block:DBox2:action:r 1)
       )
      ((= key "JB_2_r3")
       (JB_PC_Tools:Block:DBox2:action:r 2)
       )
      ((= key "JB_2_to5")
       (setq v_liste (JBf_list:subst:gc v_liste $value 3))
       )
      ((= key "JB_2_to6")
       (setq v_liste (JBf_list:subst:gc v_liste $value 9))
       )
      ((= key "JB_2_to7")
       (setq v_liste (JBf_list:subst:gc v_liste $value 10))
       )
      ((= key "JB_2_to8")
       (setq v_liste (JBf_list:subst:gc v_liste $value 11))
       )
      ((= key "JB_2_b1")
       (JB_PC_Tools:Block:DBox2:get)
       (setq JB_PC_Tools$DCL$_2_po (done_dialog 11)))
      ((= key "JB_2_b2")
       (JB_PC_Tools:Block:DBox2:action:b2)       
       )
      ((= key "JB_2_b3")
       (JB_PC_Tools:Block:DBox2:action:b3)       
       )
      
      ((= key "accept")
       (JB_PC_Tools:Block:DBox2:get)
       (JB_PC_Tools:Block:DBox2:action:BlockSubList:Save)
       (setq JB_PC_Tools$DCL$_2_po (done_dialog 1)))
      ((= key "cancel")
       (setq JB_PC_Tools$DCL$_2_po (done_dialog 99)))
      )
  )

;;;ObjLineList 4 Snap
(defun JB_PC_Tools:Block:exe:PointSnap:List (aws p1 / N RETLIST)
  (setq n 0)
  (repeat (sslength aws)
    (setq RetList(cons(list (ssname aws n)
                            (car(vl-sort(JBf_VlaObjects:GetKoord (vlax-ename->vla-object (ssname aws n)))'(lambda(e1 e2)(< (distance (JBf_list_xyz->xy p1)(JBf_list_xyz->xy e1))
                                                                                                                       (distance (JBf_list_xyz->xy p1)(JBf_list_xyz->xy e2))))))
                            (JBf_vlax-curve-Vektor:getClosestPointTo (ssname aws n) p1)
                            )RetList))
    (setq n (+ n 1)))
  retList)

;;;Kleinstes Lot zunm Punkt als (list p Distance)
(defun JB_PC_Tools:Block:exe:PointSnap:Lot (PointSnapList p1 / PLOT)
  (if (setq pLot(car(vl-sort (mapcar 'caddr(vl-remove-if '(lambda(X)
                   (not(caddr X)))PointSnapList))
    '(lambda(e1 e2)(< (distance (JBf_list_xyz->xy p1)(JBf_list_xyz->xy e1))
                      (distance (JBf_list_xyz->xy p1)(JBf_list_xyz->xy e2)))))))
    (list pLot (distance (JBf_list_xyz->xy p1)(JBf_list_xyz->xy pLot)))))

;;;Kleinster EndPunktAbstand zum Punkt als (list p distance)
(defun JB_PC_Tools:Block:exe:PointSnap:End (PointSnapList p1 / PEND)
  (if (setq pEnd(car(vl-sort (mapcar 'cadr PointSnapList)
    '(lambda(e1 e2)(< (distance (JBf_list_xyz->xy p1)(JBf_list_xyz->xy e1))
                      (distance (JBf_list_xyz->xy p1)(JBf_list_xyz->xy e2)))))))
    (list pEnd (distance (JBf_list_xyz->xy p1)(JBf_list_xyz->xy pEnd)))))
    

;;;Objektfänge
(defun JB_PC_Tools:Block:exe:PointSnap (p1 v_liste / AWS L PENDLIST PLOTLIST POINTSNAPLIST RETP WLot)
  (setq l (sqrt(+(*(atof(cdr(assoc 8 v_liste)))(atof(cdr(assoc 8 v_liste))))
                 (*(atof(cdr(assoc 8 v_liste)))(atof(cdr(assoc 8 v_liste)))))))
  (if (= l 0.0)(setq l 0.1))
  (setq l (* l 2.0))
  (vla-zoomwindow (vlax-get-acad-object)
        (vlax-3D-Point (mapcar '- p1 (list l l 0)))
        (vlax-3D-Point (mapcar '+ p1 (list l l 0))))

  (if (setq aws (ssget "_c"
                       (mapcar '-(trans p1 0 1)(trans(list l l 0)0 1))
                      (mapcar '+(trans p1 0 1)(trans(list l l 0)0 1))
                       (list (cons 0 "LINE,ARC,POLYLINE,LWPOLYLINE"))))
    (progn
      (setq PointSnapList (JB_PC_Tools:Block:exe:PointSnap:List aws p1))
      (cond ((and(= (cdr(assoc 9 v_liste))"1")(= (cdr(assoc 10 v_liste))"1"));;;wenn Lot und Endpunkt
             (setq pLotList (JB_PC_Tools:Block:exe:PointSnap:Lot PointSnapList p1)
                   PEndList (JB_PC_Tools:Block:exe:PointSnap:End PointSnapList p1))
             (if (< (cadr pLotList)(cadr PEndList))
               (if (<= (cadr pLotList)(atof(cdr(assoc 8 v_liste))))
                 (setq RetP (list (car(car pLotList))(cadr(car pLotList))(caddr p1))
                       wLot (-(angle p1 RetP)(* 0.5 pi)))
                 (setq RetP p1)
                 )
               (if (<= (cadr PEndList)(atof(cdr(assoc 8 v_liste))))
                 (setq RetP (list (car(car PEndList))(cadr(car PEndList))(caddr p1)))
                 (setq RetP p1)
                 )
               )
             )
            ((and(= (cdr(assoc 9 v_liste))"1")(= (cdr(assoc 10 v_liste))"0"));;;wenn Lot und kein Endpunkt
             (setq pLotList (JB_PC_Tools:Block:exe:PointSnap:Lot PointSnapList p1))
             (if (<= (cadr pLotList)(atof(cdr(assoc 8 v_liste))))
                 (setq RetP (list (car(car pLotList))(cadr(car pLotList))(caddr p1))
                       wLot (-(angle p1 RetP)(* 0.5 pi)))
                 (setq RetP p1)
                 )
             )
            ((and(= (cdr(assoc 9 v_liste))"0")(= (cdr(assoc 10 v_liste))"1"));;;wenn Lot und kein Endpunkt
             (setq PEndList (JB_PC_Tools:Block:exe:PointSnap:End PointSnapList p1))
             (if (<= (cadr PEndList)(atof(cdr(assoc 8 v_liste))))
                 (setq RetP (list (car(car PEndList))(cadr(car PEndList))(caddr p1)))
                 (setq RetP p1)
                 )
             )
            )
      )
    (setq RetP p1)
    )
  (vla-ZoomPrevious (vlax-get-acad-object)) 
  (list RetP wLot))
      

;;;Einfügen von Blöcken
(defun JB_PC_Tools:Block:exe (v_liste / ATTLIST P1 X W WLOT Do)
  
  (Setq Do 'T)
 
  (while Do
    (if(and(setq p1 (getpoint "\nEinfügepunkt angeben (ENTER=OPTIONEN/ENDE):"))
           (setq p1 (trans p1 1 0)))
      (progn
        (setq w (angle(trans '(0 0 0)1 0)(trans '(1 0 0)1 0)))
        (setq w (+ w (atof(cdr(assoc 6 v_liste)))))
        (if (or(= (cdr(assoc 9 v_liste))"1")(= (cdr(assoc 10 v_liste))"1"));;;wenn Snap aktiv, dann Punkt in xy verbessern 
          (setq p1 (JB_PC_Tools:Block:exe:PointSnap p1 v_liste)
                wLot (cadr p1)
                p1 (car p1)))

        (if (and (=(cdr(assoc 11 v_liste))"1")wLot)
          (setq w wLot))

        (setq w (cond ((= (cdr(assoc 7 v_liste))0)
                 (+ w 0.0))
                ((= (cdr(assoc 7 v_liste))1)
                 (+ w (* 0.5 pi)))
                ((= (cdr(assoc 7 v_liste))2)
                 (+ w pi))
                ((= (cdr(assoc 7 v_liste))3)
                 (+ w (* 1.5 pi)))))
          
        (setq JB_PC_Tools$$BlockOptionen 'T)
        (setq AttList (vl-remove-if 'not
                        (mapcar '(lambda(X)
                                   (if (=(caddr X)"1")
                                     (list (car X)
                                           (list(list 'TextString
                                                      (rtos(cond ((= (cadddr X) 0)
                                                                  (car (trans p1 0 1)))
                                                                 ((= (cadddr X) 1)
                                                                  (cadr (trans p1 0 1)))
                                                                 ((= (cadddr X) 2)
                                                                  (caddr (trans p1 0 1))))2 (cdr(assoc 4 v_liste)))))))
                                   )
                          (cadr(assoc (cdr(assoc 2 v_liste))(cdr(assoc 1 v_liste)))))))

        (JBf_VlaAdd:AddBlock
          (cdr(assoc 2 v_liste))
          (vlax-3d-point (if (=(cdr(assoc 3 v_liste))"0")p1 (reverse(cons 0.0(cdr(reverse p1))))))
          (atof(cdr(assoc 5 v_liste)))
          (if (cadr(assoc (cdr(assoc 2 v_liste))(cdr(assoc 17 v_liste))))
            (cadr(assoc (cdr(assoc 2 v_liste))(cdr(assoc 17 v_liste))))
            (getvar "CLAYER"))
          w
          (vlax-3d-point '(0 0 1))
          AttList
          nil)
        )
      (progn
        (setq JB_PC_Tools$$BlockOptionen nil)
        (setq Do nil)))
    )
  )
  
  
;;;Hauptfunktion PC_Plaetten
(defun JB_PC_Tools:Flatten ( / OSMODEALT)  
  (vla-startundomark (vla-get-activedocument(vlax-get-acad-object)))
  (JBf_init:PC_tools
    '(("CMDECHO" 0)
      ))
  
  (JB_PC_Tools:Intro "\nPC_Tools: Obj. im BKS mit \"FLATTEN\" bearbeiten.                 ")
  
     
  (JB_PC_Tools:Flatten:exe)
  (setq OsmodeAlt (getvar "OSMODE"))
  (princ "\nEnde.")
  (JBf_Reinit:PC_Tools)
  (setvar "OSMODE" OsmodeAlt)
  (vla-endundomark (vla-get-activedocument(vlax-get-acad-object)))

  (princ)
  
)

;;;Hauptfunktion PC_BKS->WKS
(defun JB_PC_Tools:BSK->WKS ( / OSMODEALT)  
  (vla-startundomark (vla-get-activedocument(vlax-get-acad-object)))
  (JBf_init:PC_tools
    '(("CMDECHO" 0)
      ))
  
  (JB_PC_Tools:Intro "\nPC_Tools: Objekte aus dem BKS ins WKS transformieren.             ")
  

     
  (JB_PC_Tools:BSK->WKS:exe nil)
  (setq OsmodeAlt (getvar "OSMODE"))
  (princ "\nEnde.")
  (JBf_Reinit:PC_Tools)
  (setvar "OSMODE" OsmodeAlt)
  (vla-endundomark (vla-get-activedocument(vlax-get-acad-object)))

  (princ)
  
)


;;;Hauptfunktion PC_Linie
(defun JB_PC_Tools:Linie ( / OSMODEALT PFAD_INI V_LISTE)

  (vla-startundomark (vla-get-activedocument(vlax-get-acad-object)))
  (JBf_init:PC_tools
    '(("CMDECHO" 0)
      ))
  
  (JB_PC_Tools:Intro "\nPC_Tools: Linien mit automatischen Verschneidungen.               ")

  (setq pfad_ini (JB_PC_Tools:pfad_ini))
  (if (not(setq v_liste (if (findfile pfad_ini)
                          (JB_PC_Tools:v_liste:load:catch pfad_ini)nil)))
    (JBf_SIC:sichern
      (setq v_liste (JB_PC_Tools:v_liste))pfad_ini nil))

  (setq v_liste(JB_PC_Tools:v_liste:Erweiterung v_liste))

  (if (not
          (or (and JB_PC_Tools_$DCL$_File(findfile JB_PC_Tools_$DCL$_File))
              (setq JB_PC_Tools_$DCL$_File (JB_PC_Tools:DclWrite))))
      (progn
        (alert "Die DCL-Datei konnte nicht geschrieben werden.")
        (exit)))

  (JB_PC_Tools:Linie:Cond v_liste pfad_ini)
  
  (setq OsmodeAlt (getvar "OSMODE"))
  (princ "\nEnde.")
  (JBf_Reinit:PC_Tools)
  (setvar "OSMODE" OsmodeAlt)
  (vla-endundomark (vla-get-activedocument(vlax-get-acad-object)))

  (princ)
  
)

;;;PC_Linie, abfrage, welche Art von Linie gezeichet verwendet werden soll
(defun JB_PC_Tools:Linie:Cond (v_liste pfad_ini / )
  
  (cond ((= (cdr(assoc 12 v_liste))0)
         (princ "\nPC_Tools: Linien mit automatischen Verschneidungen.")
         (JB_PC_Tools:Linie:exe "LINE" v_liste pfad_ini))
        ((= (cdr(assoc 12 v_liste))1)
         (princ "\nPC_Tools: Polylinie mit automatischen Verschneidungen.")
         (JB_PC_Tools:Linie:exe "PLINE" v_liste pfad_ini))
        ((= (cdr(assoc 12 v_liste))2)
         (if (=(cdr(assoc 13 v_liste))1)
           (princ "\nPC_Tools: Mehrfachlinie (z aus gepickten Punkten).")
           (princ "\nPC_Tools: Mehrfachlinie (z von A u. B jeweils aus Punkt A).")
           )
         (JB_PC_Tools:MLinie:exe (=(cdr(assoc 13 v_liste))1)v_liste pfad_ini))
        )
  )


;;;DBox3, setten
(defun JB_PC_Tools:Dbox3:set (v_liste / X)
  (mapcar '(lambda(X)
             (set_tile (strcat "JB_3_"(car X))(cadr X)))
    (list
      (list "r4" (if (=(cdr(assoc 13 v_liste))0)"1" "0"))
      (list "r5" (if (=(cdr(assoc 13 v_liste))1)"1" "0"))
      )
    )
  )

;;;DBox3, moden
(defun JB_PC_Tools:Dbox3:mode (v_liste / )
  
  (cond ((= (cdr(assoc 12 v_liste))0)
         (mode_tile "JB_3_b1" 2))
        ((= (cdr(assoc 12 v_liste))1)
         (mode_tile "JB_3_b2" 2))
        ((= (cdr(assoc 12 v_liste))2)
         (mode_tile "JB_3_b3" 2))
  )
  )



;;;Linienart über DBox3 Abfrage
(defun JB_PC_Tools:Linie:Dbox3 (v_liste pfad_ini / A DCLID OK)
  (while (not(member ok '(11 12 13 99)))
    (setq DclId(JBf_Dcl:Load_dialog JB_PC_Tools_$DCL$_File "JB_PC_TOOLS_3" JB_PC_Tools$DCL$_3_po))

    (JB_PC_Tools:Dbox3:set v_liste)
    (JB_PC_Tools:Dbox3:mode v_liste)
    
    (mapcar '(lambda(A)(action_tile A (strcat "(JB_PC_Tools:Dbox3:action \""A"\")")))
      '("JB_3_r4" "JB_3_r5"
        "JB_3_b1" "JB_3_b2" "JB_3_b3"
        "accept" "cancel"))
    
    (setq ok (start_dialog))
    (unload_dialog DclId)

    (JBf_SIC:sichern v_liste pfad_ini nil)
    
    
    )
  (if(member ok '(11 12 13))
      (JB_PC_Tools:Linie:Cond v_liste pfad_ini)
      )
  )
  

;;;Action (Variable global in Aufrufender Funktion)
(defun JB_PC_Tools:Dbox3:action (key / )
  (cond

      ((= key "JB_3_b1")
       (setq v_liste (JBf_list:subst:gc v_liste 0 12))
       (setq JB_PC_Tools$DCL$_3_po (done_dialog 11))
       )
      ((= key "JB_3_b2")
       (setq v_liste (JBf_list:subst:gc v_liste 1 12))
       (setq JB_PC_Tools$DCL$_3_po (done_dialog 12))
       )
      ((= key "JB_3_b3")
       (setq v_liste (JBf_list:subst:gc v_liste 2 12))
       (setq JB_PC_Tools$DCL$_3_po (done_dialog 13))
       ) 
      ((= key "JB_3_r4")
       (if (= $value "1")
         (setq v_liste (JBf_list:subst:gc v_liste 0 13))))
      ((= key "JB_3_r5")
       (if (= $value "1")
         (setq v_liste (JBf_list:subst:gc v_liste 1 13))))

     
      ((= key "accept")
       (setq JB_PC_Tools$DCL$_3_po (done_dialog 1)))
      ((= key "cancel")
       (setq JB_PC_Tools$DCL$_3_po (done_dialog 99)))
      )
  )


;;;über DBox4 Filter eingeben
(defun JB_PC_Tools:Block:Dbox4 ( / A DCLID FILTER OK)

  (setq Filter (cdr(assoc 16 v_liste)))

  (while (not(member ok '(1 99)))
    (setq DclId(JBf_Dcl:Load_dialog JB_PC_Tools_$DCL$_File "JB_PC_TOOLS_4" JB_PC_Tools$DCL$_4_po))

    (set_tile "JB_4_e1" Filter)
    (mode_tile "JB_4_e1" 2)

    (mapcar '(lambda(A)(action_tile A (strcat "(JB_PC_Tools:Dbox4:action \""A"\")")))
          '("accept" "cancel"))
    (setq ok (start_dialog))
    (unload_dialog DclId)
    )
  (if (= ok 1)
        (setq v_liste(JBf_list:subst:gc v_liste Filter 16))

    )
  ok)
;;;Action (Variable global in Aufrufender Funktion) 
(defun JB_PC_Tools:Dbox4:action (key / )
  (cond
    ((= key "accept")
     (setq Filter (get_tile "JB_4_e1"))
     (if (= Filter "")
       (setq Filter "*")
       )
     (setq JB_PC_Tools$DCL$_4_po (done_dialog 1)))
    ((= key "cancel")
    (setq JB_PC_Tools$DCL$_4_po (done_dialog 99)))
  )
  )
    


;;;über DBox5 Vorlagendatei auswählen
(defun JB_PC_Tools:Block:Dbox5 ( / A DCLID FILELIST L1_SEL OK PATH)

  (setq path (strcat JB_PC_Tools$$Supportpfad "BlockVorlagen\\"))
  (if(setq FileList (vl-directory-files path "*.DWG" 1))
    (progn
      (if (and(cdr(assoc 14 v_liste))(member (strcase(cdr(assoc 14 v_liste)))(mapcar 'strcase FileList)))
        (setq l1_sel (- (length FileList)(length (member (strcase(cdr(assoc 14 v_liste)))(mapcar 'strcase FileList)))))
        (setq l1_sel 0)
        )
      (while (not(member ok '(1 99)))
        (setq DclId(JBf_Dcl:Load_dialog JB_PC_Tools_$DCL$_File "JB_PC_TOOLS_5" JB_PC_Tools$DCL$_5_po))

        (start_list "JB_5_l1" 3)
        (mapcar 'add_list FileList)
        (end_list)
        (if l1_sel
          (set_tile "JB_5_l1" (itoa l1_sel))
          (set_tile "JB_5_l1" ""))
        (mode_tile "JB_5_l1" 2)
        (mapcar '(lambda(A)(action_tile A (strcat "(JB_PC_Tools:Dbox5:action \""A"\")")))
          '("JB_5_l1"
            "accept" "cancel"))
        (setq ok (start_dialog))
        (unload_dialog DclId)
        )
      (if (= ok 1)
        (setq v_liste(JBf_list:subst:gc v_liste (nth l1_sel FileList)14))
        )
      )
    (alert (strcat"Es sind keine DWG-Vorlagendateien im folgenden Verzeichnis vorhanden:\n"
                  path))
    )
  ok)


;;;Action (Variable global in Aufrufender Funktion)
(defun JB_PC_Tools:Dbox5:action (key / )
  (cond
    ((= key "JB_5_l1")
     (setq l1_sel (atoi $value)))
    ((= key "accept")
     (setq JB_PC_Tools$DCL$_5_po (done_dialog 1)))
    ((= key "cancel")
    (setq JB_PC_Tools$DCL$_5_po (done_dialog 99)))
  )
  )
    
;;;Hauptfunktion PC_PLinie
(defun JB_PC_Tools:PLinie ( / OSMODEALT)  
  (vla-startundomark (vla-get-activedocument(vlax-get-acad-object)))
  (JBf_init:PC_tools
    '(("CMDECHO" 0)
      ))
  
  (JB_PC_Tools:Intro "\nPC_Tools: Polylinie mit automatischen Verschneidungen.            ")

  (if (not
          (or (and JB_PC_Tools_$DCL$_File(findfile JB_PC_Tools_$DCL$_File))
              (setq JB_PC_Tools_$DCL$_File (JB_PC_Tools:DclWrite))))
      (progn
        (alert "Die DCL-Datei konnte nicht geschrieben werden.")
        (exit)))

     
  (JB_PC_Tools:Linie:exe "PLINE")
  (setq OsmodeAlt (getvar "OSMODE"))
  (princ "\nEnde.")
  (JBf_Reinit:PC_Tools)
  (setvar "OSMODE" OsmodeAlt)
  (vla-endundomark (vla-get-activedocument(vlax-get-acad-object)))

  (princ)
  
)

;;;Hauptfunktion PC_MLinie
(defun JB_PC_Tools:MLinie (zFlag / OSMODEALT)  
  (vla-startundomark (vla-get-activedocument(vlax-get-acad-object)))
  (JBf_init:PC_tools
    '(("CMDECHO" 0)
      ))
  (if zFlag
    (JB_PC_Tools:Intro "\nPC_Tools: Mehrfachlinie (z von A u. B jeweils aus Punkt A).       ")
    (JB_PC_Tools:Intro "\nPC_Tools: Mehrfachlinie (z aus gepickten Punkten).                ")
    )
  

     
  (JB_PC_Tools:MLinie:exe zFlag)
  (setq OsmodeAlt (getvar "OSMODE"))
  (princ "\nEnde.")
  (JBf_Reinit:PC_Tools)
  (setvar "OSMODE" OsmodeAlt)
  (vla-endundomark (vla-get-activedocument(vlax-get-acad-object)))

  (princ)
  
)

;;;PC_MLinie
(defun JB_PC_Tools:MLinie:exe (zFlag v_liste pfad_ini / DO P1 P2 Z DBoxFlag)
  (setq Do 'T)
  (while (and Do (not DBoxFlag))
    (if (and(or(setq p1 (getpoint "\nErsten Punkt angeben:(ENTER=Linientool-Optionen)"))
               (not(setq DBoxFlag 'T)))
            (setq p2 (getpoint p1 "\nNächsten Punkt angeben (ENTER=ENDE):"))
            (setq p1 (trans p1 1 0))
            (setq p2 (trans p2 1 0))
            (setq z (caddr p1)))
      (entmake (list (cons 0 "LINE")(cons 8 (getvar "CLAYER"))
                     (cons 10 p1)
                     (if zFlag
                       (cons 11 p2)
                       (cons 11 (reverse(cons z (cdr(reverse p2)))))
                       ))
        )
             
      (setq Do nil)
      )
    )
  (if DBoxFlag
    (JB_PC_Tools:Linie:Dbox3 v_liste pfad_ini)
    )
  )


;;;AWS der letzten Objekte
(defun JB_PC_Tools:LastObjs2Aws(aws LastObj / )
  (if (not aws)(setq aws (ssadd)))
  (while (setq LastObj(entnext LastObj))
    (if (not(member (cdr(assoc 0 (entget LastObj)))'("ATTRIB" "VERTEX" "SEQEND")))
      (ssadd LastObj aws)
      )
    )
  (if (/=(sslength aws)0)
    aws))

;;;AWS bereinigen, falls ungültige Objekte enthalten
(defun JB_PC_Tools:AwsPurge (aws / AWS1 N)
  (setq aws1 (ssadd))
  (setq n 0)
  (repeat (sslength aws)
    (if (not(vl-catch-all-error-p
              (vl-catch-all-apply 'entget (list(ssname aws n)))))
      (ssadd (ssname aws n)aws1))
    (setq n (+ n 1)))
  (if (/= (sslength aws1)0)
    aws1)
  )


;;;PC_Plaetten => Objekte aus BKS auswählen, ins WKS transformieren, an Plaetten übergeben, danach wieder ins BKS zurücktransformieren
(defun JB_PC_Tools:Flatten:exe ( / LASTOBJ)
  (if (setq JB_PC_Tools$$AWS (JB_PC_Tools:BSK->WKS:exe 'T))
    (progn
      (setq lastObj (entlast))
      ;(c:CADW_Plaetten)
      (command "_.flatten" "_el" 0.0 "_ex" "_no" JB_PC_Tools$$AWS "")
      (setq JB_PC_Tools$$AWS(JB_PC_Tools:LastObjs2Aws JB_PC_Tools$$AWS lastObj))
      (setq JB_PC_Tools$$AWS(JB_PC_Tools:AwsPurge JB_PC_Tools$$AWS))
      
      (JB_PC_Tools:Flatten:exe:Return2Bks JB_PC_Tools$$AWS)
      )
    )

  (setq JB_PC_Tools$$AWS nil)
    
  )

;;;Objekte aus Weltsystem zurück ins BKS transformieren
(defun JB_PC_Tools:Flatten:exe:Return2Bks (aws / KOORDS)
  (setq koords(JBf_Zoom:BildschirmAusschnitt:koords))
  (command "_.copybase" '(0 0 0) aws "")
  (command "_.ucs" "_r" "PC_TOOLS")
  (command "_.ucs" "_d" "PC_TOOLS")
  (command "_.plan" "_c")
  (command "_.pasteclip" '(0 0 0))
  (vla-zoomwindow (vlax-get-acad-object)
        (vlax-3D-Point (car koords))
        (vlax-3D-Point (cadr koords)))
  (JBf_aws:Vla-Delete aws)
  )

;;;XREF's aus Auswahlsatz entfernen
(defun JB_PC_Tools:BKS->WKS:exe:XrefEntf (aws /  AWS1 N)
  (setq aws1 (ssadd))
  (setq n 0)
    (repeat (sslength aws)
      (if (or(/=(cdr(assoc 0 (entget (ssname aws n))))"INSERT")
             (=(vla-get-IsXref(vla-item(vla-get-blocks(vla-get-activedocument(vlax-get-acad-object)))
                                (vla-get-EffectiveName(vlax-ename->vla-object (ssname aws n))))):vlax-false))
        (ssadd (ssname aws n)aws1)
        )
      (setq n (+ n 1))
     )
    

    (if (and aws1 (/=(sslength aws1)0))
      aws1)
  )

  

;;;PC_BKS->WKS Objekte aus BKS ins WKS transformieren
(defun JB_PC_Tools:BSK->WKS:exe (UcsSaveFlag / AWS KOORDS RETAWS)
  (if (and (or(/=(getvar "WORLDUCS")1)
              (alert "Sie müssen sich in einem BKS befinden."))
           (princ "\nWählen Sie Objekte, die ins WKS transformiert werden sollen:")
           (setq aws (ssget))
           (setq aws (JB_PC_Tools:BKS->WKS:exe:XrefEntf aws))
           )
    (progn
      (if UcsSaveFlag

        (command "_.ucs" "_s" "PC_TOOLS"))
      
      (setq koords(JBf_Zoom:BildschirmAusschnitt:koords))
      (command "_.copybase" '(0 0 0) aws "")
      (command "_.ucs" "_w")
      (command "_.plan" "_w")
      (setq LastObj (entlast))
      (command "_.pasteclip" '(0 0 0))
      (vla-zoomwindow (vlax-get-acad-object)
        (vlax-3D-Point (car koords))
        (vlax-3D-Point (cadr koords)))
      (setq RetAws(JB_PC_Tools:LastObjs2Aws nil lastObj))      
      (JBf_aws:Vla-Delete aws)
      )
    )
  RetAWs)
      

(defun JB_PC_Tools:Linie:exe:LineEntmake (p p1 / )
  (entmake (list (cons 0 "LINE")
                 (cons 8 (getvar "CLAYER"))
                 (cons 10 p)
                 (cons 11 p1)))  
(entlast)) 
;;;PC_Linie
(defun JB_PC_Tools:Linie:exe (Art v_liste pfad_ini / CLOSEDFLAG DO N OK P P1 PLIST PUR X Z DBoxFlag)
  (setq Do 'T)
  (if (and(or(setq p (getpoint "\nErsten Punkt angeben:(ENTER=Linientool-Optionen)"))
             (not(setq DBoxFlag 'T)))
          (setq pUr (trans p 1 0))
          (setq Z (caddr pUr)))
    (if (not DBoxFlag)
      (while Do (if (setq p1 (getpoint p "\nNächsten Punkt angeben (ENTER=Optionen):"))
                (progn
                  (setq pList (cons
                                (list(cons "p1"(setq p(reverse(cons z(cdr(reverse(trans p 1 0)))))))
                                     (cons "p2"(setq p1(reverse(cons z(cdr(reverse(trans p1 1 0)))))))
                                     (cons "obj"(JB_PC_Tools:Linie:exe:LineEntmake p p1))
                                     (cons "pv1" nil)
                                     (cons "pv2" nil)
                                     )
                                     pList))
                  (setq p p1)
                  (setq pList(JB_PC_Tools:Linie:exe:Verschnitt:Plist PList nil))
                  )
                (progn
                  (setq PList (JB_PC_Tools:Dbox1 PList)
                        ok (cadr PList)
                        PList (car PList))
                  (if (not PList)
                    (setq p (trans pUr 0 1))
                    (setq p (trans(cdr(assoc "p2" (car pList)))0 1))
                    )

                  (if (not(member ok '(11 13)))
                    (progn
                      (setq Do nil)
                      (if (= ok 99)
                        (progn
                          (mapcar '(lambda(X)
                                     (if (cdr(assoc "obj" X))
                                       (entdel (cdr(assoc "obj" X))))
                                     )PList)
                          (setq PList nil))
                        )
                      )
                    )
                  )
                )
        )
      )
    )

  
(if (not DBoxFlag)
  (if (and PList(= art "PLINE"))
    (progn
      (setq n -1)
      (setq ClosedFlag (= ok 12))
      (JBf_VlaAdd:AddLWPoly
        (apply 'append(mapcar 'JBf_list_xyz->xy(apply 'append
        (mapcar '(lambda(X)
                   (setq n (+ n 1))
                   (if (cdr(assoc "obj" X))
                     (progn
                       
                       (if (= n 0)
                         (list (if (cdr(assoc "pv1" X))(cdr(assoc "pv1" X))(cdr(assoc "p1" X)))
                               (if (cdr(assoc "pv2" X))(cdr(assoc "pv2" X))(cdr(assoc "p2" X))))
                         (if (< (+ n 1) (length PList))
                           (list (if (cdr(assoc "pv2" X))(cdr(assoc "pv2" X))(cdr(assoc "p2" X))))
                           (if (not ClosedFlag)(list (if (cdr(assoc "pv2" X))(cdr(assoc "pv2" X))(cdr(assoc "p2" X)))))
                           )
                         )
                       )
                     )
                   )
          (reverse PList)))))
        (vla-get-layer (vlax-ename->vla-object(cdr(assoc "obj"(car PList)))))
        (if ClosedFlag
          :vlax-true
          :vlax-false))
      (vla-put-elevation (vlax-ename->vla-object(entlast)) Z)

      (mapcar '(lambda(X)
                 (if (cdr(assoc "obj" X))
                   (entdel (cdr(assoc "obj" X))))
                 )PList)
      )
    )
  )

  (if DBoxFlag
    (JB_PC_Tools:Linie:Dbox3 v_liste pfad_ini)
    )
        
  )

;;;PList nach Verschnitt
(defun JB_PC_Tools:Linie:exe:Verschnitt:Plist (PList LastFlag / PLISTSUB PListSub-1 PLISTSUB-2 SP)
  (if (and(>(length pList)1)(=(logand (length pList)1)1)
          (if LastFlag
            (setq PListSub-2 (nth 0 pList))
            (setq PListSub-2 (nth 2 pList))
            )
          (if (not LastFlag)            
            (setq PListSub-1 (nth 1 pList))
            'T
            )
          (if LastFlag
            (setq PListSub (nth (-(length pList)1) pList))
            (setq PListSub (nth 0 pList))
            )
          (setq sp (inters
                     (cdr(assoc "p1" PListSub-2))
                     (cdr(assoc "p2" PListSub-2))
                     (cdr(assoc "p2" PListSub))
                     (cdr(assoc "p1" PListSub))
                     nil)))
    (progn
      (JBf_aws:Vla-DeleteRefresh (ssadd(cdr(assoc "obj" PListSub-2))))
      (if PListSub-1
        (progn
          (JBf_aws:Vla-DeleteRefresh (ssadd(cdr(assoc "obj" PListSub-1))))
          (setq PListSub-1(JBf_list:subst:gc PListSub-1 nil "obj"))
          (setq Plist (JBf_list:nth:change PList PListSub-1 1))
          )
        )

      (JBf_aws:Vla-DeleteRefresh (ssadd(cdr(assoc "obj" PListSub))))
      (setq PListSub-2 (JBf_list:subst:gc PListSub-2 sp "pv2")
            PListSub-2 (JBf_list:subst:gc PListSub-2 (JB_PC_Tools:Linie:exe:LineEntmake (if (cdr(assoc "pv1" PListSub-2))(cdr(assoc "pv1" PListSub-2))(cdr(assoc "p1" PListSub-2))) sp)"obj"))
      (redraw(entlast))
      (setq PListSub (JBf_list:subst:gc PListSub sp "pv1")
            PListSub (JBf_list:subst:gc PListSub (JB_PC_Tools:Linie:exe:LineEntmake sp (if (cdr(assoc "pv2" PListSub))(cdr(assoc "pv2" PListSub))(cdr(assoc "p2" PListSub))))"obj"))
      (redraw (entlast))
      (setq Plist (JBf_list:nth:change PList PListSub-2 (if LastFlag 0 2))
            PList (JBf_list:nth:change PList PListSub (if LastFlag (-(length pList)1)0)))
      )
    )
  PList)

;;;Schnittpunkt für Schließen
(defun JB_PC_Tools:Linie:exe:Schliessen:sp (pList / PLISTSUB PLISTSUB-0)
  (setq PListSub-0 (nth (-(length pList)1) PList))
  (setq PListSub (nth 0 PList))
  (inters
    (if (cdr(assoc "pv2" PListSub-0))(cdr(assoc "pv2" PListSub-0))(cdr(assoc "p2" PListSub-0)))
    (cdr(assoc "p1" PListSub-0))
    (if (cdr(assoc "pv1" PListSub))(cdr(assoc "pv1" PListSub))(cdr(assoc "p1" PListSub)))
    (cdr(assoc "p2" PListSub))
    nil))


;;;Abschließend verschneiden
(defun JB_PC_Tools:Dbox1:Abschluss (pList / )
  (JB_PC_Tools:Linie:exe:Verschnitt:Plist PList 'T)
  )


;;;Zurück
(defun JB_PC_Tools:Dbox1:Zurueck (pList / PLISTSUB-1 PLISTSUB-2 P_LISTE SUBLIST)
  (JBf_aws:Vla-DeleteRefresh (ssadd(cdr(assoc "obj" (car PList)))))
  (setq PList (cdr pList))
  (if (and (not(cdr(assoc "pv2"(car PList))))
           (cdr(assoc "pv2"(cadr PList))))
    (progn
      (setq PListSub-1 (car PList)
            PListSub-2 (cadr PList))
      
      (JBf_aws:Vla-DeleteRefresh (ssadd(cdr(assoc "obj" PListSub-2))))
      (setq PListSub-1 (JBf_list:subst:gc PListSub-1 (JB_PC_Tools:Linie:exe:LineEntmake (cdr(assoc "p1" PListSub-1)) (cdr(assoc "p2" PListSub-1)))"obj"))
      (redraw (entlast))
      (setq PListSub-2 (JBf_list:subst:gc PListSub-2 (JB_PC_Tools:Linie:exe:LineEntmake (if (cdr(assoc "pv1" PListSub-2))(cdr(assoc "pv1" PListSub-2))(cdr(assoc "p1" PListSub-2))) (cdr(assoc "p2" PListSub-2)))"obj"))
      (redraw (entlast))
      (setq  PListSub-2 (JBf_list:subst:gc PListSub-2 nil "pv2"))
      (setq PList(JBf_list:nth:change PList PListSub-1 0))
      (setq PList(JBf_list:nth:change PList PListSub-2 1)))
    )
  
  PList)


(defun JBf_aws:Vla-DeleteRefresh (aws / n A)
  (if aws
    (progn
      (setq n 0)
      (repeat (sslength aws)
        (if (and (ssname aws n)
              (entget (ssname aws n)))
          (progn
            (setq A (vlax-ename->vla-object (ssname aws n)))
            (vla-move A(vlax-3D-point '(0.0 0.0))(vlax-3D-point (list 0.0 (*(getvar "VIEWSIZE")10.0))))
            (vlax-invoke A 'Update)
            (vlax-invoke A 'Delete)))
        
        (setq n (+ n 1))))))


;;;DBox 1
(defun JB_PC_Tools:Dbox1 (PList / A DCLID OK)

  (while (not(member ok '(12 13 1 99)))
    (setq DclId(JBf_Dcl:Load_dialog JB_PC_Tools_$DCL$_File "JB_PC_TOOLS_1" JB_PC_Tools$DCL$_1_po))

    (JB_PC_Tools:Dbox1:mode PList)
    
    (mapcar '(lambda(A)(action_tile A (strcat "(JB_PC_Tools:Dbox1:action \""A"\")")))
      '("JB_1_b1" "JB_1_b2" "JB_1_b3"
        "accept" "cancel"))
    
    (setq ok (start_dialog))
    (unload_dialog DclId)
    
    (cond ((= ok 12);;;Abschließend verschneiden
           (setq pList(JB_PC_Tools:Dbox1:Abschluss pList))
           )
          
          
          )
    )
  (list pList ok))


;;;DBox1; moden
(defun JB_PC_Tools:Dbox1:mode (PList / )
  (if PList
    (mode_tile "JB_1_b1" 0)
    (mode_tile "JB_1_b1" 1)
    )
  (if (and (>=(length PList)5)           
           (JB_PC_Tools:Linie:exe:Schliessen:sp pList))
    (mode_tile "JB_1_b2" 0)
    (mode_tile "JB_1_b2" 1)
    )
  )
  


;;;Action (Variable global in Aufrufender Funktion)
(defun JB_PC_Tools:Dbox1:action (key / )
  (cond

      ((= key "JB_1_b1")
       (setq pList(JB_PC_Tools:Dbox1:Zurueck pList))
       (JB_PC_Tools:Dbox1:mode PList)
       )
      ((= key "JB_1_b2")
       (setq JB_PC_Tools$DCL$_1_po (done_dialog 12))
       )
      ((= key "JB_1_b3")
       (setq JB_PC_Tools$DCL$_1_po (done_dialog 13))
       )
      ((= key "accept")
       (setq JB_PC_Tools$DCL$_1_po (done_dialog 1)))
      ((= key "cancel")
       (setq JB_PC_Tools$DCL$_1_po (done_dialog 99)))
      )
  )


;;;DCL-Datei schreiben
(defun JB_PC_Tools:DclWrite ( / A  FILE)
  (if(and(setq JB_PC_Tools_$DCL$_File(vl-filename-mktemp (strcat "LineCloser.dcl")))
         (setq file (open JB_PC_Tools_$DCL$_File "w")))
    (progn
    (mapcar '(lambda(A)
               (write-line A file))
      (mapcar '(lambda(A)
                 (strcat "\n" A))
        '(
          "JB_PC_TOOLS_1: dialog {label = \"PC_Tools - Linien\";"
          ":boxed_column {label = \"Optionen\";"
          ":button {key = \"JB_1_b1\"; label = \"Segment &Zurück\";}"
          ":spacer {height = 1;}"
          ":button {key = \"JB_1_b3\"; label = \"&Weiter<\";}"
          ":button {key = \"JB_1_b2\"; label = \"Abschließend &verschneiden\";}"
          "}"
          ":row {fixed_width = true; alignment = centered;"
          ":retirement_button {label = \"&Ende\"; key= \"accept\";is_default = true;}"
          ":spacer {width=2;}"
          ":retirement_button {label = \"&Abbrechen\"; key= \"cancel\";is_cancel = true;}"
          "}"
          "}"
          "JB_PC_TOOLS_2: dialog {label = \"PC_Tools - Block einfügen\";"
          ":boxed_column {label = \"Block-Vorlagendatei\";"
          ":row{"
          ":toggle{key = \"JB_2_to2\";}"
          ":text {key = \"JB_2_t2a\"; label = \"geladen\";width = 20;}"
          ":button {key = \"JB_2_b2\"; label = \"Datei...\";}}"
          ":text {key = \"JB_2_t2\"; label = \"PC_Tools-BlockVorlagen01_m.dwg\";width = 50;}"
          "}"
          ":boxed_column {label = \"Block, Attribute\";"
          ":popup_list {key = \"JB_2_p1\"; label = \"Block\";edit_width = 30;}"
          ":row {"
          ":button  {key = \"JB_2_b3\"; label = \"Blockname-&Filter...\"; fixed_width=true;}"
          ":text {key = \"JB_2_t3\"; label = \"PC*\";width = 35;}}"
          ":text {key = \"JB_2_t4\"; label = \"aktueller Layer: \\\"MeinEinfügelayer\\\"\";width = 50;}"
          ":list_box {key = \"JB_2_l1\"; label = \"Attribute\";height = 6;}"
          ":row{"
          ":toggle {key = \"JB_2_to1\";}"
          ":radio_row{"
          ":radio_button {key = \"JB_2_r1\";label= \"X\";}"
          ":radio_button {key = \"JB_2_r2\";label= \"Y\";}"
          ":radio_button {key = \"JB_2_r3\";label= \"Z\";}}}"
          "}"
          ":boxed_column {label = \"Optionen\";"
          ":toggle {key = \"JB_2_to5\";label = \"z=0.0\";}"
          ":edit_box {key = \"JB_2_e1\";label = \"Nachkommastellen\";edit_width = 6; allow_accept=true;}"
          ":edit_box {key = \"JB_2_e2\";label = \"Faktor\";edit_width = 6; allow_accept=true;}"
          "}"
          ":boxed_column {label = \"Optionen Drehung (von Osten, linksdrehend [gon])\";"
          ":row {"
          ":edit_box {key = \"JB_2_e3\";}"
          ":button {key = \"JB_2_b1\"; label = \"Winkel<\";}}"
          ":toggle {key = \"JB_2_to8\";label = \"Winkel aus Linienelement bei Objektfang Lot\";}"
          ":popup_list {key = \"JB_2_p2\"; label = \"Relativer Winkel\";edit_width = 10;}}"
          ":boxed_column {label = \"Optionen Objektfang\";"
          ":edit_box {key = \"JB_2_e4\"; label = \"max. Abstand\";edit_width = 6; allow_accept=true;}"
          ":toggle {key = \"JB_2_to6\";label = \"Lot\";}"
          ":toggle {key = \"JB_2_to7\";label = \"Endpunkt\";}"
          "}"
          ":row {fixed_width = true; alignment = centered;"
          ":retirement_button {label = \"&Einfügen\"; key= \"accept\";is_default = true;}"
          ":spacer {width=2;}"
          ":retirement_button {label = \"E&nde\"; key= \"cancel\";is_cancel = true;}"
          "}"
          "}"
          "JB_PC_TOOLS_3: dialog {label = \"PC_Tools - Linientools\";"
          ":boxed_column {label = \"mit Verschneidung\";"
          ":button {key = \"JB_3_b1\"; label = \"&Linien\";}"
          ":button {key = \"JB_3_b2\"; label = \"&Polylinien\";}"
          "}"
          ":boxed_column {label = \"Linien mehrfach\";"
          ":button {key = \"JB_3_b3\"; label = \"&Mehrfach\";}"
          ":radio_column {"
          ":radio_button {key = \"JB_3_r4\";label = \"z von A u. B jeweils aus Punkt A\";}"
          ":radio_button {key = \"JB_3_r5\";label = \"z aus gepickten Punkten\";}}"
          "}"
          ":row {fixed_width = true; alignment = centered;"
          ":retirement_button {label = \"&Ende\"; key= \"cancel\";is_cancel = true;}"
          "}"
          "}"
          "JB_PC_TOOLS_4: dialog {label = \"Texteingabe\";"
          ":boxed_column {label = \"Blocknamefilter\";"
          ":edit_box {key = \"JB_4_e1\"; allow_accept = true;}"
          "}"
          "ok_cancel;}"
          "JB_PC_TOOLS_5: dialog {label = \"Block-Vorlagendatei\";"
          ":boxed_column {"
          ":list_box {key = \"JB_5_l1\"; width = 50; height=15;label= \"bitte auswählen\";}"
          "}"
          "ok_cancel;}"


          )))
    (close file)
    JB_PC_Tools_$DCL$_File)
    )
  )


;;;Letzten Slash eines Pfades hinzufügen
(defun JB_PC_Tools:Supportpfad:LastSlash:Add (path / STRLIST)
  (setq strList(vl-string->list path))
  (if (/= (last strList)92)
    (vl-list->string(append strList '(92)))
    path))


;;;allgemeine Funktionen für PC_Tools
;;;Supportpfad auslesen und prüfen, ob bereits eine Verzeichnis "PC_TOOLS" vorhanden, wenn nicht, dann Frage an Benutzer an Verzeichnis und dann hinzufügen
(defun JB_PC_Tools:Supportpfad ( / A PATH RETPATH)
  (if (and(setq path(findfile "PC_Tools.lsp"))
          (setq path(car(fnsplitl path)))
          (=(strcase(last(JBf_String:Delimiter->List path "\\")))"PC_TOOLS"))
    (setq RetPath path)
    (progn
      (alert (strcat "Hinweis: die Programmdatei \"PC_Tools.lsp\" muss sich in dem Programmverzeichnis \"PC_Tools\" befinden.\n"
                     "Das Programmverzeichnis muss auf einem Supportpfad liegen.\n\n"
                     "Wählen Sie im Folgenden die Programmdatei \"PC_Tools.lsp\" aus, damit das zugehörige Programmverzeichnis automatisch den Supportpfaden hinzugefügt werden kann."))

      (if (and(setq path(getfiled  "Programmdatei wählen:" "PC_Tools.lsp" "LSP" 4))
              (or (= (strcase (strcat (cadr(fnsplitl path))(caddr(fnsplitl path))))"PC_TOOLS.LSP")
                  (alert "Der Dateiname muss zwingend \PC_Tools.lsp\" heißen."))
              (or(and(setq path(car(fnsplitl path)))
                     (=(strcase(last(JBf_String:Delimiter->List path "\\")))"PC_TOOLS"))
                 (alert "Das Programmverzeichnis muss zwingend \"PC_Tools\" heißen.")))
        (progn
          (setq RetPath path)
          (setenv "ACAD"
            (vl-string-right-trim ";" (apply 'strcat
                                             (mapcar '(lambda (A)
                                                        (strcat A ";")
                                                        )
                                               (append(JBf_String:Delimiter->List (getenv "ACAD") ";")(list path))
                                             )
                                             )
              )
            )
          )
        )
      )
    )
  RetPath)

  
;;;--------------------------------------------------------------------------------------------------------
;;;allgemeine Funktionen => Dcl									   	   
;;;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



;;;DCL-Dialogfenster laden
(defun JBf_Dcl:Load_dialog (FileName DialogName JB_$DCL$_x_po / DclId)
  (setq DclId (load_dialog FileName))
  (if	JB_$DCL$_x_po
    (if (not (new_dialog DialogName DclId "" JB_$DCL$_x_po))
      (exit))
    (if (not (new_dialog DialogName DclId))
      (exit)))
  DclId
  )
;;;--------------------------------------------------------------------------------------------------------
;;;allgemeine Funktionen => Listen								   	   
;;;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

;;;Es wird der GcN-Eintrag gesubst
(defun JBf_list:subst:gc (liste Wert GcN / )
  (subst (cons GcN Wert)(assoc GcN liste)liste))

(defun JBf_list_xyz->xy (list_xyz / )
  (if (>(length list_xyz)2)
    (reverse(cdr(reverse list_xyz)))
  list_xyz))

(defun JBf_list:nth:change(liste EintragNew pos / n )
  (setq n -1)
  (mapcar '(lambda (A)
             (setq n (+ n 1))
             (if (= n pos)
               EintragNew
               A))liste))

 ;;;Att_liste aus vla-object
(defun JBf_list_att_aus_vla-blockdef (name / LISTE)
  (if name
  (if (tblsearch "BLOCK" name)
    (progn
  (vlax-for ITEM
    (vla-item
      (vla-get-blocks
        (vla-get-activedocument
          (vlax-get-acad-object)))name)
    (if (= (vla-get-Objectname ITEM) "AcDbAttributeDefinition")
      (setq liste (cons ITEM liste))))
  (reverse liste)))))


;;;--------------------------------------------------------------------------------------------------------
;;;Setzen von "TrustedPaths's" sab ACAD  2014								   
;;;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



;;;Prüfen, ob bereits TrustedPaths in der aktuelle Version verwendet werden können
  (defun JBf_AcadSystem:TrustedPaths? (/)
    (and (= "ACAD" (strcase (getvar "PROGRAM"))) (getvar "SECURELOAD"))
  )

;;;Pfadangaben immer mit BackSlashes, "\\..." hinten angestellt, damit alle untergeordneten Verzeichnisse berücksichtigt werden
  (defun JBf_AcadSystem:TrustedPaths:Add (pfad / TRUSTEDPATHS)
    (setq TrustedPaths (if (getvar "TRUSTEDPATHS") (getvar "TRUSTEDPATHS") ""))
    (if (not (member (strcase pfad) (mapcar 'strcase (JBf_AcadSystem:TrustedPath:Split TrustedPaths))))
      (setvar "TRUSTEDPATHS" (strcat TrustedPaths ";" pfad))
    )
  )

;;;Pfad entfernen
  (defun JBf_AcadSystem:TrustedPaths:Delete (pfad / A TRUSTEDPATHS)
    (setq TrustedPaths (if (getvar "TRUSTEDPATHS") (getvar "TRUSTEDPATHS") ""))
    (setvar "TRUSTEDPATHS"
            (vl-string-right-trim ";" (apply 'strcat (mapcar '(lambda (A)
                                                                      (strcat A ";")
                                                              )
                                                             (vl-remove-if 'not (mapcar '(lambda (A)
                                                                                                 (if (/= (strcase pfad) (strcase A)) A)
                                                                                         )
                                                                                        (JBf_AcadSystem:TrustedPath:Split TrustedPaths)
                                                                                )
                                                             )
                                                     )
                                      )
            )
    )
  )


;;;String splitten an Semikolons, als Liste zurückgeben
  (defun JBf_AcadSystem:TrustedPath:Split (TrustedPaths / A RETLIST TEMP)
    (mapcar '(lambda (A)
               (if (/= A 59)
                 (setq temp (cons A temp))
                 (setq RetList (cons (vl-list->string (reverse temp)) RetList)
                       temp nil
                 )
               )
             )
            (vl-string->list TrustedPaths)
    )
    (if temp
      (setq RetList (cons (vl-list->string (reverse temp)) RetList))
    )
    (reverse RetList)
  )


;;;--------------------------------------------------------------------------------------------------------
;;;allgemeine Funktionen => Strings								   	   
;;;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


;;;benutzerspezifischer Pfad zum Speichern von Programmeinstellungen
(defun JBf_String:Userpfad (UserPfad / )
  (setq UserList (JBf_String:Delimiter->List UserPfad "\\")
        Pfad (strcat (car UserList)"\\"))

  ;;;wenn UserPfad noch nicht vorhanden, dann erstellen
  (mapcar '(lambda(A)
             (setq Pfad (strcat Pfad A "\\"))
             (if (not (JBf_String:FilePath? Pfad))
               (vl-mkdir Pfad)))
    (cdr UserList))
  userpfad
  )


;;;String anhand Trennzeichen in Liste zurückgeben
(defun JBf_String:Delimiter->List (Str Delim / StrList)
  (setq Str (vl-string-left-trim Delim Str)
	Str (vl-string-right-trim Delim Str))
  (if (vl-string-search Delim Str)
    (progn
      (while (vl-string-search Delim Str)
        (setq StrList (cons (substr Str 1 (vl-string-search Delim Str))StrList)
	      Str (vl-string-left-trim Delim(substr Str(+(vl-string-search Delim Str)(+ (strlen Delim)1))))))
      (if (/= Str "")
        (setq StrList (cons Str StrList))))
    (setq StrList (cons Str StrList)))
  (reverse StrList))

;;;Dateipfad prüfen
(defun JBf_String:FilePath? (Pfad / FSO TRUE-FALSE)
  (setq Pfad (if(vl-string-search "." Pfad)(car(fnsplitl  Pfad))Pfad))
  (if (setq FSO (vlax-create-object "Scripting.FilesystemObject"))
    (progn
      (if (vlax-method-applicable-p FSO 'FOLDEREXISTS)
        (setq TRUE-FALSE
               (=(vl-catch-all-apply
                   'vlax-invoke-method
                   (list FSO 'FOLDEREXISTS Pfad)):vlax-true))
        (vlax-release-object FSO))))
  TRUE-FALSE)




  
         


;;---------------------------------------------------------------------------------------------------------
;;;allgemeine verwaltungstechnische Funktionen							   	   
;;;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

;
;;;Fehlermeldung
;;;Fehlermeldung;;;
(defun JBf_Error  (s)
  (print (strcat "***Fehler*** " s))
  (JBf_Reinit:PC_Tools))

;;;Initialisierungsfunktion
(defun JBf_init:PC_tools (InitVaris / pfad)

  (if (not JB_PC_Tools$$Supportpfad)
    (if(and(not(vl-catch-all-error-p
             (setq pfad(vl-catch-all-apply 'JB_PC_Tools:Supportpfad))))
           pfad)
      (setq JB_PC_Tools$$Supportpfad pfad)))
  (if (not JB_PC_Tools$$Supportpfad)
    (progn
      (alert "Das Programmverzeichnis liegt nicht korrekt auf einem Supportpfad, das Programm wird abgebrochen.")
      (exit)
      )
    ;;;Verzeichnis für Vorlagendateien
    (if (not (member "BlockVorlagen"  (vl-directory-files JB_PC_Tools$$Supportpfad nil -1)))
    (vl-mkdir (strcat JB_PC_Tools$$Supportpfad "BlockVorlagen")))
    )
  

  
  
  (setq	JB_Error *error*
        *error* JBf_Error)
  (vl-load-com)
  ;;;Systemvariablen aktuelle Einstellungen für ReInit speichern
  (setq JBf$ReInit$Varis
         (mapcar '(lambda(A)
                    (list (car A)(getvar (car A))))InitVaris))
  ;;;Vorgabeeistellungen für Systemvariablen
  (mapcar '(lambda(A)
             (if (cadr A)
               (setvar (car A)(cadr A))))InitVaris)
                   
                   
  )

;;;Reinitialisierung
(defun JBf_Reinit:PC_Tools ( / n)
  ;;;Systemvariablen ReInitialisieren
  (mapcar '(lambda(A)
             (setvar (car A)(cadr A)))JBf$ReInit$Varis)
  (setq JBf$ReInit$Varis nil)
  (princ)
)

  
;;;--------------------------------------------------------------------------------------------------------
;;;allgemeine Funktionen => Listen in SIC-Datei sichern  					   	   
;;;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


;;;Liste in LSP-Datei sichern
;;;Sichern von Einstellungen, Ausführung
;;;liste => DottetPairList, die es zu sichern gilt
;;;path => vollständiger Dateipfad mit Dateiname
;;;AcadTrustCheck => 'T or NIL, es wird bei 'T ein temnporärer TrustedPath erstellt und danach auch gleich wieder gelöscht
(defun JBf_SIC:sichern (liste FilePath AcadTrustCheck / FILESTREAM X)

  (setq FileStream (open FilePath "w"))
  (write-line "'(" FileStream)
  (mapcar '(lambda (X)
                   (JBf_SIC:sichern:prin1 X FileStream)
           )
          liste
  )
  (write-line ")" FileStream)
  (close FileStream)

  (if
    (if AcadTrustCheck
      (car (JBf_SIC:load:Catch FilePath nil))
      (vl-catch-all-error-p
        (vl-catch-all-apply 'JBf_SIC:load (list FilePath))
      )
    )


    (if (findfile (strcat (car (fnsplitl FilePath)) (cadr (fnsplitl FilePath)) ".bak"))
      (progn
        (alert (strcat "Die Sicherungsdatei \n\n"
                       FilePath
                       "\n\n ist fehlerhaft und wird automatisch durch die BAK-Datei\n\n"
                       (strcat (car (fnsplitl FilePath)) (cadr (fnsplitl FilePath)) ".bak")
                       "\n\nersetzt."
               )
        )
        (if (vl-file-delete FilePath)
          (vl-file-copy (strcat (car (fnsplitl FilePath)) (cadr (fnsplitl FilePath)) ".bak") FilePath)
          (alert (strcat "Die Sicherungsdatei \n\n"
                         FilePath
                         "\n\n ist fehlerhaft und konnte nicht automatisch durch die BAK-Datei\n\n"
                         (strcat (car (fnsplitl FilePath)) (cadr (fnsplitl FilePath)) ".bak")
                         "\n\nersetzt werden. Bitte führen Sie diesen Arbeitsgang manuell durch."
                 )
          )
        )
      )

      (alert (strcat "Die Sicherungsdatei \n\n"
                     FilePath
                     "\n\n ist fehlerhaft, bitte löschen Sie diese, anderfalls kann das Programm nicht mehr\n"
                     "ordnungsgemäß starten."
             )
      )
    )
    (if (findfile (strcat (car (fnsplitl FilePath)) (cadr (fnsplitl FilePath)) ".bak"))
      (if (vl-file-delete (strcat (car (fnsplitl FilePath)) (cadr (fnsplitl FilePath)) ".bak"))
        (vl-file-copy FilePath (strcat (car (fnsplitl FilePath)) (cadr (fnsplitl FilePath)) ".bak"))
        (alert (strcat "Für die Sicherungsdatei \n\n"
                       FilePath
                       "\n\n konnte keine BAK-Datei erstellt werden. Bitte löschen Sie die vorh. BAK-Datei\n\n"
                       (strcat (car (fnsplitl FilePath)) (cadr (fnsplitl FilePath)) ".bak")
                       "\n\nmanuell."
               )
        )
      )
      (vl-file-copy FilePath (strcat (car (fnsplitl FilePath)) (cadr (fnsplitl FilePath)) ".bak"))
    )
  )
)


;;;Laden der Datei um zu prüfen, ob diese korrekt ist!
  (defun JBf_SIC:load (FilePath /)
    (load FilePath)
  )

;;;Pfad muss existieren, Prüfung in aufrufender Funktion und temporärem TrustPath
  (defun JBf_SIC:load:Catch (PathFile ErrMsg / ERROR RETVAL TRUTHPATHSET)
    (if (JBf_AcadSystem:TrustedPaths?)
      (progn
        (setq TruthPathSet 'T)
        (JBf_AcadSystem:TrustedPaths:Add (strcat (car (fnsplitl PathFile)) "..."))
      )
    )

    (setq error (vl-catch-all-error-p
                  (setq RetVal (vl-catch-all-apply 'JBf_SIC:load:Catch:do (list PathFile)))
                )
    )
    (if (and error ErrMsg)
      (alert ErrMsg)
    )

    (if TruthPathSet
      (JBf_AcadSystem:TrustedPaths:Delete (strcat (car (fnsplitl PathFile)) "..."))
    )


    (list error RetVal)
  )

;;;Iteratives lustiges Listenschreiben
  (defun JBf_SIC:sichern:prin1 (A FileStream / B)

    (cond  ;;;wenn einzelner Eintrag
                 ((atom A)
                        (write-line (vl-prin1-to-string A) FileStream)
                 )
      ((and (atom (car A)) (not (cdr A)))  ;;;GC ohne Wert
            (write-line (vl-prin1-to-string A) FileStream)
      )
      ((and (atom (car A)) (cdr A) (not (listp (cdr A))))  ;;;DottedPair
            (write-line (vl-prin1-to-string A) FileStream)
      )
      ((and (atom (car A)) (cdr A) (listp (cdr A)) (= (length (cdr A)) 1) (atom (car (cdr A))))  ;;;GC + Wert
            (write-line (strcat "(" (vl-prin1-to-string (car A))) FileStream)
            (mapcar '(lambda (B)
                             (JBf_SIC:sichern:prin1 B FileStream)
                     )
                    (cdr A)
            )
         (write-line ")" FileStream)
      )
      ((and (atom (car A)) (cdr A) (listp (cdr A)))  ;;;GC + Liste
            (write-line (strcat "(" (vl-prin1-to-string (car A))) FileStream)
            (mapcar '(lambda (B)
                             (JBf_SIC:sichern:prin1 B FileStream)
                     )
                    (cdr A)
            )
         (write-line ")" FileStream)
      )
      ( 'T
        (write-line "(" FileStream)
        (mapcar '(lambda (B)
                         (JBf_SIC:sichern:prin1 B FileStream)
                 )
                A
        )
         (write-line ")" FileStream)
      )
    )
  )


;;;--------------------------------------------------------------------------------------------------------
;;;allgemeine Funktionen => vla  								   	   
;;;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

;;;LW-Polylinien adden
;;;closedFlag :vlax-true oder :vlax-false
;;;koord als (apply 'append koord-List mit xy)
(defun JBf_VlaAdd:AddLWPoly(koords layer closedFlag / KOORDSARRAY)
  (setq KoordsArray (vlax-make-safearray vlax-vbDouble (cons 0  (-(length koords)1))))
  (vlax-safearray-fill KoordsArray koords)
  (vla-addLightweightPolyline (vla-get-modelSpace (vla-get-activeDocument (vlax-get-acad-object)))KoordsArray)
  (vla-put-layer(vlax-ename->vla-object(entlast))layer)
  (vla-put-closed(vlax-ename->vla-object(entlast))closedFlag)
  )


;;;alle Objekte eins Auswahlsatzes löschen (ohne Command)
(defun JBf_aws:Vla-Delete (aws / n)
  (if aws
    (progn
      (setq n 0)
      (repeat (sslength aws)
        (if (and (ssname aws n)
              (entget (ssname aws n)))
        (vla-delete (vlax-ename->vla-object(ssname aws n))))
        (setq n (+ n 1))))))


;;;NotFlag: damit werden die WcMatch-Filter negiert
;;;Filter, dem muss der Blockname per WCMATCH entsprechen
(defun JBf_tblFuncs:Get:VlaTblObj:PC_Tools (tblName Filter NotWcmatchList NotFlag / RETLIST)
  (vlax-for ITEM (vlax-get(vla-get-activedocument (vlax-get-acad-object))tblName)
    (if (or(not NotWcmatchList)
           (and NotWcmatchList (not (JBf_tblFuncs:Get:VlaTblObj:Wcmatch?:PC_Tools NotWcmatchList (strcase Filter) NotFlag (strcase(vlax-get ITEM 'name))))))
      (setq RetList (cons (vlax-get ITEM 'name)RetList))))
  (vl-sort retList '(lambda(e1 e2)(< (strcase e1) (strcase e2)))))

;;;Namen von Tabellenobjekten per WCMatch prüfen
(defun JBf_tblFuncs:Get:VlaTblObj:Wcmatch?:PC_Tools (NotWcmatchList Filter NotFlag name / )
  (if(wcmatch name Filter)
    (vl-remove-if 'not
      (mapcar '(lambda(A)
                 (if (not NotFlag)
                       (wcmatch name A)
                       (not(wcmatch name A)))
                 )NotWcmatchList))
    'T
    ))

;;;Prüfen, ob in AttDef ein Schriftfeld vorhanden ist
(defun JBf_VlaAdd:AddBlock:FieldInAtt? (vla-Att / RETVAL)
  (vlax-for ITEM
	    (vla-GetExtensionDictionary
                       vla-Att)
    (if (=(vla-get-name ITEM)"ACAD_FIELD")
      (setq RetVal 'T)))
  RetVal)
      

;;;FeldBlockFlag: wenn 'T, dann wird bei der Vergabe von Textwerten geprüft, ob im Attribut ein Feld definiert ist, wenn ja, dann wird der Textwert nicht übertragen => das Schriftfeld bleibt erhalten
(defun JBf_VlaAdd:AddBlock (BlockName 3d-InsPoint ScaleFactor Layer Rotation 3d-Normal AttListFill FeldBlockerFlag / ATTLIST SPACE VLA-ATT VLA-OBJ X Y)
  
 (if (or(= (strcase (getvar "CTAB")) "MODEL")
         (/=(getvar "CVPORT")1))
    (setq Space (vla-get-ModelSpace (vla-get-ActiveDocument (vlax-get-acad-object))))
    (setq Space (vla-get-PaperSpace (vla-get-ActiveDocument (vlax-get-acad-object))))
    )

  (setq	vla-obj
         (vla-insertblock
           Space
           (vlax-3d-point '(0 0 0))
           BlockName
	   ScaleFactor
	   ScaleFactor
	   ScaleFactor
	   Rotation
	 ))

  (vla-put-Layer vla-obj Layer)
  ;(vla-put-Normal vla-obj 3d-Normal) => Die Normale wird automatisch entsprechend des aktuellen WKS's / BKS gesetzt, auf Nebenwirkungen achten!!!

  ;;;(vla-put-InsertionPoint vla-obj 3d-InsPoint) => musste deaktiviert und durch vla-move ersetzt werden, weil sonst Attribute mit Ausrichtung Mitte-Links die doppelte Höhe erhalten 07.09.18
  (vla-Move vla-obj (vlax-3d-point '(0 0 0)) 3d-InsPoint)

    
  (if (and AttListFill(=(vla-get-HasAttributes vla-obj):vlax-true)
	   (setq AttList (mapcar '(lambda (X)(cons (strcase(vla-get-TagString X))X))
			    (vlax-invoke vla-obj 'getAttributes))))
    (mapcar '(lambda(X)
	       (if (setq vla-att(cdr(assoc (car X)AttList)))		       
		 (mapcar '(lambda(Y)
			    (if(or (not FeldBlockerFlag)
				   (/= (car Y)'TEXTSTRING)
				   (and (=(car Y)'TEXTSTRING)
					(not (JBf_VlaAdd:AddBlock:FieldInAtt? vla-att))))
			      (if (vlax-property-available-p vla-att(car Y))
				(vlax-put vla-att (car Y)(cadr Y))))
			    )
			 (cadr X))))

	    AttListFill))
  
  vla-obj)


;;;Koordinatenliste umformen
(defun JBf_VlaObjects:GetKoord->List (n z liste / LISTE1)
  (setq i (* n -1))
  (repeat (/(length liste)n)
    (setq i (+ i n))
    (setq liste1 (cons (list (nth i liste)(nth (+ i 1) liste)(if z z(nth (+ i 2) liste)))liste1)))
  (reverse liste1))

;;;Koordinaten aus vla-Objekten abfragen
(defun JBf_VlaObjects:GetKoord (vla-obj / )
  (cond ((member (vla-get-ObjectName vla-obj) '("AcDbPolyline" "AcDbLwPolyline"))
	 (JBf_VlaObjects:GetKoord->List 2 (vla-get-Elevation vla-obj) (vlax-get vla-obj 'Coordinates)))

	((= (vla-get-ObjectName vla-obj) "AcDb2dPolyline")
	 (JBf_VlaObjects:GetKoord->List 3 (vla-get-Elevation vla-obj) (vlax-get vla-obj 'Coordinates)))

	((= (vla-get-ObjectName vla-obj) "AcDb3dPolyline")
	 (JBf_VlaObjects:GetKoord->List 3 nil (vlax-get vla-obj 'Coordinates)))
	

	((= (vla-get-ObjectName vla-obj) "AcDbArc")
	 (list
	   (vlax-get vla-obj 'StartPoint)
	   (polar (vlax-get vla-obj 'Center)
		  (angle (vlax-get vla-obj 'Center)
			 (polar (vlax-get vla-obj 'StartPoint) (angle (vlax-get vla-obj 'StartPoint) (vlax-get vla-obj 'EndPoint))
				(/(distance (vlax-get vla-obj 'StartPoint) (vlax-get vla-obj 'EndPoint))2.0)))
		  (vla-get-Radius vla-obj))
	   (vlax-get vla-obj 'EndPoint)))
	
	((= (vla-get-ObjectName vla-obj) "AcDbLine")
	 (list
	   (vlax-get vla-obj 'StartPoint)
	   (vlax-get vla-obj 'EndPoint)))))


;;;Linienelement: VektorPunkt zurückgeben
(defun JBf_vlax-curve-Vektor:VektorPkt (vla-obj / KOORDS)
  (cond((member(vlax-get vla-obj 'ObjectName)'("AcDbLine" "AcDbArc"))
        (vlax-get vla-obj 'StartPoint))
       ((member(vlax-get vla-obj 'ObjectName) '("AcDb2dPolyline" "AcDbPolyline"))
        (setq koords (vlax-get vla-obj 'Coordinates))
        (list (car koords)(cadr koords)0.0))
       ((member(vlax-get vla-obj 'ObjectName) '("AcDbSpline"))
        (setq koords (vlax-get vla-obj 'ControlPoints))
        (list (car koords)(cadr koords)0.0))))



;;;Closest PointTo
(defun JBf_vlax-curve-Vektor:getClosestPointTo (obj pkt / KOORD PKT1 VEKTOR)
  (if (setq vektor (JBf_vlax-curve-Vektor:VektorPkt(vlax-ename->vla-object obj)))
    (progn
      (vla-move (vlax-ename->vla-object obj) (vlax-3d-point vektor)(vlax-3d-point '(0.0 0.0 0.0)))
      (setq koord '(0.0 0.0 0.0)
            pkt1 (mapcar '+(vlax-curve-getClosestPointTo(vlax-ename->vla-object obj)(mapcar '- pkt vektor))vektor))
      (vla-move (vlax-ename->vla-object obj)(vlax-3d-point '(0.0 0.0 0.0)) (vlax-3d-point vektor))
      pkt1)))


    

;;;--------------------------------------------------------------------------------------------------------
;;;allgemeine Funktionen         								   	   
;;;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;;;Welt- oder BKS-Koordinaten des aktuellen Ausschnitts
(defun JBf_Zoom:BildschirmAusschnitt:koords ( / )
  (list
    (list(-(car (getvar "viewctr"))
           (*(/(getvar "viewsize")
               (cadr(getvar "screensize")))
             (car(getvar "screensize"))
             0.5))
         (-(cadr(getvar "viewctr"))
           (/(getvar "viewsize")2.0))
         )
    (list(+(car (getvar "viewctr"))
           (*(/(getvar "viewsize")
               (cadr(getvar "screensize")))
             (car(getvar "screensize"))0.5))
         (+(cadr (getvar "viewctr"))
           (/(getvar "viewsize")2.0)))))


;;;--------------------------------------------------------------------------------------------------------
;;;DBX-Funktionen            	 								   	   
;;;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


;;;Rückgabe: gültiges DBX-Objekt für aktuelle Version
(defun JBf_DBX:Open:GetVS (vs / DBX)
  (if(not(vl-catch-all-error-p
           (setq DBX (vl-catch-all-apply
                       'vla-GetInterfaceObject
                       (list
                         (vlax-get-acad-object)
                         vs)))
           ))DBX))
;;;DBX-Objekt
(defun JBf_DBX ( / DBX)
  (if (>=(setq vs (atoi (getvar "ACADVER")))15)
    (JBf_DBX:Open:GetVS (strcat "ObjectDBX.AxDbDocument."(itoa vs)))
    (JBf_DBX:Open:GetVS "ObjectDBX.AxDbDocument")
  )
)
 

;;;DWG-Datei als DBX-Object öffnen (nur, wenn gültig und nicht schreibgeschützt
(defun JBf_DBX:Open(DBX dwgname / )
  (not(vl-catch-all-error-p   
        (vl-catch-all-apply 'vla-open(list DBX dwgname)))))
;;;DBX-Object wieder freigeben
(defun JBf_DBX:Release(DBX / )
  (not(vl-catch-all-error-p
        (vl-catch-all-apply
          'vlax-release-object(list DBX)
          ))))
;;;DBX-Objekt speichern
(defun JBf_DBX:SaveAs (DBX DWGname / )
  (not(vl-catch-all-error-p
        (vl-catch-all-apply
          'vla-saveas(list DBX DWGNAME)  
        )))
  )


;;;Collection-Objekts aus DBX in aktuelle Zeichnung kopieren: dazu muss DBX-Objekte geöffnet sein
;;;Bereits vorhandene Einträge werden übergangen
;;; z.B. 'Layer oder 'Blocks
;;;Rückgabe 'T, wenn erfolgreich oder gar kein array, wenn NIL, dann fehler bei array-Bildung => irgendeins von den Objekten war wohl schlecht.
(defun JBF_DBX:Copy:CollectionObjects:PC_tools (DBX collName FilterList / array BlockEinheitCheckList RetVal)

  (setq RetVal
         (or(not(setq array(JBF_DBX:CopyObjects:coll->array:PC_tools
                             (vlax-get DBX collName)collName FilterList)))
            (not(vl-catch-all-error-p
                  (vl-catch-all-apply
                    'vla-CopyObjects
                    (list DBX
                          array
                          (vlax-get(vla-get-activedocument(vlax-get-acad-object))collName)))))))

  ;;;Jetzt noch die Blockeinheiten prüfen
  (if BlockEinheitCheckList(JB_PC_Tools:Block:Einheit:Check BlockEinheitCheckList))

  RetVal
    )


;;;Hilfsfunktion für Zeichnungseinheiten
(defun JB_PC_Tools:Block:Einheit:Check (BlockEinheitCheckList / BLOCKNAME INSUNITSLIST LOGLIST VLA-BLOCKDEF X)
  (setq InsunitsList '((0 . "Nicht festgelegt (Keine Einheiten)")
                       (1 . "Zoll")
                       (2 . "Fuß")
                       (3 . "Meilen")
                       (4 . "Millimeter")
                       (5 . "Zentimeter")
                       (6 . "Meter")
                       (7 . "Kilometer")
                       (8 . "Mikro-Zoll")
                       (9 . "Milli-Zoll")
                       (10 . "Yard")
                       (11 . "Ångström")
                       (12 . "Nanometer")
                       (13 . "Mikrometer")
                       (14 . "Dezimeter")
                       (15 . "Dekameter")
                       (16 . "Hektometer")
                       (17 . "Gigameter")
                       (18 . "Astronomische Einheiten")
                       (19 . "Lichtjahre")
                       (20 . "Parsec")
                       (21 . "US Survey Feet")
                       (22 . "US Survey Inch")
                       (23 . "US Survey Yard")
                       (24 . "US Survey Mile")))

  (mapcar '(lambda(BlockName)
             (setq vla-BlockDef (vla-item(vla-get-blocks(vla-get-activedocument(vlax-get-acad-object)))BlockName))
             (if (/= (vla-get-units vla-BlockDef)(getvar "INSUNITS"))
               (progn
                 (setq LogList (cons (list BlockName (vla-get-units vla-BlockDef)(getvar "INSUNITS"))LogList))
                 (vla-put-units vla-BlockDef (getvar "INSUNITS"))
                 )
               )
                 
             )
    BlockEinheitCheckList)

  (if LogList
    (alert (apply 'strcat
                  (append (list (strcat "Für folgende Blöcke wurde die Blockeinheit an  die aktuelle Zeichnungseinheit ["
                                  (cdr(assoc (getvar "INSUNITS")InsunitsList))"] angepasst:\n"))
                    (mapcar '(lambda(X)
                               (strcat "\n- "(car X) " ["(cdr(assoc (cadr X)InsunitsList))"]"))LogList)
                    )
                  )
          )
    )
  )
                             
  

(defun JBF_DBX:CopyObjects:coll->array:PC_tools(collObject collName FilterListe / array n COPYLIST)

  (vlax-for item collObject
    (cond ((= collName 'BLOCKS)
	   (if (not(or(=(strcase(vla-get-name item))"*MODEL_SPACE")
		      (wcmatch (strcase(vla-get-name item))"`*PAPER_SPACE*")))
             (progn
               (setq CopyList (cons ITEM CopyList))
               (if (not(tblsearch "BLOCK" (vla-get-name item)))
                 (setq BlockEinheitCheckList (cons (vla-get-name item)BlockEinheitCheckList))
                 )
               )
               ))
	   ((= collName 'LAYERS)
            (if (member(vla-get-name item)FilterListe)
              (setq CopyList (cons ITEM CopyList)))
            )
	  ))
		   


  (if CopyList
    (progn
      (setq array
             (vlax-make-safearray vlax-vbObject
               (cons 0
                     (-(length CopyList)1)
                           )
               )
            )
      ;(vlax-safearray-fill array CopyList)
      (setq n 0)
      (foreach item CopyList
        (vlax-safearray-put-element array n item)
        (setq n(+ n 1))
        )
      array
      )
    )
       
)

;;;Objekt prüfen, ob in Filterliste vorhanden
(defun JBF_DBX:Copy:Objects:InFilterList? (vla-obj FilterList / RETVAL)
  (while (and (not RetVal)FilterList)
    (if (and (vl-remove-if '(lambda(X)(/=(strcase(vla-get-layer vla-obj))X))(mapcar 'strcase (car(car FilterList))))
             (vl-remove-if '(lambda(X)(/=(vla-get-Objectname vla-obj)X))(cadr(car FilterList))))
      (setq RetVal 'T))
    (setq FilterList (cdr FilterList)))
  RetVal)
  


;;;kopieren von Objekten aus DBX-Objekt Modelbereich in Modelbereich aktuelle Zeichnung anhand von Filterlisten
(defun JBF_DBX:Copy:Objects (FilePath FilterList / COPYLIST DBX EXITFLAG)
  
  
  (if (setq DBX(JBf_DBX))
    (progn
      (if (JBf_DBX:Open DBX FilePath)
	(progn
          (vlax-for item
                 (vla-get-modelSpace DBX)
            (if (JBF_DBX:Copy:Objects:InFilterList? item FilterList)
              (setq CopyList (cons item CopyList))
              )
            )

          (if CopyList
            (vla-CopyObjects
              DBX
              (vlax-safearray-fill
                    (vlax-make-safearray
                      vlax-vbObject
                      (cons 0 (-(length CopyList) 1))
                      )
                    (reverse CopyList))
              (vla-get-ModelSpace(vla-get-activedocument
                                   (vlax-get-acad-object)
                                   ))
              ))
          )

	(alert (strcat "Die Datei \"" FilePath "\" konnte nicht geöffnet werden, Schreibschutz?"))
	)
      (JBf_DBX:Release DBX))
    )
  )



;;;BlockDefinition (dublizieren)in temporäres DBX-Objekt kopieren, dann umbenennen und dann wieder in die Zeichnung zurück kopieren
;;;Neuer Name muss vorher geprüft werden, ob er nicht bereits existiert oder ungültig ist.
(defun JBF_DBX:BlockDefCopy (BlocknameAlt BlockNameNeu / DBX VLA-BLOCKDBX VLA-BLOCKDEFDBX VLA-BLOCKDEFDRAWING VLA-BLOCKDRAWING VLA-DRAWING)
  (if (setq DBX(JBf_DBX))
    (progn
      (setq vla-Drawing (vla-get-activedocument(vlax-get-acad-object)))
      (setq vla-BlockDrawing (vla-get-blocks vla-Drawing))
      (setq vla-BlockDbx (vla-get-blocks DBX))
      (setq vla-BlockDefDrawing (vla-item vla-BlockDrawing BlocknameAlt))
      
      (vlax-invoke vla-Drawing 'Copyobjects (list vla-BlockDefDrawing) vla-BlockDbx)
      (setq vla-BlockDefDbx (vla-item vla-BlockDbx BlocknameAlt))
      (vla-put-Name vla-BlockDefDbx BlockNameNeu)
      (vlax-invoke DBX 'Copyobjects (list vla-BlockDefDbx) vla-BlockDrawing)
      (JBf_DBX:Release DBX)
      )
    )
  )


;;;--------------------------------------------------------------------------------------------------------
;;;BricsCAD-TIN-Funktionen     	 								   	   
;;;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


;;;Prüfen, ob BricsCAD Pro V21 aufwärts 
(defun JBf_Brics_TIN:Pro21-p ( / )
  (or(and(=(strcase(getvar "PROGRAM"))"BRICSCAD")
         (not(null vl-load-tin))
         (>=(atof(getvar "ACADVER"))22.1)
         (>(getvar "RUNASLEVEL")0))
         (alert "Hinweis: Für die Nutzung der TIN-Funktionen wird BricsCAD Pro 21 aufwärts benötigt.")
  )
  
)

;;;vor Nutzung der TIN-Funktionen nutzen
(defun JBf_Brics_TIN:Ini ( / )
  (if(JBf_Brics_TIN:Pro21-p)
    (vl-load-tin))
)

;;;TIN aus Koordiantenliste erstellen => Rückgabe TIN-Surface als obj
(defun JBf_Brics_TIN:CreateWithPoints (koords / minPoint maxPoint objTIN)
  (if (>= (length koords) 3)
    (progn
      (setq minPoint (list (apply 'min (mapcar 'car koords))
                           (apply 'min (mapcar 'cadr koords))
                           (apply 'min (mapcar 'caddr koords))
                     )
      )
      (setq maxPoint (list (apply 'max (mapcar 'car koords))
                           (apply 'max (mapcar 'cadr koords))
                     )
      )
      (setq objTIN (tin:createTin minPoint maxPoint (length koords)))
      (if (tin:addpoints objTIN koords)
        objTIN
      )
    )
  )
)


;;;--------------------------------------------------------------------------------------------------------
;;;Info für Textfenster nach dem laden des Programms							   
;;;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

(princ (strcat
          "\n|++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++|"
          "\n|PC_Tools: Funktionen für Pointcab.                              |"
          "\n|----------------------------------------------------------------|"
          "\n|erstellt durch Bosse-engineering - www.bosse-engineering.com    |"
          "\n|----------------------------------------------------------------|"
          "\n| - PC_LINIE: (Poly)Linien mit Verschneidung oder Mehrfachlinien.|"
          "\n| - PC_BKS->WKS: Objekte aus dem BKS ins WKS transformieren.     |"
          "\n| - PC_FLATTEN:   Obj. im BKS mit \"FLATTEN\" bearbeiten.          |"
          "\n| - PC_BLOCK: Blöcke einfügen.                                   |"
          "\n| - PC_FLAECHE: TIN-Oberfläche aus gepickten Punkten.            |"
          "\n|++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++|"
          )
       )
(princ)


