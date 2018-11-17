#Include 'Protheus.ch'
#Include "rwmake.ch"      
#Include "TopConn.ch"
#Include "TOTVS.CH"  
#INCLUDE "COLORS.CH"               	
#INCLUDE "TBICONN.CH"
#INCLUDE "msgraphi.ch" 
#INCLUDE "FONT.CH"
#INCLUDE "VKEY.CH"
#INCLUDE "PTMENU.CH"

#Define DS_MODALFRAME   128

/*                                                    
+-----------+------------+----------------+-------------------+-------+---------------+
| Programa  | FSCRMA32   | Desenvolvedor  |Catharina Oliveira | Data  | 30/10/2018    |
+-----------+------------+----------------+-------------------+-------+---------------+
| Descricao | Alteração nas agendas da Central de Atendimento e do CRM.               |
+-----------+-------------------------------------------------------------------------+
| Modulo    | SIGACRM - CRM e CALL CENTER                                             |
+-----------+-------------------------------------------------------------------------+
|                      ALTERACOES FEITAS DESDE A CRIACAO                   		      |
+----------+-----------+--------------------------------------------------------------+
| Autor    | Data      | Descricao                                       			  |
+----------+-----------+--------------------------------------------------------------+
|          |           |                                                              |
+----------+-----------+--------------------------------------------------------------+
*/                                                        	

User Function FSCRMA32(cPar01)
***************************************************************************************
*
*
*****
   
	Local aTrsfArea  := GetArea()
	
	Default cPar01   := ""

	Private oBrowAgn 
	Private aAgenda  := {}   
	Private cOrigem  := cPar01   	// CRM / CAT	
	Private cPesqui	 := Space(200)                     
	Private cToConsul:= Space(6)	
	Private cFilEven := Space(6)
	Private cFilOpVe := Space(6)
	Private cFilOrig := Space(2)
	Private cFilCli	 := Space(6)
	Private cFilLoj  := Space(2)                   
	Private nTotalReg:= 0
	Private nMarcaReg:= 0	
	Private cFilDtDe := ""
	Private cFilDtAte:= ""		
	Private cPerg 	 := ""	
	Private cCadastro:= "Transferir Agendamentos "+If(cOrigem=="CAT","- Atendimento Remoto","- Atendimento Presencial") 
		
	GohAgenda(cOrigem,1)  		
	
	RestArea(aTrsfArea)   
	
Return()
   

