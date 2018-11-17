#INCLUDE 'Protheus.ch'
#INCLUDE "rwmake.ch"
#INCLUDE "TOTVS.CH"         	
#INCLUDE "TBICONN.CH"
#INCLUDE "TOPCONN.CH"
#Include "Colors.ch"
#INCLUDE "Fileio.ch"

#DEFINE DS_MODALFRAME   128 

/*              
+-----------+------------+----------------+-------------------+-------+---------------+
| Programa  | FSCRMA30   | Desenvolvedor  | Catharina Oliveira| Data  | 13.09.2017    |       
+-----------+------------+----------------+-------------------+-------+---------------+
| Descricao | CRM                                |
+-----------+-------------------------------------------------------------------------+
| Modulos   | SIGATMK + SIGACRM                                                       |
+-----------+-------------------------------------------------------------------------+
|           ALTERACOES FEITAS DESDE A CRIACAO                            		      |
+----------+-----------+--------------------------------------------------------------+
| Autor    | Data      | Descricao                                       			  |
+----------+-----------+--------------------------------------------------------------+
|          |           |                                                              |
+----------+-----------+--------------------------------------------------------------+ 
*/                                                            

User Function FSCRMA30()  
****************************************************************************************
* 
* 
*****

    Local cAdminCAT		:= SuperGetMV("FS_USADMCA", (.T.), "")  
    Local cAdminCRM		:= SuperGetMV("FS_USCRMAD", (.T.), "")     
    
	Private cPerg		:= ""
	Private cFilAtEv  	:= Space(6)         // Código Atendimento CAT ou Evolução CRM
	Private cFilOpVe 	:= Space(6)         // Código Operador ou Vendedor
	Private cFilCod  	:= Space(6)
	Private cFilReg  	:= Space(1)
	Private cFilSeg		:= Space(6)	
	Private cFilCat  	:= Space(2)  
	Private cFilDtDe 	:= Space(8)			// Data Atendimento CAT ou Agendamento CRM	
	Private cFilDtAte 	:= Space(8)			// Data Atendimento CAT ou Agendamento CRM	
	Private nFilStat   	:= 1
	Private nEditPos	:= 0
	Private nEditEvol	:= 0
	Private lBloqCAT   	:= .F.
	Private lBloqCRM   	:= .F.	
	Private lFiltro		:= .F.
    Private dDataAD7	:= Date()  
	Private lAdminCAT	:= ( __CUSERID $ cAdminCAT )  			 // É administrador?
	Private lAdminCRM	:= ( __CUSERID $ cAdminCRM )  			 // É administrador?	
    Private cOpeNVenc	:= SuperGetMV("FS_OPNVENC", (.T.), "")   // Usuário com atendimento remoto sem vencimento. 
    Private cVenNVenc	:= SuperGetMV("FS_VENVENC", (.T.), "")   // Usuário com atendimento presencial sem vencimento. 
    Private cCodOper	:= ""
    Private cNomOper	:= ""
    Private cCodVend	:= Space(6)
    Private cVendTmp	:= Space(6)
    Private cNomVend	:= ""     
	Private	cBloqueio	:= ""
    Private cUSEstat	:= ""    
    Private cHoraIni    := ""
	Private cMemoObs1	:= "" 
	Private cMemoObs2	:= ""    
	Private cEvenCAT	:= ""   
	Private cLocalUC	:= ""	              

	Private cUCEstag	:= "" 
	Private cUDMotRe	:= ""
	Private cEmLigac	:= ""
	Private cEvenCRM	:= ""  
	Private cMotCAT		:= ""   								// Inclusão do Motivo do desinteresse ou Inexistência | Catharina - 14.09.2018	
	Private cMotCRM		:= ""									// Inclusão do Motivo do desinteresse ou Inexistência | Catharina - 14.09.2018	
	Private cDescLoc	:= ""	
	Private	dDesBloqu 	:= CToD("")
    Private dDtEvento	:= CToD("")	
	Private dDtAgenda	:= CToD("") 
	Private	cHoraAgen 	:= "  :  "          
    Private cHoraEven	:= "  :  "     
	Private	cLocAgen    := Space(3)  
    Private cUCAgen		:= Space(3)  
	Private cSayData	:= "Para quando:"     
	Private oCodVend,  oNomVend,  oMsCalend
	Private oDtEvento, oHoraEven, oUCAgen
	Private oDtAgenda, oHoraAgen, oLocAgen, oDescLoc, oCmbCAT  
	Private oMemoObs1, oCombCAT,  oCombCRM, oMemoObs2, oCmbCRM
	    
    Private aBrowCAT	:= {}  
    Private aBrowCRM	:= {}     
    Private oBrowCAT, oBrowCRM
    
   	Private oVERD := LoadBitmap( GetResources(), "BR_VERDE" 	) 
	Private oAMAR := LoadBitmap( GetResources(), "BR_AMARELO" 	) 
	Private oVERM := LoadBitmap( GetResources(), "BR_VERMELHO"	) 	
	Private oLARA := LoadBitmap( GetResources(), "BR_LARANJA" 	) 		
	Private oAZUL := LoadBitmap( GetResources(), "BR_AZUL" 		) 
	
	If !(cEmpant $ '13') //!!		
		MsgBox(OemToAnsi("Esta empresa não está parametrizada para utilização desta rotina. Gentileza alterar!!!"),OemtoAnsi("Erro!!!"),"STOP")				
		Return ( .F. )
	EndIf			
    
	lBloqCRM := fBuscaCod(__CUSERID)
	
	If Empty(cCodOper)
		lBloqCAT := .T.
	EndIf   
	
	If Empty(cCodVend)
		lBloqCRM := .T.
		cCodVend := Space(6) 
		cVendTmp := Space(6)
	Else
		cVendTmp := cCodVend
	EndIf	            		

	// Executa SQL
	Processa({|| Consulta()},"Aguarde...","Buscando Clientes...")    		
	
	MontaTela()
	
Return()  


Static Function fBuscaCod(cUsuar)
***************************************************************************************
* Buscar código de operador (CAT), vendedor (CRM) e situação de bloqueio
* do usuário logado.
*****

	Local aArea		:= GetArea()  
	Local cQuery	:= "" 
	Local cU7Vend	:= ""  
	Local cU7CodV	:= ""
	Local lRet		:= .F.          
	Local cLiberados:= 
     
    // Busca código de vendedor (CRM)
    dbSelectArea("SA3")
    dbSetOrder(7)                      
	If dbSeek ( xFilial ( "SA3" ) + cUsuar) 
	
		If !(SA3->A3_USBLOQU == "1")
			cCodVend  := AllTrim(SA3->A3_COD)
			cNomVend  := SA3->A3_NOME
			cBloqueio := SA3->A3_USBLOQU
			dDesBloqu := SA3->A3_DTBLOQU 		
		EndIf 
		
		// Se bloqueado, não permite acesso do vendedor				
	EndIf
	
    // Busca código de operador (CAT)
    dbSelectArea("SU7")
    dbSetOrder(4)                      
	If dbSeek ( xFilial ( "SU7" ) + cUsuar)  
		If SU7->U7_TIPOATE $ '2_4_6' //TeleVendas + TeleAtendimento ou 4=Todos
			cCodOper := SU7->U7_COD
			cNomOper := SU7->U7_NOME
			cU7Vend	 := SU7->U7_VEND 
			cU7CodV  := AllTrim(SU7->U7_CODVEN)
			
			// Para operador da CAT, Caso o vendedor não esteja associado ao operador corretamente, não libera CRM
			If cU7Vend <> "1" .Or. Empty(cU7CodV) .Or. cU7CodV <> cCodVend
		   		cCodVend := Space(6)
		   		cNomVend := ""
			EndIf			
		EndIf		
	EndIf	                      
             
	RestArea(aArea)	

Return(lRet)


Static Function Consulta(nOpc)
*****************************************************************
* 
*                                                             
***                                             
	Local cQuery    := ""          
	Local dAgenData	:= Date() 
	
	Default nOpc 	:= 0     
	
	ProcRegua(10)  
	IncProc()
	IncProc()	

	// Executa se Geral ou 1=Específico(CAT)
	If nOpc <> 2

		cQuery	:= " SELECT U4_LISTA LISTA, CASE WHEN ISNULL(UC_PENDENT,'')='' THEN U4_DATA 	 	" + CRLF 
		cQuery	+= " 	ELSE UC_PENDENT END DATALST, U4_HORA1 HORALST, U4_DESC DESCRICAO,  			" + CRLF 
		cQuery	+= "	U4_OPERAD OPERADOR, /*SU7.U7_NOME NOMEOPER,*/ UC_CODOBS, US_COD, US_LOJA,	" + CRLF	
		cQuery	+= "	ISNULL(UC_CODIGO,'')UC_CODIGO, US_CODCLI CODCLI, US_LOJACLI LOJACLI,		" + CRLF
		cQuery	+= "	U4_ESTAGIO ESTAGIO, U4_CODLIG CODLIG, ISNULL(UD_MOTREAG,'') UD_MOTREAG,		" + CRLF 
		cQuery	+= "	U4_CONTATO CODCONT,SUS.US_NOME NOMECLI,US_DDD, RTRIM(LTRIM(SUS.US_TEL))TEL1," + CRLF
		cQuery	+= "	RTRIM(LTRIM(SUS.US_FAX))TEL2,RTRIM(LTRIM(SUS.US_EMAIL)) EMAIL,U4_DATA DTDIS," + CRLF 
		cQuery	+= "	SUS.US_ZORIGEM LOCALCAD, SUS.US_ZORIGEX ORIGEX, ISNULL(X5_DESCRI,'') ORIGEM," + CRLF
		cQuery  += "	CASE WHEN U4_ESTAGIO= '2' AND ISNULL(POTENCIAL,'')=''  THEN 'ASEMCONTATO'	" + CRLF		// Nunca contactado-Potencial
		cQuery  += "		 WHEN U4_ESTAGIO= '2' AND ISNULL(POTENCIAL,'')<>'' THEN 'REDISTRIBUIDO'	" + CRLF		// Já contactado e agora Redistribuído
		cQuery  += "		 ELSE 'SEMAGENDAMENTO' 													" + CRLF        // Apontado como sem agendamento
		cQuery  += "	END SITUACAO, DATEDIFF(DAY,U4_DATA,GETDATE()) DIFDIAS, US_ZOBS,		   		" + CRLF  
		cQuery  += "	CAST(CAST(US_HISTOBS AS Varbinary(8000)) as Varchar(8000)) US_HISTOBS		" + CRLF 		
		
		cQuery	+= " FROM "+RetSqlName("SU4")+" SU4 							  					" + CRLF
		cQuery	+= "	JOIN "+RetSqlName("SU6")+" SU6 ON (SU6.D_E_L_E_T_='' AND U4_LISTA = U6_LISTA)	  	   		" + CRLF		
		cQuery	+= "	JOIN "+RetSqlName("SUS")+" SUS ON (SUS.D_E_L_E_T_='' AND SUS.US_COD+SUS.US_LOJA=U6_CODENT)	" + CRLF	
		cQuery	+= "	LEFT JOIN "+RetSqlName("SU7")+" SU7 ON (SU7.D_E_L_E_T_ <> '*' AND SU7.U7_COD = U4_OPERAD) 	" + CRLF		
		cQuery	+= "	LEFT JOIN "+RetSqlName("SUC")+" SUC ON UC_CODIGO = U4_CODLIG AND SUC.D_E_L_E_T_=''	   		" + CRLF 	
		cQuery	+= "   		AND	UC_NEWDESK = 'S'	   					" + CRLF 	
		cQuery	+= " 	LEFT JOIN (						 				" + CRLF 
		cQuery	+= "		SELECT UD_CODIGO, MAX(UD.R_E_C_N_O_) SUDREC	" + CRLF 
		cQuery	+= "   		FROM "+RetSqlName("SUD")+" UD 				" + CRLF 
		cQuery	+= "   		WHERE UD.D_E_L_E_T_=''		   				" + CRLF 
		cQuery	+= "   		GROUP BY UD_CODIGO 			 				" + CRLF 
		cQuery	+= "	) UD ON UD_CODIGO=SUC.UC_CODIGO		  			" + CRLF 
		cQuery	+= " 	LEFT JOIN "+RetSqlName("SUD")+" SUD ON SUDREC=SUD.R_E_C_N_O_ AND SUD.D_E_L_E_T_=''			" + CRLF 			
		cQuery	+= " 	LEFT JOIN "+RetSqlName("SX5")+" SX5 ON X5_TABELA='SU' AND X5_CHAVE=US_ZORIGEX AND SX5.D_E_L_E_T_='' " + CRLF 

		cQuery	+= " 	LEFT JOIN (						 				" + CRLF 
		cQuery	+= "		SELECT UC_CHAVE	POTENCIAL					" + CRLF 
		cQuery	+= "   		FROM "+RetSqlName("SUC")+" UC 				" + CRLF 
		cQuery	+= "   		WHERE UC.D_E_L_E_T_=''		   				" + CRLF 
		cQuery	+= "   		GROUP BY UC_CHAVE 			 				" + CRLF   
		cQuery	+= " 		UNION						 				" + CRLF 
		cQuery	+= "		SELECT (AD1_PROSPE+AD1_LOJPRO) POTENCIAL	" + CRLF 
		cQuery	+= "   		FROM "+RetSqlName("AD1")+" AD1				" + CRLF 
		cQuery	+= "   		WHERE AD1.D_E_L_E_T_=''		   				" + CRLF 
		cQuery	+= "   		GROUP BY (AD1_PROSPE+AD1_LOJPRO)			" + CRLF 		
		cQuery	+= "	) EXISTE ON POTENCIAL=SUS.US_COD+SUS.US_LOJA	" + CRLF 
				
		cQuery	+= " WHERE SU4.D_E_L_E_T_ <> '*'   						" + CRLF  
		cQuery	+= "    AND U4_ESTAGIO NOT IN ('6','8')					" + CRLF  									// Não pode ser 6=Inapto, nem 8=Visita Agendada
		cQuery	+= " 	AND U4_STATUS IN ('1') 	  		 				" + CRLF        
		If nOpc <> 0  
			// Adição do funcionamento das operações de filtragem | 17/04/2018 - Catharina Oliveira	.
			If lFiltro
	                 
				// Consultor sempre filtra o próprio usuario
				If !lAdminCAT
					cQuery += " AND U4_OPERAD = '" +cCodOper+ "'	 			" + CRLF  			
			    EndIf 
	
                If !Empty(cFilAtEv)
		  			cQuery+= " 	AND U4_CODLIG = '" +cFilAtEv+ "' 				" + CRLF   
			    EndIf    

                If !Empty(cFilOpVe)
		  			cQuery+= " 	AND U4_OPERAD = '" +cFilOpVe+ "' 				" + CRLF  			
			    EndIf
				    
                If !Empty(cFilCod)
		  			cQuery+= " 	AND SUS.US_COD = '" +cFilCod+ "' 				" + CRLF  						
			    EndIf

                If !Empty(cFilReg)
		  			cQuery+= " 	AND SUS.US_REGINTE = '" +cFilReg+ "'   			" + CRLF  						
			    EndIf		    			    			    
				    
                If !Empty(cFilSeg)
		  			cQuery+= " 	AND SUS.US_SATIV = '" +cFilSeg+ "' 				" + CRLF  						
			    EndIf
				    
                If !Empty(cFilCat)
		  			cQuery+= " 	AND SUS.US_CATEGOR = '" +cFilCat+ "'  			" + CRLF  						
			    EndIf
				    
                If nFilStat == 1
		  			cQuery+= " 	AND U4_ESTAGIO= '2' AND ISNULL(POTENCIAL,'')='' " + CRLF 
		  		ElseIf  nFilStat == 2						
		  			cQuery+= " 	AND U4_ESTAGIO= '2' AND ISNULL(POTENCIAL,'')<>''" + CRLF  
		  		ElseIf  nFilStat == 3
		  			cQuery+= " 	AND U4_ESTAGIO<>'2' 							" + CRLF  				
			    EndIf
	
				If !Empty(cFilDtDe) .Or. !Empty(cFilDtAte)
					cQuery+= "  AND CASE WHEN ISNULL(UC_PENDENT,'')='' THEN U4_DATA  ELSE UC_PENDENT END BETWEEN '" +cFilDtDe+ "' AND '" +cFilDtAte+ "' " + CRLF  	
		  		Else		  				  		
					cQuery+= "  AND U4_DATA <= '" +DtoS(dAgenData)+ "'   		" + CRLF  		  							
				EndIf			    			    			    			    
				
			Else		
				
				If !lAdminCAT
					cQuery += " AND U4_OPERAD = '" +cCodOper+ "'	 			" + CRLF  			
			    EndIf                                                                     
		    	cQuery  += "  	AND U4_DATA <= '" +DtoS(dAgenData)+ "'   		" + CRLF  									//Se passou, baixa de todo jeito.
				
			EndIf 		
			
		EndIf
		cQuery  += " 	AND U4_OPERAD <>''					 			" + CRLF  	    
		cQuery	+= " ORDER BY SITUACAO, DATALST,SUS.US_NOME, UC_CODIGO DESC		" + CRLF	 

		    
		TCQuery cQuery New Alias "PEN"
	
		dbSelectArea("PEN")
		dbGoTop()     

		IncProc()
		IncProc()
		
		aBrowCAT := {}
		While !Eof()  
	
			aAdd(aBrowCAT,{	AllTrim(PEN->SITUACAO)	,;		 	// 01
							PEN->NOMECLI			,; 			// 02
							"("+PADL(Alltrim(PEN->US_DDD),3,'0')+") "+PADL(Alltrim(PEN->TEL1),11,' '),; // 03
							PADL(Alltrim(PEN->TEL2),11,' ')	,; 	// 04
							AllTrim(PEN->UC_CODOBS)	,; 			// 05   
							AllTrim(PEN->US_COD)	,; 			// 06               
							AllTrim(PEN->US_LOJA)	,; 			// 07                   
							""						,; 			// 08   
							AllTrim(PEN->CODCONT)	,; 			// 09           					
							AllTrim(PEN->UC_CODIGO)	,; 			// 10  
							AllTrim(PEN->CODCLI)	,; 			// 11 
							AllTrim(PEN->LOJACLI)	,; 			// 12 												
							AllTrim(PEN->LISTA)		,; 			// 13 							
							PEN->DIFDIAS			,; 			// 14
							AllTrim(PEN->ORIGEM)	,; 			// 15
							AllTrim(PEN->EMAIL)		,; 			// 16	  
							AllTrim(PEN->US_HISTOBS),;			// 17 	
							DTOC(STOD(PEN->DATALST)),;	 		// 18  
							STOD(PEN->DTDIS)		,;			// 19  	
							AllTrim(PEN->OPERADOR)	})	 		// 20  
														
								  																				
							          												
			PEN->(dbSkip())
		EndDo
	
		PEN->(dbCloseArea())	    

		If nOpc == 0 		
			cEvenCAT := "99"  			
	  		For nX := 1 To Len(aBrowCAT)  
	  			
		  		If aBrowCAT[nX][14] >= 21.And. !(aBrowCAT[nX][20] $ cOpeNVenc)  // Usuário com atendimento remoto sem vencimento. 
			  		fSalvCAT(0,nX) 	  			
			  	EndIf

			Next nX 
			cEvenCAT := ""
			Consulta(1)
	    EndIf
	
	EndIf
    
	IncProc()
	IncProc()

	// Executa se Geral ou 2=Específico(CRM)
	If nOpc <> 1
	
		cQuery	:= " SELECT CASE WHEN ISNULL(AD5.AD5_EVENTO,'')='000010' THEN 'NAOCOMPAR' ELSE 'AGENDADO' END SITUACAO,	" + CRLF
		cQuery	+= "	AD1_NROPOR,AD1_DESCRI, AD1_CODTMK,US_COD, US_LOJA, US_NOME NOMECLI, AD1_CODCLI, AD1_LOJCLI,		" + CRLF
		cQuery	+= "	AD1_PROPOS,AD1_STAGE,ISNULL(UC_CODOBS,'') UC_CODOBS,AD7.AD7_DATA,AD7.AD7_HORA1,AD7.AD7_HORA2, 	" + CRLF	
		cQuery	+= "	AD7.AD7_LOCAL, US_DDD,RTRIM(LTRIM(SUS.US_TEL))TEL1, RTRIM(LTRIM(SUS.US_FAX))TEL2,AD7.AD7_DTEXEC," + CRLF   
		cQuery	+= "	CAST(CAST(US_HISTOBS AS Varbinary(8000)) as Varchar(8000)) AD1_OBSPRO, 							" + CRLF
		cQuery	+= "	AD1_VEND, DATEDIFF(DAY,AD7M.AD7_DATA,GETDATE()) DIFDIAS	  	  									" + CRLF 
		cQuery	+= " FROM "+RetSqlName("AD1")+" AD1 JOIN "+RetSqlName("SUS")+" SUS ON (AD1_PROSPE+AD1_LOJPRO)=(US_COD+US_LOJA) " + CRLF												
		cQuery	+= " 	JOIN ( 		   						 															" + CRLF		  		   		 											
		// Agendamentos que estão em aberto, aguardando apontamento			
		cQuery	+= "		SELECT AD7NROPOR, AD7_DTEXEC, AD7REC, MINREC, PRIMAGEN			   							" + CRLF								
		cQuery	+= "		FROM (										 												" + CRLF		
		cQuery	+= "			SELECT AD7_NROPOR AD7NROPOR, MAX(R_E_C_N_O_) AD7REC	, 									" + CRLF								
		cQuery	+= "				MIN(R_E_C_N_O_) MINREC, MIN(AD7_DATA) PRIMAGEN										" + CRLF		
		cQuery	+= "			FROM "+RetSqlName("AD7")+" 		 	" + CRLF					
		cQuery	+= "			WHERE D_E_L_E_T_=''	   				" + CRLF	   	   			
		If (cEmpant $ '01') //!!
			cQuery	+= "			AND AD7_NROPOR >= '020405'	 	" + CRLF			
		EndIf
		cQuery	+= "			GROUP BY AD7_NROPOR	  				" + CRLF			   		
		cQuery	+= "		) AD7AGEND 								" + CRLF							
		cQuery	+= "		JOIN "+RetSqlName("AD7")+" AD7 ON AD7.AD7_NROPOR = AD7NROPOR AND AD7.D_E_L_E_T_=''	   		" + CRLF					
		cQuery	+= "		AND AD7.R_E_C_N_O_=AD7REC AND AD7_DTEXEC=''													" + CRLF
					
		cQuery	+= "		UNION ALL								" + CRLF		
        // Agendamentos que foram apontados, mas estão em negociação 
		cQuery	+= "		SELECT AD7NROPOR, AD7_DTEXEC, AD7REC, MINREC, PRIMAGEN										" + CRLF		
		cQuery	+= "		FROM (									" + CRLF		
		cQuery	+= "			SELECT AD7_NROPOR AD7NROPOR, MAX(R_E_C_N_O_) AD7REC	,									" + CRLF		
		cQuery	+= "				MIN(R_E_C_N_O_) MINREC, MIN(AD7_DATA) PRIMAGEN 										" + CRLF		
		cQuery	+= "			FROM "+RetSqlName("AD7")+"			" + CRLF												
		cQuery	+= "			WHERE D_E_L_E_T_=''	   	   			" + CRLF		
		If (cEmpant $ '01') //!!
			cQuery	+= "			AND AD7_NROPOR >= '020405'	 	" + CRLF			
		EndIf
		cQuery	+= "			GROUP BY AD7_NROPOR			   		" + CRLF							
		cQuery	+= "		) AD7AGEND 								" + CRLF		
		cQuery	+= "		JOIN "+RetSqlName("AD7")+" AD7 ON AD7.AD7_NROPOR = AD7NROPOR AND AD7.D_E_L_E_T_=''			" + CRLF		 
		cQuery	+= "		AND AD7.R_E_C_N_O_=AD7REC AND AD7_DTEXEC<>''												" + CRLF															
		cQuery	+= "    ) AGENDADOS ON AD7NROPOR=AD1_NROPOR			" + CRLF											
		cQuery	+= "    JOIN "+RetSqlName("AD7")+" AD7 ON AD7.AD7_NROPOR = AD7NROPOR AND AD7.D_E_L_E_T_='' 				" + CRLF		
		cQuery	+= "		AND AD7.R_E_C_N_O_=AD7REC 				" + CRLF		                                            
		
		cQuery	+= "	JOIN "+RetSqlName("AD7")+" AD7M ON AD7M.AD7_NROPOR = AD7NROPOR AND AD7M.D_E_L_E_T_=''			" + CRLF					
		cQuery	+= "		AND AD7M.R_E_C_N_O_=MINREC 																	" + CRLF		
		// Identifica o evento do último apontamento
		cQuery	+= "	LEFT JOIN (									" + CRLF
		cQuery	+= "		SELECT AD5_NROPOR AD5NROPOR, MAX(R_E_C_N_O_) AD5REC	 										" + CRLF									
		cQuery	+= "		FROM "+RetSqlName("AD5")+" 				" + CRLF
		cQuery	+= "		WHERE D_E_L_E_T_=''	   	   				" + CRLF
		cQuery	+= "		GROUP BY AD5_NROPOR			   			" + CRLF																	
 		cQuery	+= "   	) APONTADO ON AD5NROPOR=AD1_NROPOR			" + CRLF
 		cQuery	+= "   	LEFT JOIN "+RetSqlName("AD5")+" AD5 ON AD5.AD5_NROPOR = AD5NROPOR AND AD5.D_E_L_E_T_='' 		" + CRLF
		cQuery	+= "		AND AD5.R_E_C_N_O_=AD5REC  				" + CRLF
		
		cQuery	+= "	LEFT JOIN "+RetSqlName("SUC")+" SUC ON UC_CODIGO = AD1_CODTMK AND SUC.D_E_L_E_T_='' 			" + CRLF
		cQuery	+= " WHERE AD1.D_E_L_E_T_=''						" + CRLF		
		cQuery	+= "	AND AD1_STAGE  <= '005'						" + CRLF		
		cQuery	+= "	AND AD1_STATUS = '1'						" + CRLF		
	    // Executa a baixa dos dias vencidos.
	    If !nOpc == 0           
	
			// Adição do funcionamento das operações de filtragem 
			If lFiltro
                 
                // Vendedor sempre filtra o próprio usuario e data corrente selecionada     
				If !lAdminCRM 
			   		cQuery+= "	AND AD1_VEND ='" +cCodVend+ "'		" + CRLF 			   				   			
			    EndIf

                If !Empty(cFilAtEv)
		  			cQuery+= " 	AND AD1.AD1_NROPOR='" +cFilAtEv+ "' " + CRLF   
			    EndIf    

                If !Empty(cFilOpVe)
		  			cQuery+= " 	AND AD1.AD1_VEND = '" +cFilOpVe+ "' " + CRLF  			
			    EndIf
			    
                If !Empty(cFilCod)
		  			cQuery+= " 	AND SUS.US_COD = '" +cFilCod+ "' 	" + CRLF  						
			    EndIf

                If !Empty(cFilReg)
		  			cQuery+= " 	AND SUS.US_REGINTE ='" +cFilReg+ "' " + CRLF  						
			    EndIf		    			    			    
			    
                If !Empty(cFilSeg)
		  			cQuery+= " 	AND SUS.US_SATIV = '" +cFilSeg+ "' 	" + CRLF  						
			    EndIf
			    
                If !Empty(cFilCat)
		  			cQuery+= " 	AND SUS.US_CATEGOR ='" +cFilCat+ "' " + CRLF  						
			    EndIf
			    
                If nFilStat == 1
		  			cQuery+= " 	AND AD5.AD5_EVENTO = '000007'  		" + CRLF 
		  		ElseIf  nFilStat == 2						
		  			cQuery+= " 	AND AD5.AD5_EVENTO = '000010' 		" + CRLF 
			    EndIf
			    
                If !Empty(cFilDtDe) .Or. !Empty(cFilDtAte)
		  			cQuery+= " AND AD7.AD7_DATA BETWEEN '" +cFilDtDe+ "' AND '" +cFilDtAte+ "' " + CRLF  						
			    EndIf			    			    			    			    
			
			Else		
			
				If Empty(DtoS(dDataAD7))
				    cQuery+= " 	AND AD7.AD7_DATA = '" +DtoS(dDataBase)+ "' 	" + CRLF  			
				Else
				    cQuery+= " 	AND AD7.AD7_DATA = '" +DtoS(dDataAD7)+ "'  	" + CRLF  			
		    	EndIf 
			
				If !lAdminCRM
			   		cQuery+= "	AND AD1_VEND ='" +cCodVend+ "'				" + CRLF	
			    EndIf
			
		    EndIf 
		    
		EndIf
		cQuery	+= " ORDER BY SITUACAO, AD7.AD7_HORA1,US_NOME, AD1_NROPOR DESC											" + CRLF	 
		
		TCQuery cQuery New Alias "PEN"
	
		dbSelectArea("PEN")
		dbGoTop()  
		IncProc()
		IncProc()		   
		
		aBrowCRM := {}
		While !Eof()  
		
			aAdd(aBrowCRM,{	AllTrim(PEN->SITUACAO)	,;		 	// 01       
							AllTrim(PEN->AD1_NROPOR),;		 	// 02
							PEN->NOMECLI			,; 			// 03
							"("+PADL(Alltrim(PEN->US_DDD),3,'0')+") "+PADL(Alltrim(PEN->TEL1),11,' '),; // 04
							PADL(Alltrim(PEN->TEL2),11,' ')	,; 	// 05
							AllTrim(PEN->UC_CODOBS)	,; 			// 06       
							AllTrim(PEN->US_COD)	,; 			// 07               
							AllTrim(PEN->US_LOJA)	,; 			// 08                   
							AllTrim(PEN->AD1_OBSPRO),; 			// 09 
							If(Empty(PEN->AD7_DTEXEC),STOD(PEN->AD7_DATA),CtoD(''))	,; 			// 10
							If(Empty(PEN->AD7_DTEXEC),AllTrim(PEN->AD7_HORA1),'')	,; 			// 11  
							If(Empty(PEN->AD7_DTEXEC),AllTrim(PEN->AD7_LOCAL),'')	,; 			// 12							
							AllTrim(PEN->AD1_CODCLI),; 			// 13 
							AllTrim(PEN->AD1_LOJCLI),; 			// 14 												
							AllTrim(PEN->AD1_PROPOS),;			// 15 	
							AllTrim(PEN->AD1_VEND)  ,; 			// 16 	
							AllTrim(PEN->AD1_STAGE) ,; 			// 17 		
							PEN->DIFDIAS			}) 			// 18						
							          												
			PEN->(dbSkip())
		EndDo
	
		PEN->(dbCloseArea())			

		If nOpc == 0 
			cEvenCRM := "99"  			
	  		For nX := 1 To Len(aBrowCRM)  		  		
		  		If aBrowCRM[nX][18] >= 31 .And. !(aBrowCRM[nX][16] $ cVenNVenc)  // Usuário com atendimento presencial sem vencimento.	  		
			  		fSalvCRM(0,nX)
				EndIf  
			Next nX 
			cEvenCRM := ""
			Consulta(2)
	    EndIf			

	EndIf    

	IncProc()
	IncProc()
	IncProc()
	IncProc()
	IncProc()
	IncProc()		

