#Include 'Protheus.ch'
#Include "rwmake.ch"
#Include "topconn.ch"
#Include "TOTVS.CH

/*
+-----------+------------+----------------+-------------------+-------+---------------+
| Programa  | FSCRMF03   | Desenvolvedor  | Catharina Oliveira| Data  | 06.11.2018    |       
+-----------+------------+----------------+-------------------+-------+---------------+
| Descricao | Função grava histórico da transferência de agenda ou substituição poten.|
+-----------+-------------------------------------------------------------------------+
|   USO     | CRM                                                                     |
+-----------+-------------------------------------------------------------------------+
| Modulos   | SIGACRM                                                                 |
+-----------+-------------------------------------------------------------------------+
|           ALTERACOES FEITAS DESDE A CRIACAO                            		      |
+----------+-----------+--------------------------------------------------------------+
|Autor     | Data      | Descricao                                       			  |
+----------+-----------+--------------------------------------------------------------+
|          |           |                                                              |
+----------+-----------+--------------------------------------------------------------+
*/

User Function fHistCRM(cOrgm,cCodMov,cLista,cConAtual,cToConsul, cCliAnt,cCliPos,cAgendAnt)
*********************************************************************************
* Registra histórico da movimentação - sequencial é por recno
* Movimentações abrangidas: Transferência de agenda e Substituição de prospect.
*
**** 
	Local aHisArea := GetArea()
	
	// Campos opcionais de acordo com a movimentação
    Default cCodMov		:= ""
    Default cLista		:= ""    
    Default cToConsul	:= ""     
    Default cCliPos		:= "" 
    Default cAgendAnt	:= ""        
    
	dbSelectArea("SZS")	
	If RecLock("SZS",.T.) 
 
		Replace ZS_FILIAL	With xFilial ("SZS")                
		Replace ZS_DEONDE	With cOrgm							// R= Remoto; P=Presencial
		Replace ZS_CODMOV	With cCodMov         		   		// CodLig (R) or Nropor (P)
		Replace ZS_LISTA	With cLista		    	 	   		// SU4 (R), caso não tenha CodLig
		Replace ZS_CONSANT 	With cConAtual      	 	   		// Vendedor/Operador Anterior
		Replace ZS_CONSPOS 	With cToConsul      	 	   		// Novo Vendedor/Operador
		Replace ZS_CLIANT 	With cCliAnt		 	 	  		// Cliente Anterior
		Replace ZS_CLIPOS 	With cCliPos		  	 			// Novo Cliente
		Replace ZS_USREXC 	With Alltrim(UsrRetName(__cUserID))	// Quem executou a mudança  
		Replace ZS_DTREXC 	With Date()		                    // Data da mudança
		Replace ZS_HREXEC 	With SubStr(Time(),1,5)             // Hora da mudança    
		Replace ZS_ALTAGEN	With cAgendAnt                      // Agendamento Anterior
												
		MsUnLock (  )   
		
	EndIf

	RestArea(aHisArea)
		
Return()