Static Function GohAgenda(cOrigem,nOpc)
***************************************************************************************
*
*
*****
	Local cQuery := ""
	
	aAgenda  := {}
	nTotalReg:= 0

	// Agenda Remota = Call Center	
	If cOrigem == "CAT"
	
		cQuery := " 	SELECT U7_COD,U7_NOME CONSULTOR, CASE WHEN U4_CODLIG<>'' THEN 'SEMAGEN'			" +CRLF   
	 	cQuery += " 		WHEN U4_CODLIG='' AND ISNULL(POTENCIAL,'')='' THEN 'SEMCONT' 	   			" +CRLF  
	 	cQuery += "  		ELSE 'REDISTR' END TIPOATEND, U4_CODLIG, US_COD, US_LOJA, US_NOME, US_TEL,	" +CRLF     
	 	cQuery += " 	 	X5_DESCRI,US_EMAIL, U4_LISTA,	 	  							  			" +CRLF 
		cQuery += "   		CASE WHEN U4_CODLIG='' THEN U4_DATA ELSE UC_PENDENT END DTATEND    			" +CRLF  			
		cQuery += " 	FROM "+RetSqlName("SU4")+" SU4										   	 		" +CRLF  
		cQuery += " 	JOIN "+RetSqlName("SU6")+" SU6 ON U4_LISTA=U6_LISTA AND SU6.D_E_L_E_T_='' 		" +CRLF 	
		cQuery += " 	JOIN "+RetSqlName("SU7")+" SU7 ON U4_OPERAD=U7_COD AND SU7.D_E_L_E_T_=''		" +CRLF    
		cQuery += " 	JOIN "+RetSqlName("SUS")+" SUS ON US_COD+US_LOJA=U6_CODENT AND SUS.D_E_L_E_T_=''" +CRLF   		
 		cQuery += " 	LEFT JOIN "+RetSqlName("SX5")+" SX5 ON X5_TABELA='SU' AND X5_CHAVE=US_ZORIGEX	" +CRLF  		
 		cQuery += " 		AND SX5.D_E_L_E_T_=''	   										" +CRLF  		 		
		cQuery += " 	LEFT JOIN (						 			 	  					" +CRLF 
		cQuery += "	 		SELECT UC_CHAVE	POTENCIAL			  		  			 		" +CRLF 
		cQuery += "  		FROM "+RetSqlName("SUC")+" UC 				  					" +CRLF 
		cQuery += "  		WHERE UC.D_E_L_E_T_=''		   				  		   			" +CRLF 
		cQuery += "  		GROUP BY UC_CHAVE 			 		   		   	 				" +CRLF   
		cQuery += " 		UNION						 									" +CRLF 
		cQuery += "			SELECT (AD1_PROSPE+AD1_LOJPRO) POTENCIAL  		 	 			" +CRLF 
		cQuery += "  	 	FROM "+RetSqlName("AD1")+" AD1				  		 			" +CRLF 
		cQuery += "  	 	WHERE AD1.D_E_L_E_T_=''		   			  		  				" +CRLF 
		cQuery += "  	 	GROUP BY (AD1_PROSPE+AD1_LOJPRO)		 		  		 		" +CRLF 		
		cQuery += "		) EXISTE ON POTENCIAL=U6_CODENT						  	  			" +CRLF 

		cQuery += " 	LEFT JOIN "+RetSqlName("SUC")+" SUC ON UC_CODIGO=U4_CODLIG 			" +CRLF   
		cQuery += " 		AND SUC.D_E_L_E_T_='' 									 		" +CRLF   
		
		cQuery += " 	WHERE SU4.D_E_L_E_T_=''												" +CRLF  
		cQuery += "			AND U4_OPERAD<>''												" +CRLF 
		cQuery += "	   		AND U4_STATUS='1'												" +CRLF 	 
	   	 	
		// Filtro Default: ao entrar na tela
		If nOpc == 1
		 	cQuery += " 		AND ( (SUC.D_E_L_E_T_ IS NULL )OR  							" +CRLF 
		 	cQuery += "    		(UC_DTENCER='' AND UC_STATUS='2' AND UC_PENDENT <>'') )		" +CRLF 		
		
		// Filtro Botão: executado pelo usuário
		Else
			If !Empty(cFilCli) .And. !Empty(cFilLoj)		
		 		cQuery += " 	AND US_COD='"+cFilCli+"'									" +CRLF  	
			 	cQuery += " 	AND US_LOJA='"+cFilLoj+"'									" +CRLF  			 			 		
		 	EndIf   	 	
			If !Empty(cFilOpVe)		 	
			 	cQuery += " 	AND U4_OPERAD='"+cFilOpVe+"'	   							" +CRLF  		 	
		 	EndIf 		 	
			If !Empty(cFilEven)
		 		cQuery += " 	AND U4_CODLIG='"+cFilEven+"'								" +CRLF  		 	
		 	EndIf 		 	
			If !Empty(cFilOrig)
			 	cQuery += " 	AND US_ZORIGEX='"+cFilOrig+"'								" +CRLF  		 	
		 	EndIf 		 	
			If !Empty(cFilDtAte)
			 	cQuery += " 	AND ( (SUC.D_E_L_E_T_ IS NULL AND (U4_DATA BETWEEN '"+cFilDtDe+"' AND '"+cFilDtAte+"'))OR 			 " +CRLF 
			 	cQuery += "  		(UC_DTENCER='' AND UC_STATUS='2' AND (UC_PENDENT BETWEEN '"+cFilDtDe+"' AND '"+cFilDtAte+"' )) ) " +CRLF 
		 	EndIf 		 	
		EndIf

		cQuery += "	 ORDER BY	CONSULTOR, CASE WHEN U4_CODLIG='' THEN U4_DATA ELSE UC_PENDENT END DESC, U4_CODLIG	 				 " +CRLF 	 
			 		
		TCQuery cQuery New Alias "AGND"
						
		dbSelectArea("AGND")  										
		AGND->(dbGoTop()) 
	
		While !AGND->(Eof())
   			nTotalReg++
			aAdd(aAgenda,{.F.,;                   	// 01
							AGND->TIPOATEND  	,;	// 02
		  					AGND->U4_CODLIG		,;  // 03									  					
							AGND->CONSULTOR		,;  // 04
							AGND->X5_DESCRI  	,;	// 05
		  					AGND->US_COD+AGND->US_LOJA,;  // 06
		  					AGND->US_NOME		,;  // 07
		  					AGND->US_TEL 		,;  // 08		  							  					
		  					AGND->US_EMAIL 		,;  // 09
		  					DtoC(StoD(AGND->DTATEND)),;	  // 10
		  					AGND->U4_LISTA})  		// 11
		
			AGND->(dbSkip())
		EndDo               
		
		AGND->(dbCloseArea())

	// Agenda Presencial = CRM	
	Else

	 	cQuery += "	SELECT DISTINCT A3_COD CODIGO,A3_NOME CONSULTOR, 						" +CRLF  	
	 	cQuery += "		CASE WHEN AD5_EVENTO='000010' THEN 'NAOCOMP' 						" +CRLF  	
	 	cQuery += "		   	 WHEN AD5_EVENTO='000009' THEN 'INSPROP'						" +CRLF  	
	 	cQuery += "			 WHEN AD5_EVENTO='000007' THEN 'NEGOAND'						" +CRLF  	
	 	cQuery += " 	ELSE 'AGENDAD' END TIPOATEND,AD7REC, AD7_DATA, AD7_LOCAL, AD7_HORA1," +CRLF  	
	 	cQuery += " 	AD1_NROPOR, AD1_VEND, A3_NOME, US_COD, US_LOJA, US_NOME, US_TEL,	" +CRLF  			  
	 	cQuery += " 	X5_DESCRI,US_EMAIL  					  							" +CRLF 	 	
	 	cQuery += " FROM "+RetSqlName("AD1")+" AD1 	   										" +CRLF  	
	 	cQuery += " 	JOIN "+RetSqlName("SUS")+" SUS ON US_COD= AD1_PROSPE  		 		" +CRLF 
	 	cQuery += " 		AND US_LOJA= AD1_LOJPRO AND SUS.D_E_L_E_T_='' 					" +CRLF 
	 	cQuery += " 	JOIN "+RetSqlName("SA3")+" SA3 ON A3_COD=AD1_VEND AND SA3.D_E_L_E_T_='' 		" +CRLF  																		  
 		cQuery += " 	LEFT JOIN "+RetSqlName("SX5")+" SX5 ON X5_TABELA='SU' AND X5_CHAVE=US_ZORIGEX 	"+CRLF  		
 		cQuery += " 		AND SX5.D_E_L_E_T_=''	  				" +CRLF  
	 	cQuery += " 	JOIN (	   									" +CRLF   		  		 	 	
	 	cQuery += " 		SELECT AD7_NROPOR AD7NROPOR, MAX(R_E_C_N_O_) AD7REC				" +CRLF  	 
	 	cQuery += " 		FROM  "+RetSqlName("AD7") 				
	 	cQuery += " 		WHERE D_E_L_E_T_=''	   					" +CRLF  		 			
	 	cQuery += " 		GROUP BY AD7_NROPOR	  					" +CRLF  		 		
	 	cQuery += " 	 ) AD7APONT ON AD1.AD1_NROPOR = AD7NROPOR	" +CRLF  		 																	  
	 	cQuery += " 	JOIN "+RetSqlName("AD7")+" AD7 ON AD7_NROPOR= AD7NROPOR AND AD7.D_E_L_E_T_='' 	" +CRLF 
	 	cQuery += " 	AND AD7.R_E_C_N_O_=AD7REC 					" +CRLF   	

	 	cQuery += " 	LEFT JOIN (	   		  		 	   									" +CRLF  	
	 	cQuery += " 		SELECT AD5_NROPOR AD5NROPOR, MAX(R_E_C_N_O_) AD5REC	  		 	" +CRLF  	
	 	cQuery += " 		FROM "+RetSqlName("AD5")+"   				 					" +CRLF  	
	 	cQuery += " 		WHERE D_E_L_E_T_=''			 									" +CRLF  	
	 	cQuery += " 		GROUP BY AD5_NROPOR	  		 		  							" +CRLF  	
	 	cQuery += " 	) AD5APONT ON AD7.AD7_NROPOR = AD5NROPOR						  	" +CRLF  			 
	 	cQuery += " 	LEFT JOIN "+RetSqlName("AD5")+" AD5 ON AD5.AD5_NROPOR=AD5NROPOR   	" +CRLF  	
	 	cQuery += " 		AND AD5.R_E_C_N_O_=AD5REC AND AD5.D_E_L_E_T_=''	 				" +CRLF  		 	 					
	 	cQuery += " 	WHERE AD1.D_E_L_E_T_=''  											" +CRLF  	
	 	cQuery += " 		AND AD1_STATUS='1'												" +CRLF  	
	 	cQuery += " 		AND AD1_STAGE  <= '005'  										" +CRLF  
		 cQuery += "  		AND (AD5_EVENTO IS NULL OR AD5_EVENTO IN ('000004','000005','000007','000009','000010'))	" +CRLF 	 	

		// Filtro Botão: executado pelo usuário
		If nOpc <> 1
			If !Empty(cFilCli) .And. !Empty(cFilLoj)		
			 	cQuery += " 	AND US_COD='"+cFilCli+"'									" +CRLF  	
			 	cQuery += " 	AND US_LOJA='"+cFilLoj+"'									" +CRLF  			 			 		
		 	EndIf 
		 	If !Empty(cFilOpVe)		 	
			 	cQuery += " 	AND AD1_VEND='"+cFilOpVe+"'	   								" +CRLF  		 	
		 	EndIf
		 	If !Empty(cFilEven)
			 	cQuery += " 	AND AD1_NROPOR='"+cFilEven+"'								" +CRLF  		 	
		 	EndIf
		 	If !Empty(cFilOrig)
			 	cQuery += " 	AND US_ZORIGEX='"+cFilOrig+"'								" +CRLF  		 	
		 	EndIf
		 	If !Empty(cFilDtAte)
		 		cQuery += " 	AND AD7_DATA BETWEEN '"+cFilDtDe+"' AND '"+cFilDtAte+"'		" +CRLF 	 	
			EndIf
		EndIf

		cQuery += "	 ORDER BY 	CONSULTOR, AD7_DATA DESC, AD1_NROPOR						" +CRLF 	 
	 												 	 	
		TCQuery cQuery New Alias "AGND"
						
		dbSelectArea("AGND")  										
		AGND->(dbGoTop())

		While !AGND->(Eof())
   			nTotalReg++	
			aAdd(aAgenda,{.F.,;                   	// 01
							AGND->TIPOATEND  	,;	// 02
		  					AGND->AD1_NROPOR	,;  // 03													
							AGND->CONSULTOR		,;  // 04
							AGND->X5_DESCRI  	,;	// 05
		  					AGND->US_COD+AGND->US_LOJA,;  // 06
		  					AGND->US_NOME		,;  // 07
		  					AGND->US_TEL 		,;  // 08
		  					AGND->US_EMAIL 		,;  // 09
		  					AGND->AD7_DATA		,;  // 10		  					
							AGND->AD7_LOCAL		,;  // 11
							AGND->AD7_HORA1  	,;	// 12	
					  		AGND->AD7REC		})	// 13	
		
			AGND->(dbSkip())
		EndDo               
		
		AGND->(dbCloseArea())

	EndIf					
 	
	// Carrega tela de entrada 	
    If nOpc == 1		
		Processa({|| ShowInfo()},"Aguarde...","Montando Tela...")  

	// Atualiza Browse
	Else
		oBrowAgn:SetArray(aAgenda)	
		oBrowAgn:Refresh()   
	EndIf	
		