Return()


Static Function MontaTela()
*********************************************************************************
* Monta Tela 
*
****

	Local aSize		:= {}  
	Local cOpcao	:= ""
	Local cPesq		:= Space(200)
	Local cNJanela	:= "CRM - Consultor: "+If(Empty(cNomOper),cNomVend,cNomOper)
	Local aItemsCAT	:= {'','1=Cliente não existe','2=Interesse Futuro','3=Cliente sem agendamento','4=Agendamento','5=Sem Interesse'}   //
	Local aItemsCRM := {"","000007=Negociação em Andamento","000008=Interesse Futuro","000009=Inserir Proposta",;
						"000010=Não Compareceu","000011=Cliente Desistiu"}
						
	Local aMotCRM	:= {'','1=Sem capital para investimento','2=Valor da Unidade Comercial',"3=UC's disponíveis não agradaram o cliente",;
						'4=Não possui fornecedor no momento','5=Não possui vendedor ou quem fique na UC','6=Deseja apenas UC de porta',;
						'7=Deseja apenas mais informações sobre o negocio','8=Opinião contrária de um influenciador','9=Comercializa produtos piratas',;
						'0=Não atende ou não responde'}

	Private aMotCAT1:= {'','1=Informa não ter preenchido','2=Número de outra pessoa','3=Continua sem interesse na repescagem',;
						'4=Tem interesse, mas em outra cidade','5=Deseja abrir uma unidade em outros bairros ou outra cidade',;
						'6=Procura emprego/ Deseja deixar currículo','7=Buscando fornecedores de atacado'}
						    
	Private aMotCAT2:= {'','11=Sem capital para investimento','12=Valor da Unidade Comercial',"13=UC's disponíveis não agradaram o cliente",;
						'14=Não possui fornecedor no momento','15=Não possui vendedor ou quem fique na UC','16=Deseja apenas UC de porta',;
						'17=Deseja apenas mais informações sobre o negocio','18=Opinião contrária de um influenciador','19=Comercializa produtos piratas',;
						'20=Não atende ou não responde'}

	Private aMotCAT := {}
	
	Private lButProp:= .F.	
	Private oButProp, oDlgSUSB, oScr
	     
	DEFINE MSDIALOG oDlgSUSB TITLE OemToAnsi(cNJanela) From 000,000 To 690,1365 Pixel 
	
		//----------------------------------TELEATENDIMENTO-------------------------------------------------------------------------------------------------------
		@ 005,005 to 303/*A*/,348/*L*/ LABEL "Atendimento Remoto" COLOR CLR_BLUE Of oDlgSUSB Pixel 
				
		oBrowCAT := TCBrowse():New(017,010, 330/*L:aSize[6]-05*/,170/*A:aSize[4]-22*/,,,,oDlgSUSB,,,,,,,/**/oFont,,,,,.F.,,.T.,,.F.,,,) 		

		oBrowCAT:AddColumn( TcColumn():New('St.'		,{|| If(Empty(aBrowCAT),oAMAR, If(aBrowCAT[oBrowCAT:nAt,01]=='ASEMCONTATO',oAMAR,;
																If(aBrowCAT[oBrowCAT:nAt,01]=='REDISTRIBUIDO',oAZUL,oLARA))) },"@!",,,"LEFT", 10,.T.,.F.,,{|| .F. },,.F., ))
		oBrowCAT:AddColumn( TcColumn():New('Nome'		,{|| If(Empty(aBrowCAT),Space(130),aBrowCAT[oBrowCAT:nAt,02])},"@!",,,"LEFT"	, 110,.F.,.F.,,{|| .F. },,.F., )) 
		oBrowCAT:AddColumn( TcColumn():New('Telefone 1'	,{|| If(Empty(aBrowCAT),Space(050),aBrowCAT[oBrowCAT:nAt,03])},"@!",,,"CENTER"	, 50,.F.,.F.,,{|| .F. },,.F., )) 
		oBrowCAT:AddColumn( TcColumn():New('Dt.Atendim'	,{|| If(Empty(aBrowCAT),Space(020),aBrowCAT[oBrowCAT:nAt,18])},"@!",,,"CENTER"	, 35,.F.,.F.,,{|| .F. },,.F., )) 

		oBrowCAT:AddColumn( TcColumn():New('Origem'	,{|| If(Empty(aBrowCAT),Space(003),aBrowCAT[oBrowCAT:nAt,15])},"@!",,,"LEFT", 50,.F.,.F.,,{|| .F. },,.F., )) 
		oBrowCAT:AddColumn( TcColumn():New('E-mail'	,{|| If(Empty(aBrowCAT),Space(050),aBrowCAT[oBrowCAT:nAt,16])},"",,,"LEFT"	, 110,.F.,.F.,,{|| .F. },,.F., )) 
		
		oBrowCAT:SetArray(aBrowCAT)		
		oBrowCAT:bChange :={|| fExecBut("CAT","M") }
	   		
		oBrowCAT:lAdjustColSize := .F.   
		oBrowCAT:Refresh() 
		                                             
		oBrowCAT:bDrawSelect:= {|| If(nEditPos>0,(oBrowCAT:SetFocus(),oBrowCAT:GoPosition(nEditPos)),)}
		oBrowCAT:bSeekChange:= {|| If(nEditPos>0,(oBrowCAT:SetFocus(),oBrowCAT:GoPosition(nEditPos),MsgBox("Cancele a edição ou Salve o registro para prosseguir.","Inválido!","INFO")),)}		
		
		@ 205, 010 Get cMemoObs1 Size 330,55 MEMO Object oMemoObs1
		oMemoObs1:lReadOnly := .T.  
		
		@ 195,010 Bitmap oAMARELO ResName 'BR_AMARELO' SIZE 20,20 NoBorder When .F. Pixel
		@ 195,022 Say 'Sem Contato' Pixel  
		
		@ 195,065 Bitmap oAZULIM ResName 'BR_AZUL' SIZE 20,20 NoBorder When .F. Pixel
		@ 195,077 Say 'Redistribuído' Pixel	

		@ 195,118 Bitmap oLARANJA ResName 'BR_LARANJA' SIZE 20,20 NoBorder When .F. Pixel
		@ 195,130 Say 'Sem Agendamento' Pixel				
		
		@ 267,010 Say "O que aconteceu:" COLOR CLR_HBLUE Pixel Of oDlgSUSB 
		@ 266,058 Combobox cEvenCAT Items aItemsCAT Size 79,13 Object oCombCAT
		oCombCAT:bChange := {|| fAtualCAT() }
        oCombCAT:Disable()
		
		@ 267,148 Say "Motivo:"  COLOR CLR_BLACK Pixel Of oDlgSUSB 
		@ 266,174 Combobox cMotCAT Items aMotCAT Size 167,13 Object oCmbCAT
		oCmbCAT:Disable()			

		@ 284,010 Say cSayData COLOR CLR_BLACK Pixel Of oDlgSUSB	  
		@ 283,048 Get dDtEvento Size 35,10 Picture PesqPict("SUC","UC_DATA") Object oDtEvento   	  
		@ 283,086 Get cHoraEven Size 20,10 Picture "99:99" Object oHoraEven 
		oHoraEven:bChange := {|| cHoraEven:=AllTrim(StrTran(cHoraEven,".",":")) }
		oDtEvento:Disable()
		oHoraEven:Disable()  
				         
		@ 284,127 Say 'Local:' COLOR CLR_BLACK Pixel Of oDlgSUSB	  
		@ 283,148 Get cUCAgen 	Size 15,10 F3 "SX5CAD" Picture "@!" Valid (cLocalUC := AllTrim(Posicione("SX5",1,xFilial("SX5")+'CZ'+cUCAgen,"X5_DESCRI")),oLocalUC:Refresh(),ExistCpo('SX5','CZ'+cUCAgen)) Object oUCAgen 	 
		@ 283,180 Get cLocalUC 	Size 50,10 When .F. Object oLocalUC	 
		oUCAgen:Disable() 

		@ 284,237 Say 'Consult.:' COLOR CLR_BLACK Pixel Of oDlgSUSB	  
		@ 283,262 Get cCodVend 	Size 30,10 F3 "SA3001" Picture "@!" Valid (cNomVend := AllTrim(Posicione("SA3",1,xFilial("SA3")+cCodVend,"A3_NOME")),;
					oNomVend:Refresh(),dDataAD7:=oMsCalend:dDiaAtu,fAtuaBrow(2,"S"),ExistCpo('SA3',cCodVend)) Object oCodVend 	 
		@ 283,297 Get cNomVend 	Size 44,10 When .F. Object oNomVend  
		oNomVend:Disable()
		oCodVend:Disable()
		
		oButBmp1:=TBtnBmp2():New( 377,0577,030,030,'AlterarCrm',,,,{|| fEditaPot("CAT") },oDlgSUSB,"Editar Potencial",,.T. )  						
		oButBmp2:=TBtnBmp2():New( 377,0611,030,030,'Filtro' ,,,,{|| fFiltraBw("CAT",1)},oDlgSUSB,"Filtrar",,.T. )
		oButBmp5:=TBtnBmp2():New( 377,0645,029,029,'Limpar' ,,,,{|| fFiltraBw("CAT",2)},oDlgSUSB,"Limpar Filtro",,.T. ) 
		
		oButSlvCAT:=TButton():New(310,076,"Salvar"	,oDlgSUSB,{ || If(fValida(1), fExecBut("CAT","S"),) },41,11,,,,.T.,,,,)
		oButCanCAT:=TButton():New(310,010,"Cancelar",oDlgSUSB,{ || nEditPos := 0, fExecBut("CAT","C") 	},57,11,,,,.T.,,,,)   

		oButAgnCAT:=TButton():New(330,010,"Transferir Agenda",oDlgSUSB,{ || U_FSCRMA32("CAT")},57,11,,,,.T.,,,,)  

 		oButPotCAT:=TButton():New(310,234,"Cliente" ,oDlgSUSB,{|| fPotencial("CAT") },41,11,,,,.T.,,,,)                            				
		oButSolCAT:=TButton():New(310,283,"Solicitar Clientes",oDlgSUSB,{|| fSolicitar() },57,11,,,,.T.,,,,)
			   
		oButSlvCAT:Disable()
		oButCanCAT:Disable()   
		oButAgnCAT:Disable()				

		//----------------------------------EVOLUÇÃO COMERCIAL----------------------------------------------------------------------------------------------------
		@ 005,359 to 303,677 LABEL "Atendimento Presencial" COLOR CLR_BLUE Of oDlgSUSB Pixel 
		
		oBrowCRM := TCBrowse():New(017,365, 305/*L:aSize[6]-05*/,170/*A:aSize[4]-22*/,,,,oDlgSUSB,,,,,,,/**/oFont,,,,,.F.,,.T.,,.F.,,,) 
		oBrowCRM:AddColumn( TcColumn():New('St.'	,{|| If(Empty(aBrowCRM),oVERD,If(aBrowCRM[oBrowCRM:nAt,01]=='AGENDADO',oVERD,oVERM))	},"@!",,,"LEFT", 10,.T.,.F.,,{|| .F. },,.F., ))  							
		oBrowCRM:AddColumn( TcColumn():New('N°Evolução'	,{|| If(Empty(aBrowCRM),Space(037), aBrowCRM[oBrowCRM:nAt,02]) },"@!",,,"CENTER"	, 37,.F.,.F.,,{|| .F. },,.F., )) 						
		oBrowCRM:AddColumn( TcColumn():New('Nome'		,{|| If(Empty(aBrowCRM),Space(100), aBrowCRM[oBrowCRM:nAt,03])},"@!",,,"LEFT"	, 100,.F.,.F.,,{|| .F. },,.F., )) 
		oBrowCRM:AddColumn( TcColumn():New('Telefone 1'	,{|| If(Empty(aBrowCRM),Space(050), aBrowCRM[oBrowCRM:nAt,04])},"@!",,,"CENTER"	, 50,.F.,.F.,,{|| .F. },,.F., )) 
	   	oBrowCRM:AddColumn( TcColumn():New('Telefone 2'	,{|| If(Empty(aBrowCRM),Space(040), aBrowCRM[oBrowCRM:nAt,05])},"@!",,,"CENTER"	, 40,.F.,.F.,,{|| .F. },,.F., )) 
		oBrowCRM:AddColumn( TcColumn():New('Horário   '	,{|| If(Empty(aBrowCRM),Space(030), aBrowCRM[oBrowCRM:nAt,11])},"@!",,,"CENTER"	, 30,.F.,.F.,,{|| .F. },,.F., )) 
		oBrowCRM:AddColumn( TcColumn():New('Local     '	,{|| If(Empty(aBrowCRM),Space(020), aBrowCRM[oBrowCRM:nAt,12])},"@!",,,"CENTER"	, 20,.F.,.F.,,{|| .F. },,.F., )) 
		       
		oBrowCRM:SetArray(aBrowCRM)		

		oBrowCRM:bChange :={|| fExecBut("CRM","M") }
	   
		oBrowCRM:lAdjustColSize := .F.           
		oBrowCRM:Refresh() 
		
		oBrowCRM:bDrawSelect:= {|| If(nEditEvol>0,(oBrowCRM:SetFocus(),oBrowCRM:GoPosition(nEditEvol)),)}

		oBrowCRM:bSeekChange:= {|| If(nEditEvol>0,(oBrowCRM:SetFocus(),oBrowCRM:GoPosition(nEditEvol),MsgBox("Cancele a edição ou Salve o registro para prosseguir.","Inválido!","INFO")),)}		
  		@ 195, 510 Say "Observação:" COLOR CLR_BLACK Pixel Of oDlgSUSB 
		@ 205, 510 Get cMemoObs2 Size 160,55 MEMO Object oMemoObs2
		oMemoObs2:lReadOnly := .T.	 
 
   		oMsCalend:= MsCalend():New(195,365,oDlgSUSB,.T.)		 
		oMsCalend:dDiaAtu := dDataAD7  
		oMsCalend:bChange := {|| 	dDataAD7:=oMsCalend:dDiaAtu,fFiltraBw("CRM",2),oBrowCRM:Refresh(),oMsCalend:CtrlRefresh() }	
		oMsCalend:bChangeMes := {|| dDataAD7:=oMsCalend:dDiaAtu,fFiltraBw("CRM",2),oBrowCRM:Refresh(),oMsCalend:CtrlRefresh() }  			   		
				      
		@ 267,365 Say "O que aconteceu:"  COLOR CLR_HBLUE Pixel Of oDlgSUSB 
		@ 266,415 Combobox cEvenCRM Items aItemsCRM Size 093,13 Object oCombCRM
		oCombCRM:bChange := {|| fAtualCRM() }   
		oCombCRM:Disable()		
		
		@ 267,516 Say "Motivo:"  COLOR CLR_BLACK Pixel Of oDlgSUSB 
		@ 266,537 Combobox cMotCRM Items aMotCRM Size 134,13 Object oCmbCRM
		oCmbCRM:Disable()	
		      
		@ 284,365 Say "Dt.Reunião:" COLOR CLR_BLACK Pixel Of oDlgSUSB	  
		@ 283,415 Get dDtAgenda Size 35,10 Picture PesqPict("AD1","AD1_DATA") Object oDtAgenda   	  
		@ 283,453 Get cHoraAgen Size 20,10 Picture "99:99" Object oHoraAgen 
		oHoraAgen:bChange := {|| cHoraAgen:=AllTrim(StrTran(cHoraAgen,".",":")) }
		oDtAgenda:Disable()
		oHoraAgen:Disable()
        //  
		@ 284,516 Say 'Local:' COLOR CLR_BLACK Pixel Of oDlgSUSB	  
		@ 283,536 Get cLocAgen 	Size 15,10 F3 "SX5CAD" Picture "@!" Valid (cDescLoc := AllTrim(Posicione("SX5",1,xFilial("SX5")+'CZ'+cLocAgen,"X5_DESCRI")),oDescLoc:Refresh(),ExistCpo('SX5','CZ'+cLocAgen)) Object oLocAgen 	 
		@ 283,569 Get cDescLoc 	Size 58,10 When .F. Object oDescLoc	
		oLocAgen:Disable()    
		
		oButBmp3:=TBtnBmp2():New( 377,1238,030,030,'AlterarCrm',,,,{|| fEditaPot("CRM")},oDlgSUSB,"Editar Evolução",,.T. )  		
		oButBmp4:=TBtnBmp2():New( 377,1272,030,030,'Filtro' ,,,,{|| fFiltraBw("CRM",1)},oDlgSUSB,"Filtrar",,.T. )  	   					
		oButBmp6:=TBtnBmp2():New( 377,1306,029,029,'Limpar' ,,,,{|| fFiltraBw("CRM",2)},oDlgSUSB,"Limpar Filtro",,.T. ) 	 			

		oButSlvCRM:=TButton():New(310,436,"Salvar",oDlgSUSB,{ || If(fValida(2), fExecBut("CRM","S"),) },41,11,,,,.T.,,,,)
		oButCanCRM:=TButton():New(310,365,"Cancelar",oDlgSUSB,{ || fExecBut("CRM","C") },57,11,,,,.T.,,,,)    

		oButAgnCRM:=TButton():New(330,365,"Transferir Agenda",oDlgSUSB,{ || U_FSCRMA32("CRM")	},57,11,,,,.T.,,,,)

		oButAbrPro:=TButton():New(330,613,"Reabrir Proposta",oDlgSUSB,{ || fReabrirP() },57,11,,,,.T.,,,,)

		oButPotCRM:=TButton():New(310,564,"Cliente" ,oDlgSUSB,{|| fPotencial("CRM") },41,11,,,,.T.,,,,)                            				
		oButProp  :=TButton():New(310,613,"Proposta de Contrato",oDlgSUSB,{|| fProposta() },57,11,,,,.T.,,,,)   

		oButLegen := TButton():New(330,436,"Legenda",oDlgSUSB,{|| Legenda() },41,11,,,,.T.,,,,)   
		oButFecha := TButton():New(330,564,"Fechar" ,oDlgSUSB,{|| oDlgSUSB:End() },41,11,,,,.T.,,,,)
		
		oButSlvCRM:Disable()
		oButCanCRM:Disable()
		oButAgnCRM:Disable()

		If Len(aBrowCRM) > 0 .And. aBrowCRM[oBrowCRM:nAt,17] == '005'
			oButProp:Enable()  
			oButSlvCRM:Disable()
			oButCanCRM:Disable()			
		Else		
			oButProp:Disable() 
    	EndIf              
    	
        // Usuário não bloqueado para CAT
		If !lBloqCAT
			oBrowCAT:bLDblClick	:= {||	fExecBut("CAT","DC") }  						  
		Else                  
			oButBmp1:Disable()		
			oButBmp2:Disable()					
			oButBmp5:Disable()			
			oButSlvCAT:Disable()
			oButCanCAT:Disable()	
			oButPotCAT:Disable()				
			oButSolCAT:Disable()  
			oButAgnCAT:Disable()			
		EndIf        
		
		// Acesso Exclusivo do Gestor - Transferir Agenda Remota
		If lAdminCAT
			oButAgnCAT:Enable()  			
		Else		
			oButAgnCAT:Disable() 
    	EndIf  		

        // Usuário não bloqueado para CRM
		If !lBloqCRM
			oBrowCRM:bLDblClick	:= {||	fExecBut("CRM","DC") } 			
		Else     
			oButBmp3:Disable()		
			oButBmp4:Disable()
			oButBmp6:Disable()			
			oButProp:Disable()						
			oButPotCRM:Disable()
			oButSlvCRM:Disable()
			oButCanCRM:Disable()
			oButAbrPro:Disable()
			oButAgnCRM:Disable()
		EndIf		

		// Acesso Exclusivo do Gestor - Transferir Agenda Presencial 
		If lAdminCRM
			oButAgnCRM:Enable()  			
		Else		
			oButAgnCRM:Disable() 
    	EndIf 				
		
	ACTIVATE MSDIALOG oDlgSUSB CENTERED
	
