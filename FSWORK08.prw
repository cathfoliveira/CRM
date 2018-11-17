#Include 'Protheus.ch'
#Include "rwmake.ch"      
#Include "TopConn.ch"

/*
+-----------+------------+----------------+-------------------+-------+---------------+
| Programa  | FSWORK08   | Desenvolvedor  | Catharina Oliveira| Data  | 07.11.2017    |       
+-----------+------------+----------------+-------------------+-------+---------------+
| Descricao | Função para atualizar US_ESTATUS e Ligação do Potencial (SUS).          |
+-----------+-------------------------------------------------------------------------+
| Modulos   | TODOS                                                                   |
+-----------+-------------------------------------------------------------------------+
|           ALTERACOES FEITAS DESDE A CRIACAO                            		      |
+----------+-----------+--------------------------------------------------------------+
|Autor     | Data      | Descricao                                       			  |
+----------+-----------+--------------------------------------------------------------+
|          |           |                                                              |
+----------+-----------+--------------------------------------------------------------+
*/                                    


User Function fPotenEst(cChaveSUS, cUSEstat, cEmLigac,cTipoOper,cChaveSA1,cHistObs,dIntFutu)
****************************************************************************************
* Atualiza US_ESTATUS do Cliente Potencial cChave(US_COD+US_LOJA or US_CODCLI+US_LOJCLI):
*
*	US_ESTATUS do Cliente Potencial 
*	0=Cliente Inapto "Excluído", manipulado apenas pela rotina de Exclusão Inaptos. 
*	1=Sem Contato;
*	2=Agendado;
*	3=Atendido;
*	4=Cliente Ativo;
*	5=Cliente Inativo; 
*	6=Interesse Futuro;     
*	7=Em Proposta; 
*	8=Sem Agendamento; 
*	A=Substituído;
*	9=Inapto  
****

    Local aAreaUs	  := GetArea()   
    Local cRetorn	  := "" 
    Local cEstatTmp	  := ""
    Local cQuery  	  := ""
    
    Default cUSEstat  := ""
    Default cEmLigac  := "" 
    Default cChaveSUS := ""
    Default cChaveSA1 := ""    
    Default cHistObs  := ""  
    Default dIntFutu  := CtoD("")
    
    // Se parâmetro for por código de cliente, busca o potencial
    If AllTrim(cChaveSUS) == ""
    
		dbSelectArea("SUS")
		dbSetOrder(5)    
		If dbSeek(xFilial("SUS") + cChaveSA1)
  			cChaveSUS := SUS->US_COD+SUS->US_LOJA
		EndIf	    
    
    EndIf    

    // Verifica se está em aberto na CAT  //!!!!! 
	cQuery := " SELECT 'SEMAGENDAMENTO' SITUACAT	"	
	cQuery += " FROM SUC010 SUC	   	"                          
	cQuery += " WHERE SUC.D_E_L_E_T_=''	 	  		"				
	cQuery += " 	AND UC_CHAVE= '" +cChaveSUS+ "'	"		
	cQuery += " 	AND UC_STATUS='2'  				" 
	cQuery += " UNION ALL  				" 		                 
	cQuery += " SELECT 'SEMAGENDAMENTO' SITUACAT	"	
	cQuery += " FROM SUC130 SUC	   	"                           
	cQuery += " WHERE SUC.D_E_L_E_T_=''	 	  		"				
	cQuery += " 	AND UC_CHAVE= '" +cChaveSUS+ "'	"		
	cQuery += " 	AND UC_STATUS='2'  				"	

	TCQuery cQuery New Alias "SIT"
	
	dbSelectArea("SIT")
	dbGoTop()

	If !Eof()    
		cEstatTmp := "8"  			  					  		// 8=Cliente Sem Agendamento    
   		cEmLigac  := "1"		
	EndIf
		
	SIT->(dbCloseArea())   
    
	If Empty(cEstatTmp)
	    // Verifica se está em aberto por Evolução Comercial ou Em Proposta
		cQuery := " SELECT CASE WHEN AD1_STATUS ='1' THEN 'AGENDADO'   					"
		cQuery += " 	   ELSE 'EMPROPOSTA' END SITUACRM, ZI_ESTATUS 					"
		cQuery += " FROM AD1010 AD1 LEFT JOIN SZI010 SZI ON ZI_NUMERO=AD1_PROPOS        "
		cQuery += " 	AND SZI.D_E_L_E_T_=''  											"
		cQuery += " WHERE AD1.D_E_L_E_T_=''	  		                                    " 
		cQuery += " 	AND (AD1_PROSPE+AD1_LOJPRO)= '" +cChaveSUS+ "' 					"	
		cQuery += " 	AND ( AD1_STATUS='1' OR (AD1_STATUS='9'                         "
		cQuery += " 	AND ZI_ESTATUS NOT IN ('P','X','W','H')) )               		"
		cQuery += " UNION ALL  			   												"   
		cQuery += " SELECT CASE WHEN AD1_STATUS ='1' THEN 'AGENDADO'   					"
		cQuery += " 	   ELSE 'EMPROPOSTA' END SITUACRM, ZI_ESTATUS 					"
		cQuery += " FROM AD1130 AD1 LEFT JOIN SZI130 SZI ON ZI_NUMERO=AD1_PROPOS        "  
		cQuery += " 	AND SZI.D_E_L_E_T_=''  											"
		cQuery += " WHERE AD1.D_E_L_E_T_=''	  		                                    " 
		cQuery += " 	AND (AD1_PROSPE+AD1_LOJPRO)= '" +cChaveSUS+ "' 					"	
		cQuery += " 	AND ( AD1_STATUS='1' OR (AD1_STATUS='9'                         "
		cQuery += " 	AND ZI_ESTATUS NOT IN ('P','X','W','H')) )              		"

		cQuery += " ORDER BY SITUACRM	  												"
	
		TCQuery cQuery New Alias "SIT"
		
		dbSelectArea("SIT")
		dbGoTop()
	
		If !Eof()    
			If AllTrim(SIT->SITUACRM) == "AGENDADO"         	// 2=Agendado
		   		cEstatTmp := "2"                                             
		   		cEmLigac  := "1"		   		
		   	ElseIf AllTrim(SIT->ZI_ESTATUS) == "C"
		   		cEstatTmp := "7" 		   						// 7=Em Proposta       
		   		cEmLigac  := "2"
		   	Else
		   		cEstatTmp := "7" 		   						// 7=Em Proposta		   		
		   		cEmLigac  := "2"
			EndIf
		EndIf
			
		SIT->(dbCloseArea()) 	
	EndIf	

	// Verifica se o potencial é cliente ativo ou inativo	
	cQuery := " SELECT ZC_ESTATUS CONTRATO, US_CODCLI, US_COD, US_LOJA 		" + CRLF
	cQuery += " FROM SUS130 SUS JOIN SZC010 SZC ON ZC_LOJACLI=US_LOJACLI 	" + CRLF
	cQuery += " AND ZC_CODCLIE=US_CODCLI AND SZC.D_E_L_E_T_='' 		  		" + CRLF
	cQuery += " WHERE SUS.D_E_L_E_T_='' 			  						" + CRLF
	cQuery += " 	AND US_CODCLI<>'' 					 					" + CRLF
	cQuery += " 	AND (US_COD+US_LOJA) ='"+cChaveSUS+"' 	  				" + CRLF	   	
	cQuery += " UNION ALL  			   										"  		 //!!	
	cQuery += " SELECT ZC_ESTATUS CONTRATO, US_CODCLI, US_COD, US_LOJA		" + CRLF //!!
	cQuery += " FROM SUS130 SUS JOIN SZC130 SZC ON ZC_LOJACLI=US_LOJACLI 	" + CRLF
	cQuery += " AND ZC_CODCLIE=US_CODCLI AND SZC.D_E_L_E_T_='' 		   		" + CRLF
	cQuery += " WHERE SUS.D_E_L_E_T_='' 			  						" + CRLF
	cQuery += " 	AND US_CODCLI<>'' 					 					" + CRLF
	cQuery += " 	AND (US_COD+US_LOJA) ='"+cChaveSUS+"' 	  				" + CRLF
	
	cQuery += " ORDER BY ZC_ESTATUS 					 					" + CRLF 
	
	TCQuery cQuery New Alias "EHCLI"

	dbSelectArea("EHCLI")
	dbGoTop()
	
	If !Eof()		
		If AllTrim(EHCLI->CONTRATO) == "A"
	  		cRetorn:= "4"  										// 4=Cliente Ativo	  
		Else
			cRetorn:= "5"  										// 5=Cliente Inativo	  
		EndIf
	EndIf     
	
	EHCLI->(dbCloseArea())   
	
	If (Empty(cEstatTmp) .Or. cEstatTmp == '1') .And. cRetorn <> ""
  		cUSEstat := cRetorn   
  	ElseIf !Empty(cEstatTmp) .And. cRetorn == ""
   		cUSEstat := cEstatTmp   	
   		cRetorn  := cEstatTmp 
  	ElseIf !Empty(cEstatTmp)
   		cUSEstat := cEstatTmp  
   	ElseIf cRetorn <> ""   
   		cUSEstat := cRetorn
    ElseIf cUSEstat==""   		  
   		cUSEstat := "9"   										// 9=Cliente Inapto
   		cRetorn  := "9"  
   		cEmLigac := "2"   		
  	ElseIf cRetorn == ""  
  		cRetorn  := cUSEstat                              		// 3=Atendido; 6=Interesse Futuro ; 8=Sem Agendamento; 9=Inapto; A=Substituído   		    		
	EndIf
	
    // Atualiza Status do Potencial					
	dbSelectArea ( "SUS" )
	dbSetOrder ( 1 )
	If dbSeek(xFilial("SUS") + cChaveSUS)  
	
		If cTipoOper == "A" .And. cUSEstat <> "" 					
			If RecLock ("SUS",.F.)	            

				Replace US_ESTATUS With cUSEstat 

				If !Empty(cEmLigac)	 
			   		Replace US_EMLIGAC With cEmLigac			
				EndIf

				If !Empty(cHistObs)	 
			   		Replace US_HISTOBS With cHistObs			
				EndIf	

				If !Empty(DtoS(dIntFutu))	                   
			   		Replace US_INTFUTU With dIntFutu			
				EndIf							
				
				MsUnLock (  )
			EndIf   
		EndIf		

	Else
		cRetorn := ""
	EndIf     
    
	RestArea(aAreaUs)    

Return(cRetorn)