Return()


Static Function ShowInfo()
*************************************************************************************
* Exibe agenda dos consultores em tela
*
***** 

	Local cToDesc	:= ""
	Local oSize       
	Local oVERD 	:= LoadBitmap( GetResources(), "BR_VERDE" 	) // 0      
	Local oAMAR 	:= LoadBitmap( GetResources(), "BR_AMARELO" ) // 1
	Local oVERM 	:= LoadBitmap( GetResources(), "BR_VERMELHO") // 2   
	Local oBRAN 	:= LoadBitmap( GetResources(), "BR_BRANCO" 	) // 4 
	Local oAZUL 	:= LoadBitmap( GetResources(), "BR_AZUL" 	) // 5
	Local oLARA 	:= LoadBitmap( GetResources(), "BR_LARANJA" ) // 6   
	Local oPINK 	:= LoadBitmap( GetResources(), "BR_PINK" 	) // 7
	Local oNoMark  	:= LoadBitmap( GetResources(), "LBNO" 		)       	
	Local oMarked  	:= LoadBitmap( GetResources(), "LBOK" 		) 
	Local nAjuste	:= If(cOrigem=="CRM",0,-12)	
	
	Private oDlgAgn     	
    Private aRot 	:= {}
	
	aAdd(aRot,{"Lengenda CRM"  ,{|| Legenda() } , OemToAnsi("Lengenda CRM"),"Legenda" })
	
	ProcRegua(4)  
 	IncProc() 
 	IncProc()
 				
	oSize:= FwDefSize():New( .T.)
	oSize:AddObject( "ENCHOICE", 100, 60, .T., .T. )
	oSize:lProp 	:= .T. 
	oSize:aMargins 	:= { 3, 3, 3, 3 }  
	oSize:Process() 

	DEFINE MSDIALOG oDlgAgn TITLE cCadastro From oSize:aWindSize[1],oSize:aWindSize[2]  TO oSize:aWindSize[3],oSize:aWindSize[4] Pixel
	
		oBrowAgn := TCBrowse():New( oSize:GetDimension("ENCHOICE","LININI")+20,oSize:GetDimension("ENCHOICE","COLINI"),;
			oSize:GetDimension("ENCHOICE","COLEND"),oSize:GetDimension("ENCHOICE","LINEND") - 42,,,,oDlgAgn,,,,,,,,,,,,.F.,,.T.,,.F.,,,) 

		oBrowAgn:AddColumn( TcColumn():New('Mk.',{|| If(Len(aAgenda)>0,If(aAgenda[oBrowAgn:nAt,01],oMarked,oNoMark),oNoMark) },"@!",,,"LEFT", 10,.T.,.F.,,{|| .F. },,.F., ))
		oBrowAgn:AddColumn( TcColumn():New('St'	,{|| If(Empty(aAgenda),oBRAN,If(aAgenda[oBrowAgn:nAt,02]=='SEMCONT',oAMAR,If(aAgenda[oBrowAgn:nAt,02]=='REDISTR',oAZUL,;
							If(aAgenda[oBrowAgn:nAt,02]=='SEMAGEN',oLARA,If(aAgenda[oBrowAgn:nAt,02]=='NEGOAND',oVERD,;
							If(aAgenda[oBrowAgn:nAt,02]=='NAOCOMP',oVERM,If(aAgenda[oBrowAgn:nAt,02]=='INSPROP',oPINK,oBRAN)))))))	},"@!",,,"LEFT", 10,.T.,.F.,,{|| .F. },,.F., ))  			   		
		oBrowAgn:AddColumn( TcColumn():New('Cod.Atend.'		,{|| If(Len(aAgenda)>0,aAgenda[oBrowAgn:nAt,03],Space(30))},"@!",,,"CENTER", 30,.F.,.F.,,{|| .F. },,.F., )) 
		oBrowAgn:AddColumn( TcColumn():New('Consultor' 		,{|| If(Len(aAgenda)>0,aAgenda[oBrowAgn:nAt,04],Space(130))},"@!",,,"LEFT", 130,.F.,.F.,,{|| .F. },,.F., )) 
		oBrowAgn:AddColumn( TcColumn():New('Origem' 		,{|| If(Len(aAgenda)>0,aAgenda[oBrowAgn:nAt,05],Space(80))},"@!",,,"LEFT", 80,.F.,.F.,,{|| .F. },,.F., )) 
		oBrowAgn:AddColumn( TcColumn():New('Codigo-Loja'	,{|| If(Len(aAgenda)>0,aAgenda[oBrowAgn:nAt,06],Space(50))},"@!",,,"CENTER", 50,.F.,.F.,,{|| .F. },,.F., )) 
		oBrowAgn:AddColumn( TcColumn():New('Nome Potencial ',{|| If(Len(aAgenda)>0,aAgenda[oBrowAgn:nAt,07],Space(130))},"@!",,,"LEFT", 130,.F.,.F.,,{|| .F. },,.F., )) 
		oBrowAgn:AddColumn( TcColumn():New('Celular/What '	,{|| If(Len(aAgenda)>0,aAgenda[oBrowAgn:nAt,08],Space(50))},"@!",,,"CENTER", 50,.F.,.F.,,{|| .F. },,.F., ))
		oBrowAgn:AddColumn( TcColumn():New('E-mail '   		,{|| If(Len(aAgenda)>0,aAgenda[oBrowAgn:nAt,09],Space(130))},"@!",,,"LEFT", 130,.F.,.F.,,{|| .F. },,.F., ))		
		oBrowAgn:AddColumn( TcColumn():New('Agendamento' 	,{|| If(Len(aAgenda)>0,aAgenda[oBrowAgn:nAt,10],Space(25))},"@!",,,"CENTER", 25,.F.,.F.,,{|| .F. },,.F., )) 
		If cOrigem == 'CRM'			
			oBrowAgn:AddColumn( TcColumn():New('Local '		,{|| If(Len(aAgenda)>0,aAgenda[oBrowAgn:nAt,11],Space(20))},"@!",,,"CENTER", 20,.F.,.F.,,{|| .F. },,.F., )) 
			oBrowAgn:AddColumn( TcColumn():New('Hora  '		,{|| If(Len(aAgenda)>0,aAgenda[oBrowAgn:nAt,12],Space(10))},"@!",,,"CENTER", 10,.F.,.F.,,{|| .F. },,.F., )) 
		EndIf
	
   		oBrowAgn:bLDblClick := {|| If(Len(aAgenda)>0,(aAgenda[oBrowAgn:nAt][1] := !aAgenda[oBrowAgn:nAt][1]),)} 				
		oBrowAgn:SetArray(aAgenda)	
		oBrowAgn:Refresh()      		
		
		If cOrigem == 'CRM'			
			oButAgn0:=TBtnBmp2():New(oSize:GetDimension("ENCHOICE","LININI")+37,010,030,030,'AgendaCrm' ,,,,{|| AltAgend(cOrigem) },oDlgAgn,"Altera Agendamento Posicionado",,.T. )  										
		EndIf
		
		@ oSize:GetDimension("ENCHOICE","LININI")+05,025+nAjuste Say "N° Total de Registros: "+AllTrim(Transform(nTotalReg,"@E 99,999")) COLOR CLR_RED Pixel Of oDlgAgn  				
		oButAgn1:=TButton():New(oSize:GetDimension("ENCHOICE","LININI")+02,100+nAjuste,"Filtros",oDlgAgn,{ || Filtrar(cOrigem) },41,13,,,,.T.,,,,)   			

		@ oSize:GetDimension("ENCHOICE","LININI")+05,152+nAjuste Say "Quantos registros marcar?" COLOR CLR_RED Pixel Of oDlgAgn  	
		@ oSize:GetDimension("ENCHOICE","LININI")+02,223+nAjuste Get nMarcaReg  Size 30,23 Valid (U_MarkBrow(.T.,@aAgenda,@oBrowAgn,nMarcaReg),.T.) Picture "9999"  Object oMarcaReg
		oMarcaReg:OGET:OGET:OGET:NHEIGHT:= 27

		@ oSize:GetDimension("ENCHOICE","LININI")+05,264+nAjuste Say "Transferir para Consultor:" COLOR CLR_RED Pixel Of oDlgAgn  	
		If cOrigem == 'CRM'		
			@ oSize:GetDimension("ENCHOICE","LININI")+02,333+nAjuste Get cToConsul  Size 30,23 F3 "SA3001" Valid (cToDesc:= AllTrim(Posicione("SA3",1,xFilial("SA3")+cToConsul,"A3_NOME")),.T.) Picture "@!"  Object oToConsult
		Else
			@ oSize:GetDimension("ENCHOICE","LININI")+02,333+nAjuste Get cToConsul  Size 30,23 F3 "SU7001" Valid (cToDesc:= AllTrim(Posicione("SU7",1,xFilial("SU7")+cToConsul,"U7_NOME")),.T.) Picture "@!"  Object oToConsult		
		EndIf
		@ oSize:GetDimension("ENCHOICE","LININI")+02,371+nAjuste Get cToDesc  Size 93,25 When .F. Picture "@!" Object oToDesc          
		oToConsult:OGET:OGET:OGET:NHEIGHT:= 27
		oToDesc:OGET:OGET:OGET:NHEIGHT	 := 27         
		
		oButAgn1:=TButton():New(oSize:GetDimension("ENCHOICE","LININI")+02,466+nAjuste,">>",oDlgAgn,{ || ;//U_MarkBrow(.T.,@aAgenda,@oBrowAgn,nMarcaReg);
			If( MsgBox("Deseja, realmente, transferir o(s) regitro(s) selecionado(s) para o consultor "+RTrim(cToDesc)+"?","Transferir Agenda","YESNO"),;
			(Transferir(cOrigem), U_MarkBrow(.T.,@aAgenda,@oBrowAgn,nMarcaReg),cToConsul:=Space(6),cToDesc:=""), );
			},10,13,,,,.T.,,,,)   
				
	Activate MSDIALOG oDlgAgn Center ON INIT EnchoiceBar(oDlgAgn,{|| aLERT("SAI"),oDlgAgn:End() },{|| oDlgAgn:End()},,@aRot)

 	IncProc() 
 	IncProc()
	