Return(.T.)       


Static Function fPotencial(cOrigem)
****************************************************************************************
*
*
****

	Local nUpd 	:= If(cOrigem=="CRM",2,1)
	Local aAreaP:= GetArea()
	
	// Chama Tela: Cadastro de Potenciais
	U_FSCRMA31(cOrigem)   
	
	RestArea(aAreaP)
	
	// Atualiza Browse CAT/CRM   
	fAtuaBrow(1,"S")   
	fAtuaBrow(2,"S")  
	
	// Limpa Dados
	fExecBut(cOrigem,"C")
	
Return()     


Static Function fSolicitar()
****************************************************************************************
* Operador(a) solicita inclusão em sua lista de clientes nos parâmetros preenchidos
*
****

	Local oDlgAgen
	Local cRegiInte:= ""  
	Local lExecuta := .F.           
	Local lDistrib := .F.
	Local nQtidade := 1 	
	Local aRegiInte:= {"","1=Centro de BH","2=Barro Preto","3=Savassi","4=Venda Nova","5=Barreiro","6=Contagem","7=Betim"}	

	// Quantos clientes de qual região deseja que distribuam em seu usuário?   
	Define MSDialog oDlgAgen Title "Agendamento" From 0,0 To 210,350 Pixel Style DS_MODALFRAME
		
		@ 015,010 Say "Região Inter: " Pixel Of oDlgAgen 
		@ 013,050 Combobox cRegiInte Items aRegiInte Size 055,010 Of oDlgAgen Pixel	
	
		@ 033,010 Say "Quantidade:" Pixel Of oDlgAgen
		@ 031,050 Get nQtidade Size 45,09 Picture "@E 99" Pixel Of oDlgAgen 
	                      
		@ 084,050 Button "Confirmar" Size 050,012 Action (lExecuta := .T., oDlgAgen:End()) Pixel Of oDlgAgen 	
	  	@ 084,109 Button "Cancelar"  Size 050,012 Action (lExecuta := .F., oDlgAgen:End()) Pixel Of oDlgAgen 
					
	Activate MSDialog oDlgAgen Centered

	If !lExecuta .Or. nQtidade <= 0
		Return
	EndIf           
    
    // Executa a distribuição	   
	Processa({|| lDistrib := fDistribuir(cRegiInte,nQtidade) },"Aguarde...","Montando Atendimentos...")    		
	
	// Atualiza Browse CAT  
	fAtuaBrow(1,"S")   
	
	// Limpa Dados 
	fExecBut("CAT","C") 		
	
	If lDistrib		
		MsgInfo ( OemToAnsi ( "Clientes distribuídos com sucesso!" )  ) 	
	Else
		MsgInfo ( OemToAnsi ( "Não foram encontrados Clientes para distribuir com os parâmetros preenchidos." )  ) 		
	EndIf
Return()
                                  

Static Function fDistribuir(cRegiInte,nQtidade) 
****************************************************************************************
* Distribui clientes Sem Contato para o(a) Operador(a).
*
****

	Local cQuery   := ""
	Local cOperado := ""   
	Local cNumList := ""  
	Local aCentVet := {}                
	Local aAreaTmp := {}
	Local aAreaSol := GetArea()			
	Local nX:=1
	
	ProcRegua(2*nQtidade+8)  
	IncProc()  
	IncProc()	

	// Puxa o código do operador
	dbSelectArea("SU7")
	dbSetOrder(4)		
	If dbSeek(xFilial("SU7")+__cUserID)
   		cOperado := SU7->U7_COD
	EndIf                   
          
	IncProc()  
	IncProc()    
    
	// Pesquisa clientes 'Sem Contato' na região e quantidade especificadas.TOP "+AllTrim(Str(nQtidade))+"
	cQuery	:= " SELECT TOP "+AllTrim(Str(nQtidade))+" US_COD, US_LOJA, US_NOME, AC8_CODCON " + CRLF	
	cQuery	+= " FROM "+RetSqlName("SUS")+" SUS LEFT JOIN "+RetSqlName("AC8")+" AC8 ON AC8.D_E_L_E_T_ ='' 	" + CRLF		
	cQuery	+= " AND (SUS.US_COD+SUS.US_LOJA) = AC8_CODENT AND AC8_ENTIDA = 'SUS' 			" + CRLF		
	cQuery	+= " LEFT JOIN (						 			" + CRLF 
	cQuery	+= "	SELECT UC_CHAVE	POTENCIAL					" + CRLF 
	cQuery	+= "  	FROM "+RetSqlName("SUC")+" UC 				" + CRLF 
	cQuery	+= "  	WHERE UC.D_E_L_E_T_=''		   				" + CRLF 
	cQuery	+= "  	GROUP BY UC_CHAVE 			 				" + CRLF   
	cQuery	+= "	UNION						 				" + CRLF 
	cQuery	+= "	SELECT (AD1_PROSPE+AD1_LOJPRO) POTENCIAL	" + CRLF 
	cQuery	+= "   	FROM "+RetSqlName("AD1")+" AD1 				" + CRLF 
	cQuery	+= "   	WHERE AD1.D_E_L_E_T_=''		   				" + CRLF 
	cQuery	+= "   	GROUP BY (AD1_PROSPE+AD1_LOJPRO)			" + CRLF 		
	cQuery	+= " ) EXISTE ON POTENCIAL=SUS.US_COD+SUS.US_LOJA	" + CRLF 			
	cQuery	+= " WHERE SUS.D_E_L_E_T_ =''  						" + CRLF  
	cQuery	+= "    AND POTENCIAL IS NULL						" + CRLF 
	cQuery	+= "    AND US_EMLIGAC <> '1'						" + CRLF 
	cQuery	+= "    AND US_ESTATUS='1'							" + CRLF 	
	cQuery	+= "    AND US_REGINTE='"+cRegiInte+"'				" + CRLF        
	cQuery	+= " ORDER BY US_COD DESC							" + CRLF 
	    
	TCQuery cQuery New Alias "TMPS"
	IncProc()  
	IncProc()
		
	dbSelectArea("TMPS")   
	dbGoTop()
	
	// Não há dados para distribuir.
	If Eof()
	  
		TMPS->(dbCloseArea())		    
		IncProc()  
		IncProc()	
		RestArea(aAreaSol)
		Return(.F.)
	EndIf
	
	While !Eof()  			 
		IncProc()  
		IncProc()				
   	
	   	cNumList := GetSx8Num("SU4","U4_LISTA")                      
		aCentVet := {}				   

		aAdd(aCentVet,{	cNumList   						,;								// 01 - Código da Lista de Atendimento
						Left(AllTrim("A CONTACTAR - "+TMPS->US_NOME),30),; 				// 02 - Descrição Lista Momento Atual
						TMPS->AC8_CODCON			 	,; 								// 03 - Código Contato
						cOperado		   		  		,; 	   							// 04 - Código Operador   
						TMPS->US_COD	  			 	,; 								// 05 - Código Potencial
						TMPS->US_LOJA      				}) 	   							// 06 - Loja do Potencial
	    
	   // Tmp
		aAreaTmp := GetArea()														
		
		U_GeraList(aCentVet)  
        
        RestArea(aAreaTmp)                             
        
		//Tmp
		aAreaTmp := GetArea() 
		
		// Sem Contato e Ligação Ativa - Sugestão
		U_fPotenEst(TMPS->US_COD + TMPS->US_LOJA, "1", "1","A",,,)			    																					

		RestArea(aAreaTmp)

		dbSelectArea("TMPS")  									          												
		dbSkip()
			
	EndDo

	TMPS->(dbCloseArea())		    
	IncProc()  
	IncProc()
	
	RestArea(aAreaSol)	
	
Return(.T.)


Static Function fProposta()
****************************************************************************************
*
*
****

	Local aAreaSZI := GetArea()

	dbSelectArea("AD1")
	dbSetOrder(1)   
	
	If dbSeek( xFilial("AD1") + aBrowCRM[oBrowCRM:nAt,02] )
        
		If AD1->AD1_STAGE  <= '005' .And. AD1->AD1_STATUS <> '2'
			// Chama Tela: Proposta de Contrato
			U_FSCON002() 
	    EndIf
	Else
		MsgBox("Não existe Proposta de Contrato para esta evolução.","Registro Inexistente!","INFO")	
	EndIf
	
	RestArea(aAreaSZI)
		
	// Atualiza Browse CRM   
	fAtuaBrow(2,"S")   
	
	// Limpa Dados
	fExecBut("CRM","C")        
		
Return()


Static Function fExecBut(cOrig,cOper)
****************************************************************************************
* Executa operações para cada Tela de Atendimento:
*	S = Salvar 
*	C = Cancelar 
*   M = bChange / Mudança de Registro          
*	DC= Double Click
****

	If cOrig == "CAT" .And. cOper == "S"

		oMemoObs1:lReadOnly:=.T.
		aBrowCAT[oBrowCAT:nAt,17]:=cMemoObs1
		Processa({|| fSalvCAT(@nEditPos,oBrowCAT:nAt)},"Aguarde...","Salvando Atendimento...")
		cEvenCAT := ""
		fAtualCAT()
		oCombCAT:Disable()
		oCombCAT:Refresh()  
		oButSlvCAT:Disable()
		oButCanCAT:Disable()		
		oBrowCAT:SetFocus()
		fAtuaBrow(1,)
		If Len(aBrowCAT)>0 
			cMemoObs1:= aBrowCAT[oBrowCAT:nAt,17] 
		Else 
			cMemoObs1:= ''
		EndIf			
		cCodVend := cVendTmp    
		cNomVend := AllTrim(Posicione("SA3",1,xFilial("SA3")+cCodVend,"A3_NOME"))

	ElseIf cOrig == "CAT" .And. cOper == "C"  
	
		cEvenCAT := ""

		If Len(aBrowCAT)>0 
			cMemoObs1:= aBrowCAT[oBrowCAT:nAt,17] 
		Else 
			cMemoObs1:= ''
		EndIf         		
		fAtualCAT()
		oMemoObs1:lReadOnly := .T.
		oCombCAT:Disable()
		oCombCAT:Refresh()
		oButSlvCAT:Disable()
		oButCanCAT:Disable()				
		oBrowCAT:SetFocus()
		oBrowCAT:Refresh()                                  

	ElseIf cOrig == "CAT" .And. cOper == "M" // Mudança na linha do registro
		
		If Len(aBrowCAT)>0
			cMemoObs1:= aBrowCAT[oBrowCAT:nAt,17] 
		Else 
			cMemoObs1:= ''
		EndIf
		oMemoObs1:Refresh()
		oBrowCAT:Refresh() 			
   		
	ElseIf cOrig == "CAT" .And. cOper == "DC" // Duplo Click

		If Len(aBrowCAT) > 0
			nEditPos:=oBrowCAT:nAt
			oCombCAT:Enable()  
	  		oButSlvCAT:Enable()
	  		oButCanCAT:Enable()			
			oMemoObs1:lReadOnly:=.F.
			oMemoObs1:Refresh()
			oBrowCAT:SetFocus()
			oBrowCAT:Refresh()
			cHoraIni := Time()
		Else
			MsgBox("Não há atendimento para editar.","Atenção!","INFO")
		EndIf
		
	ElseIf cOrig == "CRM" .And. cOper == "S" 
	
		oMemoObs2:lReadOnly:=.T.
		aBrowCRM[oBrowCRM:nAt,09]:= cMemoObs2
		Processa({|| fSalvCRM(@nEditEvol,oBrowCRM:nAt)},"Aguarde...","Salvando Esforço...")
		cEvenCRM := ""
		fAtualCRM()            
		If(Len(aBrowCRM)>0 .And. aBrowCRM[oBrowCRM:nAt,17] == '005' .And. !lBloqCRM)
			oButProp:Enable()
		Else
			oButProp:Disable()
		EndIf
		oCombCRM:Disable()
		oCombCRM:Refresh() 
		oButSlvCRM:Disable()
		oButCanCRM:Disable()				
		oBrowCRM:SetFocus()
		fAtuaBrow(2,"S")			
		
	ElseIf cOrig == "CRM" .And. cOper == "C"     
		nEditEvol := 0	
		cEvenCRM := "" 
		cMemoObs2:= If( Len(aBrowCRM)>0,aBrowCRM[oBrowCRM:nAt,09],'')
		fAtualCRM()
		oMemoObs2:lReadOnly := .T.
		oCombCRM:Disable() 
		oCombCRM:Refresh()             
		If(Len(aBrowCRM)>0 .And. aBrowCRM[oBrowCRM:nAt,17] == '005' .And. !lBloqCRM)
			oButProp:Enable()
		Else
			oButProp:Disable()
		EndIf
		oButSlvCRM:Disable()
		oButCanCRM:Disable()		
		oBrowCRM:SetFocus()
		oBrowCRM:Refresh()  	
	
	ElseIf cOrig == "CRM" .And. cOper == "M" //Mudança	
	
		cMemoObs2:= If( Len(aBrowCRM)>0,aBrowCRM[oBrowCRM:nAt,09],'')
		oMemoObs2:Refresh()
		If(Len(aBrowCRM)>0 .And. aBrowCRM[oBrowCRM:nAt,17] == '005' .And. !lBloqCRM)
			oButProp:Enable()			
		Else
			oButProp:Disable()		
   		EndIf 

	ElseIf cOrig == "CRM" .And. cOper == "DC"
		
		If Len(aBrowCRM)>0 .And. aBrowCRM[oBrowCRM:nAt,17] <> '005'
			nEditEvol := oBrowCRM:nAt
			oCombCRM:Enable() 
			oButSlvCRM:Enable()
			oButCanCRM:Enable()				
			oMemoObs2:lReadOnly:=.F.
			oMemoObs2:Refresh()
			oBrowCRM:SetFocus()
			oBrowCRM:Refresh()
		ElseIf Len(aBrowCRM) <= 0 
			MsgBox("Não há evolução comercial para editar.","Atenção!","INFO")
		EndIf
	
	EndIf


