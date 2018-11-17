#Include 'Protheus.ch'
#Include "rwmake.ch"
#Include "topconn.ch"
#Include "TOTVS.CH

/*
+-----------+------------+----------------+-------------------+-------+---------------+
| Programa  | FSCRMF03   | Desenvolvedor  | Catharina Oliveira| Data  | 06.11.2018    |       
+-----------+------------+----------------+-------------------+-------+---------------+
| Descricao | Fun��o grava hist�rico da transfer�ncia de agenda ou substitui��o poten.|
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
* Registra hist�rico da movimenta��o - sequencial � por recno
* Movimenta��es abrangidas: Transfer�ncia de agenda e Substitui��o de prospect.
*
**** 
	Local aHisArea := GetArea()
	
	// Campos opcionais de acordo com a movimenta��o
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
		Replace ZS_LISTA	With cLista		    	 	   		// SU4 (R), caso n�o tenha CodLig
		Replace ZS_CONSANT 	With cConAtual      	 	   		// Vendedor/Operador Anterior
		Replace ZS_CONSPOS 	With cToConsul      	 	   		// Novo Vendedor/Operador
		Replace ZS_CLIANT 	With cCliAnt		 	 	  		// Cliente Anterior
		Replace ZS_CLIPOS 	With cCliPos		  	 			// Novo Cliente
		Replace ZS_USREXC 	With Alltrim(UsrRetName(__cUserID))	// Quem executou a mudan�a  
		Replace ZS_DTREXC 	With Date()		                    // Data da mudan�a
		Replace ZS_HREXEC 	With SubStr(Time(),1,5)             // Hora da mudan�a    
		Replace ZS_ALTAGEN	With cAgendAnt                      // Agendamento Anterior
												
		MsUnLock (  )   
		
	EndIf

	RestArea(aHisArea)
		
Return()