Return()     
        

Static Function Transferir(cOrigem)
*********************************************************************************
* 
*
****

    Local nX := 0     
    Local cConAtual := ""    // Consultor (Vendedor ou Operador)             
    Local cPropost 	:= ""   
    Local cRecAd7	:= ""
    Local cSeqAd5	:= "" 
    Local aAreaAd5	:= {}   
    
    Private aTransf := {}

    If Empty(cToConsul) .Or. Empty(aAgenda)
    	MsgBox("Consultor ou browse em branco. Revise os dados e tente novamente.","Campo em branco","ALERT")
    	Return()
    EndIf
    
    // Se Atendimento Remoto
    If cOrigem == "CAT"
    
	    For nX:= 1 To Len(aAgenda)
	        // Se selecionada:
			If aAgenda[nX][01]  			

				Begin Transaction
							
					dbSelectArea("SU4")     
					dbSetOrder(1)
					If dbSeek (xFilial("SU4")+aAgenda[nX][11])
	
						cConAtual := SU4->U4_OPERAD				
						If RecLock("SU4",.F.) 
							
							Replace U4_OPERAD With cToConsul						
							MsUnLock (  )   				
									
						EndIf					
					EndIf          
						
					dbSelectArea("SU6")
					dbSetOrder(1)
					If dbSeek (xFilial("SU6")+aAgenda[nX][11])
			
						If RecLock("SU6",.F.) 
							
							Replace U6_CODOPER With cToConsul						
							MsUnLock (  )   
							
						EndIf					         
					EndIf         
					
					If !Empty(aAgenda[nX][03])
					
						dbSelectArea("SUC")
						dbSetOrder(1)
						If dbSeek (xFilial("SUC")+aAgenda[nX][03])
								
							If RecLock("SUC",.F.) 
								
								Replace UC_OPERADO With cToConsul
								Replace UC_DECROPE With AllTrim(Posicione("SU7",1,xFilial("SU7")+cToConsul,"U7_NOME"))		  														
								MsUnLock (  )   
								
							EndIf        
					 	EndIf
					 	
						dbSelectArea("SUD")
						dbSetOrder(1)
						If dbSeek (xFilial("SUD")+aAgenda[nX][03])
							While SUD->UD_CODIGO == aAgenda[nX][03]							
								If RecLock("SUD",.F.) 
									
									Replace UD_OPERADO With cToConsul								
									MsUnLock (  )   
									
								EndIf
								SUD->(dbSkip())
							EndDo          
					 	EndIf
				 	
				 	EndIf			 	
	                // Salva histórico da alteração
					U_fHistCRM("R",aAgenda[nX][03],aAgenda[nX][11],cConAtual,cToConsul,aAgenda[nX][06],/**/)	
					
					dbCommitAll()
		
				End Transaction
					
			EndIf   			
	    
	    Next nX

    // Se Atendimento Presencial    
	Else
		aTransf := {}
	    For nX:= 1 To Len(aAgenda)
	        
	        // Se selecionada:
			If aAgenda[nX][01]  			
			    
				// Se não houve conflito de agendas (de origem e destino):
				If !ExistDupl(aAgenda[nX][03],cToConsul)
				
					Begin Transaction
					
						dbSelectArea("AD1")     
						dbSetOrder(1)
						If dbSeek (xFilial("AD1")+aAgenda[nX][03])
		
							cConAtual := AD1->AD1_VEND 
							cPropost  := If(Empty(AD1->AD1_PROPOS),AD1->AD1_PROPAB,AD1->AD1_PROPOS)
						
							If RecLock("AD1",.F.) 
								
								Replace AD1_VEND With cToConsul
								
								MsUnLock (  )   
								
							EndIf
							
						EndIf          
							
						dbSelectArea("AD5")
						dbSetOrder(2)
						If dbSeek (xFilial("AD5")+aAgenda[nX][03])
							While AD5->AD5_NROPOR == aAgenda[nX][03] 			
				
					 			cRecAd7 := fRecAD7(AD5->AD5_NROPOR,AD5->AD5_SEQUEN,AD5->AD5_VEND,DtoS(AD5->AD5_DATA))
						  		cSeqAd5 := fSeqAD5(cToConsul, DtoS(AD5->AD5_DATA))
							
								If RecLock("AD5",.F.) 
									
									Replace AD5_VEND 	With cToConsul
									Replace AD5_SEQUEN 	With cSeqAd5								
									MsUnLock (  )   
									
								EndIf 						
								
								// Existe sequência correspondente no AD7?!														
								If !Empty(cRecAd7)	
									aAreaAd5 := GetArea()
	
									dbSelectArea("AD7")
									dbGoTo(cRecAd7)   
									If RecLock("AD7",.F.) 
										
										Replace AD7_VEND 	With cToConsul
										Replace AD7_SEQAP 	With cSeqAd5																	
										MsUnLock (  )   
										
									EndIf             
									
									RestArea(aAreaAd5)															
								EndIf								
													
						  		AD5->(dbSkip())
							
					 		EndDo          
						EndIf         
						
						dbSelectArea("AD7")
						dbSetOrder(6)
						If dbSeek (xFilial("AD7")+aAgenda[nX][03])
							While AD7->AD7_NROPOR == aAgenda[nX][03]							
								If RecLock("AD7",.F.) 
									
									Replace AD7_VEND With cToConsul								
									MsUnLock (  )   
									
								EndIf
								AD7->(dbSkip())
							EndDo          
					 	EndIf 
					 	
					 	If !Empty(cPropost)
	
							dbSelectArea("SZI")
							dbSetOrder(1)
							If dbSeek (xFilial("SZI")+cPropost)												
									If RecLock("SZI",.F.) 
										
										Replace ZI_VENDEDO With cToConsul 
										Replace ZI_NOMEVEN With AllTrim(Posicione("SA3",1,xFilial("SA3")+cToConsul,"A3_NOME"))							
										
										MsUnLock (  )   
										
									EndIf
						 	EndIf			 	
						
						EndIf
									
						U_fHistCRM("P",aAgenda[nX][03],/**/,cConAtual,cToConsul,aAgenda[nX][06],/**/)
	
						dbCommitAll()
			
					End Transaction
	            
				EndIf // Se não houve conflito de agendas
	
			EndIf // Está marcado?  
			
	    Next nX
	
	EndIf
    
	GohAgenda(cOrigem,2)	

	// Houve conflito de agendas... 	
 	If Len(aTransf) > 0
		MsgBox("Transferência executada, porém, uma ou mais evoluções não puderam ser transferidas. O intervalo de horário da agenda de origem já está alocado para o representante de destino. Altere o agendamento e tente novamente.","Atenção!","INFO") 
		
		// Imprime listagem dos conflitos.
		ImpExcel(aTransf)
	Else
	    MsgBox("Agenda transferida com sucesso.","FIM","INFO")	
	EndIf
	