Return()

 
Static Function fAtualCAT()
****************************************************************************************
* Atualiza variáveis sempre que alterar o combobox das ocorrências (eventos)
*
****	
    
	// Interesse Futuro
	If (cEvenCAT $'2')		
		cSayData :='Para quando:'		
		oDtEvento:Enable()
		oHoraEven:Disable()
		cUCAgen	 := Space(3)
		cLocalUC := ""		 
		cCodVend := cVendTmp    
		cNomVend := AllTrim(Posicione("SA3",1,xFilial("SA3")+cCodVend,"A3_NOME"))		    
		oUCAgen:Disable()
		oCodVend:Disable()
		oUCAgen:Refresh() 
		cMotCAT	 := ""						
		oCmbCAT:Disable()			
		oDlgSUSB:Refresh() 	    
		
	// Atualiza o estatus do cliente para Sem Agendamento - permite uma data
	ElseIf cEvenCAT=='3'
		
		cSayData :='Para quando:'		  	
		dDtEvento:=CtoD("")  	 	
		cHoraEven:= "  :  "
		cUCAgen	 := Space(3)
		cLocalUC := ""	 
		cCodVend := cVendTmp    
		cNomVend := AllTrim(Posicione("SA3",1,xFilial("SA3")+cCodVend,"A3_NOME"))	
		
		oDtEvento:Enable()	  			
		oHoraEven:Disable()
		oUCAgen:Disable()
		oUCAgen:Refresh()
		oCodVend:Disable()				
		cMotCAT	 := ""
		oCmbCAT:Disable() 					
		oDlgSUSB:Refresh()	

	// Agendamento atualiza o estatus do cliente para Agendado
	ElseIf cEvenCAT=='4'
		cSayData :='Agendamento:'
		oDtEvento:Enable()
		oHoraEven:Enable()
		oUCAgen:Enable()
		// Usuário logado é operador e consultor próprio, não edita campo.
		If Empty(cCodOper) .Or. Empty(cVendTmp) 
			oCodVend:Enable()
		EndIf
		cMotCAT	 := ""
		oCmbCAT:Disable()					
		oDlgSUSB:Refresh()   
	
	//Cliente 1=Não Existe / 5=Sem Interesse
	Else
		cSayData :='Agendamento:'
		dDtEvento:=CtoD("")
		cHoraEven:= "  :  "
		cUCAgen	 := Space(3)
		cLocalUC := ""	 
		cCodVend := cVendTmp    
		cNomVend := AllTrim(Posicione("SA3",1,xFilial("SA3")+cCodVend,"A3_NOME"))	
		oDtEvento:Disable()
		oHoraEven:Disable()
		oUCAgen:Disable()
		oUCAgen:Refresh()
		oCodVend:Disable()				
				
		// 1=Opções do Evento Não Existe | Inclusão do Motivo do desinteresse ou Inexistência	
		If cEvenCAT=='1'  
			oCmbCAT:aItems := aClone(aMotCAT1)		
			oCmbCAT:Refresh()  
			oCmbCAT:Enable()

		// 5=Opções do Evento Sem Interesse				
		ElseIf cEvenCAT=='5' 
			oCmbCAT:aItems := aClone(aMotCAT2)				 
			oCmbCAT:Refresh()								
			oCmbCAT:Enable()        
		Else
			cMotCAT	 := ""
			oCmbCAT:Disable()
		EndIf 

		oDlgSUSB:Refresh() 		
		
	EndIf									
	
Return()     


Static Function fAtualCRM()
****************************************************************************************
* Atualiza variáveis sempre que alterar o combobox das eventos do CRM
*
****	
    
	// Negociação em Andamento
	If (cEvenCRM == '000007')				
		oDtAgenda:Enable()
		oHoraAgen:Enable()
		oLocAgen :Enable()
		cLocAgen := Space(3)
		cDescLoc := "" 			 
		oLocAgen:Refresh()		
		oDescLoc:Refresh()	
		cMotCRM	 := ""
		oCmbCRM:Disable()				
		oDlgSUSB:Refresh() 		

	// Interesse Futuro
	ElseIf cEvenCRM == '000008'
		dDtAgenda:= CtoD("")
		cHoraAgen:= "  :  "
		cLocAgen := Space(3)
		cDescLoc := "" 					
		oDtAgenda:Enable()
		oHoraAgen:Disable()
		oLocAgen :Disable()
		oLocAgen:Refresh() 
		oDescLoc:Refresh()
		cMotCRM	 := ""
		oCmbCRM:Disable()	
		oDlgSUSB:Refresh()

	// Inserção de Proposta ou Não Compareceu ou Cliente Desistiu
	Else
		dDtAgenda:= CtoD("")
		cHoraAgen:= "  :  "
		cLocAgen := Space(3)
		cDescLoc := "" 					
		oDtAgenda:Disable()
		oHoraAgen:Disable()
		oLocAgen :Disable()
		oLocAgen:Refresh() 
		oDescLoc:Refresh()
        
		// Cliente Desistiu - Inclusão do Motivo do desinteresse, desistência ou Inexistência
		If cEvenCRM == '000011'
			oCmbCRM:Enable()		
			oCmbCRM:Refresh()		
		Else
			cMotCRM	 := ""
			oCmbCRM:Disable()	   		
		EndIf
							
		oDlgSUSB:Refresh()							
	EndIf									
	
Return()     
 

Static Function fSalvCAT(nEditPos,nLinha)
****************************************************************************************
* 
*
****	

	Local lInclui 	:= .F. 
	Local cQuery	:= ""
	Local cSeqSUD	:= ""
	Local cNumAtend := ""  
	Local cNumLista := ""      
	Local _nTam, _nTam1 
	Local dRetoAten := CtoD(" ")
	Local cHoraReto	:= ""
	Local cCodAcao	:= ""
	Local aAreaUs 	:= {}
	Local cQry	  	:= ""  
	Local cEstTemp	:= ""   
	Local cHorTemp	:= ""         
	Local cStatAten := "" 
	Local cSU4Statu := "2"
	Local aEvolVet	:= {}	
	Local cCodEnce	:= ""
	Local cNrOport	:= ""   	
	Local cU4Desc	:= ""
	
	ProcRegua(22)  
	IncProc()
	IncProc()
	  
	If cEvenCAT == "99" 
		lInclui		:= .F.
	Else
		lInclui 	:= If(aBrowCAT[nLinha,10]=="",.T.,.F.)	
	EndIf	
	cNrOport  := ""	

	// Reagendamento para a CAT - Sem Agendamento CRM
	If cEvenCAT $'3'  
		cStatAten := "2"        	// Pendente
		dEnceAten := CtoD(" ") 
		dRetoAten := dDtEvento		// Não encerra SU4 
		cHoraReto := "09:00"    
		cSU4Stat  := "1"
		cCodAcao  := "000101" 		// Reagendamento
		cUDMotRe  := "2"
		cUCEstag  := "1"
		cEmLigac  := "1"			
		cUSEstat  := "8"         	// Cliente Sem Agendamento
		cCodEnce  := ""   
		cU4Desc	  := "SEM AGENDAMENTO"
	
	// Agendamento para Atendimento Presencial - Consultor de Vendas		
	ElseIf cEvenCAT $'4'   
		cStatAten := "3"         	// Encerrado
		cSU4Stat  := "2"
		dRetoAten := CtoD(" ")
		cHoraReto := "  :  "
		dEnceAten := dDataBase	  
		cCodAcao  := "000103" 		// Agendamento     
		cCodEnce  := "000012"  
		cUCEstag  := "8"	
		cUDMotRe  := ""	  
		cUSEstat  := "2"            // Cliente Agendado
		cEmLigac  := "1"		   
		cU4Desc	  := "AGENDADO"
		
	ElseIf cEvenCAT =='99' 
		cStatAten := "3"      
		dRetoAten := CtoD(" ")
		cHoraReto := "  :  "
		dEnceAten := dDataBase	
		cCodAcao  := "000104" 		// Ligação Improdutiva/Chamada Encerrada      
		cUDMotRe  := ""	
		cEmLigac  := "2"
		cSU4Stat  := "2"	 
		cCodEnce  := "000016"    	
		cUCEstag  := "7"   	   		// Estágio = Sem Interesse / VENCIDO 

		If aBrowCAT[nLinha,01] == 'ASEMCONTATO'		                        
			cUSEstat := "1"         // Cliente Sem Contato = Antigo Potencial  
		Else
			cUSEstat := "8"         // Cliente Sem Agendamento  		
		EndIf	
		cU4Desc	  := "VENCIDO"		
	Else                                                                              	
		cStatAten := "3"      
		dRetoAten := CtoD(" ")
		cHoraReto := "  :  "
		dEnceAten := dDataBase	
		cCodAcao  := "000104" 		// Ligação Improdutiva/Chamada Encerrada      
		cUDMotRe  := ""	
		cEmLigac  := "2"
		cSU4Stat  := "2"	   
				
		// Cliente não existe
		If cEvenCAT=='1'
			cCodEnce := "000015"                              
			cUCEstag := "6"   		// Estágio = Inapto  
			cUSEstat := "9"         // Cliente Inapto
	  		cU4Desc	 := "NÃO EXISTE"
	  		
		// Interesse futuro
		ElseIf cEvenCAT=='2'            	
			cCodEnce := "000014"      
			dRetoAten:= dDtEvento 
			cHoraReto:= "09:00"						
			cUCEstag := "5"			// Interesse Futuro
			cUSEstat := "6"         // Cliente de Interesse Futuro    
			cU4Desc	 := "INTERESSE FUTURO"
			
		// Sem Interesse 
		ElseIf cEvenCAT=='5'
			cCodEnce := "000013"                              
			cUCEstag := "6"   		// Estágio = Inapto  
			cUSEstat := "9"         // Cliente Inapto			
			cU4Desc	 := "SEM INTERESSE"
		EndIf	   
	EndIf  

	IncProc()
	IncProc()	            				
	
	Begin Transaction

		If cEvenCAT $'4'  
	  		cNrOport := GetSx8Num("AD1","AD1_NROPOR")
	 	EndIf
		
		If lInclui      
					
   			dbSelectArea("SU4")
   			dbSetOrder(1)  
   			
   			If dbSeek(xFilial("SU4") + aBrowCAT[nLinha,13]) 
   			    
   				// Assegura que CRM não puxará o cliente para trabalho.
   				If RecLock ("SU4",.F.) .And. SU4->U4_STATUS=='1'
   			  
					cNumAtend := GetSx8Num("SUC","UC_CODIGO")  			 
			        
					// Cabeçalho Atendimento
					dbSelectArea ( "SUC" )
					dbSetOrder ( 1 )
					If RecLock ("SUC",.T.)
			
						Replace UC_CODIGO  With cNumAtend 
						Replace UC_FILIAL  With "01"
						Replace UC_XCLASCH With "1"			
						Replace UC_DATA    With dDataBase
						Replace UC_ENTIDAD With	"SUS"	
						Replace UC_CHAVE   With	(aBrowCAT[nLinha,06]+aBrowCAT[nLinha,07]) 
						Replace UC_DESCPOT With	aBrowCAT[nLinha,02]
						Replace UC_CODCONT With aBrowCAT[nLinha,09]				
						Replace UC_OPERADO With cCodOper  
						Replace UC_DECROPE With cNomOper
						Replace UC_MIDIA   With "000006"
						Replace UC_OPERACA With "1"			// Ativo
						Replace UC_STATUS  With cStatAten
						Replace UC_TIPO    With "000002"  	
						Replace UC_CODCAMP With "000031"    // Expansão SP
						Replace UC_DSCRCAM With Posicione("SUO",1,xFilial ( "SUO" ) + "000031","UO_DESC")		
						Replace UC_PENDENT With dRetoAten
						Replace UC_HRPEND  With cHoraReto
						Replace UC_NROPOR  With cNrOport
						Replace UC_DTENCER With dEnceAten
						Replace UC_CODENCE With cCodEnce	
						Replace UC_NEWDESK With 'S'
						Replace UC_ESTAGIO With cUCEstag
						Replace UC_INICIO  With cHoraIni
						Replace UC_FIM	   With Time()
						Replace UC_PROSPEC With .F.
						Replace UC_CODMOT  With cMotCAT	    // Inclusão do Motivo do desinteresse ou Inexistência	
						
						ConfirmSx8("SUC")			
						
						MsUnLock (  )
					Else
					    RollbackSx8()
					EndIf 
				
				Else 
					MsgBox("Registro sem interação foi apontado por outro consultor, não poderá continuar.","Registro indisponível.","INFO")  
					fAtuaBrow(1,"S")
					Return()	
	            EndIf
			Else
				MsgBox("Lista não encontrada, operação interrompida.","Registro inexistente.","INFO")  
				fAtuaBrow(1,"S")
				Return()
			EndIf

			IncProc()
			IncProc()	
    
	    // Altera
		ElseIf aBrowCAT[nLinha,10] <> ""     
            
			cNumAtend := aBrowCAT[nLinha,10]  			 

			// Cabeçalho Atendimento
			dbSelectArea ( "SUC" )
			dbSetOrder ( 1 ) 

			If dbSeek( "01" + cNumAtend )

				If RecLock ("SUC",.F.)
		
					Replace UC_OPERADO With cCodOper  
					Replace UC_DECROPE With cNomOper
					Replace UC_STATUS  With cStatAten
					Replace UC_PENDENT With dRetoAten
					Replace UC_HRPEND  With cHoraReto
					Replace UC_NROPOR  With cNrOport
					Replace UC_DTENCER With dEnceAten
					Replace UC_CODENCE With cCodEnce	
					Replace UC_ESTAGIO With cUCEstag
					Replace UC_FIM	   With Time()
					Replace UC_CODMOT  With cMotCAT	  	
									
					_nTam 	  := TamSX3("UC_CODOBS")
					_nTam1 	  := _nTam[1]
					
					// Temporariamente salvando vazio, para retirar de funcionamento - Todo histórico ficará na SUS do Cliente.
					If !Empty(MSMM(aBrowCAT[nLinha,05]))
						MSMM(aBrowCAT[nLinha,05],_nTam1,,"",1,,,"SUC","UC_CODOBS")
					EndIf
																
					MsUnLock (  )
				EndIf 				

			Else	
			     MsgBox("Não foi possível atualizar o Atendimento. Atendimento não localizado.","Registro Inexistente!", "INFO")  
			     fAtuaBrow(1,"S")
			     Return()
			EndIf    
			
			IncProc()
			IncProc()			
			
		EndIf                        
		
		If cNumAtend <> ""         
        
			cSeqSUD := fSeqSUD(cNumAtend)
	
			// Interações das Ligações do Atendimento	
			dbSelectArea ( "SUD" )
			dbSetOrder ( 1 )	
			If RecLock ("SUD",.T.)
				Replace UD_CODIGO  With cNumAtend	
				Replace UD_FILIAL  With "01"
				Replace UD_ITEM    With cSeqSUD
				Replace UD_ASSUNTO With "000105'
				Replace UD_DESCRSS With AllTrim(Posicione("SX5",1,xFilial("SX5")+"T1000105","X5_DESCRI"))  
				Replace UD_OCORREN With "000201"
				Replace UD_DESCROC With AllTrim(Posicione("SUR",2,xFilial("SUR")+"000201      ","UR_DESC"))  
				Replace UD_SOLUCAO With cCodAcao
				Replace UD_DESCRSO With AllTrim(Posicione("SUR",2,xFilial("SUR")+"000201"+cCodAcao,"UR_DESC"))  
				Replace UD_DATA    With dDataBase
				Replace UD_STATUS  With cStatAten	
				Replace UD_MOTREAG With cUDMotRe
				Replace UD_DTEXEC  With dDataBase
				Replace UD_OPERADO With cCodOper
				Replace UD_PENDENT With dRetoAten
				Replace UD_HRPEND  With cHoraReto       			
	
				MsUnLock (  )			
			EndIf 
	        
		EndIf

		IncProc()
		IncProc()
		
		// NROPOR - Gera Evolução		
		If cNrOport <> "" .And. cEvenCAT == "4"   
               
			aEvolVet := {}
			
			aAdd(aEvolVet,{	cNrOport	,;		 											// 01 - Código Evolução
							Left(AllTrim("ATEND.CLIENTE CAT - "+aBrowCAT[nLinha,02]),50),; 	// 02 - Descrição Evolução Momento Atual
							cCodVend,; 														// 03 - Código Vendedor
							aBrowCAT[nLinha,06]		 		,; 	   							// 04 - Código Prospect   
							aBrowCAT[nLinha,07]				,; 								// 05 - Loja Prospect 
							cUCAgen							,; 	  							// 06 - CC/Local Agendamento                   
							cNumAtend						,; 		  						// 07 - Código Atendimento CAT   
							cCodOper  						,; 		   						// 08 - Código do Operador CAT           					
							cNomOper						,; 								// 09 - Nome do Operador CAT          
							aBrowCAT[nLinha,02]  			,; 		  						// 10 - Nome do Cliente Potencial
							aBrowCAT[nLinha,17]				,; 		   						// 11 - Observação  												
							aBrowCAT[nLinha,11]				,; 		   						// 12 - Código do Cliente  												
							aBrowCAT[nLinha,12] 			,; 	   							// 13 - Loja do Cliente  							
							dDtEvento			  			,; 		  						// 14 - Data Agendamento
							cHoraEven						,; 		   						// 15 - Hova Inicial  												
							Ft320SomHr(cHoraEven)			,; 		   						// 16 - Hora Final											
							aBrowCAT[nLinha,09]				,; 	   							// 17 - Contato							
							""								}) 	   							// 18 - Evento

			aAreaUs := GetArea()														
			U_GeraEvol(aEvolVet)	 
			RestArea(aAreaUs)	
											
		EndIf 

		IncProc()
		IncProc()
    
		// Atualiza as listas trabalhadas no atendimento atual		
		cQuery := " UPDATE "+RetSqlName("SU4")+" SET U4_STATUS='"+cSU4Stat+"',U4_CODLIG='"+cNumAtend+"',U4_ESTAGIO='"+cUCEstag+"', "
		cQuery += " 	U4_DESC='" +Left(AllTrim(cU4Desc+" - "+aBrowCAT[nLinha,02]),55)+ "' "  				
		If cEvenCAT $'4'          
			cQuery += " ,U4_NROPORT ='"+cNrOport+"'"
		EndIf 
 		cQuery += " FROM "+RetSqlName("SU4")+" U4 JOIN "+RetSqlName("SU6")+" U6 ON U4_LISTA=U6_LISTA AND U6.D_E_L_E_T_=''	"						 		
 		cQuery += " WHERE U4.D_E_L_E_T_ = '' AND U4_LISTA ='"+aBrowCAT[nLinha,13]+"'		"
 		cQuery += " AND U6_CODENT ='"+(aBrowCAT[nLinha,06]+aBrowCAT[nLinha,07])+"' 			"
 		
   		TCSQLExec(cQuery) 		

		IncProc()
		IncProc()
	
		cQuery := " UPDATE "+RetSqlName("SU6")+" SET U6_STATUS='"+cSU4Stat+"',U6_CODLIG='"+cNumAtend+"'" 
		If cEvenCAT $'4'          
			cQuery += " ,U6_NROPORT ='"+cNrOport+"'"
		EndIf				 		
 		cQuery += " WHERE D_E_L_E_T_ = '' AND U6_LISTA ='"+aBrowCAT[nLinha,13]+"'		"
 		cQuery += " AND U6_CODENT ='"+(aBrowCAT[nLinha,06]+aBrowCAT[nLinha,07])+"' 		"
 		
   		TCSQLExec(cQuery)  
		         
		IncProc()
		IncProc()		
		IncProc()
		IncProc()     		
		          		
		nEditPos := 0 
	
	  	dbCommitAll()    
	  	
		aAreaUs := GetArea()

		// Atualiza Estatus do Cliente Pontecial e EmLigacao.
		U_fPotenEst(aBrowCAT[nLinha,06]+aBrowCAT[nLinha,07], cUSEstat, cEmLigac,"A",,aBrowCAT[nLinha,17],dRetoAten)  

		RestArea(aAreaUs)

		IncProc()
		IncProc()	  	
		  
	End Transaction	


	If !(cEvenCAT == "99")
		fAtuaBrow(2,"S")		
	EndIf	
	
	IncProc()
	IncProc()
	
Return()                
                        