Return               


Static Function ExistDupl(cNropor,cToConsul)
****************************************************************************************
* 
*
**** 

	Local lRet		:= .F.
	Local cQuery  	:= ""
	Local aAreaAD5	:= GetArea()
	
	// Evolução de origem
	cQuery := " SELECT AD7_NROPOR, AD7_DATA DATA, AD7_HORA1 HORA,AD7_HORA2  "
	cQuery += " FROM "+RetSqlName("AD7")
	cQuery += " WHERE AD7_NROPOR = '" + cNropor + "'   	"
	cQuery += " 	AND D_E_L_E_T_=''				 	"	
	cQuery += " 	AND AD7_DTEXEC=''				 	"		
	cQuery += " ORDER BY AD7_DATA, AD7_HORA1			"

	TCQuery cQuery New Alias "SEQ3"

	dbSelectArea("SEQ3")
	dbGoTop()
	
	While !Eof()	
	
		dbSelectArea("AD7")
		dbSetOrder(1)
		If dbSeek( xFilial("AD7")+cToConsul+ SEQ3->DATA )
	
			While DToS(AD7->AD7_DATA) == SEQ3->DATA
				If Empty(AD7->AD7_DTEXEC) .And. ((SEQ3->HORA <= AD7->AD7_HORA2 .And. SEQ3->AD7_HORA2 >= AD7->AD7_HORA1) .Or.;
					 (SEQ3->HORA <= AD7->AD7_HORA2 .And. SEQ3->HORA >= AD7->AD7_HORA1) .Or. AllTrim(SEQ3->HORA) == AllTrim(AD7->AD7_HORA1))
					
		   			aAdd(aTransf,{SEQ3->AD7_NROPOR,DtoC(StoD(SEQ3->DATA)), SEQ3->HORA,SEQ3->AD7_HORA2,AD7->AD7_NROPOR,AD7->AD7_HORA1,AD7->AD7_HORA2})
					lRet := .T.
		            
				EndIf							
				
				AD7->(dbSkip())
			EndDo		
        EndIf 
		  		
		SEQ3->(dbSkip())
	EndDo

	SEQ3->(dbCloseArea())
	
	RestArea(aAreaAD5)


Return (lRet)  


Static Function fSeqAD5(cVend, cData)
****************************************************************************************
* Retorna a próxima numeração sequencial para a AD5 deste vendedor neste dia.
*
**** 

	Local cSeq		:= "01"
	Local cQuery  	:= ""
	Local aAreaAD5	:= GetArea()
	
	cQuery := " SELECT AD5_VEND, AD5_DATA, MAX(AD5_SEQUEN) ULTIMO  "
	cQuery += " FROM "+RetSqlName("AD5")
	cQuery += " WHERE AD5_VEND = '" + cVend + "'   	"
	cQuery += " 	AND AD5_DATA = '" + cData + "' 	"
	cQuery += " 	AND D_E_L_E_T_=''				"	
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


Static Function fRecAD7(cNRopor, cSeq,cVend, cData)
****************************************************************************************
* Retorna se existe uma sequência correspondente à seq do AD5 para a evolução passada.
*
**** 

	Local cRecAd7	:= ""
	Local cQuery  	:= ""
	Local aAreaAD7	:= GetArea()
	
	cQuery := " SELECT ISNULL(AD7.R_E_C_N_O_,'') RECAD7   								"
	cQuery += " FROM "+RetSqlName("AD5")+" AD5 LEFT JOIN "+RetSqlName("AD7")+" AD7 		"
	cQuery += " 	ON AD7_NROPOR=AD5_NROPOR AND AD5_DATA=AD7_DTEXEC AND AD7_SEQAP<>''	"
	cQuery += " 	AND AD7_SEQAP=AD5.AD5_SEQUEN AND AD7.D_E_L_E_T_=''					"	
	cQuery += " WHERE AD5.D_E_L_E_T_=''    			"
	cQuery += " 	AND AD5_NROPOR='" + cNRopor + "'"
	cQuery += " 	AND AD5_SEQUEN='" + cSeq  + "' 	"
	cQuery += " 	AND AD5_VEND = '" + cVend + "' 	"
	cQuery += " 	AND AD5_DATA = '" + cData + "' 	"

	TCQuery cQuery New Alias "SEQ2"

	dbSelectArea("SEQ2")
	dbGoTop()
	
	If !Eof()		
		cRecAd7 := SEQ2->RECAD7
	EndIf

	SEQ2->(dbCloseArea())

	RestArea(aAreaAD7)

Return (cRecAd7)