Static Function fSalvCRM(nEditEvol,nLinha)
****************************************************************************************
* 
*
****	       
	Local cSeqAD5	:= "" 
	Local cQry		:= ""
	Local lDtExcec	:= .F.     
	Local aAreaDtEx	:= {}
	Local cCompar	:= ""
	Local cAD1Statu := "" 
	Local cAD1Stage := ""  		
	Local cAD1Descr := ""
	Local cConsVend	:= ""  
	Local cAD7Conta := ""
	Local cAD7CdTMK := ""
	Local cEvenTemp := ""
	Local cEvenBaix := ""       
	Local dDtIntFut := CtoD("")     
	Local aAreaOur	:= {}

	Private cEvolucao := "" 
		
	ProcRegua(14)  
	IncProc()
	IncProc()	    
	
	cEvolucao := aBrowCRM[nLinha,02]
		
	// Negociação em Andamento
	If cEvenCRM == '000007'  
		cAD1Statu	:= "1"
		cEmLigac	:= "1"		
		cAD1Stage	:= "003"      
		cUSEstat 	:= "2"				// Cliente Agendado	
		cAD1Descr	:= Left(AllTrim("NEGOCIAÇÃO EM ANDAMENTO - "+aBrowCRM[nLinha,03]),50) 
		dDtIntFut	:= CtoD("")
	
	// Interesse Futuro 
	ElseIf cEvenCRM == '000008'  
		cAD1Statu	:= "2"    
		cEmLigac	:= "2"
		cAD1Stage	:= "003"
		cAD1Descr	:= Left(AllTrim("INTERESSE FUTURO - "+aBrowCRM[nLinha,03]),50)	
		cUSEstat	:= "6"		   		
		dDtIntFut	:= dDtAgenda

	// Inserir Proposta - Encerrado com Sucesso  
	ElseIf cEvenCRM == '000009'                                                                                	
		cAD1Statu	:= "1"    			
		cEmLigac	:= "1"
		cAD1Stage	:= "005"  
		cAD1Descr	:= Left(AllTrim("PROPOSTA INSERIDA - "+aBrowCRM[nLinha,03]),50)	  
		cUSEstat 	:= "2"		   		// Continua com Agendado, virará Cliente Em Proposta quando gerar a Proposta.	  
		dDtIntFut	:= CtoD("")
				
	ElseIf cEvenCRM == '99' 
		cAD1Statu	:= "2"    
		cEmLigac	:= "2"
 		// Estágio = Sem Interesse 
		If aBrowCRM[nLinha,01] == 'AGENDADO'                        
			cAD1Stage	:= "003"  
			cAD1Descr	:= Left(AllTrim("ATENDIDO-VENCIDO 30 DIAS - "+aBrowCRM[nLinha,03]),50)	  
			cUSEstat 	:= "3"		   	
			cEvenBaix 	:= '000007' 
		Else
			cAD1Stage	:= "003"  
			cAD1Descr	:= Left(AllTrim("INAPTO-VENCIDO 30 DIAS - "+aBrowCRM[nLinha,03]),50)	  
			cUSEstat 	:= "9"		   	
			cEvenBaix 	:= '000010' 
		EndIf			
		cEvenTemp 	:= '99'
		cCompar	  	:= "3" 
		dDtIntFut	:= CtoD("")

	// Cliente Desistiu 
	ElseIf cEvenCRM == '000011'  
		cAD1Statu	:= "2"    
		cEmLigac	:= "2"
		cAD1Stage	:= "003"
		cAD1Descr	:= Left(AllTrim("CLIENTE DESISTIU - "+aBrowCRM[nLinha,03]),50)
		cUSEstat	:= "9"		   		// 9=Cliente Inapto
		dDtIntFut	:= CtoD("")
				
	// 000010=Não Compareceu - Não compareceu e não conseguiu falar com ele para novo agendamento. Continua por até 30 dias do primeiro agendamento 
	Else                                                                              	
		cAD1Statu	:= "1"    			
		cEmLigac	:= "1"
		cAD1Stage	:= "003"  
		cAD1Descr	:= Left(AllTrim("NÃO COMPARECEU - "+aBrowCRM[nLinha,03]),50)	  
		cUSEstat 	:= "2"		   				
		dDtIntFut	:= CtoD("")		
	EndIf  

	IncProc()
	IncProc()	            				

	Begin Transaction

		dbSelectArea("AD7")
		dbSetOrder(6)
		If dbSeek(xFilial("AD7")+cEvolucao)
		
			cSeqAD5	:= fSeqAD5(aBrowCRM[nLinha,16],DtoS(DATE()))	
		
			If (cEvenCRM == "000007")
	   				
	   				cAD7Conta := AD7->AD7_CONTAT
	   				cAD7CdTMK:= AD7->AD7_CODTMK
			
				While AD7->AD7_NROPOR == cEvolucao
					If Empty(AD7->AD7_DTEXEC) .And.  AD7->AD7_DATA == dDtAgenda
				   
						If MsgYesNo("Já existe uma agenda da Evolução "+Alltrim(cEvolucao)+" para "+DtoC(dDtAgenda)+" com inicio às "+AD7->AD7_HORA1+" deseja remove-la?","Atenção!")
							Reclock("AD7",.F.)
								dbDelete()
							MsUnlock() 
	
						// Finaliza o apontamento em aberto para gerar o novo.	
						Else
							RecLock ( "AD7", .F.  )
								AD7->AD7_DTEXEC := DATE()
								AD7->AD7_STAGE  := cAD1Stage     
						  		AD7->AD7_SEQAP	:= cSeqAD5
							MsUnLock (  )  
						EndIf
					
					// Finaliza o apontamento em aberto para gerar o novo.	
					ElseIf Empty(AD7->AD7_DTEXEC) .And.  AD7->AD7_DATA <> dDtAgenda
						RecLock ( "AD7", .F.  )
							AD7->AD7_DTEXEC := DATE()
							AD7->AD7_STAGE  := cAD1Stage     
					  		AD7->AD7_SEQAP	:= cSeqAD5
						MsUnLock (  )  
					EndIf
					dbSkip()
				EndDo               
						      		        
				// Agenda Atendimento Presencial
				dbSelectArea ( "AD7" )
				dbSetOrder (1)
				If RecLock ( "AD7",.T. )
					Replace	AD7->AD7_TOPICO	With cAD1Descr
					Replace	AD7->AD7_DATA	With dDtAgenda
					Replace	AD7->AD7_HORA1	With cHoraAgen
					Replace	AD7->AD7_HORA2	With Ft320SomHr(cHoraAgen)
					Replace	AD7->AD7_NROPOR	With cEvolucao  
					Replace	AD7->AD7_VEND	With aBrowCRM[nLinha,16]
					Replace	AD7->AD7_LOCAL	With cLocAgen
					Replace	AD7->AD7_PROVEN With "000001"  
					Replace	AD7->AD7_STAGE	With cAD1Stage		//003 = Em Atendimento
					Replace	AD7->AD7_CODTMK With cAD7CdTMK	
					Replace	AD7->AD7_AGEREU With 'A'
					Replace	AD7->AD7_PROSPE	With aBrowCRM[nLinha,07]
					Replace	AD7->AD7_LOJPRO	With aBrowCRM[nLinha,08]
					Replace	AD7->AD7_CONTAT With cAD7Conta			
					If !Empty(aBrowCRM[nLinha,13])
				  		Replace	AD7->AD7_CODCLI With aBrowCRM[nLinha,13]
				  		Replace	AD7->AD7_LOJA	With aBrowCRM[nLinha,14]
					EndIf 						
					MsUnLock (  )
				EndIf	
			
			// Encerra com o Final Stage
			Else    
			
				If (cEvenTemp == '99')
					cEvenCRM := cEvenBaix		
				EndIf			
				
				While AD7->AD7_NROPOR == cEvolucao
					If Empty(AD7->AD7_DTEXEC)
						RecLock ( "AD7", .F.  )
							AD7->AD7_DTEXEC := DATE()
							AD7->AD7_STAGE  := cAD1Stage      
					  		AD7->AD7_SEQAP	:= cSeqAD5
						MsUnLock (  )  
						lDtExcec := .T.	
					EndIf
					dbSkip()
				EndDo			 
								
				If !lDtExcec  				
					
					aAreaDtEx := GetArea()
					
					cQry := " SELECT AD7NROPOR, MAXREC									" + CRLF 
					cQry += " FROM (					  								" + CRLF 
					cQry += " 	SELECT AD7_NROPOR AD7NROPOR, MAX(R_E_C_N_O_) MAXREC		" + CRLF 
					cQry += " 	FROM "+RetSqlName("AD7")+"			  					" + CRLF 						
					cQry += " 	WHERE D_E_L_E_T_=''	   								   	" + CRLF 	
					cQry += " 	AND AD7_NROPOR='"+cEvolucao+"'							" + CRLF 
					cQry += " 	GROUP BY AD7_NROPOR										" + CRLF 		   					
					cQry += " ) AD7AGEND JOIN "+RetSqlName("AD7")+" AD7B ON 			" + CRLF 						
					cQry += " AD7B.AD7_NROPOR = AD7NROPOR AND AD7B.D_E_L_E_T_='' 		" + CRLF 						
					cQry += " AND AD7B.R_E_C_N_O_=MAXREC 								" + CRLF 
					
					TCQuery cQry New Alias "ULTAD7"
					
					dbSelectArea("ULTAD7")  										
					
					If ULTAD7->(!Eof())
                        dbSelectArea("AD7")
                        AD7->(dbGoTo(ULTAD7->MAXREC)) 
                        
						RecLock ( "AD7", .F.  )
							AD7->AD7_DTEXEC := DATE()
							AD7->AD7_STAGE  := cAD1Stage      
					  		AD7->AD7_SEQAP	:= cSeqAD5
						MsUnLock (  )  										
					
					EndIf
					
					ULTAD7->(dbCloseArea())
				    
					RestArea(aAreaDtEx)
				
				EndIf  
			
			EndIf 	 
			
			IncProc()
			IncProc()
						
			dbSelectArea ( "AD5" )
			dbSetOrder ( 1 )
			If RecLock ( "AD5", .T.  )
				Replace AD5->AD5_VEND 	With aBrowCRM[nLinha,16]
				Replace AD5->AD5_DATA 	With DATE()
				Replace AD5->AD5_SEQUEN	With cSeqAD5
				Replace AD5->AD5_NROPOR With cEvolucao
				Replace AD5->AD5_EVENTO With cEvenCRM
			    Replace AD5->AD5_PROSPE With aBrowCRM[nLinha,07]
				Replace AD5->AD5_LOJPRO With aBrowCRM[nLinha,08]
				Replace AD5->AD5_OBS	With aBrowCRM[nLinha,09]			
		  		Replace AD5->AD5_USUARI With __CUSERID
		  		Replace AD5->AD5_EVOLUC With "S"     
		  		Replace AD5->AD5_COMPAR With cCompar   
				Replace AD5->AD5_MOTIVO	With cMotCRM	
				If !Empty(aBrowCRM[nLinha,13])
			  		Replace	AD5_CODCLI	With aBrowCRM[nLinha,13]
			  		Replace	AD5_LOJA	With aBrowCRM[nLinha,14]
				EndIf		  		
				
				MsUnLock (  )
			EndIf			
		
			dbSelectArea ("AD1")
			dbSetOrder(1)   
			
			If dbSeek( xFilial("AD1") + cEvolucao )		
				
				If RecLock ( "AD1", .F.  )
					Replace AD1->AD1_STATUS With cAD1Statu
					Replace AD1->AD1_STAGE  With cAD1Stage
					Replace AD1->AD1_OBSPRO With aBrowCRM[nLinha,09]
					Replace AD1->AD1_DESCRI	With cAD1Descr
					
					MsUnLock (  )   
				EndIf
			EndIf       			         

			IncProc()
			IncProc()			          		
		
			// Habilita botão para Inserção de Proposta
			If cEvenCRM == '000009'  
		   		oButProp:Enable()     
			EndIf
	         
			// Libera Browse para navegação
			nEditEvol := 0 
			
	  		dbCommitAll()  
	  		
	  		aAreaOur := GetArea()
	  		
			// Atualiza Estatus do Cliente Pontecial e EmLigacao.
			U_fPotenEst(aBrowCRM[nLinha,07]+aBrowCRM[nLinha,08], cUSEstat, cEmLigac,"A",,aBrowCRM[nLinha,09],dDtIntFut)
	        
			RestArea(aAreaOur)
			
			IncProc()
			IncProc()	  		
		
		Else
			MsgBox("Evolução não encontrada. Procure a TI para apuração.","Código não encontrado!","ALERT")
		EndIf  

	End Transaction    

	IncProc()
	IncProc()

	If !(cEvenTemp == '99')
		fAtuaBrow(2,"S")   
	Else
 		cEvenCRM := '99' 		
	EndIf			

	IncProc()
	IncProc()
	
Return()                


User Function GeraEvol(aEvolVet)
****************************************************************************************
* 
*
****   
	Local cSeqAD5	:= "" 
	Local cAD1Stage := ""	
	
	// Sem Evento - Veio da Central	=> Estágio Agendado
	If aEvolVet[01,18] == ""
		cAD1Stage := "002"   
	
	// Com Evento - Veio do CRM		=> Estágio Em Atendimento 
	Else
		cAD1Stage := "003"
	EndIf

   	// Gera Evolução/Oportunidade Comercial
	dbSelectArea ("AD1")
	If RecLock ("AD1",.T.)                  
		Replace AD1_NROPOR With aEvolVet[01,01]
		Replace AD1_REVISA With "01"
		Replace AD1_DESCRI With aEvolVet[01,02]
		Replace AD1_VEND   With aEvolVet[01,03]                
		Replace AD1_PROSPE With aEvolVet[01,04]		 
		Replace AD1_LOJPRO With aEvolVet[01,05]		 
		Replace AD1_CENTRO With aEvolVet[01,06]
		Replace AD1_CODTMK With aEvolVet[01,07]
		Replace AD1_TMKUSR With aEvolVet[01,08]
		Replace AD1_TMKNOM With aEvolVet[01,09]
		Replace AD1_NOMPOT With aEvolVet[01,10]
		Replace AD1_OBSPRO With aEvolVet[01,11]
		Replace AD1_STAGE  With cAD1Stage
		Replace AD1_STATUS With "1"
		Replace AD1_PRIOR  With "1"		            	
		Replace AD1_DATA   With Date()
		Replace AD1_DTINI  With Date() 
		Replace AD1_HORA   With Time()
		Replace AD1_USER   With Alltrim (__cUserId)
		Replace AD1_PROVEN With "000001"
		Replace AD1_MOEDA  With 1		            		 		
		If !Empty(aEvolVet[01,12])
	  		Replace	AD1_CODCLI With aEvolVet[01,12]
	  		Replace	AD1_LOJCLI With aEvolVet[01,13]
		EndIf 					
		MsUnLock (  )
		
		ConfirmSx8("AD1")				
	Else
	    RollbackSx8()
	EndIf
	
	// Agenda Atendimento Presencial
	dbSelectArea ( "AD7" )
	dbSetOrder (1)
	If RecLock ( "AD7",.T. )
		Replace	AD7->AD7_NROPOR	With aEvolVet[01,01]
		Replace	AD7->AD7_TOPICO	With aEvolVet[01,02]
		Replace	AD7->AD7_VEND	With aEvolVet[01,03]
		Replace	AD7->AD7_PROSPE	With aEvolVet[01,04]		 
		Replace	AD7->AD7_LOJPRO	With aEvolVet[01,05] 
		Replace	AD7->AD7_LOCAL	With aEvolVet[01,06]   
		Replace	AD7->AD7_CODTMK With aEvolVet[01,07]							
		Replace	AD7->AD7_DATA	With aEvolVet[01,14]	
		Replace	AD7->AD7_HORA1	With aEvolVet[01,15]	
		Replace	AD7->AD7_HORA2	With aEvolVet[01,16]	
		Replace	AD7->AD7_CONTAT With aEvolVet[01,17]
		Replace	AD7->AD7_STAGE	With cAD1Stage
		Replace	AD7->AD7_AGEREU With 'A'
		Replace	AD7->AD7_PROVEN With "000001"  
		If !Empty(aEvolVet[01,12])
	  		Replace	AD7->AD7_CODCLI With aEvolVet[01,12]
	  		Replace	AD7->AD7_LOJA	With aEvolVet[01,13]
		EndIf 						
		MsUnLock (  )
	EndIf								

	// Origem do CRM possui pelo menos um atendimento.    
	If aEvolVet[01,18] <> ""     
	   
		cSeqAD5	:= fSeqAD5(aEvolVet[01,03],DtoS(Date()))
	
		dbSelectArea ( "AD5" )
		dbSetOrder (1)
		If RecLock ( "AD5",.T. )           

			Replace AD5_VEND   With aEvolVet[01,03]
			Replace AD5_DATA   With Date()
			Replace AD5_SEQUEN With cSeqAD5
			Replace AD5_NROPOR With aEvolVet[01,01]
			Replace AD5_EVENTO With aEvolVet[01,18]
		    Replace	AD5_PROSPE With aEvolVet[01,04]
			Replace AD5_LOJPRO With aEvolVet[01,05] 
			Replace AD5_OBS    With aEvolVet[01,11]
			Replace AD5_USUARI With Alltrim (__cUserId)   
	  		Replace AD5->AD5_EVOLUC With "S" 			
			If !Empty(aEvolVet[01,12])
		  		Replace	AD5_CODCLI	With aEvolVet[01,12]
		  		Replace	AD5_LOJA	With aEvolVet[01,13]
			EndIf			
			
			MsUnLock (  )
		EndIf	

    EndIf

Return()     


User Function GeraList(aCentVet)
****************************************************************************************
* 
*
****   

	Local aAreaSU4 := GetArea()

  	Begin Transaction
		
		dbSelectArea("SU4")
		If RecLock("SU4",.T.)
 
			Replace SU4->U4_FILIAL	With xFilial("SU4"),;
					SU4->U4_TIPO	With "4",;
					SU4->U4_STATUS	With "1",;
					SU4->U4_ESTAGIO	With "2",;
					SU4->U4_LISTA	With aCentVet[01,01],;
					SU4->U4_DESC	With aCentVet[01,02],;
					SU4->U4_DATA	With Date(),;
					SU4->U4_FORMA	With "1",;
					SU4->U4_TELE	With "5",;
					SU4->U4_TIPOTEL	With "2",;
					SU4->U4_HORA1	With Time(),;
					SU4->U4_CONTATO With aCentVet[01,03],;
					SU4->U4_OPERAD  With aCentVet[01,04],;  
			   		SU4->U4_ROTINA  With "TELEATENDIMENTO"
		  
			ConfirmSx8(.T.)	 
					
			MsUnLock (  )
		Else
		    RollbackSx8()
		EndIf
		
		dbSelectArea("SU6")
		If RecLock("SU6",.T.)
	
			Replace SU6->U6_FILIAL	With xFilial("SU6"),;
					SU6->U6_LISTA	With aCentVet[01,01],;
					SU6->U6_CODIGO	With "000001",;
					SU6->U6_CONTATO	With aCentVet[01,03],;
					SU6->U6_ENTIDA	With "SUS",;
					SU6->U6_CODENT	With (aCentVet[01,05]+aCentVet[01,06]),;
					SU6->U6_ORIGEM	With "2",;
					SU6->U6_DATA	With dDataBase,;
					SU6->U6_HRINI	With "09:00",;
					SU6->U6_HRFIM	With "18:00",;
					SU6->U6_STATUS	With "1",;
					SU6->U6_DTBASE	With dDataBase,;
					SU6->U6_CODOPER With aCentVet[01,04]  
			MsUnlock()
		EndIf

		dbCommitAll()
		
	End Transaction

	RestArea(aAreaSU4)
			
Return()
                        

Static Function fSeqSUD(cNumAtend)
****************************************************************************************
* Retorna a próxima numeração sequencial para a SUD do atendimento corrente.
*
**** 

	Local cSeq 		:= "01"
	Local aAreaUD 	:= GetArea()  	
	Local cQry 		:= ""	 
	
	cQry := " SELECT TOP 1 UD_ITEM ULTIMO			" + CRLF
	cQry += " FROM "+RetSqlName("SUD")+" SUD 						" + CRLF
	cQry += " WHERE SUD.D_E_L_E_T_='' 			  	" + CRLF
	cQry += " 	AND UD_CODIGO ='" +cNumAtend+ "' 	" + CRLF
	cQry += " ORDER BY UD_ITEM DESC					" + CRLF 
	
	TCQuery cQry New Alias "SEQ"

	dbSelectArea("SEQ")
	dbGoTop()
	
	If !Eof()		
		cSeq := Soma1(AllTrim(SEQ->ULTIMO))
	EndIf
	
	SEQ->(dbCloseArea()) 
	
	RestArea(aAreaUD)    

Return(cSeq)          


Static Function fSeqAD5(cVend, cData)
****************************************************************************************
* Retorna a próxima numeração sequencial para a AD5 deste vendedor neste dia.
*
**** 

	Local cSeq		:= "01"
	Local cQuery  	:= ""
	Local aAreaAD5	:= GetArea()
	
	cQuery := " SELECT AD5_VEND, AD5_DATA, MAX(AD5_SEQUEN) ULTIMO  "
	cQuery += " FROM "+RetSqlName("AD5")+" "
	cQuery += " WHERE AD5_VEND = '" + cVend + "'   	"
	cQuery += " 	AND AD5_DATA = '" + cData + "' 	"
	cQuery += " GROUP BY AD5_VEND, AD5_DATA			"

	TCQuery cQuery New Alias "SEQ"

	dbSelectArea("SEQ")
	dbGoTop()
	
	If !Eof()		
		cSeq := Soma1(AllTrim(SEQ->ULTIMO))
	EndIf

	SEQ->(dbCloseArea())

	RestArea(aAreaAD5)

Return (cSeq)


Static Function fValida(nOpc)
****************************************************************************************
* Valida preenchimento para prosseguir com função Salvar
*
**** 
    Local lRet		:= .T.
	Local cHoraFim	:= ""  
	Local cQuery	:= ""      
	Local aAreaVAL	:= GetArea()                                               
    
    // Valida informações da Central de Atendimento
    If nOpc == 1

		cHoraFim := Ft320SomHr(cHoraEven)
		
	    // Evento não preenchido
		If Empty(cEvenCAT)			
			
			MsgBox("Favor preencher a Ocorrência do atendimento remoto.",OemtoAnsi("Campo em Branco!"),"INFO")					
			lRet := .F.
		
		EndIf
	
	    // Interesse Futuro
		If (cEvenCAT $'2') .And. lRet		
	
			If Empty(DtoS(dDtEvento))
			
				MsgBox("A Data de interesse encontra-se em branco. Revise seus lançamentos e tente novamente.",OemtoAnsi("Campo em Branco!"),"INFO")					
				lRet := .F.
		
			EndIf  
		
			If lRet .And. ( DtoS(dDtEvento)<= DtoS(dDatabase) )
			
				MsgBox("A Data de interesse deve ser maior que a data corrente. Revise seus lançamentos e tente novamente.",OemtoAnsi("Campo Inválido!"),"INFO")					
				lRet := .F.
		
			EndIf 
	   	
	   	// Não Existe - Inclusão do Motivo do desinteresse ou Inexistência 
		ElseIf (cEvenCAT $'1') .And. lRet .And. Empty(cMotCAT)				
	
			MsgBox("Para cliente Não Existente, deve-se escolher um motivo.",OemtoAnsi("Campo em Branco!"),"INFO")					
			lRet := .F.
			
	   	// Sem Interesse - Inclusão do Motivo do desinteresse ou Inexistência 
		ElseIf (cEvenCAT $'5') .And. lRet .And. Empty(cMotCAT)		 	
	
			MsgBox("Para cliente Sem Interesse, deve-se escolher um motivo.",OemtoAnsi("Campo em Branco!"),"INFO")					
			lRet := .F.
		
	    // Sem Agendamento - Inclusão e validação de data de interesse futuro
		ElseIf (cEvenCAT $'3') .And. lRet		
	
			If Empty(DtoS(dDtEvento))
			
				MsgBox("A Data de interesse encontra-se em branco. Revise seus lançamentos e tente novamente.",OemtoAnsi("Campo em Branco!"),"INFO")					
				lRet := .F.
		
			EndIf 			

			If lRet .And. ( DtoS(dDtEvento)< DtoS(dDatabase) )
			
				MsgBox("A Data de interesse deve ser maior que a data corrente. Revise seus lançamentos e tente novamente.",OemtoAnsi("Campo Inválido!"),"INFO")					
				lRet := .F.
		
			EndIf 			
		
			If lRet .And. DateDiffDay(aBrowCAT[oBrowCAT:nAt,19],dDtEvento) > 20 .And. !(aBrowCAT[oBrowCAT:nAt,20] $ cOpeNVenc) 
			
				MsgBox("A Data de interesse deve ser até 20 dias da data de distribuição. Revise seus lançamentos e tente novamente.",OemtoAnsi("Campo Inválido!"),"INFO")					
				lRet := .F.
		
			EndIf 		
				 
	    // Agendamento Presencial
		ElseIf cEvenCAT=='4' .And. lRet		
		 
			If lRet .And. ( Empty(DtoS(dDtEvento)) .Or. Empty(cHoraEven) .Or.  AllTrim(cHoraEven)==":" .Or. Empty(cUCAgen) )
			
				MsgBox("Os campos Data, Hora e Local do Agendamento Presencial são de preenchimento obrigatório. Revise seus lançamentos e tente novamente.",;
						OemtoAnsi("Campo em Branco!"),"INFO")					
				lRet := .F.
		
			EndIf   
			
			If lRet .And. (cHoraEven > '18:30' .Or. cHoraEven < '09:00')
	
				MsgBox("Favor agendar o cliente em horário comercial válido, compreendido entre 09h e 18:30h!","Atenção!","INFO")								
				lRet := .F.
								
			EndIf	 
			
			If lRet .And. (( DtoS(dDtEvento) == DtoS(dDatabase) .And. cHoraEven < Time() ) .Or. DtoS(dDtEvento) < DtoS(dDatabase))
			
				MsgBox("Períodos passados não serão aceitos para agendamento. Revise seus lançamentos e tente novamente.",OemtoAnsi("Campo Inválido!"),"INFO")					
				lRet := .F.
		
			EndIf 							
			
			// Verifica duplicidade de agendamento e agendamento fora do horário permitido ( Entre 09:00 e 18:30 ).
			dbSelectArea("AD7")
			dbSetOrder(1)
			If dbSeek(xFilial("AD7")+cCodVend+DtoS(dDtEvento))
		
				While lRet .And. AD7->AD7_DATA == dDtEvento
					If Empty(AD7->AD7_DTEXEC) .And. ((cHoraFim <= AD7->AD7_HORA2 .And. cHoraFim >= AD7->AD7_HORA1) .Or.;
						 (cHoraEven <= AD7->AD7_HORA2 .And. cHoraEven >= AD7->AD7_HORA1) .Or. AllTrim(cHoraEven) == AllTrim(AD7->AD7_HORA1))
						
						MsgBox("O intervalo de horário informado já está alocado para este representante!","Atenção!","INFO")			
						lRet := .F.
			            Exit
					EndIf							
					
					dbSkip()
				EndDo		
	        EndIf 
		EndIf 

    // Valida informações da Evolução Comercial
	Else               
		
	    // Evento não preenchido
		If Empty(cEvenCRM)			
			
			MsgBox("Favor preencher o Evento do atendimento presencial.",OemtoAnsi("Campo em Branco!"),"INFO")					
			lRet := .F.
		
		EndIf     
		
		// Valida dados para Negociação em Andamento
		If cEvenCRM == "000007" .And. lRet		

	   		cHoraFim := Ft320SomHr(cHoraAgen)
		
		
	   		If lRet .And. (Empty(DtoS(dDtAgenda)) .Or. Empty(cHoraAgen) .Or.  AllTrim(cHoraAgen)==":" .Or. Empty(cLocAgen))
			
				MsgBox("Os campos Data, Hora e Local do Agendamento Presencial são de preenchimento obrigatório. Revise seus lançamentos e tente novamente.",;
						OemtoAnsi("Campo em Branco!"),"INFO")					
				lRet := .F.
		
			EndIf   		
			
			If lRet .And. (cHoraAgen > '18:30' .Or. cHoraAgen < '09:00')
	
				MsgBox("Favor agendar o cliente em horário comercial válido, compreendido entre 09h e 18:30h!","Atenção!","INFO")								
				lRet := .F.

			EndIf	   
			
			If lRet .And. (( DtoS(dDtAgenda) == DtoS(dDatabase) .And. cHoraAgen < Time() ) .Or. DtoS(dDtAgenda) < DtoS(dDatabase))
			
				MsgBox("Períodos passados não serão aceitos para agendamento. Revise seus lançamentos e tente novamente.",OemtoAnsi("Campo Inválido!"),"INFO")					
				lRet := .F.
		
			EndIf 						
			
			// Verifica duplicidade de agendamento e agendamento fora do horário permitido ( Entre 09:00 e 18:30 ).
			dbSelectArea("AD7")
			dbSetOrder(1)
			If dbSeek(xFilial("AD7")+cCodVend+DtoS(dDtAgenda))
		
				While lRet .And. AD7->AD7_DATA == dDtAgenda
					If Empty(AD7->AD7_DTEXEC) .And. ((cHoraFim <= AD7->AD7_HORA2 .And. cHoraFim >= AD7->AD7_HORA1) .Or.;
						 (cHoraAgen <= AD7->AD7_HORA2 .And. cHoraAgen >= AD7->AD7_HORA1) .Or. AllTrim(cHoraAgen) == AllTrim(AD7->AD7_HORA1))
						
						MsgBox("O intervalo de horário informado já está alocado para este representante!","Atenção!","INFO")			
						lRet := .F.
			            Exit
					EndIf						
					
					dbSkip()
				EndDo 					
	
			EndIf
	    
	    // Novo Interesse Futuro
		ElseIf cEvenCRM == "000008" .And. lRet .And. ( Empty(DtoS(dDtAgenda)) .Or. DtoS(dDtAgenda)<= DtoS(dDatabase) )

			MsgBox("A Data de interesse encontra-se em branco ou inválida. Revise seus lançamentos e tente novamente.",OemtoAnsi("Campo em Branco!"),"INFO")					
			lRet := .F.         
			
	   	// Cliente Desistiu	 
		ElseIf cEvenCRM == "000011" .And. lRet  .And. Empty(cMotCRM)			
	
			MsgBox("Para cliente Desistente, deve-se escolher um motivo.",OemtoAnsi("Campo em Branco!"),"INFO")					
			lRet := .F.							
	
		// Somente permite inserir proposta com dados do potencial devidamente preenchidos.	    
		ElseIf cEvenCRM == "000009" .And. lRet		
		
			dbSelectArea ( "SUS" )
			dbSetOrder ( 1 )
			If dbSeek(xFilial("SUS") + aBrowCRM[oBrowCRM:nAt,07] + aBrowCRM[oBrowCRM:nAt,08])   					
	
				If Empty(SUS->US_CATEGOR) .And. lRet	
					MsgBox("Categoria em branco ou inexistente. Verifique seus dados e tente novamente.","Campo em branco!","INFO")
					lRet := .F.
				ElseIf (Empty(SUS->US_DDD) .Or. Empty(SUS->US_TEL)) .And. lRet	
					MsgBox("DDD + Telefone Celular devem ser preenchidos corretamente. Verifique seus dados e tente novamente.","Campo inválido!","INFO")
					lRet := .F.
				ElseIf Empty(SUS->US_REGINTE) .And. lRet	
					MsgBox("Região de interesse em branco ou inexistente. Verifique seus dados e tente novamente.","Campo em branco!","INFO")
					lRet := .F.  
				ElseIf ( Empty(SUS->US_EMAIL) .Or. !IsEmail(SUS->US_EMAIL) ) .And. lRet 
					MsgBox("E-mail em branco ou inexistente. Verifique seus dados e tente novamente.","Campo em branco!","INFO")
					lRet := .F.					
				EndIf
			
			EndIf  
	
		EndIf 
	EndIf

	RestArea(aAreaVAL)			

Return(lRet)