Static Function Filtrar(cOrigem)
*********************************************************************************
* Define qual pergunta chamar e atualiza browse
*
****
    
	If cOrigem == "CAT"

		cPerg := "FSCRMA32A"
	      			
	Else

		cPerg := "FSCRMA32B"
			
	EndIf     

    AjustaSX1(cOrigem)
	
	If !Pergunte(cPerg) 
		Return()			
	EndIf 			

	cFilEven  	:= MV_PAR01         // Código Atendimento CAT ou Evolução CRM
	cFilOpVe 	:= MV_PAR02         // Código Operador ou Vendedor
	cFilCli		:= MV_PAR03	
	cFilLoj  	:= MV_PAR04                                       
	cFilOrig  	:= MV_PAR05	
	cFilDtDe 	:= DtoS(MV_PAR06)	// Data Atendimento CAT ou Agendamento CRM
	cFilDtAte 	:= DtoS(MV_PAR07)	// Data Atendimento CAT ou Agendamento CRM	

	GohAgenda(cOrigem,2)	

Return                 


Static Function AltAgend(cOrigem)
*********************************************************************************
* Altera o agendamento do registro posicionado
*
****

    Local oDlg1    
    Local lOk	  := .F.                                                  
    Local cCodVnd := ""            
	Local cTitulo := "Alteração do Agendamento"                     
    Local cNropor := aAgenda[oBrowAgn:nAt,03]
    Local cVended := Left(aAgenda[oBrowAgn:nAt,04],28)
    Local dDataAg := StoD(aAgenda[oBrowAgn:nAt,10])
	Local cLocal  := aAgenda[oBrowAgn:nAt,11]    
	Local cHrAg01 := aAgenda[oBrowAgn:nAt,12]    
    
	dbSelectArea("AD7")
	dbSetOrder(6) 	
	If dbSeek (xFilial("AD7")+cNropor)
		cCodVnd := AD7->AD7_VEND         
	Else
	    Alert("Evolução não encontrada!") 
	    Return .F.
	EndIf	

	DEFINE MSDIALOG oDlg1 TITLE cTitulo FROM 100,100 TO 400,480 PIXEL Style DS_MODALFRAME

	@ 020,020 Say OemToAnsi("Evolução") SIZE 60,10 OF oDlg1 PIXEL
	@ 020,085 Say OemToAnsi(cNropor) SIZE 60,10 OF oDlg1 PIXEL
	@ 040,020 Say OemToAnsi("Consultor") SIZE 60,10 OF oDlg1 PIXEL
	@ 040,085 Say OemToAnsi(cVended) SIZE 100,10 OF oDlg1 PIXEL
	@ 060,020 Say OemToAnsi("Data") SIZE 50,10 OF oDlg1 PIXEL
	@ 058,085 Get dDataAg Size 35,10 Picture PesqPict("SUC","UC_DATA") Object oDataAg 
	@ 080,020 Say OemToAnsi("Hora") SIZE 50,16 OF oDlg1 PIXEL
	@ 078,085 Get cHrAg01 Size 20,10 Picture "99:99" Object oHora01     
	
	@ 110,030 Button "Confirma" Size 050,020 ACTION ( If( Valida(cCodVnd,DtoS(dDataAg),cHrAg01), (lOk:=.T.,oDlg1:End()),) ) PIXEL OF oDlg1
	@ 110,110 Button "Fechar" Size 050,020 ACTION (lOk:=.F.,oDlg1:End(), oDlg1) PIXEL OF oDlg1  

	Activate MsDialog oDlg1 CENTERED 
    
	If lOk
		Alert("Confirmou")
	EndIf

	GohAgenda(cOrigem,2)	

Return                      



Static Function Valida(cCodVnd,cDataAg,cHora)
*********************************************************************************
* Valida dados preenchidos
*
****

	Local lRet := .T.		
	Local cHoraFim := Ft320SomHr(cHora)
	
	If ( Empty(cDataAg) .Or. Empty(cHora) .Or. AllTrim(cHora)==":" )
	
		MsgBox("Os campos Data e Hora do Agendamento Presencial são de preenchimento obrigatório. Revise seus lançamentos e tente novamente.",;
				OemtoAnsi("Campo em Branco!"),"INFO")					
		lRet := .F.

	EndIf   		
	
	If lRet .And. (cHora > '18:30' .Or. cHora < '09:00')

		MsgBox("Favor agendar o cliente em horário comercial válido, compreendido entre 09h e 18:30h!","Atenção!","INFO")								
		lRet := .F.

	EndIf	   
	
	If lRet .And. (( cDataAg == DtoS(dDatabase) .And. cHora < Time() ) .Or. cDataAg < DtoS(dDatabase))
	
		MsgBox("Períodos passados não serão aceitos para agendamento. Revise seus lançamentos e tente novamente.",OemtoAnsi("Campo Inválido!"),"INFO")					
		lRet := .F.

	EndIf 						
	
	// Verifica duplicidade de agendamento e agendamento fora do horário permitido ( Entre 09:00 e 18:30 ).
	dbSelectArea("AD7")
	dbSetOrder(1)
	If dbSeek(xFilial("AD7")+cCodVnd+cDataAg)

		While lRet .And. AD7->AD7_DATA == StoD(dDtAgenda)
			If Empty(AD7->AD7_DTEXEC) .And. ((cHoraFim <= AD7->AD7_HORA2 .And. cHoraFim >= AD7->AD7_HORA1) .Or.;
				 (cHora <= AD7->AD7_HORA2 .And. cHora >= AD7->AD7_HORA1) .Or. AllTrim(cHora) == AllTrim(AD7->AD7_HORA1))
				
				MsgBox("O intervalo de horário informado já está alocado para este representante!","Atenção!","INFO")			
				lRet := .F.
	            Exit
			EndIf						
			
			dbSkip()
		EndDo 					
	EndIf
	
Return(lRet)
                 

Static Function ImpExcel(aTransf)
***************************************************************************************
*
*
*****

	Local aExcel	:= {"EVOL. A TRANSF.","DATA ","HORA1","HORA2","EVOL. EXISTENTE","HORA1 DEST", "HORA2 DEST"}   
	Local lCont		:= .F.   	      
	Local cTitulo	:= "AGENDAMENTOS NÃO TRANSFERIDOS - DATA E HORÁRIO JÁ OCUPADOS NA AGENDA DE DESTINO"

	While !lCont == .T.
		
		If !ApOleClient("MSExcel")
	
			MsgAlert("Microsoft Excel não instalado!")
	
		EndIf
		DlgToExcel({ {"ARRAY", cTitulo,  aExcel, aTransf} })
		
		If MsgYesNo(OemToAnsi("A informação foi apresentada com sucesso no Excel?"))		
			
			lCont := .T.

		EndIf		
    EndDo