Static Function fEditaPot(cOrigem)
***************************************************************************************
*
*
*****
	
	Local cDlgTitul	  := ""
	Local aRegiInte	  := {"","1=Centro de BH","2=Barro Preto","3=Savassi","4=Venda Nova","5=Barreiro","6=Contagem","7=Betim"} 
	Local aOpcCont	  := {"","1=WhatsApp","2=Ligação"}
	Local aAreaPt	  := GetArea()
	
	Private cTitulo	  := "Evolução Comercial - " + cNomVend
	Private oGetD, oDlgEvoluc, oDadCadas, oCodiEvol, oDescEvol, oCodiPote, oPoteEvol, oCodSubst, lCodSubst, oNomSubst
	Private oTeleFixo, oTeleOutr, oSegPoten, oDesClie1, oDescOrig, oRegiInte, oBtnConfir,oBtnCancel,oEmailPot, oCodTMK
	Private oOrigePot, lCodiEvol, lCodiPote, lTeleFixo, lTeleOutr, lSegPoten, lOrigePot, lRegiInte, lEmailPot, lCodTMK
	Private lGrauPar, lCatPoten, oGrauPar, oCatPoten, oDesCateg, oCodLoja, lCodLoja, lOpcCont,oOpcCont,lEventRD,oEventRD
	Private lChamaCRM := .F.
	Private lVisualiz := .F.
	Private lTrocaSub := .F.
	Private cRegiInte := Space(1)
	Private cCodiEvol := Space(6)  
	Private cCodProsp := Space(6)
	Private cLojProsp := Space(2)
	Private cDDDPoten := Space(3)
	Private cSegPoten := Space(6) 
	Private cCategor  := Space(2)
	Private cTelePote := Space(15)
	Private cTeleFixo := Space(15)
	Private cTeleOutr := Space(15)
	Private cEmailPot := Space(150)
	Private cCodSubst := Space(8)
	Private cTrocaSub := Space(6)
	Private cNomeSubs := Space(50)
	Private cNomePote := Space(50)
	Private cDescSeg1 := Space(50) 
	Private cDescEvol := Space(50) 
	Private cGrauPar  := Space(50)	
	Private cCodTMK	  := Space(6)
	Private cCategor  := Space(2)	
	Private cOpcCont  := Space(1) 	// 1=WHATSAPP | 2=LIGACAO | 3=NAO INFORMADO 
	Private cEventRD  := Space(254) // ÚLTIMO EVENTO RD STATION 
	Private cOrigePot := ""
	Private cDescOrig := ""
	Private cDesCateg := "" 	 
	Private cProposta := ""
	
	If cOrigem == "CRM"

		lChamaCRM := .T. 
		cDlgTitul := "Dados da Evolução"   
		cTitulo	  := "Evolução Comercial - " + cNomVend
	
		If Empty(aBrowCRM)
			Return
		EndIf
		
		cCodiEvol := aBrowCRM[oBrowCRM:nAt,02]	
			
		dbSelectArea("AD1")
		dbSetOrder(1)   
		
		If dbSeek( xFilial("AD1") + cCodiEvol )
		
			cDescEvol := AD1->AD1_DESCRI
			cCodProsp := AD1->AD1_PROSPE
			cLojProsp := AD1->AD1_LOJPRO
			cCodTMK	  := AD1->AD1_CODTMK
			cProposta := AD1->AD1_PROPOS
			If Empty(cProposta)
				cProposta := AD1->AD1_PROPAB
			EndIf
			
			fMontaSUS()
			
		Else
			MsgBox("Evolução não encontrada. Procure a TI para apuração.","Código não encontrado!","ALERT")
			Return()
		EndIf  
		
	Else
		
		lChamaCRM := .F.	
		cDlgTitul := "Dados do Atendimento"  
		cTitulo	  := "Central de Atendimento - " + cNomOper
			
		If Empty(aBrowCAT)
			Return
		EndIf

		cCodProsp := aBrowCAT[oBrowCAT:nAt,06]	
		cLojProsp := aBrowCAT[oBrowCAT:nAt,07]	
		cCodTMK	  := aBrowCAT[oBrowCAT:nAt,10]	

		fMontaSUS()
		 			
	EndIf
		                                
	If U_fPotenEst(cCodProsp + cLojProsp,/*Estatus*/,/*Ligacao*/,"C",,,) == "4"
		lVisualiz := .T.
	EndIf
	
	Define MSDialog oDlgEvoluc Title cTitulo From 0,0 To 380/*350*/,570 Pixel  Style DS_MODALFRAME
		 
	  	// Aba Dados Cadastrais
	   	oDadCadas := TGroup():New(005,010,/*155*/167,278,cDlgTitul,oDlgEvoluc,CLR_BLACK,CLR_WHITE,.T.,.F. )

		If lChamaCRM
			lCodiEvol := TSay():New( 019,019,{|| "Evol.Comercial: "},oDadCadas,,,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,040,008)
			oCodiEvol := TGet():New( 018,059,{|u| If(PCount()>0,cCodiEvol:=u,cCodiEvol)},oDadCadas,030,008,'',,CLR_BLACK,CLR_WHITE,,,,.T.,"",,,.F.,.F.,,.T.,,"","cCodiEvol",,)
		Else
			lCodTMK   := TSay():New( 019,019,{|| "Atend.Remoto: "},oDadCadas,,,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,040,008)
			oCodTMK   := TGet():New( 018,059,{|u| If(PCount()>0,cCodTMK:=u,cCodTMK)},oDadCadas,030,008,'',,CLR_BLACK,CLR_WHITE,,,,.T.,"",,,.F.,.F.,,.T.,,"","cCodTMK",,)		
		EndIf	   
		
		lEventRD := TSay():New( 019,095,{|| "Evento:"},oDadCadas,,,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,032,008)  
		oEventRD := TGet():New( 018,115,{|u| If(PCount()>0,cEventRD:=u,cEventRD)},oDadCadas,146,008,'',,CLR_BLACK,CLR_WHITE,,,,.T.,"",,,.F.,.F.,,.T.,,"","cEventRD",,)	                                                	
					 
		lCodiPote := TSay():New( 035,019,{|| "Potencial:"},oDadCadas,,,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,032,008)
		oCodiPote := TGet():New( 034,059,{|x| If(PCount() > 0,cCodProsp := x,cCodProsp)},oDadCadas,030,008,PesqPict("SUS","US_COD"),{|| },,,,,,.T.,,,,,,,.T.,,,"cCodProsp")
		oCodLoja  := TGet():New( 034,095,{|x| If(PCount() > 0,cLojProsp := x,cLojProsp)},oDadCadas,010,008,PesqPict("SUS","US_LOJA"),{|| },,,,,,.T.,,,,,,,.T.,,,"cLojProsp")
		oPoteEvol := TGet():New( 034,115,{|u| If(PCount()>0,cNomePote:=u,cNomePote)},oDadCadas,146,008,'',,CLR_BLACK,CLR_WHITE,,,,.T.,"",,,.F.,.F.,,lVisualiz,,"","cNomePote",,)	                                                	

        If cOrigem == "CRM"
			lSegPoten := TSay():New( 051,019,{|| "Produto:"},oDadCadas,,,.F.,.F.,.F.,.T.,CLR_HBLUE,CLR_WHITE,032,008)
		Else 
			lSegPoten := TSay():New( 051,019,{|| "Produto:"},oDadCadas,,,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,032,008)		
		EndIf
		If lVisualiz 
			oSegPoten := TGet():New( 050,059,{|u| If(PCount()>0,cSegPoten:=u,cSegPoten)},oDadCadas,024,008,'',,  CLR_BLACK,CLR_WHITE,,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","cSegPoten",,)		
			oBtnF3:= TButton():New( 050,084,"?",oDlgEvoluc, {|| cSegPoten:=fSegmen(cCodProsp,cLojProsp,"C",""),;
		 				cDescSeg1 := AllTrim(Posicione("SX5",1,xFilial("SX5")+'T3'+cSegPoten,"X5_DESCRI")),oDesClie1:Refresh(),;
		 				oCatPoten:SetFocus() },07,010,,,,.T.,,"",,,,.F. )

			oSegPoten:bValid := {|| cDescSeg1 := AllTrim(Posicione("SX5",1,xFilial("SX5")+'T3'+cSegPoten,"X5_DESCRI")),oDesClie1:Refresh(), fSegmen(cCodProsp,cLojProsp,"V",cSegPoten) }
			oSegPoten:bChange:= {|| cDescSeg1 := AllTrim(Posicione("SX5",1,xFilial("SX5")+'T3'+cSegPoten,"X5_DESCRI")),oDesClie1:Refresh() }
			oDesClie1 := TGet():New( 050,095,{|u| If(PCount()>0,cDescSeg1:=u,cDescSeg1)},oDadCadas,166,008,'',,CLR_BLACK,CLR_WHITE,,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","cDescSeg1",,)

		Else
			oSegPoten := TGet():New( 050,059,{|u| If(PCount()>0,cSegPoten:=u,cSegPoten)},oDadCadas,023,008,'',,  CLR_BLACK,CLR_WHITE,,,,.T.,"",,,.F.,.F.,,lVisualiz,.F.,"T3","cSegPoten",,)		
			oSegPoten:bValid := {|| cDescSeg1 := AllTrim(Posicione("SX5",1,xFilial("SX5")+'T3'+cSegPoten,"X5_DESCRI")),oDesClie1:Refresh(),Empty(cSegPoten).Or.ExistCpo('SX5','T3'+cSegPoten) }
			oSegPoten:bChange:= {|| cDescSeg1 := AllTrim(Posicione("SX5",1,xFilial("SX5")+'T3'+cSegPoten,"X5_DESCRI")),oDesClie1:Refresh() }
			oDesClie1 := TGet():New( 050,095,{|u| If(PCount()>0,cDescSeg1:=u,cDescSeg1)},oDadCadas,166,008,'',,CLR_BLACK,CLR_WHITE,,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","cDescSeg1",,)			
		EndIf
		
		lCatPoten := TSay():New( 067,019,{|| "Categoria:"},oDadCadas,,,.F.,.F.,.F.,.T.,CLR_HBLUE,CLR_WHITE,032,008)
		oCatPoten := TGet():New( 066,059,{|u| If(PCount()>0,cCategor:=u,cCategor)},oDadCadas,032,008,'',,  CLR_BLACK,CLR_WHITE,,,,.T.,"",,,.F.,.F.,,lVisualiz,.F.,"Z6","cCategor",,)
		oCatPoten:bValid := {|| cDesCateg := AllTrim(Posicione("SX5",1,xFilial("SX5")+'Z6'+cCategor,"X5_DESCRI")),oDesClie1:Refresh(),ExistCpo('SX5','Z6'+cCategor) }
		oCatPoten:bChange:= {|| cDesCateg := AllTrim(Posicione("SX5",1,xFilial("SX5")+'Z6'+cCategor,"X5_DESCRI")),oDesClie1:Refresh() }
		oDesCateg := TGet():New( 066,095,{|u| If(PCount()>0,cDesCateg:=u,cDesCateg)},oDadCadas,166,008,'',,CLR_BLACK,CLR_WHITE,,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","cDesCateg",,)		
	    
		lTeleEvol := TSay():New( 083,019,{|| "Celular/What:"},oDadCadas,,,.F.,.F.,.F.,.T.,CLR_HBLUE,CLR_WHITE,032,008)
		oTeleEvol := TGet():New( 082,059,{|x| If(PCount() > 0,cDDDPoten := x,cDDDPoten)},oDadCadas,020,008,'999',{|| },,,,,,.T.,,,,,,,lVisualiz,,,"cDDDPoten")
		oDDDEvol  := TGet():New( 082,095,{|u| If(PCount()>0,cTelePote:=u,cTelePote)},oDadCadas,035,008,'',,CLR_BLACK,CLR_WHITE,,,,.T.,"",,,.F.,.F.,,lVisualiz,,"","cTelePote",,)
	
		lTeleFixo := TSay():New( 083,142,{|| "Fixo:"},oDadCadas,,,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,032,008)
		oTeleFixo := TGet():New( 082,157,{|u| If(PCount()>0,cTeleFixo:=u,cTeleFixo)},oDadCadas,035,008,'',,CLR_BLACK,CLR_WHITE,,,,.T.,"",,,.F.,.F.,,lVisualiz,,"","cTeleFixo",,)
	
		lTeleOutr := TSay():New( 083,204,{|| "Outro:"},oDadCadas,,,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,032,008)
		oTeleOutr := TGet():New( 082,224,{|u| If(PCount()>0,cTeleOutr:=u,cTeleOutr)},oDadCadas,036,008,'',,CLR_BLACK,CLR_WHITE,,,,.T.,"",,,.F.,.F.,,lVisualiz,,"","cTeleOutr",,)
	
		lRegiInte := TSay():New( 99,019,{|| "Região Inter: "},oDadCadas,,,.F.,.F.,.F.,.T.,CLR_HBLUE,CLR_WHITE,030,008)
		oRegiInte := TComboBox():New( 98,059,{|u|if(PCount()>0,cRegiInte:=u,cRegiInte)},aRegiInte,048,008,oDadCadas,,,{|| Pertence("1234567") },,,.T.,,,,{|| !lVisualiz},,,,,"cRegiInte")
		
		lEmailPot := TSay():New( 115,019,{|| "E-mail:"},oDadCadas,,,.F.,.F.,.F.,.T.,CLR_HBLUE,CLR_WHITE,032,008)
		oEmailPot := TGet():New( 114,059,{|u| If(PCount()>0,cEmailPot:=u,cEmailPot)},oDadCadas,200,008,'',,CLR_BLACK,CLR_WHITE,,,,.T.,"",,,.F.,.F.,,lVisualiz,,"","cEmailPot",,)	

		lOpcCont := TSay():New( 99,142,{|| "Opc.Contato:"},oDadCadas,,,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,032,008)  // 1=WHATSAPP | 2=LIGACAO | 3=NAO INFORMADO 
		oOpcCont := TComboBox():New( 98,177,{|u|if(PCount()>0,cOpcCont:=u,cOpcCont)},aOpcCont,048,008,oDadCadas,,,{|| },,,.T.,,,,{|| !lVisualiz},,,,,"cOpcCont")
		
		If lTrocaSub .And. lChamaCRM
			lCodSubst := TSay():New( 134,019,{|| "Substituir Pot:"},oDadCadas,,,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,040,008)
			oCodSubst := TGet():New( 133,059,{|x| If(PCount() > 0,cCodSubst := x,cCodSubst)},oDadCadas,047,008,PesqPict("SUS","US_CODSUBS"),,  CLR_BLACK,CLR_WHITE,,,,.T.,"",,,.F.,.F.,,lVisualiz,.F.,"SUSP01","cCodSubst")
			oNomSubst := TGet():New( 133,112,{|u| If(PCount()>0,cNomeSubs:=u,cNomeSubs)},oDadCadas,148,008,'',,CLR_BLACK,CLR_WHITE,,,,.T.,"",,,.F.,.F.,,.T.,,"","cNomeSubs",,)	                                                	
	  		oCodSubst:bValid := {|| cNomeSubs := AllTrim(Posicione("SUS",1,xFilial("SUS")+cCodSubst,"US_NOME")),oNomSubst:Refresh(),ExistCpo('SUS',cCodSubst) }				 

			lGrauPar  := TSay():New( 151,019,{|| "Grau Parentes:"},oDadCadas,,,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,047,008)
	   		oGrauPar  := TGet():New( 150,059,{|u| If(PCount()>0,cGrauPar:=u,cGrauPar)},oDadCadas,202,008,'',,CLR_BLACK,CLR_WHITE,,,,.T.,"",,,.F.,.F.,,lVisualiz,,"","cGrauPar",,)	                                                	
		EndIf		
				
		oBtnConfir:= TButton():New( 173,150,"Confirmar",oDlgEvoluc, {|| fSalvSUS() },050,012,,,,.T.,,"",,,,.F. )
		oBtnCancel:= TButton():New( 173,210,"Cancelar" ,oDlgEvoluc, {|| fFechar()},050,012,,,,.T.,,"",,,,.F. )
	
	
	Activate Dialog oDlgEvoluc Centered  
	
	RestArea(aAreaPt)
	
Return (.T.)
      

Static Function fSalvSUS()
***************************************************************************************
* Salva informações da edição da evolução comercial
*
*****     
	Local cQuery	:= ""  	
	Local cZOrigM	:= "" 
	Local cZOrigX	:= "" 
	Local aAreaOr	:= {} 
	Local aAreaSUS	:= {}
	
	If !lVisualiz
	
		aAreaSUS	:= GetArea()
	
		If Empty(cCategor)
			MsgBox("Categoria em branco ou inexistente. Verifique seus dados e tente novamente.","Campo em branco!","INFO")
			Return(.F.)
		ElseIf Empty(cDDDPoten) .Or. Empty(cTelePote)   
			MsgBox("DDD + Telefone Celular devem ser preenchidos corretamente. Verifique seus dados e tente novamente.","Campo inválido!","INFO")
			Return(.F.)
		ElseIf Empty(cRegiInte)
			MsgBox("Região de interesse em branco ou inexistente. Verifique seus dados e tente novamente.","Campo em branco!","INFO")
			Return(.F.)   
		ElseIf Empty(cEmailPot)
			MsgBox("E-mail do cliente é de preenchimento obrigatório. Verifique seus dados e tente novamente.","Campo em branco!","INFO")
			Return(.F.)		
		EndIf
		
		If lChamaCRM .And. lTrocaSub .And. !Empty(cCodSubst)        
			
			// Verifica proposta se está com status de cadastrada, do contrário não permite mudança
			If !Empty(aBrowCRM[oBrowCRM:nAt,15])
			
				dbSelectArea("SZI")
				dbSetOrder(1)   
				
				If dbSeek( xFilial("SZI") + aBrowCRM[oBrowCRM:nAt,15] ) .And. SZI->ZI_ESTATUS <> 'C'		
					MsgBox("Proposta deve estar com Status de Cadastrada para ser alterada. Mudança de Potencial não permitida.","Solicitação Negada!","INFO")
					Return(.F.)	
				EndIf		
	
			EndIf		
			
			If !MsgBox(" << Atenção >> O preenchimento do campo 'Substituir Potencial', substituirá o Cliente Potencial atual pelo novo escolhido,"+;
					  " em todo o processo de negociação vinculado a esta Evolução Comercial. Deseja, realmente, continuar?","Atenção! Substituição de Potencial","YESNO")

				Return(.F.)	
		  	EndIf 
		  	
			// Troca cliente potencial pelo novo cliente, em todas as instâncias da evolução comercial.  
			If !fTrocaPot()    
		  		Return(.F.)	
			EndIf	
			
		    // Atualiza informações no cadastro do Potencial, unicamente, para a primeira troca   
			If lTrocaSub .And. Empty(cTrocaSub)	                  
				dbSelectArea("SUS")
				dbSetOrder(1)      
				If dbSeek(xFilial("SUS") + cCodProsp + cLojProsp) 			
					Reclock("SUS",.F.)			 		 			 		
				 		Replace	SUS->US_CODSUBS	With cCodSubst 
				 		Replace SUS->US_GRAUPAR With cGrauPar	 		
					MsUnlock()	
	  			EndIf
				
				aAreaOr := GetArea()
			  
				cZOrigM := SUS->US_ZORIGEM
				cZOrigX := SUS->US_ZORIGEX  
			  
				dbSelectArea("SUS")
				dbSetOrder(1)     
				If dbSeek(xFilial("SUS") + cCodSubst ) .And. AllTrim(SUS->US_ZORIGEM) ==''

					Reclock("SUS",.F.)                                                                                                                                                     
						Replace SUS->US_ZORIGEM	With cZOrigM
						Replace SUS->US_ZORIGEX With cZOrigX                                        
					MsUnlock()       
				EndIf       
			  
				RestArea(aAreaOr)
				
			EndIf
			
			// Cliente atual deixa de estar em ligação e novo cliente passa a estar em ligação + Atualiza US_ESTATUS de Ambos
			U_fPotenEst(cCodProsp + cLojProsp, "A" /*Cliente Substituído*/, "2","A",,aBrowCRM[oBrowCRM:nAt,09],)   
			U_fPotenEst(cCodSubst, "", "1","A",,,)     
			
			// Salva histórico da substituição na SZS.
			U_fHistCRM("P",aBrowCRM[oBrowCRM:nAt,02],"",aBrowCRM[oBrowCRM:nAt,16],"", cCodProsp + cLojProsp,cCodSubst)
			Limpa()
	
		Else
				    	
		    // Atualiza informações no cadastro do Potencial                    
			dbSelectArea("SUS")
			dbSetOrder(1)      
			If dbSeek(xFilial("SUS") + cCodProsp + cLojProsp) 
			
				Reclock("SUS",.F.)       
					Replace	SUS->US_NOME	With cNomePote
			  		Replace	SUS->US_DDD		With PADL(Alltrim(cDDDPoten),3,'0')
			 		Replace	SUS->US_TEL		With cTelePote 
			 		Replace	SUS->US_FAX		With cTeleFixo
			 		Replace	SUS->US_WHATSAP	With cTeleOutr
			 		Replace	SUS->US_SATIV	With cSegPoten
			 		Replace	SUS->US_REGINTE	With cRegiInte	 			 			 			 		
			 		Replace	SUS->US_EMAIL	With cEmailPot
			 		Replace SUS->US_CATEGOR With cCategor 
			 		Replace SUS->US_OPCCONT	With cOpcCont
			 		Replace SUS->US_EVENTRD	With cEventRD			 		  
	
				MsUnlock()	
			EndIf
		
		EndIf
		
		RestArea(aAreaSUS)                  

	    // Atualiza os dados do browse, caso tenha alterado telefones.                                                                            	    
	    If lChamaCRM
			fAtuaBrow(2,"N") 
		Else
			fAtuaBrow(1,"N") 		
		EndIf
	
		MsgInfo ( OemToAnsi ( "Cadastro do Potencial alterado com sucesso!" )  ) 	

	ElseIf fSegmen(cCodProsp,cLojProsp,"V",cSegPoten)
	
		 // Atualiza informações no cadastro do Potencial                    
		dbSelectArea("SUS")
		dbSetOrder(1)      
		If dbSeek(xFilial("SUS") + cCodProsp + cLojProsp) 
		
			Reclock("SUS",.F.)       
		 		Replace	SUS->US_SATIV	With cSegPoten
			MsUnlock()	
		EndIf 
		
	    // Atualiza os dados do browse, caso tenha alterado telefones.                                                                            	    
	    If lChamaCRM
			fAtuaBrow(2,"N") 
		Else
			fAtuaBrow(1,"N") 		
		EndIf
	
		MsgInfo ( OemToAnsi ( "Cadastro do Potencial alterado com sucesso!" )  ) 		
		
	EndIf
	
	fFechar()
	
Return ()            
               

// Adição do funcionamento das operações de filtragem 
Static Function fFiltraBw(cOrigem, nDo)
****************************************************************************************
* Filtra Consultor, Atendimento, Evolução, Cliente, Região, Produto, Categoria, Data.
*
****
	Local nUpd := 1

    If cOrigem == "CAT"  
		cPerg 	:= "FSCRMA30A" 
		nUpd	:= 1
	Else
		cPerg 	:= "FSCRMA30B"	
		nUpd	:= 2
	EndIf
	
	// Filtrar
	If nDo == 1
	    AjustaSX1(cOrigem)
		
		If !Pergunte(cPerg) 
			lFiltro := .F.
			Return()			
		EndIf       
		 
		lFiltro := .T.
		
		cFilAtEv  	:= MV_PAR01         // Código Atendimento CAT ou Evolução CRM
		cFilOpVe 	:= MV_PAR02         // Código Operador ou Vendedor
		cFilCod  	:= MV_PAR03
		cFilReg  	:= MV_PAR04
		cFilSeg		:= MV_PAR05	
		cFilCat  	:= MV_PAR06  
		nFilStat   	:= MV_PAR07 
		cFilDtDe 	:= DtoS(MV_PAR08)	// Data Atendimento CAT ou Agendamento CRM
		cFilDtAte 	:= DtoS(MV_PAR09)	// Data Atendimento CAT ou Agendamento CRM
			
	//Limpar Filtro
	Else

		lFiltro := .F.
		
		cFilAtEv  	:= Space(6)
		cFilOpVe 	:= Space(6)
		cFilCod  	:= Space(6)
		cFilReg  	:= Space(1)
		cFilSeg		:= Space(6)	
		cFilCat  	:= Space(2)  
		nFilStat   	:= 1 
		cFilDtDe 	:= Space(8)
		cFilDtAte 	:= Space(8)
			
	EndIf     
	
	// Atualiza Browse CAT/CRM   
	fAtuaBrow(nUpd,"S")    
	
	// Limpa Dados
	fExecBut(cOrigem,"C") 
    
Return()      


Static Function fAtuaBrow(nOpc,cReposiciona)
****************************************************************************************
* Atualiza os dados dos Browses.
*
****

	Default cReposiciona := "S"

	If nOpc == 1
		Consulta(1)
		oBrowCAT:SetArray(aBrowCAT)
		oBrowCAT:Refresh()
	Else
		Consulta(2)
		oBrowCRM:SetArray(aBrowCRM)   
		If Len(aBrowCRM) > 0
			If cReposiciona == "S"
		   		oBrowCRM:nAt := 1
			Else
				oBrowCRM:SetFocus()
			EndIf
			cMemoObs2:= If( Len(aBrowCRM)>0,aBrowCRM[oBrowCRM:nAt,09],'')  
			oMemoObs2:Refresh()	 
			If(aBrowCRM[oBrowCRM:nAt,17] == '005' .And. !lBloqCRM)
				oButProp:Enable()
			Else
				oButProp:Disable()
			EndIf
		Else
			oButProp:Disable()		
		EndIf            
		oBrowCRM:Refresh()	
	EndIf

Return()


Static Function fMontaSUS()
***************************************************************************************
*
*
*****

	Local aAreaSUS := GetArea()
	
	dbSelectArea("SUS")
	dbSetOrder(1)      
	If dbSeek(xFilial("SUS") + cCodProsp + cLojProsp)

		cNomePote := SUS->US_NOME	
		cDDDPoten := PADL(Alltrim(SUS->US_DDD),3,'0') 	// DDD
		cTelePote := SUS->US_TEL              			// CELULAR/WHATSAPP
		cTeleFixo := SUS->US_FAX              			// FIXO
		cTeleOutr := SUS->US_WHATSAP		  			// OUTRO
		cSegPoten := SUS->US_SATIV                      // PRODUTO        
	    cRegiInte := SUS->US_REGINTE   
	    cEmailPot := SUS->US_EMAIL  		
		cTrocaSub := SUS->US_CODSUBS
		cGrauPar  := SUS->US_GRAUPAR 
		cCategor  := SUS->US_CATEGOR
		cOpcCont  := SUS->US_OPCCONT					// 1=WHATSAPP | 2=LIGACAO | 3=NAO INFORMADO
		cEventRD  := SUS->US_EVENTRD		            // ULTIMO EVENTO RD
		
		lTrocaSub := .T.
		cDescSeg1 := AllTrim(Posicione("SX5",1,xFilial("SX5")+"T3"+cSegPoten,"X5_DESCRI"))
		cDesCateg := AllTrim(Posicione("SX5",1,xFilial("SX5")+'Z6'+cCategor,"X5_DESCRI"))		

	EndIf

	RestArea(aAreaSUS)
	
Return()   

      
Static Function fTrocaPot()  
***************************************************************************************
* Troca cliente potencial atual pelo novo escolhido.
*
*****
    Local aAreaAll	:= GetArea()
    Local cCodNovo	:= Left(cCodSubst ,6)
	Local cLojNovo	:= Right(cCodSubst,2)  
	Local cNomNovo	:= ""
    Local cCliCdNovo:= ""
	Local cCliLjNovo:= "" 
	Local cCliNmNovo:= ""	
	Local cQuery	:= "" 
	Local cHistNovo := ""  
	
	If Empty(cGrauPar)
		MsgBox("Grau de Parentesco é de preenchimento obrigatório.","Campo em Branco!","INFO")			
		Return(.F.)	
	EndIf
	
    // Verifica existência do Potencial
    dbSelectArea("SUS")
    dbSetOrder(1)                      
	If !dbSeek ( xFilial ( "SUS" ) + cCodNovo + cLojNovo)
		MsgBox("Potencial substituto não encontrado. Entre em contato com o(a) administrador(a) do Sistema.","Processo interrompido!","INFO")			
		Return(.F.)
	Else                 
	
		If SUS->US_EMLIGAC == '1'
			MsgBox("Cliente Substituto já se encontra Em Atendimento na CAT ou no CRM. Processo não poderá continuar.","Processo interrompido!","INFO")			
   			Return(.F.)		
		EndIf
		cNomNovo  := SUS->US_NOME
		cCliCdNovo:= SUS->US_CODCLI
		cCliLjNovo:= SUS->US_LOJACLI
		cCliNmNovo:= AllTrim(Posicione("SA1",1,xFilial("SA1")+cCliCdNovo+cCliLjNovo,"A1_NOME"))
		cHistNovo := "OBSERVACAO DO ATEND.PRESENCIAL CORRENTE:"+ CRLF+aBrowCRM[oBrowCRM:nAt,09]+CRLF+CRLF+;
		"OBSERVACAO DO CADASTRO DO NOVO CLIENTE:"+ CRLF+SUS->US_HISTOBS
	EndIf	

    // Tabela Principal da Evolução Comercial     	
	cQuery := " UPDATE "+RetSqlName("AD1")+" SET AD1_PROSPE='"+cCodNovo+"',AD1_LOJPRO='"+cLojNovo+"',	"
	cQuery += " 	AD1_NOMPOT='"+cNomNovo+"',AD1_CODCLI='"+cCliCdNovo+"',AD1_LOJCLI='"+cCliLjNovo+"', 	"	
	cQuery += " 	AD1_OBSPRO=CAST(('"+cHistNovo+"') as varbinary(8000)) 	"
 	cQuery += " WHERE D_E_L_E_T_ = '' AND AD1_NROPOR ='"+cCodiEvol+"' 									"

	TCSQLExec(cQuery)   
	
    // Tabela de Agendamento - Atendimento Presencial      	
	cQuery := " UPDATE "+RetSqlName("AD7")+" SET AD7_PROSPE='"+cCodNovo+"',AD7_LOJPRO='"+cLojNovo+"',	"
	cQuery += " 	AD7_CODCLI='"+cCliCdNovo+"',AD7_LOJA='"+cCliLjNovo+"' 				"	
 	cQuery += " WHERE D_E_L_E_T_ = '' AND AD7_NROPOR ='"+cCodiEvol+"'					"

	TCSQLExec(cQuery) 	
	
    // Tabela de Apontamento - Ocorrência Evolução     	
	cQuery := " UPDATE "+RetSqlName("AD5")+" SET AD5_PROSPE='"+cCodNovo+"',AD5_LOJPRO='"+cLojNovo+"',	"
	cQuery += " 	AD5_CODCLI='"+cCliCdNovo+"', AD5_LOJA='"+cCliLjNovo+"' 				"
 	cQuery += " WHERE D_E_L_E_T_ = '' AND AD5_NROPOR ='"+cCodiEvol+"'					"

	TCSQLExec(cQuery) 	
	
    // Tabela da Proposta
	cQuery := " UPDATE "+RetSqlName("SZI")+" SET ZI_CODPROS='"+cCodNovo+"',ZI_LOJAPRO='"+cLojNovo+"',ZI_NOMEPRO='"+cNomNovo+"',ZI_NOMEMEI='',	"
	cQuery += " 	ZI_DOCMEI='',ZI_ELEITOR='', ZI_DTNASCI='',ZI_NUMIR='',ZI_CPF='',ZI_EMAIL='',ZI_END='', ZI_FAX='',		"	
	cQuery += " 	ZI_TELEX='',ZI_NUM='',ZI_COMPLE='', ZI_BAIRRO='',ZI_CEP='',ZI_EST ='',ZI_TEL='',ZI_TEL2='',ZI_TEL3='',	"	
	cQuery += " 	ZI_NOMECLI='"+cCliNmNovo+"', ZI_CODCLIE='"+cCliCdNovo+"',ZI_LOJACLI='"+cCliLjNovo+"' 						"		
 	cQuery += " WHERE D_E_L_E_T_ = '' AND ZI_NUMERO ='"+cProposta+"' 															"

	TCSQLExec(cQuery) 		
     
	If !Empty(cCodTMK)
	    // Tabela Cabeçalho do Atendimento CAT
		cQuery := " UPDATE "+RetSqlName("SUC")+" SET UC_CHAVE='"+cCodSubst+"', UC_DESCPOT='"+cNomNovo+"',	"
		cQuery += " 		UC_CLIENTE='"+cCliCdNovo+"',UC_LOJA='"+cCliLjNovo+"' 			"		
	 	cQuery += " WHERE D_E_L_E_T_ = '' AND UC_CODIGO ='"+cCodTMK+"'						"
	
		TCSQLExec(cQuery)     
	
	    // Tabela Principal das Listas de Distribuição - CAT
		cQuery := " UPDATE "+RetSqlName("SU6")+" SET U6_CODENT='"+cCodSubst+"'			"		
	 	cQuery += " WHERE D_E_L_E_T_ = '' AND U6_CODLIG ='"+cCodTMK+"'	"
	
		TCSQLExec(cQuery) 
    EndIf
    
    RestArea(aAreaAll)

Return (.T.)         


Static Function fFechar()
***************************************************************************************
*
*
*****

	oDlgEvoluc:End()
                       
**
Return ( .T. )         
**    
                                


Static Function fSegmen(cCdCli,cLjCli,cFazer,cSegmen)
***********************************************************************
*  Consulta padrão.
*
*****
	
	Local cConteu	:= Space(800)     
	Local cQuery	:=""
	Local cRetorna	:= "" 
	Local lValida 	:= .F.
	Local nX		:= 1	
	Local oDlg     
	Local aAreaRam	:= GetArea()
	       
	Private oBrwRamo 
	Private aBrwRamo  := {}		
    
	//
	cQuery := " SELECT DISTINCT RAMO_ATIVIDADE, X5_DESCRI DESCRICAO, ORDEM
	cQuery += " FROM (	
    For nX:=1 To 10
		
		If nX > 1
			cQuery += " 	UNION ALL		"
		EndIf   
		cOrdem := AllTrim(Str(nX))

		cQuery += " SELECT DISTINCT A1_SATIV"+cOrdem+" RAMO_ATIVIDADE, X5_DESCRI, '"+cOrdem+"' ORDEM	" 
		cQuery += " FROM "+RetSqlName("SA1")+" SA1 LEFT JOIN "+RetSqlName("SX5")+" X5 ON X5.D_E_L_E_T_ = ''    "
		cQuery += " 	AND X5.X5_TABELA = 'T3' AND X5.X5_CHAVE = A1_SATIV"+cOrdem                                               
		cQuery += " 	JOIN "+RetSqlName("SUS")+" SUS ON US_CODCLI=A1_COD AND US_LOJACLI=A1_LOJA  "		
		cQuery += " WHERE SA1.D_E_L_E_T_='' AND SUS.D_E_L_E_T_=''		  			"
		cQuery += " 	AND US_COD+US_LOJA='"+cCdCli+cLjCli+"'				"
		cQuery += " 	AND A1_SATIV"+cOrdem+" <> ''  								"

	Next nX

	cQuery += " ) RAMO
	cQuery += " ORDER BY ORDEM
	            
	TCQuery cQuery Alias "RMATV" New
	    
	dbSelectArea("RMATV")
	dbGoTop()
	
	nX := 0
	While !Eof()	

		nX 	:= aScan(aBrwRamo, {|x| Alltrim(Upper(x[1])) == Alltrim(Upper(RMATV->RAMO_ATIVIDADE))} ) 

		If nX == 0
			aAdd(aBrwRamo,{AllTrim(RMATV->RAMO_ATIVIDADE),RMATV->DESCRICAO})
		EndIf   
		
		If AllTrim(cSegmen) == RMATV->RAMO_ATIVIDADE
			lValida := .T.		
		EndIf      
		
        RMATV->(dbSkip())
	EndDo
	    
	RMATV->(dbCloseArea())          
	
	If cFazer == "V" 
		If !lValida
			MsgBox("Segmento Inválido!","VLDSEGMENTO","ALERT")
		EndIf
 		Return(lValida)
    EndIf
    
	oDlg      := MSDialog():New( 050,200,500,700,"Segmento do Cliente Ativo" ,,,.F.,,,,,,.T.,,,.T. )
	oBrwRamo := TWBrowse():New( 20 , 05, 245/*L*/,175/*A*/,,{'Código','Descrição'},{30,130},oDlg,,,,,{||},,,,,,,.F.,,.T.,,.F.,,, )
    
	oBrwRamo:SetArray(aBrwRamo)
	oBrwRamo:bLine := {|| {	If(Empty(aBrwRamo),Space(030),aBrwRamo[oBrwRamo:nAt,01]),;
					   		If(Empty(aBrwRamo),Space(130),aBrwRamo[oBrwRamo:nAt,02])}}

	@ 005,005 Say '<Para Cliente Ativo, são disponibilizados apenas segmentos existentes no cadastro do Cliente.>' COLOR CLR_RED PIXEL OF oDlg  	

	oButton:=tButton():New(200,160,'&Ok',oDlg,{|| cRetorna:= aBrwRamo[oBrwRamo:nAt,01], oDlg:End()},30,12,,,,.T.)	
	oButton:=tButton():New(200,198,'&Segmentos' ,oDlg,{|| ConPad1(,,,"T3") },37,12,,,,.T.)		

	oBrwRamo:bLDblClick := {|| If(Empty(aBrwRamo),,cRetorna:= aBrwRamo[oBrwRamo:nAt,01]), oDlg:End()}
    		
	oDlg:Activate(,,,.T.) 

	RestArea(aAreaRam)

Return(cRetorna)
 
Static Function fReabrirP()
****************************************************************************************
* Reabrir proposta derrotada/cancelada/rejeitada | Catharina Oliveira - 24.04.2018
*
****	

    Local nPos		:= 1
	Local aReOpen	:= {}
	Local lOk		:= .F.
	Local cNJanela	:= "ROTINA DE REABERTURA DE PROPOSTAS PERDIDAS"	          
	Local cQuery 	:= "" 
	Local cLcPara	:= ""  
	Local CDescLc 	:= ""     
	Local dDtPara	:= CToD("")
	Local cHrPara	:= "  :  "  
	Local cLcPara	:= Space(03) 
				
    Private oDlgRep, oDtPara, oHrPara   
    Private oCliente,oLcPara, oDescLc   
    	 														    
    // Limpa browse
	fExecBut("CRM","C")	
	    
	// 
	cQuery	:= " SELECT AD1_NROPOR EVOLUCAO,ZI_NUMERO,ZI_ESTATUS,ZI_DESCSTA,ZI_CODCLIE,	" + CRLF         
	cQuery	+= " 	ZI_LOJACLI, ZI_CODPROS, ZI_LOJAPRO, US_NOME NOME, ZI_VENDEDO,		" + CRLF         
	cQuery	+= " 	ZI_UNIDADE, ZI_TIPOPRP, ZI_UNIDATU, ZI_CANCMOT		 		   		" + CRLF   	
	cQuery	+= " FROM "+RetSqlName("SZI")+" SZI 		   	   					   		" + CRLF         
	cQuery	+= " 	JOIN "+RetSqlName("AD1")+" AD1 ON AD1_PROPOS = ZI_NUMERO   	   		" + CRLF
	cQuery	+= " 	JOIN "+RetSqlName("SUS")+" SUS ON US_COD = AD1_PROSPE 	  	   		" + CRLF
	cQuery	+= " 	AND US_LOJA=AD1_LOJPRO			  	   		" + CRLF	
	cQuery	+= " WHERE	SZI.D_E_L_E_T_=''			 	   		" + CRLF         
	cQuery	+= " 	AND AD1.D_E_L_E_T_=''				  		" + CRLF         
	cQuery	+= " 	AND SUS.D_E_L_E_T_=''				  		" + CRLF 	
	cQuery	+= " 	AND SZI.ZI_ESTATUS IN ('W','X','H')  		" + CRLF         
	cQuery	+= " 	AND AD1_VEND ='"+cCodVend+"'	  	   		" + CRLF         
	cQuery	+= " ORDER BY AD1_NROPOR, ZI_DATAINC DESC 	   		" + CRLF 
	    
	TCQuery cQuery New Alias "REOPEN"
	IncProc()  
	IncProc()
		
	dbSelectArea("REOPEN")   
	dbGoTop()  
	
	While !Eof()  
            
			aAdd(aReOpen, {	REOPEN->EVOLUCAO		  		,;  //01 
							REOPEN->ZI_NUMERO 				,;  //02 							
							AllTrim(REOPEN->ZI_TIPOPRP)	 	,;  //03 
							AllTrim(REOPEN->ZI_UNIDADE)	  	,;  //04 
							AllTrim(REOPEN->ZI_UNIDATU)	 	,;  //05 
							AllTrim(REOPEN->ZI_CODPROS)	 	,;  //06 							
							AllTrim(REOPEN->ZI_LOJAPRO)	 	,;  //07 														
							Capital(AllTrim(REOPEN->NOME))	,;  //08  
							AllTrim(REOPEN->ZI_CODCLIE)	  	,;  //09 
							AllTrim(REOPEN->ZI_LOJACLI)	 	,;  //10 
							AllTrim(REOPEN->ZI_CANCMOT)	  	})  //11   
													
						
		dbSelectArea("REOPEN")
		dbSkip()
	
	Enddo  

	dbCloseArea("REOPEN")	
	                                                  
	DEFINE MSDIALOG oDlgRep TITLE OemToAnsi(cNJanela) From 0,0 To 430,675 Pixel   //1175	   
  
	  	oCliente := TWBrowse():New( 020, 005, 330,170/*L*/,,,,oDlgRep,,,,,,,/*oFont*/,,,,,.F.,,.T.,{ || .T. },.F.,,,) 
		oCliente:AddColumn( TcColumn():New('Evolução '	,{|| If(Empty(Len(aReOpen)),Space(20),aReOpen[oCliente:nAt,01])},"@!",,,"CENTER", 25,.F.,.F.,,{|| .F. },,.F., )) 
		oCliente:AddColumn( TcColumn():New('Proposta '	,{|| If(Empty(Len(aReOpen)),Space(40),aReOpen[oCliente:nAt,02])},"@!",,,"CENTER", 40,.F.,.F.,,{|| .F. },,.F., )) 
		oCliente:AddColumn( TcColumn():New('Tipo '		,{|| If(Empty(Len(aReOpen)),Space(10),aReOpen[oCliente:nAt,03])},"@!",,,"CENTER", 10,.F.,.F.,,{|| .F. },,.F., )) 		
		oCliente:AddColumn( TcColumn():New('Unidade  '	,{|| If(Empty(Len(aReOpen)),Space(20),aReOpen[oCliente:nAt,04])},"@!",,,"CENTER", 25,.F.,.F.,,{|| .F. },,.F., )) 
		oCliente:AddColumn( TcColumn():New('Unid.Atual'	,{|| If(Empty(Len(aReOpen)),Space(20),aReOpen[oCliente:nAt,05])},"",  ,,"CENTER", 25,.F.,.F.,,{|| .F. },,.F., )) 
		oCliente:AddColumn( TcColumn():New('Prospect'	,{|| If(Empty(Len(aReOpen)),Space(20),aReOpen[oCliente:nAt,06])},"",  ,,"CENTER", 20,.F.,.F.,,{|| .F. },,.F., )) 
		oCliente:AddColumn( TcColumn():New('Loja'	,{|| If(Empty(Len(aReOpen)),Space(10),aReOpen[oCliente:nAt,07])},"",  ,,"CENTER", 10,.F.,.F.,,{|| .F. },,.F., ))  
		oCliente:AddColumn( TcColumn():New('Nome Prospect',{|| If(Empty(Len(aReOpen)),Space(100),aReOpen[oCliente:nAt,08])},"",  ,,"LEFT", 100,.F.,.F.,,{|| .F. },,.F., )) 						
		oCliente:AddColumn( TcColumn():New('Cod.Clien.'	,{|| If(Empty(Len(aReOpen)),Space(20),aReOpen[oCliente:nAt,09])},"",  ,,"CENTER", 20,.F.,.F.,,{|| .F. },,.F., )) 		
		oCliente:AddColumn( TcColumn():New('Loja Clie.'	,{|| If(Empty(Len(aReOpen)),Space(10),aReOpen[oCliente:nAt,10])},"",  ,,"CENTER", 10,.F.,.F.,,{|| .F. },,.F., )) 	
		oCliente:AddColumn( TcColumn():New('Motivo Cancelamento',{|| If(Empty(Len(aReOpen)),Space(100),aReOpen[oCliente:nAt,11])},"@!",,,"LEFT", 100,.F.,.F.,,{|| .F. },,.F., )) 

		oCliente:SetArray(aReOpen)    
		oCliente:lAdjustColSize := .F.      		  
		oCliente:bLDblClick := {|| If(Empty(aReOpen),,nPos:= oCliente:nAt), lOk := .T., oDlgRep:End()}
		oCliente:Refresh() 

		@ 196,010 Say "Dt.Reunião:" COLOR CLR_BLACK Pixel Of oDlgRep	  
		@ 195,043 Get dDtPara Size 35,10 Picture PesqPict("AD1","AD1_DATA") Object oDtPara   	  
		@ 195,086 Get cHrPara Size 20,10 Picture "99:99" Object oHrPara 
		oHrPara:bChange := {|| cHrPara:=AllTrim(StrTran(cHrPara,".",":")) }
        
		@ 196,122 Say 'Local:' COLOR CLR_BLACK Pixel Of oDlgRep	  
		@ 195,143 Get cLcPara 	Size 15,10 F3 "SX5CAD" Picture "@!" Valid (cDescLc := AllTrim(Posicione("SX5",1,xFilial("SX5")+'CZ'+cLcPara,"X5_DESCRI")),oDescLc:Refresh(),ExistCpo('SX5','CZ'+cLcPara)) Object oLcPara 	 
		@ 195,179 Get cDescLc 	Size 58,10 When .F. Object oDescLc	
   
		oButton:=tButton():New(195,245,'&Reabrir' ,oDlgRep,{|| If(Empty(aReOpen),lOk := .F.,(nPos:= oCliente:nAt,lOk := .T.)),oDlgRep:End()},40,11,,,,.T.)
		oButton:=tButton():New(195,296,'&Cancelar',oDlgRep,{|| lOk := .F.,oDlgRep:End()},40,11,,,,.T.)  
                                                                                       
	Activate MsDialog oDlgRep Centered On Init .T.    
		  			 
	// Confirma reabertura?
    If lOk       	    
    	If MsgYesNo(OemToAnsi("A Proposta de Contrato de número "+aReOpen[nPos,02]+" e Evolução Comercial "+aReOpen[nPos,01]+" será reaberta. " +;
    						  " Deseja, realmente, prosseguir?"))	    
	
			cEvenCRM := "000007"		
			dDtAgenda:=	dDtPara
			cHoraAgen:=	cHrPara
			cLocAgen := cLcPara
			
			If fValida(2)			
		        Processa( {|| ExecReab(aReOpen,nPos) } ,"Reabrindo Proposta de Contrato","Aguarde... ... ...") 	    		    	
			Else  
		   		cEvenCRM := ""
		   		fAtualCRM()
			EndIf
	
		Else 
			lOk := .F.
		EndIf

    EndIf     		 	
	
Return() 


Static Function ExecReab(aReOpen,nPos)
****************************************************************************************
* Legenda de Cores  
*
****	

	Local cEvolAb := aReOpen[nPos,01]	
	Local cPropAb := aReOpen[nPos,02]    
	Local cStatPr := "" 
	Local cStagPr := ""    
	Local cQuery  := "" 
	Local nLinha  := 0
	Local aAreReab:= GetArea()

    dbSelectArea("SUS")
	dbSetOrder(1)   
	
	If !dbSeek( xFilial("SUS") + aReOpen[nPos,06] + aReOpen[nPos,07] )		
		MsgBox("Prospect não encontrado.","INFO") 
   		cEvenCRM := ""
   		fAtualCRM()
		RestArea(aAreReab)
		Return(.F.)	 
		
	ElseIf SUS->US_EMLIGAC == '1'
		MsgBox("Cliente já se encontra Em Atendimento na CAT ou no CRM. Processo não poderá continuar.","Processo interrompido!","INFO")			
   		cEvenCRM := ""
   		fAtualCRM()
		RestArea(aAreReab)		
		Return(.F.)			
	EndIf

    cStatPr := SUS->US_ESTATUS 

	// Coloca prospect como agendado e em ligação .   
   	U_fPotenEst(aReOpen[nPos,06] + aReOpen[nPos,07],"2","1","A",,,)

    dbSelectArea("AD1")
	dbSetOrder(1)   
	
	If !dbSeek( xFilial("AD1") + cEvolAb )		
	   
		MsgBox("Evolução não encontrada.","Não existe!","INFO")  
		
		// Volta o prospect ao status anterior, sem ligação.
		U_fPotenEst(aReOpen[nPos,06] + aReOpen[nPos,07],cStatPr,"2","A",,,)
   		cEvenCRM := ""
   		fAtualCRM()		
		RestArea(aAreReab)  		
  		Return(.F.)
  		
    EndIf

    cStagPr := AD1->AD1_STAGE

	If Reclock("AD1",.F.)

	   	Replace	AD1->AD1_PROPAB	With cPropAb   
	   	Replace	AD1->AD1_PROPOS	With ""	   	
		Replace	AD1->AD1_STATUS	With "1"
		Replace	AD1->AD1_STAGE	With "003"	
		Replace	AD1->AD1_DESCRI	With Left(AllTrim("PROPOSTA REABERTA - "+aReOpen[nPos,08]),50)			

		MsUnlock()
	EndIf		
	
	lFiltro := .T.
	
	cFilAtEv  	:= cEvolAb           
	cFilCod  	:= Space(6)
	cFilReg  	:= Space(1)
	cFilSeg		:= Space(6)	
	cFilCat  	:= Space(2)  
	nFilStat   	:= 3
	cFilDtDe 	:= Space(8)
	cFilDtAte 	:= DToS(CtoD(""))

	// Atualiza e limpa browse
	fAtuaBrow(2,"S")  

	nLinha := aScan(aBrowCRM, {|x| AllTrim(x[2]) == AllTrim(cEvolAb)} )   
	
	If nLinha > 0    
     
        oMsCalend:dDiaAtu := dDtAgenda
        oMsCalend:CtrlRefresh()
        

		fSalvCRM(0,nLinha) 
   				
	Else	
	    dbSelectArea("AD1")
		dbSetOrder(1)   
	
		If dbSeek( xFilial("AD1") + cEvolAb )		
			If Reclock("AD1",.F.)
	
			   	Replace	AD1->AD1_PROPAB	With ""   
			   	Replace	AD1->AD1_PROPOS	With cPropAb   	
				Replace	AD1->AD1_STATUS	With "9"
				Replace	AD1->AD1_STAGE	With cStagPr	
				Replace	AD1->AD1_DESCRI	With Left(AllTrim("PROPOSTA INSERIDA - "+aReOpen[nPos,02]),50)			
		
				MsUnlock()
			EndIf		
				
		EndIf
			
		// Volta o prospect ao status anterior, sem ligação.
		U_fPotenEst(aReOpen[nPos,06] + aReOpen[nPos,07],cStatPr,"2","A",,,) 	
		MsgBox("Evolução não encontrada.","Browse!","INFO")  		   
	  		
	EndIf
 	cEvenCRM := ""
	fAtualCRM()	
	RestArea(aAreReab)

Return()   

Static Function Legenda()
****************************************************************************************
* Legenda de Cores  
*
****	

	Local aLegenda 	:= {{"BR_AMARELO"  	, OemToAnsi("Sem Contato."		)},;
						{"BR_AZUL"  	, OemToAnsi("Redistribuído Não Contatado."	)},;
						{"BR_LARANJA"  	, OemToAnsi("Sem Agendamento."	)},;
						{"BR_VERDE" 	, OemToAnsi("Agendado."   		)},;					                 		                                                          		 
						{"BR_VERMELHO" 	, OemToAnsi("Não Compareceu." 	)}}    
														
	BrwLegenda("Lengenda - Atendimento CRM","Remoto e Presencial", aLegenda)											
	
Return()   

Static Function AjustaSX1(cOrigem)
*********************************************************************************
* Monta tela de parâmetros para filtro.
*
****
	Local aHelpPor1 := {} 
	Local aHelpPor2 := {} 
	Local aHelpPor3 := {} 
	Local aHelpPor4 := {} 
	Local aHelpPor5 := {}  
	Local aHelpPor6 := {} 	
	Local aHelpPor7 := {}  
	Local aHelpPor8 := {} 	
	Local aHelpPor9 := {} 	
		
	If cOrigem == "CAT"				
	 	aAdd( aHelpPor1, "Código do Atendimento CAT,")    
		aAdd( aHelpPor1, "quando houver.")
	 	aAdd( aHelpPor2, "Informe código do consultor ")    
		aAdd( aHelpPor2, "da central de atendimento.")	     	  
		aAdd( aHelpPor3, "Informe o código do Cliente")  	   	 		
		aAdd( aHelpPor3, "Potencial.")  	   	 				
		aAdd( aHelpPor4, "Forneça a região de interesse.")   
		aAdd( aHelpPor5, "Informe a categoria ")   
		aAdd( aHelpPor5, "a ser filtrada.") 		
		aAdd( aHelpPor6, "Informe o produto principal")   
		aAdd( aHelpPor6, "a ser filtrado.")   
		aAdd( aHelpPor7, "Informe o status do atendimento")   		
		aAdd( aHelpPor7, "a ser filtrado.")   				
		aAdd( aHelpPor8, "Informe uma data inicial de ") 		
		aAdd( aHelpPor8, "atendimento a ser filtrado.") 				
		aAdd( aHelpPor9, "Informe uma data final de") 			
		aAdd( aHelpPor9, "atendimento a ser filtrado.")   
		
		PutSx1(cPerg,"01","Atendimento?"			,"","","mv_ch1","C",06,0,0,"G","","","","","mv_par01","","","","","","","","","","","","","","","","",aHelpPor1,{},{})
		PutSx1(cPerg,"02","Consultor Atend. (CAT)?"	,"","","mv_ch2","C",06,0,0,"G","","SU7001","","","mv_par02","","","","","","","","","","","","","","","","",aHelpPor2,{},{})
		PutSx1(cPerg,"03","Cliente?"	  	 		,"","","mv_ch3","C",06,0,0,"G","","SUS","","","mv_par03","","","","","","","","","","","","","","","","",aHelpPor3,{},{})		
		PutSx1(cPerg,"04","Região Interesse?"	  	,"","","mv_ch4","C",01,0,0,"C","","","","","mv_par04","","","","","","","","","","","","","","","","",aHelpPor4,{},{})		
		PutSx1(cPerg,"05","Categoria?"	   			,"","","mv_ch5","C",02,0,0,"G","","Z6","","","mv_par05","","","","","","","","","","","","","","","","",aHelpPor5,{},{})									
		PutSx1(cPerg,"06","Produto?"	   			,"","","mv_ch6","C",06,0,0,"G","","T3","","","mv_par06","","","","","","","","","","","","","","","","",aHelpPor6,{},{})									
		PutSx1(cPerg,"07","O que aconteceu?" 		,"","","mv_ch7","C",01,0,0,"C","","","","","mv_par07","Sem Contato","","","","Redistribuído","","","Sem Agendamento","","","Todos","","","","","",aHelpPor7,{},{})			
		PutSx1(cPerg,"08","Dt.Atendimento De?"	   	,"","","mv_ch8","D",08,0,0,"G","","","","","mv_par08","","","","","","","","","","","","","","","","",aHelpPor8,{},{})
		PutSx1(cPerg,"09","Dt.Atendimento Até?"	   	,"","","mv_ch9","D",08,0,0,"G","","","","","mv_par09","","","","","","","","","","","","","","","","",aHelpPor9,{},{})
	Else
	 	aAdd( aHelpPor1, "Código da Evolução(Oportunidade)")    
		aAdd( aHelpPor1, "a ser filtrada.")
	 	aAdd( aHelpPor2, "Informe código do consultor ")    
		aAdd( aHelpPor2, "de vendas.")	     	  
		aAdd( aHelpPor3, "Informe o código do Cliente")  	   	 		
		aAdd( aHelpPor3, "Potencial.")  	   	 				
		aAdd( aHelpPor4, "Forneça a região de interesse.")   
		aAdd( aHelpPor5, "Informe a categoria ")   
		aAdd( aHelpPor5, "a ser filtrada.") 		
		aAdd( aHelpPor6, "Informe o produto principal")   
		aAdd( aHelpPor6, "a ser filtrado.") 
		aAdd( aHelpPor7, "Informe o status do agendamento")   		
		aAdd( aHelpPor7, "a ser filtrado.")  		  
		aAdd( aHelpPor8, "Informe uma data inicial de ") 		
		aAdd( aHelpPor8, "agendamento a ser filtrado.") 				
		aAdd( aHelpPor9, "Informe uma data final de ") 			
		aAdd( aHelpPor9, "agendamento a ser filtrado.") 	

		PutSx1(cPerg,"01","Evolução?"		  		,"","","mv_ch1","C",06,0,0,"G","","","","","mv_par01","","","","","","","","","","","","","","","","",aHelpPor1,{},{})
		PutSx1(cPerg,"02","Consultor Vendas.(CRM)?"	,"","","mv_ch2","C",06,0,0,"G","","SA3001","","","mv_par02","","","","","","","","","","","","","","","","",aHelpPor2,{},{})
		PutSx1(cPerg,"03","Cliente?"	  	 		,"","","mv_ch3","C",06,0,0,"G","","SUS","","","mv_par03","","","","","","","","","","","","","","","","",aHelpPor3,{},{})		
		PutSx1(cPerg,"04","Região Interesse?"	  	,"","","mv_ch4","C",01,0,0,"C","","","","","mv_par04","","","","","","","","","","","","","","","","",aHelpPor4,{},{})		
		PutSx1(cPerg,"05","Categoria?"	   			,"","","mv_ch5","C",02,0,0,"G","","Z6","","","mv_par05","","","","","","","","","","","","","","","","",aHelpPor5,{},{})									
		PutSx1(cPerg,"06","Produto?"	   			,"","","mv_ch6","C",06,0,0,"G","","T3","","","mv_par06","","","","","","","","","","","","","","","","",aHelpPor6,{},{})									
		PutSx1(cPerg,"07","O que aconteceu?" 		,"","","mv_ch7","C",01,0,0,"C","","","","","mv_par07","Agendado","","","","Não Compareceu","","","Todos","","","","","","","","",aHelpPor7,{},{})			
		PutSx1(cPerg,"08","Dt.Agendamento De?"	   	,"","","mv_ch8","D",08,0,0,"G","","","","","mv_par08","","","","","","","","","","","","","","","","",aHelpPor8,{},{})
		PutSx1(cPerg,"09","Dt.Agendamento Até?"	   	,"","","mv_ch9","D",08,0,0,"G","","","","","mv_par09","","","","","","","","","","","","","","","","",aHelpPor9,{},{})
		
	EndIf				                 

Return