Return()         
        

Static Function Legenda()
****************************************************************************************
* Legenda de Cores  
*
****	

	Local aLegenda 	:= {{"BR_AMARELO"  	, OemToAnsi("Sem contato"	  				)},;
						{"BR_AZUL"  	, OemToAnsi("Redistribuído não contatado"	)},;
						{"BR_LARANJA"  	, OemToAnsi("Sem agendamento presencial"	)},;						
						{"BR_BRANCO" 	, OemToAnsi("Primeiro agendamento"			)},;							
						{"BR_VERDE" 	, OemToAnsi("Em negociação - Reagendado" 	)},;					                 		                                                          		 
						{"BR_PINK" 		, OemToAnsi("Inserindo proposta"			)},;						
						{"BR_VERMELHO" 	, OemToAnsi("Não compareceu" 				)}}    
														
	BrwLegenda("Agenda CRM","Remoto e Presencial", aLegenda)											
	
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
		
	If cOrigem == "CAT"				
	 	aAdd( aHelpPor1, "Código do Atendimento CAT,")    
		aAdd( aHelpPor1, "quando houver.")
	 	aAdd( aHelpPor2, "Informe código do consultor ")    
		aAdd( aHelpPor2, "da central de atendimento.")	     	  
		aAdd( aHelpPor3, "Informe o código do Cliente")  	   	 		
		aAdd( aHelpPor3, "Potencial.")  	   	 				
		aAdd( aHelpPor4, "Loja do Cliente Potencial.")   
		aAdd( aHelpPor5, "Informe a origem do Cliente ")   
		aAdd( aHelpPor5, "a ser filtrada.") 		
		aAdd( aHelpPor6, "Informe data inicial do ")   
		aAdd( aHelpPor6, "atendimento a ser filtrada.")   
		aAdd( aHelpPor7, "Informe data final do ")   		
		aAdd( aHelpPor7, "atendimento a ser filtrada.")   				
		
		U_fPutSx1(cPerg,"01","Atendimento?"			,"","","mv_ch1","C",06,0,0,"G","","","","","mv_par01","","","","","","","","","","","","","","","","",aHelpPor1,{},{})
		U_fPutSx1(cPerg,"02","Consultor Atend. (CAT)?"	,"","","mv_ch2","C",06,0,0,"G","","SU7001","","","mv_par02","","","","","","","","","","","","","","","","",aHelpPor2,{},{})
		U_fPutSx1(cPerg,"03","Cliente?"	  	 		,"","","mv_ch3","C",06,0,0,"G","","SUS001","","","mv_par03","","","","","","","","","","","","","","","","",aHelpPor3,{},{})		
		U_fPutSx1(cPerg,"04","Loja?"	   				,"","","mv_ch4","C",02,0,0,"G","","","","","mv_par04","","","","","","","","","","","","","","","","",aHelpPor4,{},{})		
		U_fPutSx1(cPerg,"05","Origem?"		   			,"","","mv_ch5","C",02,0,0,"G","","SU","","","mv_par05","","","","","","","","","","","","","","","","",aHelpPor5,{},{})									
		U_fPutSx1(cPerg,"06","Dt.Atendimento De?"	   	,"","","mv_ch6","D",08,0,0,"G","","","","","mv_par06","","","","","","","","","","","","","","","","",aHelpPor6,{},{})
		U_fPutSx1(cPerg,"07","Dt.Atendimento Até?"	   	,"","","mv_ch7","D",08,0,0,"G","","","","","mv_par07","","","","","","","","","","","","","","","","",aHelpPor7,{},{})
	Else
	 	aAdd( aHelpPor1, "Código da Evolução(Oportunidade)")    
		aAdd( aHelpPor1, "a ser filtrada.")
	 	aAdd( aHelpPor2, "Informe código do consultor ")    
		aAdd( aHelpPor2, "de vendas.")	     	  
		aAdd( aHelpPor3, "Informe o código do Cliente")  	   	 		
		aAdd( aHelpPor3, "Potencial.")  	   	 				
		aAdd( aHelpPor4, "Loja do Cliente Potencial.")   
		aAdd( aHelpPor5, "Informe a origem do Cliente ")   
		aAdd( aHelpPor5, "a ser filtrada.") 		
		aAdd( aHelpPor6, "Informe data inicial do ")   
		aAdd( aHelpPor6, "atendimento a ser filtrada.")   
		aAdd( aHelpPor7, "Informe data final do ")   		
		aAdd( aHelpPor7, "atendimento a ser filtrada.")   				  

		U_fPutSx1(cPerg,"01","Evolução?"		  		,"","","mv_ch1","C",06,0,0,"G","","","","","mv_par01","","","","","","","","","","","","","","","","",aHelpPor1,{},{})
		U_fPutSx1(cPerg,"02","Consultor Vendas.(CRM)?"	,"","","mv_ch2","C",06,0,0,"G","","SA3001","","","mv_par02","","","","","","","","","","","","","","","","",aHelpPor2,{},{})
		U_fPutSx1(cPerg,"03","Cliente?"	  		 		,"","","mv_ch3","C",06,0,0,"G","","SUS001","","","mv_par03","","","","","","","","","","","","","","","","",aHelpPor3,{},{})		
		U_fPutSx1(cPerg,"04","Loja?"	  				,"","","mv_ch4","C",02,0,0,"C","","","","","mv_par04","","","","","","","","","","","","","","","","",aHelpPor4,{},{})		
		U_fPutSx1(cPerg,"05","Origem?"	   				,"","","mv_ch5","C",02,0,0,"G","","SU","","","mv_par05","","","","","","","","","","","","","","","","",aHelpPor5,{},{})									
		U_fPutSx1(cPerg,"06","Dt.Agendamento De?"	   	,"","","mv_ch6","D",08,0,0,"G","","","","","mv_par06","","","","","","","","","","","","","","","","",aHelpPor6,{},{})
		U_fPutSx1(cPerg,"07","Dt.Agendamento Até?"	   	,"","","mv_ch7","D",08,0,0,"G","","","","","mv_par07","","","","","","","","","","","","","","","","",aHelpPor7,{},{})
		
	EndIf				                 

Return