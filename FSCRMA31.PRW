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
   

#DEFINE  CLRF  CHR ( 13 ) + CHR ( 10 )

#DEFINE DS_MODALFRAME   128

/*                                             
+-----------+------------+----------------+-------------------+-------+---------------+
| Programa  | FSCRMA31   | Desenvolvedora |Catharina Oliveira | Data  | 04/10/2017    |
+-----------+------------+----------------+-------------------+-------+---------------+
| Descricao | Cadastro Cliente Potencial - CRM                                        |
+-----------+-------------------------------------------------------------------------+
| Modulo    | SIGACRM                                                                 |
+-----------+-------------------------------------------------------------------------+
|           ALTERACOES FEITAS DESDE A CRIACAO                            		      |
+----------+-----------+--------------------------------------------------------------+
|Autor     | Data      | Descricao                                       			  |
+----------+-----------+--------------------------------------------------------------+
|          |           |                                                              |
+----------+-----------+--------------------------------------------------------------+

*/

User Function FSCRMA31(cPar01)
***************************************************************************************
*
*
*****
	
	Local cAlias 		:= "SUS"      
	Local aCores 		:= {}	 
	Local aAreaCRM		:= GetArea()
	 
	Default cPar01		:= ""
	
	Private aRotina		:= {} 
	Private aBrowSUS	:= {} 	
	Private oBrowSUS	                
	Private cTitulo		:= "Clientes Potenciais"
	Private cFiltro		:= ""   
	Private cPesqui		:= Space(200)
	Private cOpcao		:= '1'	
	Private cOrigem 	:= cPar01   // CRM / CAT
	Private dDtAgSUS	:= CtoD("")
	Private cHoraSUS    := "  :  "
	Private cLocaSUS	:= Space(3)  
	
	If !(cOrigem $ "CAT_CRM")
   		cOrigem := "NAT"
	EndIF
	 		
	If !FunName() == "FSCRMA31" 

		// Não pode ser 0='Inaptos deletados do banco', nem 9=Inaptos		
		aAdd(aRotina,{"Visualizar"	,{|| U_fAtuSUS(cOrigem,2) },"Visualizar" })	
		aAdd(aRotina,{"Incluir"		,{|| U_fAtuSUS(cOrigem,3) },"Incluir" }) 
		aAdd(aRotina,{"Agendamento"	,{|| U_fAgendaPot()},"Agendamento" })				
		aAdd(aRotina,{"Legenda"		,{|| U_LegenSUS() },"Legenda" }) 						
		aAdd(aRotina,{"Nova Loja"	,{|| U_fAtuSUS(cOrigem,6) },"Nova Loja" })			
	    	          	        
	Else 
		// Não visualiza 9='Inaptos deletados do banco'
		aAdd(aRotina,{"Visualizar"	,{|| U_fAtuSUS(cOrigem,2) },"Visualizar" })	
		aAdd(aRotina,{"Incluir"		,{|| U_fAtuSUS(cOrigem,3) },"Incluir" }) 
		aAdd(aRotina,{"Alterar"		,{|| U_fAtuSUS(cOrigem,4) },"Alterar" })	
		aAdd(aRotina,{"Legenda"		,{|| U_LegenSUS() },"Legenda" }) 							
		aAdd(aRotina,{"Nova Loja"	,{|| U_fAtuSUS(cOrigem,6) },"Nova Loja" })	
   	           			    
	EndIf


   	Private oVERD := LoadBitmap( GetResources(), "BR_VERDE" 	) 
	Private oAMAR := LoadBitmap( GetResources(), "BR_AMARELO" 	) 
	Private oVERM := LoadBitmap( GetResources(), "BR_VERMELHO"	) 	
	Private oLARA := LoadBitmap( GetResources(), "BR_LARANJA" 	) 		
	Private oAZUL := LoadBitmap( GetResources(), "BR_AZUL" 		) 		
   	Private oBRAN := LoadBitmap( GetResources(), "BR_BRANCO" 	) 
	Private oPINK := LoadBitmap( GetResources(), "BR_PINK" 		) 
	Private oMARR := LoadBitmap( GetResources(), "BR_MARROM"	) 	
	Private oPRET := LoadBitmap( GetResources(), "BR_PRETO" 	) 		
	Private oCANC := LoadBitmap( GetResources(), "BR_CANCEL"	) 	
	Private oCINZ := LoadBitmap( GetResources(), "BR_VIOLETA"	) 	
										
	dbSelectArea(cAlias)
	dbSetOrder(1)  
	
	TelaSUS()
	
	RestArea(aAreaCRM)

Return()   


Static Function TelaSUS()
*********************************************************************************
* Monta Tela de Títulos para Financeiro e Loja(Centro Comercial)
*
****

	Local lOk       := .F.     
	Local oSize		
	Local aOpcao 	:= {"1=Nome Cliente","2=Telefone","3=CPF/CNPJ","4=Código"} 
	Local aAreaTl	:= GetArea()

	Private cCadastro	:= 'CADASTRO DE CLIENTES POTENCIAIS'

	oSize:= FwDefSize():New( .T.)
	oSize:AddObject( "ENCHOICE", 100, 60, .T., .T. )
	oSize:lProp 	:= .T. 
	oSize:aMargins 	:= { 3, 3, 3, 3 }  
	oSize:Process() 

	DEFINE MSDIALOG oDlg TITLE cCadastro From oSize:aWindSize[1],oSize:aWindSize[2]  TO oSize:aWindSize[3],oSize:aWindSize[4] Pixel
	
		oBrowSUS := TCBrowse():New( oSize:GetDimension("ENCHOICE","LININI")+20,oSize:GetDimension("ENCHOICE","COLINI"),;
			oSize:GetDimension("ENCHOICE","COLEND"),oSize:GetDimension("ENCHOICE","LINEND") - 42,,,,oDlg,,,,,,,/**/oFont,,,,,.F.,,.T.,,.F.,,,) 

		oBrowSUS:AddColumn( TcColumn():New('St.'	,{|| If(aBrowSUS[oBrowSUS:nAt,01]=='1',oVERD,If(aBrowSUS[oBrowSUS:nAt,01]=='2',oAMAR,;
							If(aBrowSUS[oBrowSUS:nAt,01]=='3',oVERM,If(aBrowSUS[oBrowSUS:nAt,01]=='4',oAZUL,If(aBrowSUS[oBrowSUS:nAt,01]=='5',oLARA,;
							If(aBrowSUS[oBrowSUS:nAt,01]=='6',oBRAN,If(aBrowSUS[oBrowSUS:nAt,01]=='7',oPINK,If(aBrowSUS[oBrowSUS:nAt,01]=='8',oMARR,;
							If(aBrowSUS[oBrowSUS:nAt,01]=='A',oPRET,If(aBrowSUS[oBrowSUS:nAt,01]=='B',oCINZ,oCANC))))))))))	},"@!",,,"LEFT", 08,.T.,.F.,,{|| .F. },,.F., ))  			   		
		oBrowSUS:AddColumn( TcColumn():New('Codigo   '	,{|| aBrowSUS[oBrowSUS:nAt,02]},"999999",,,"CENTER", 20,.F.,.F.,,{|| .F. },,.F., )) 
		oBrowSUS:AddColumn( TcColumn():New('Loja  '		,{|| aBrowSUS[oBrowSUS:nAt,03]},"99",,,"CENTER", 10,.F.,.F.,,{|| .F. },,.F., )) 
		oBrowSUS:AddColumn( TcColumn():New('Nome ' 		,{|| aBrowSUS[oBrowSUS:nAt,04]},"@!",,,"LEFT", 90,.F.,.F.,,{|| .F. },,.F., )) 
		oBrowSUS:AddColumn( TcColumn():New('Endereço  '	,{|| aBrowSUS[oBrowSUS:nAt,05]},"@!",,,"LEFT", 90,.F.,.F.,,{|| .F. },,.F., )) 
		oBrowSUS:AddColumn( TcColumn():New('Município '	,{|| aBrowSUS[oBrowSUS:nAt,06]},"@!",,,"CENTER", 45,.F.,.F.,,{|| .F. },,.F., )) 
		oBrowSUS:AddColumn( TcColumn():New('UF'			,{|| aBrowSUS[oBrowSUS:nAt,07]},"@!",,,"CENTER", 15,.F.,.F.,,{|| .F. },,.F.,))
		oBrowSUS:AddColumn( TcColumn():New('DDD   '		,{|| aBrowSUS[oBrowSUS:nAt,08]},"@!",,,"CENTER", 10,.F.,.F.,,{|| .F. },,.F.,))
		oBrowSUS:AddColumn( TcColumn():New('Celular/What '	,{|| aBrowSUS[oBrowSUS:nAt,09]},"@!",,,"CENTER", 25,.F.,.F.,,{|| .F. },,.F., ))
		oBrowSUS:AddColumn( TcColumn():New('E-mail '	,{|| aBrowSUS[oBrowSUS:nAt,10]},"@!",,,"LEFT", 70,.F.,.F.,,{|| .F. },,.F., ))		
		oBrowSUS:AddColumn( TcColumn():New('CPF/CNPJ '	,{|| aBrowSUS[oBrowSUS:nAt,11]},"@!",,,"CENTER", 45,.F.,.F.,,{|| .F. },,.F., ))
		oBrowSUS:AddColumn( TcColumn():New('Dt.Cadastro',{|| aBrowSUS[oBrowSUS:nAt,12]},"@!",,,"CENTER", 30,.F.,.F.,,{|| .F. },,.F.,))  
		oBrowSUS:AddColumn( TcColumn():New('Origem  '	,{|| aBrowSUS[oBrowSUS:nAt,13]},"@!",,,"CENTER", 15,.F.,.F.,,{|| .F. },,.F., )) 
		oBrowSUS:AddColumn( TcColumn():New('Local Cad. ',{|| aBrowSUS[oBrowSUS:nAt,14]},"@!",,,"CENTER", 15,.F.,.F.,,{|| .F. },,.F., )) 
		oBrowSUS:AddColumn( TcColumn():New('Nome Cadas.',{|| aBrowSUS[oBrowSUS:nAt,15]},"@!",,,"LEFT", 50,.F.,.F.,,{|| .F. },,.F.,)) 
		oBrowSUS:AddColumn( TcColumn():New('Cod.Cli.  '	,{|| aBrowSUS[oBrowSUS:nAt,21]},"999999",,,"CENTER", 20,.F.,.F.,,{|| .F. },,.F., )) 
		oBrowSUS:AddColumn( TcColumn():New('Loja Cli. '	,{|| aBrowSUS[oBrowSUS:nAt,22]},"99",,,"CENTER", 10,.F.,.F.,,{|| .F. },,.F., )) 
		oBrowSUS:AddColumn( TcColumn():New('Segmento '	,{|| aBrowSUS[oBrowSUS:nAt,19]},"@!",,,"CENTER", 15,.F.,.F.,,{|| .F. },,.F., )) 
		oBrowSUS:AddColumn( TcColumn():New('Observação ',{|| aBrowSUS[oBrowSUS:nAt,23]},"@!",,,"LEFT",50,.F.,.F.,,{|| .F. },,.F., ))		
		
		// Executa SQL
		SeleDados()
		
		oBrowSUS:SetArray(aBrowSUS)
	
		oBrowSUS:lAdjustColSize := .F.   
	
		oBrowSUS:Refresh()   		

		@ oSize:GetDimension("ENCHOICE","LININI")+06,005 Say 'Pesquisa: ' COLOR CLR_RED PIXEL OF oDlg  
		@ oSize:GetDimension("ENCHOICE","LININI")+03,040 Get cPesqui Size 75,11 Picture "@!" Pixel   
		@ oSize:GetDimension("ENCHOICE","LININI")+06,135 Say 'Utilize de informações completas ou parciais do Nome, CPF/CNPJ, Telefone ou Código para pesquisar o Cliente.' COLOR CLR_RED PIXEL OF oDlg  	
		
		oButton:=TButton():New(oSize:GetDimension("ENCHOICE","LININI")+03,115,">>",oDlg,{ || AtualBrw(cOpcao),oBrowSUS:nAt:=1,oBrowSUS:SetFocus(),oBrowSUS:Refresh() },10,13,,,,.T.,,,,)
													
	ACTIVATE MSDIALOG oDlg ON INIT (EnchoiceBar(oDlg,{||lOk:=.T.,oDlg:End()},{||oDlg:End()},,@aRotina))

	RestArea(aAreaTl)
	
Return(.T.)               	
 

Static Function SeleDados(cOpc)
*********************************************************************************
* Monta Browse
*
****

	Local cQuery := ""
	Local cPsqui := ""
   
	cPsqui := AllTrim(cPesqui)     
	
	cQuery := " SELECT US_ESTATUS, US_COD, US_LOJA, US_NOME, US_END, US_MUN,US_EST, US_DDD, " 
	cQuery += " 	US_TEL, US_EMAIL, US_CGC, US_ZDATACA, US_ZORIGEX,US_ZORIGEM,US_NOMCAD,	" 	
	cQuery += " 	US_FILIAL, US_FAX, US_WHATSAP, US_SATIV, US_REGINTE,US_CATEGOR,US_ZOBS,	" 	
	cQuery += " 	US_CODCLI, US_LOJACLI,US_EMLIGAC,US_OPCCONT,US_EVENTRD,					"  
	cQuery += "		CAST(CAST(US_HISTOBS AS Varbinary(8000)) as Varchar(8000)) US_HISTOBS	" 			
	cQuery += " FROM "+RetSqlName("SUS")+" SUS	" 		
	cQuery += " WHERE D_E_L_E_T_=''	" 	 
	If !FunName() == "FSCRMA31" 			

	    If Empty(cPsqui)
		    cQuery += " AND US_ESTATUS IN ('')	" 	
		Else
			cQuery += " AND (US_NOME LIKE '%"+cPsqui+"%' OR US_TEL LIKE '%"+cPsqui+"%' OR 	" 					 
			cQuery += " US_CGC LIKE '%"+cPsqui+"%' OR US_COD LIKE '%"+cPsqui+"%' ) 			" 					 			
	    EndIf   		
		cQuery += " AND US_ESTATUS NOT IN ('0')	"    				
	Else  
		
	    If !Empty(cPsqui)		    
			cQuery += " AND (US_NOME LIKE '%"+cPsqui+"%' OR US_TEL LIKE '%"+cPsqui+"%' OR 	" 					 
			cQuery += " US_CGC LIKE '%"+cPsqui+"%' OR US_COD LIKE '%"+cPsqui+"%' ) 			" 					 			
	    EndIf 			
	
   		cQuery += " AND US_ESTATUS NOT IN ('0')	" 	
	EndIf                                        
	
	cQuery += " ORDER BY US_COD, US_LOJA, US_NOME	" 
				
	TCQuery cQuery Alias "SUS0" New
	dbSelectArea("SUS0") 			
	dbGoTop()       
		
	aBrowSUS:={}
	
	While !Eof()			
   		aAdd(aBrowSUS, {SUS0->US_ESTATUS   				,;  // 01
   						SUS0->US_COD					,;  // 02
						AllTrim(SUS0->US_LOJA) 			,;  // 03
						SUS0->US_NOME			  		,;  // 04						
						AllTrim(SUS0->US_END)   		,;  // 05 
						AllTrim(SUS0->US_MUN)  			,;  // 06
						AllTrim(SUS0->US_EST)  			,;  // 07						
						SUS0->US_DDD		 			,;  // 08												
						SUS0->US_TEL			   		,;  // 09  
						SUS0->US_EMAIL			 		,;  // 10												
						AllTrim(SUS0->US_CGC)   		,;  // 11												
						DToC(StoD(SUS0->US_ZDATACA))	,;  // 12
						SUS0->US_ZORIGEX    			,;  // 13
						SUS0->US_ZORIGEM		  		,;  // 14  
						AllTrim(SUS0->US_NOMCAD)		,;  // 15  						                                       
						AllTrim(SUS0->US_FILIAL)   		,;  // 16  
						SUS0->US_FAX		 			,;  // 17												
						SUS0->US_WHATSAP		  		,;  // 18												
						SUS0->US_SATIV					,;  // 19
						SUS0->US_CATEGOR    			,;  // 20
						AllTrim(SUS0->US_CODCLI)  		,;  // 21  
						AllTrim(SUS0->US_LOJACLI)  		,;  // 22 						
						SUS0->US_HISTOBS		 		,;  // 23     				   
						AllTrim(SUS0->US_REGINTE) 		,;  // 24  						
						AllTrim(SUS0->US_EMLIGAC) 		,;	// 25
						AllTrim(SUS0->US_OPCCONT)		,;  // 26	
						SUS0->US_EVENTRD				})  // 27	
																		
	    SUS0->(dbSkip())	 
    Enddo
		
	SUS0->(dbCloseArea())

Return
      

User Function fAtuSUS(cOrigVer,nOpcx)
****************************************************************************************
* Função que efetua operações de acordo com solicitação do usuário.
* 
*****
	Local aRegiInte 	:= {"","1=Centro de BH","2=Barro Preto","3=Savassi","4=Venda Nova","5=Barreiro","6=Contagem","7=Betim"}	 
	Local aOpcCont	 	:= {"","1=WhatsApp","2=Ligação"}	 	
	Local lAlterCond	:= .F.
	Local aAreaPr 		:= GetArea() 
	Local oCmbRegInt,oCmbOpcCont	
	Local cFilOrig		:= SuperGetMV("FS_FILORIG", (.T.), "")  
	
	Default cOrigVer	:= ""

	Private aButtons	:= {}
	Private nOpca		:= 0
	Private lInclui 	:= .F.  
	Private lAltera 	:= .F. 
	Private lNovaLoja	:= .F.           
	Private	cDescLocal 	:= ""
	Private cDescOrig  	:= ""
	Private cDescSeg1	:= "" 
	Private cDescCat	:= ""  
	Private cCodigo 	:= ""        

	If (cOrigVer $ "CAT_CRM_NAT")
		If Empty(aBrowSUS) .And. nOpcx <> 3  
		 	Return()	
		EndIf 
	Else      	
		Private cOrigem := ""
	EndIf
	
	dbSelectArea("SUS")

	If nOpcx <> 3   
        dbSelectArea("SUS")
        dbSetOrder(1)
        If !dbSeek(xFilial()+aBrowSUS[oBrowSUS:nAt,02]+aBrowSUS[oBrowSUS:nAt,03])
             Return()
        EndIf
		RegToMemory ( "SUS",.F.,.T.,.F. )
		
		M->US_COD 		:= aBrowSUS[oBrowSUS:nAt,02]
		M->US_LOJA		:= aBrowSUS[oBrowSUS:nAt,03]
		M->US_FILIAL	:= aBrowSUS[oBrowSUS:nAt,16]
		M->US_NOME		:= aBrowSUS[oBrowSUS:nAt,04]
		M->US_DDD		:= aBrowSUS[oBrowSUS:nAt,08]	          
		M->US_TEL  		:= aBrowSUS[oBrowSUS:nAt,09]	
		M->US_FAX 		:= aBrowSUS[oBrowSUS:nAt,17]
		M->US_WHATSAP	:= aBrowSUS[oBrowSUS:nAt,18]
		M->US_SATIV		:= aBrowSUS[oBrowSUS:nAt,19]	          
		M->US_REGINTE	:= aBrowSUS[oBrowSUS:nAt,24]		
		M->US_ZORIGEM	:= aBrowSUS[oBrowSUS:nAt,14]
		M->US_ZORIGEX	:= aBrowSUS[oBrowSUS:nAt,13]
		M->US_CATEGOR	:= aBrowSUS[oBrowSUS:nAt,20]			
		M->US_EMAIL		:= aBrowSUS[oBrowSUS:nAt,10]
		M->US_HISTOBS	:= aBrowSUS[oBrowSUS:nAt,23]
		M->US_CODCLI	:= aBrowSUS[oBrowSUS:nAt,21]
		M->US_LOJACLI	:= aBrowSUS[oBrowSUS:nAt,22]
		M->US_EMLIGAC	:= aBrowSUS[oBrowSUS:nAt,25]
		M->US_ESTATUS	:= aBrowSUS[oBrowSUS:nAt,01]        
		M->US_OPCCONT	:= aBrowSUS[oBrowSUS:nAt,26]		
		M->US_EVENTRD	:= aBrowSUS[oBrowSUS:nAt,27]		
				 
		If nOpcx == 4    
			// Permite alteração se não Ativo
			If U_fPotenEst(M->US_COD + M->US_LOJA,/*Estatus*/,/*Ligacao*/,"C",,,) <> "4"
		  		lAltera 	:= .T.
		    EndIf 
		
		// Cópia para nova loja
		ElseIf nOpcx >= 6  
				   
	   		lNovaLoja	 := .T. 
	   		lAltera 	 := .T.
	   		lInclui 	 := .T. 
	   		M->US_LOJA	 := Soma1(M->US_LOJA)
			M->US_EMLIGAC:= "2"
			M->US_ESTATUS:= "1"	
			M->US_CODCLI := ""
			M->US_LOJACLI:= ""	
 			   		
		EndIf 

 		cDescLocal 		:= AllTrim(Posicione("SX5",1,xFilial("SX5")+'CZ'+M->US_ZORIGEM,"X5_DESCRI"))
 		cDescOrig  		:= AllTrim(Posicione("SX5",1,xFilial("SX5")+'SU'+M->US_ZORIGEX,"X5_DESCRI"))
  		cDescSeg1 		:= AllTrim(Posicione("SX5",1,xFilial("SX5")+'T3'+M->US_SATIV  ,"X5_DESCRI"))
 		cDescCat  		:= AllTrim(Posicione("SX5",1,xFilial("SX5")+'Z6'+M->US_CATEGOR,"X5_DESCRI"))
		
	Else       
		RegToMemory ( "SUS",.T.,.T.,.F. )
	
		M->US_COD	:= ""
	   	M->US_LOJA	:= "01"
	   	lInclui 	:= .T.  
		lAltera 	:= .T.		
	EndIf
	
	Define MSDialog oDlgVai Title OemToAnsi(If(cCodigo=="",'','Código: '+cCodigo+' - ')+ cTitulo) From 0,0 To 032,073 
  		
		@ 006,005 To 220,285 LABEL "Cadastrais" Of oDlgVai Pixel    		
		@ 019,010 Say 'Código:' COLOR CLR_HBLUE Pixel Of oDlgVai
		@ 017,055 Get M->US_COD Size 040,11 When .F. Object oCod
		@ 019,148 Say 'Loja:'   COLOR CLR_HBLUE Pixel Of oDlgVai	     
		@ 017,192 Get M->US_LOJA Size 015,11 When lNovaLoja Picture '99' Object oLoja		
		@ 035,010 Say 'Nome:' COLOR CLR_HBLUE Pixel Of oDlgVai	  
		@ 033,055 Get M->US_NOME  Size 215,11 When lAltera Picture '@!' Object oNome	
		@ 051,010 Say 'DDD:' COLOR CLR_HBLUE Pixel Of oDlgVai
		@ 049,055 Get M->US_DDD Size 024,11 When lAltera Object oDDD		
		@ 051,148 Say 'Celular/What.:' COLOR CLR_HBLUE  Pixel Of oDlgVai		
		@ 049,192 Get M->US_TEL Size 040,11 When lAltera Object oCelTel	   
	
		@ 067,010 Say 'Tel.Fixo:' Pixel Of oDlgVai	
		@ 065,055 Get M->US_FAX Size 040,11 When lAltera Object oFixoFax 
		@ 067,148 Say 'Outro Tel.:' Pixel Of oDlgVai	
		@ 065,192 Get M->US_WHATSAPP Size 040,11 When lAltera Object oWhtsOutr
			
		@ 083,010 Say 'E-mail:' COLOR CLR_HBLUE Pixel Of oDlgVai
		@ 081,055 Get M->US_EMAIL Size 215,11 When lAltera Object oEmail       
		If cOrigem <> ""     
			@ 099,010 Say 'Local Cadast.:' COLOR CLR_HBLUE Pixel Of oDlgVai		
			@ 097,055 Get M->US_ZORIGEM Size 025,11 Picture '@!' When lInclui Valid (cDescLocal := AllTrim(Posicione("SX5",1,xFilial("SX5")+'CZ'+M->US_ZORIGEM,"X5_DESCRI")),ExistCpo('SX5','CZ'+M->US_ZORIGEM)) F3 "CZ" Object oZOrigem 
			@ 099,148 Say 'Desc. Local:'  Pixel Of oDlgVai	  
			@ 097,192 Get cDescLocal Size 078,11 When .F. Picture '@!' Object oLocDesc 
				 
			@ 115,010 Say 'Orig.Poten.:' COLOR CLR_HBLUE Pixel Of oDlgVai		
			
			If cOrigem == "CRM"  
				@ 114,055 Get M->US_ZORIGEX Size 30,11 When lInclui Valid (cDescOrig := AllTrim(Posicione("SX5",1,xFilial("SX5")+'SU'+M->US_ZORIGEX,"X5_DESCRI")),ExistCpo('SX5','SU'+M->US_ZORIGEX) .And.;
				AllTrim(Posicione("SX5",1,xFilial("SX5")+'SU'+M->US_ZORIGEX,"X5_CHAVE"))$ cFilOrig ) F3 "SX5USF" Object oZOrigex 
			Else
				@ 114,055 Get M->US_ZORIGEX Size 30,11 When lInclui Valid (cDescOrig := AllTrim(Posicione("SX5",1,xFilial("SX5")+'SU'+M->US_ZORIGEX,"X5_DESCRI")),ExistCpo('SX5','SU'+M->US_ZORIGEX)) F3 "SX5SUS" Object oZOrigex 
			EndIf
			@ 115,148 Say 'Desc.Origem:'  Pixel Of oDlgVai	  
			@ 114,192 Get cDescOrig Size 078,11  When .F. Picture '@!' Object oDescOrig		

	    // Inclusão de potencial na substituição 
		ElseIf nOpcx == 3 .And. cOrigem == "" .And. !Empty(SUS->US_ZORIGEX)    
			M->US_ZORIGEX := SUS->US_ZORIGEX
			M->US_ZORIGEM := SUS->US_ZORIGEM
		EndIf 			
		@ 131,010 Say 'Segmento:' Pixel Of oDlgVai	  
		@ 129,055 Get M->US_SATIV Size 040,11 F3 "T3" When lAltera Valid (cDescSeg1 := AllTrim(Posicione("SX5",1,xFilial("SX5")+'T3'+M->US_SATIV,"X5_DESCRI")),(Empty(M->US_SATIV).Or.ExistCpo('SX5','T3'+M->US_SATIV))) Object oSement     
		@ 131,148 Say 'Desc.Segm.:'  Pixel Of oDlgVai	  
		@ 129,192 Get cDescSeg1 Size 078,11 When .F. Picture '@!' Object oDescSeg1 
				
		@ 147,010 Say 'Região Intere.:' COLOR CLR_HBLUE Pixel Of oDlgVai	              
		@ 145,055 Combobox M->US_REGINTE Items aRegiInte Size 050,11 Object oCmbRegInt	
		oCmbRegInt:bWhen := {|| lAltera }

		@ 147,148 Say 'Opc. de Contato:' Pixel Of oDlgVai	              
		@ 145,192 Combobox M->US_OPCCONT Items aOpcCont Size 050,11 Object oCmbOpcCont	
		oCmbOpcCont:bWhen := {|| lAltera }
		
		@ 163,010 Say 'Categoria:' COLOR CLR_HBLUE Pixel Of oDlgVai	  
		@ 161,055 Get M->US_CATEGOR Size 030,11 F3 "Z6" When lAltera Valid (cDescCat := AllTrim(Posicione("SX5",1,xFilial("SX5")+'Z6'+M->US_CATEGOR,"X5_DESCRI")),(Empty(M->US_CATEGOR).Or.ExistCpo('SX5','Z6'+M->US_CATEGOR))) Object oCategor		
		@ 163,148 Say 'Desc.Categ.:'  Pixel Of oDlgVai	  
		@ 161,192 Get cDescCat Size 078,11 Picture '@!'  When .F. Object oDescCat   
		
		@ 178,010 Say 'Observação:'  Pixel Of oDlgVai	  
		@ 176,055 Get M->US_HISTOBS Size 215,25 MEMO Object oZObs 	
		oZObs:lReadOnly := !lAltera                                              
		
		@ 207,010 Say 'Último Evento:' Pixel Of oDlgVai
		@ 206,055 Get M->US_EVENTRD Size 215,11 When lAltera Object oEvento 		

		oBtnCancel:= TButton():New( 227,160,"Confirmar",oDlgVai, {|| If((lAltera .And. fValidSUS(nOpcx) .And.;
			 MsgBox("Deseja, realmente, salvar as informações digitadas?","Salvando Informações","YESNO")),(nOpca:=1,oDlgVai:End()), nOpca:=0 )},050,010,,,,.T.,,"",,,,.F. )

  		oBtnConfir:= TButton():New( 227,220,"Cancelar",oDlgVai, {|| nOpca:=0, oDlgVai:End()},050,010,,,,.T.,,"",,,,.F. )
	
	ACTIVATE DIALOG oDlgVai CENTERED
	
	// Incluir ou Alterar = Grava as informações digitadas 
	If nOpca<>0 .And. ( AllTrim(Str(nOpcx)) $ "3_4_6_7" )  
		GrvDados(nOpcx)	 
	EndIf
	
	RestArea(aAreaPr)
	
Return()          


Static Function fValidSUS(nOpcx)
****************************************************************************************
* Valida o preenchimento dos campos para prosseguir com a confirmação.
* 
***** 

	Local lRet 		:= .T.   
	Local aAreaEx 	:= {} 
	Local cQuery	:= ""
	
	If AllTrim(M->US_EMLIGAC) == "1"
   			MsgBox("Cliente já se encontra Em Atendimento pela CAT ou pelo CRM. Aguarde o término do atendimento para iniciar um novo.",OemtoAnsi("Validação:Processo Exclusivo!"),"INFO")					
		lRet := .F.
	ElseIf Empty(M->US_LOJA)
		MsgBox("A Loja do Cliente deve ser devidamente preenchida. Revise o lançamento e tente novamente.",OemtoAnsi("Campo em Branco!"),"INFO")					
		lRet := .F.
	ElseIf Empty(M->US_NOME)
		MsgBox("O Nome do Cliente deve ser devidamente preenchido. Revise o lançamento e tente novamente.",OemtoAnsi("Campo em Branco!"),"INFO")					
		lRet := .F.	
	ElseIf Empty(M->US_DDD)
		MsgBox("O DDD do telefone deve ser devidamente preenchido. Revise o lançamento e tente novamente.",OemtoAnsi("Campo em Branco!"),"INFO")					
		lRet := .F.		
	ElseIf Empty(M->US_TEL)
		MsgBox("O campo Celular deve ser preenchido. Revise o lançamento e tente novamente.",OemtoAnsi("Campo em Branco!"),"INFO")					
		lRet := .F.	
	ElseIf Empty(M->US_CATEGOR)
		MsgBox("A Categoria desejada deve ser devidamente preenchida. Revise o lançamento e tente novamente.",OemtoAnsi("Campo em Branco!"),"INFO")					
		lRet := .F.	
	ElseIf Empty(M->US_REGINTE)
		MsgBox("Escolha a Região de Interesse para continuar e tente novamente.",OemtoAnsi("Campo em Branco!"),"INFO")					
		lRet := .F.	
	ElseIf Empty(M->US_EMAIL) .Or. !IsEmail(M->US_EMAIL)
		MsgBox("O E-mail deve ser preenchido e válido. Revise o lançamento e tente novamente.",OemtoAnsi("Campo em Branco!"),"INFO")					
		lRet := .F.			
	ElseIf Empty(M->US_ZORIGEM) .And. cOrigem <> ""     
		MsgBox("A Origem do Cadastro deve ser devidamente preenchida. Revise o lançamento e tente novamente.",OemtoAnsi("Campo em Branco!"),"INFO")					
		lRet := .F.	
	ElseIf Empty(M->US_ZORIGEX) .And. cOrigem <> ""     
		MsgBox("A Origem do Cliente deve ser devidamente preenchida. Revise o lançamento e tente novamente.",OemtoAnsi("Campo em Branco!"),"INFO")					
		lRet := .F. 
	Else                    
	
		aAreaEx := GetArea()		
		If nOpcx == 3 .Or. nOpcx >= 6 

			If lRet
				// Duplicidade de cadastro pelos dados DDD+Telefone
				cQuery := " SELECT US_COD,US_LOJA,US_NOME, US_DDD, US_TEL	" + CRLF  
				cQuery += " FROM "+RetSqlName("SUS")+" SUS					" + CRLF  
				cQuery += " WHERE SUS.D_E_L_E_T_='' 	  	   				" + CRLF
				cQuery += " 	AND US_ESTATUS <> '0' 	  	   				" + CRLF				
				cQuery += " 	AND ((RIGHT(US_DDD,2) = RIGHT('"+ PADL(Alltrim(M->US_DDD),3,'0') +"',2) " + CRLF		
				cQuery += " 	AND RTRIM(US_TEL)= '"+ AllTrim(M->US_TEL) +"' ))			" + CRLF		
						
		  		TCQuery cQuery Alias "DUPL" New   
	
				dbSelectArea("DUPL")
		  		dbGoTop()  			 						
		    
			    If !DUPL->(Eof())   		   	
					MsgBox("Cliente já existente no código "+AllTrim(DUPL->US_COD)+"-"+AllTrim(DUPL->US_LOJA)+". Não será possível continuar com o processo",OemtoAnsi("Erro!"),"ALERT")						                	 
			   		lRet := .F.			 			  				  									
				EndIf	   
			 
			 	DUPL->(dbCloseArea())  		
			EndIf  
			
			If nOpcx >= 6 .And. lRet 
				dbSelectArea("SUS")				
				dbSetOrder(1)		
				If dbSeek(xFilial("SUS") + Alltrim(M->US_COD) + M->US_LOJA) 			
		   			MsgBox("Loja já existente para este cliente. Cadastre nova Loja para mesmo Cliente ou utilize a opção 'Incluir' para novo Cliente.",OemtoAnsi("Campo Inválido!"),"ALERT")					
			   		lRet := .F.
	       		EndIf  
	       	EndIf
		EndIf            
		  
        RestArea(aAreaEx)

	EndIf	

Return(lRet)


Static Function GrvDados (nOpcx)
***************************************************************************************
*
*
*****     

	Local cNrOport	:= "" 
	Local cNumList	:= ""    
	Local cOperado	:= ""
	Local cEvento	:= ""
	Local cCdContat	:= ""
	Local cUSEstat	:= If(cOrigem=="CRM","2","1")  		// Cliente Potencial ou Agendado
	Local lInclui	:= .F.
	Local cEmLigac	:= If(cOrigem $ "CAT_CRM","1","2")	// Cliente Em Ligação não pode ser trabalhado por mais ninguém. 		  
	Local lNovoCod	:= .F.
	Local aAreaAC8	:= {}
	Local aEvolVet	:= {}
	Local aCentVet	:= {}
	Local aAreaPr 	:= {}
	    
	// Inclusão de novo Cliente, Loja 01 ou Nova Loja para Cliente já existente.
	If nOpcx==3 .Or. nOpcx == 6 .Or. nOpcx == 7 
 		lInclui	:= .T.
	EndIf

	dbSelectArea ( "SUS" )
	dbSetOrder ( 1 )	
	
	If RecLock ( "SUS", lInclui )   
	        
		If lInclui .And. Empty(M->US_COD)   
			
			lNovoCod	:= .T.
			cEvento		:= "000004"	   	   				// Reunião com Inclusão do novo Cliente Potencial no Sistema
			M->US_COD	:= GetSX8Num("SUS","US_COD")    
			
			Replace	US_COD 		With M->US_COD      
			Replace	US_ESTATUS  With cUSEstat 
			Replace US_EMLIGAC	With cEmLigac  

		// Adiciona Loja para mesmo cliente
		ElseIf lInclui 
			Replace	US_COD 		With M->US_COD      
			Replace	US_ESTATUS  With cUSEstat 
			Replace US_EMLIGAC	With cEmLigac 						
		Else
			cEvento		:= "000005"	  		   			// Reunião com Atualização do Cadastro do Cliente Potencial já existente no Sistema		
			If cOrigem=="CRM"
	  			Replace	US_ESTATUS  With "2" 
				Replace US_EMLIGAC	With "1"
			ElseIf cOrigem=="CAT"
				Replace US_EMLIGAC	With "1"			
			EndIf
        EndIf
             
		Replace	US_LOJA		With M->US_LOJA
		Replace	US_FILIAL	With xFilial("SUS")
		Replace	US_NOME		With AllTrim(M->US_NOME)
		Replace US_DDD		With AllTrim(M->US_DDD)
		Replace US_TEL		With AllTrim(M->US_TEL)
		Replace US_FAX		With AllTrim(M->US_FAX)
		Replace US_WHATSAP	With AllTrim(M->US_WHATSAP)
		Replace	US_ZORIGEM	With M->US_ZORIGEM
		Replace	US_ZORIGEX	With M->US_ZORIGEX    
		Replace US_SATIV	With M->US_SATIV  
		Replace	US_REGINTE	With M->US_REGINTE
		Replace	US_ZORIGEX	With M->US_ZORIGEX 
		Replace	US_CATEGOR	With M->US_CATEGOR
		Replace	US_EMAIL	With AllTrim(M->US_EMAIL) 
		Replace	US_HISTOBS	With AllTrim(M->US_HISTOBS)
		Replace	US_ZDATACA 	With Date()    
		Replace	US_ZHORACA 	With Substr(Time(),1,5)        
		Replace	US_USRCAD 	With Alltrim (__cUserId)
		Replace	US_NOMCAD	With Alltrim ( SubStr ( Alltrim ( cUsuario ) ,7,15 ) )		
		Replace	US_TIPO   	With "R"
		Replace	US_DDI    	With "55"
		Replace	US_CGC		With If(Empty(M->US_CGC),"00000000000",M->US_CGC)
		Replace	US_PAIS		With "105"
		Replace	US_ZOPERAD	With "000001"       
		Replace US_OPCCONT	With M->US_OPCCONT  
		Replace US_EVENTRD	With M->US_EVENTRD  
		
		If lNovoCod
			ConfirmSX8(.T.)
		EndIf

		MsUnLock (  )       
		
		If lInclui
		
			cCdContat := GetSX8Num("SU5","U5_CODCONT")
					
		  	dbSelectArea("SU5")
			If RecLock("SU5",.T.)
					
				Replace SU5->U5_FILIAL	With  xFilial("SU5"),;
						SU5->U5_CODCONT	With  cCdContat,;
						SU5->U5_CONTAT	With  AllTrim(M->US_NOME),;
						SU5->U5_EST		With  "MG",;
						SU5->U5_DDD		With  M->US_DDD,;
						SU5->U5_FONE	With  M->US_TEL,;
						SU5->U5_CELULAR With  M->US_FAX,;
						SU5->U5_EMAIL 	With  M->US_EMAIL
																									
				MsUnLock() 
						
			EndIf				  
	
			dbSelectArea("AC8")
			
			If RecLock("AC8",.T.)
					
				Replace	AC8->AC8_FILIAL  With  xFilial("AC8"),;
						AC8->AC8_FILENT  With  xFilial("AC8"),;
						AC8->AC8_ENTIDA  With  "SUS",;
						AC8->AC8_CODENT	 With  M->US_COD+M->US_LOJA,;
						AC8->AC8_CODCON	 With  cCdContat									
	
				MsUnLock() 
					
			EndIf 
		
			ConfirmSX8("SU5","U5_CODCONT")//Confirma a numeração SX8.	  	
		
		EndIf
		
	EndIf		                        
	
	// Gera Evolução pelo Agendamento	         
	If cOrigem == "CRM"				
 
 		aAreaAC8 := GetArea()
		dbSelectArea("AC8")
		dbSetOrder(2)		
		If dbSeek(xFilial("AC8") + "SUS" + "  " + M->US_COD + M->US_LOJA)
			cCdContat := AC8->AC8_CODCONT
		EndIf	
		RestArea(aAreaAC8)	
                
		// Chama Tela de Agendamento
		fTelaAgen()
	    	    
		cNrOport := GetSx8Num("AD1","AD1_NROPOR")
		aEvolVet := {}
			
		aAdd(aEvolVet,{	cNrOport	,;		 											// 01 - Código Evolução
						Left("ATEND.CLIENTE CRM - "+AllTrim(M->US_NOME),50),; 			// 02 - Descrição Evolução Momento Atual
						cCodVend						,; 								// 03 - Código Vendedor
						M->US_COD		   				,; 	   							// 04 - Código Prospect   
						M->US_LOJA						,; 								// 05 - Loja Prospect 
						cLocaSUS	     				,; 	  							// 06 - CC/Local Agendamento                   
						""								,; 		  						// 07 - Código Atendimento CAT   
						""		  						,; 		   						// 08 - Código do Operador CAT           					
						""								,; 								// 09 - Nome do Operador CAT          
						AllTrim(M->US_NOME)		    	,; 		  						// 10 - Nome do Cliente Potencial
						M->US_HISTOBS 					,; 		   						// 11 - Observação  								
						M->US_CODCLI   					,; 		   						// 12 - Código do Cliente  												
						M->US_LOJACLI		 			,; 	   							// 13 - Loja do Cliente  							
						dDtAgSUS			  			,; 		  						// 14 - Data Agendamento 
						cHoraSUS						,; 		   						// 15 - Hova Inicial   											
						Ft320SomHr(cHoraSUS)	  		,; 		   						// 16 - Hora Final											
						cCdContat						,; 	   							// 17 - Contato							
						cEvento							}) 	   							// 18 - Evento

		aAreaPr := GetArea()													
		U_GeraEvol(aEvolVet)
		RestArea(aAreaPr)		     
	
	// Gera Lista de Atendimento			  
	ElseIf cOrigem == "CAT"	
	
 		aAreaAC8 := GetArea()      
 		
		dbSelectArea("AC8")
		dbSetOrder(2)		
		If dbSeek(xFilial("AC8") + "SUS" + "  " + M->US_COD + M->US_LOJA)
			cCdContat := AC8->AC8_CODCONT
		EndIf	                         
		
		dbSelectArea("SU7")
		dbSetOrder(4)		
		If dbSeek(xFilial("SU7")+__cUserID)
	   		cOperado := SU7->U7_COD
		EndIf
				
		RestArea(aAreaAC8)	 
		
		cNumList := GetSx8Num("SU4","U4_LISTA")                      
		aCentVet := {}
			
		aAdd(aCentVet,{	cNumList   						,;								// 01 - Código da Lista de Atendimento
						"A CONTACTAR - " + Alltrim(M->US_NOME)	,; 						// 02 - Descrição Lista Momento Atual
						cCdContat				 		,; 								// 03 - Código Contato
						cOperado		   		  		,; 	   							// 04 - Código Operador   
						M->US_COD	  			 		,; 								// 05 - Código Potencial
						M->US_LOJA	      				}) 	   							// 06 - Loja do Potencial
		
		aAreaPr := GetArea()											
		U_GeraList(aCentVet)	
		RestArea(aAreaPr)								
		
	EndIf 	

	If cOrigem <> ""
		DBSelectArea ( "SUS" )
		AtualBrw(cOpcao)
	EndIf
		
	If lInclui
		MsgInfo ( OemToAnsi ( "Cliente Potencial cadastrado com sucesso!" )  ) 	
    ElseIf cOrigem $ "CRM"
    	MsgInfo ( OemToAnsi ( "Cliente Potencial agendado com sucesso!" )  ) 
    ElseIf cOrigem $ "CAT"
    	MsgInfo ( OemToAnsi ( "Cliente Potencial distribuído com sucesso!" )  )     	
    Else
    	MsgInfo ( OemToAnsi ( "Cliente Potencial alterado com sucesso!" )  )     	
    EndIf

Return()


User Function fAgendaPot()
***********************************************************************
* 
* 
*****     

    Local cNrOport	:= ""    
    Local cCdContat	:= "" 
    Local cNumList  := ""
    Local cOperado	:= ""
    Local cLista	:= "" 
    Local cQuery	:= ""
    Local cUSEstat	:= "1"     
    Local cEmLigac	:= "2"
    Local cEvento	:= "000005"	  			// Reunião com Atualização do Cadastro do Cliente Potencial já existente no Sistema	 
    Local aAreaAC8	:= {}          
	Local aEvolVet	:= {}
	Local aCentVet	:= {}   
	Local aAreaPr 	:= {}
    Local lOk		:= .T.
                                     
	If Empty(aBrowSUS)
	 	Return	
	EndIf
	
    If cOrigem == "CRM"  
	
		aAreaAC8 := GetArea()
		dbSelectArea("AC8")
		dbSetOrder(2)		
		If dbSeek(xFilial("AC8") + "SUS" + "  " + aBrowSUS[oBrowSUS:nAt,02] + aBrowSUS[oBrowSUS:nAt,03])
			cCdContat := AC8->AC8_CODCONT
		EndIf	
		RestArea(aAreaAC8)	
         
		// Verifica se o cliente pode ser "roubado"(devolve a lista a dar baixa) da central de atendimento ou se está em uso (CRM/Sem Agendamento)
		cLista := RoubaLig(aBrowSUS[oBrowSUS:nAt,02],aBrowSUS[oBrowSUS:nAt,03]) 
		
		If Empty(cLista)  
//	   		MsgBox("Cliente já se encontra Em Atendimento pela CAT ou pelo CRM. Processo não poderá continuar.",OemtoAnsi("Processo Exclusivo!"),"INFO")					
	   		Return()		
		EndIf

		dbSelectArea("SU4")
		dbSetOrder(1)  
   		
   		// Assegura que CAT não puxará o cliente para trabalho.	
		If dbSeek(xFilial("SU4") + cLista)    			
			If RecLock ("SU4",.F.)

				// Chama Tela de Agendamento
				lOk := fTelaAgen(.F.)    
				
				If !lOk   
					MsUnLock() 
			   		Return()
				EndIf   

				// Atualiza as listas trabalhadas no atendimento atual		
				cQuery := " UPDATE "+RetSqlName("SU4")+" SET U4_STATUS='2',U4_ESTAGIO='9' 	"     //9=Capturado da CAT pelo CRM
				cQuery += " FROM "+RetSqlName("SU4")+" U4 JOIN "+RetSqlName("SU6")+" U6 ON U4_LISTA=U6_LISTA AND U6.D_E_L_E_T_=''		"						 		
				cQuery += " WHERE U4.D_E_L_E_T_ = '' AND U4_STATUS ='1'		"
			 	cQuery += " AND U6_CODENT ='"+(aBrowSUS[oBrowSUS:nAt,02] + aBrowSUS[oBrowSUS:nAt,03])+"'"
			 		
			   	TCSQLExec(cQuery) 		
			
				cQuery := " UPDATE "+RetSqlName("SU6")+" SET U6_STATUS='2'				"		 		
			 	cQuery += " WHERE D_E_L_E_T_ = '' AND U6_STATUS ='1' 	"			 	
			 	cQuery += " AND U6_CODENT ='"+(aBrowSUS[oBrowSUS:nAt,02] + aBrowSUS[oBrowSUS:nAt,03])+"'"
			 		
			 	TCSQLExec(cQuery) 				
								
				MsUnLock() 
			EndIf
        
        Else
			// Chama Tela de Agendamento
			lOk := fTelaAgen(.F.)    
			
			If !lOk   
		   		Return()
			EndIf           
        EndIf 
	    	    
		cNrOport := GetSx8Num("AD1","AD1_NROPOR")
		aEvolVet := {}
			
		aAdd(aEvolVet,{	cNrOport	,;		 											// 01 - Código Evolução
						Left(AllTrim("ATEND.CLIENTE CRM - "+aBrowSUS[oBrowSUS:nAt,04]),50),; 		// 02 - Descrição Evolução Momento Atual
						cCodVend						,; 								// 03 - Código Vendedor
						aBrowSUS[oBrowSUS:nAt,02]		,; 	   							// 04 - Código Prospect   
						aBrowSUS[oBrowSUS:nAt,03]		,; 								// 05 - Loja Prospect 
						cLocaSUS	    				,; 	  							// 06 - CC/Local Agendamento                   
						""								,; 		  						// 07 - Código Atendimento CAT   
						""		  						,; 		   						// 08 - Código do Operador CAT           					
						""								,; 								// 09 - Nome do Operador CAT          
						aBrowSUS[oBrowSUS:nAt,04]		,; 		  						// 10 - Nome do Cliente Potencial
						aBrowSUS[oBrowSUS:nAt,23]		,; 		   						// 11 - Observação  								
						aBrowSUS[oBrowSUS:nAt,21]		,; 		   						// 12 - Código do Cliente  												
						aBrowSUS[oBrowSUS:nAt,22]		,; 	   							// 13 - Loja do Cliente  							
						dDtAgSUS			  			,; 		  						// 14 - Data Agendamento 
						cHoraSUS						,; 		   						// 15 - Hova Inicial   											
						Ft320SomHr(cHoraSUS)  			,; 		   						// 16 - Hora Final											
						cCdContat						,; 	   							// 17 - Contato							
						cEvento							}) 	   							// 18 - Evento

		aAreaPr := GetArea()													
		U_GeraEvol(aEvolVet)  
		RestArea(aAreaPr)
        
		// Agendado e Ligação Ativa
		cUSEstat := "2"
		cEmLigac := "1"
		
		aAreaPr := GetArea()		
		U_fPotenEst(aBrowSUS[oBrowSUS:nAt,02] + aBrowSUS[oBrowSUS:nAt,03], cUSEstat, cEmLigac,"A",,,)			
		RestArea(aAreaPr)
        
        AtualBrw(cOpcao)
        
	    MsgInfo ( OemToAnsi ( "Cliente Potencial agendado com sucesso!" )  ) 
    
    ElseIf cOrigem == "CAT"  
         
    	cLista := RoubaLig(aBrowSUS[oBrowSUS:nAt,02],aBrowSUS[oBrowSUS:nAt,03]) 
		
		If Empty(cLista)  
	   		Return() 
	   		
	   	ElseIf aBrowSUS[oBrowSUS:nAt,25] == "1"
   			MsgBox("Cliente já se encontra Em Atendimento pela CAT ou pelo CRM. Aguarde o término do atendimento para iniciar um novo.",OemtoAnsi("Processo Exclusivo!"),"INFO")					
	   		Return()	
		EndIf
    
    
 		aAreaAC8 := GetArea()

		dbSelectArea("AC8")
		dbSetOrder(2)		
		If dbSeek(xFilial("AC8") + "SUS" + "  " + aBrowSUS[oBrowSUS:nAt,02] + aBrowSUS[oBrowSUS:nAt,03])
			cCdContat := AC8->AC8_CODCONT
		EndIf	  
		
		dbSelectArea("SU7")
		dbSetOrder(4)		
		If dbSeek(xFilial("SU7")+__cUserID)
	   		cOperado := SU7->U7_COD
		EndIf		

		RestArea(aAreaAC8)	 
		
		cNumList := GetSx8Num("SU4","U4_LISTA")                      
		aCentVet := {}
			
		aAdd(aCentVet,{	cNumList   						,;								// 01 - Código da Lista de Atendimento
						Left(AllTrim("A CONTACTAR - "+aBrowSUS[oBrowSUS:nAt,04]),30),;  // 02 - Descrição Lista Momento Atual
						cCdContat				 		,; 								// 03 - Código Contato
						cOperado		   		  		,; 	   							// 04 - Código Operador   
						aBrowSUS[oBrowSUS:nAt,02] 		,; 								// 05 - Código Potencial
						aBrowSUS[oBrowSUS:nAt,03]		}) 	   							// 06 - Loja do Potencial

		aAreaPr := GetArea()													
		U_GeraList(aCentVet)  
		RestArea(aAreaPr)

		// Mantém o Estatus atual e Ligação Ativa - Sugestão
		cUSEstat := aBrowSUS[oBrowSUS:nAt,01]
		cEmLigac := "1"
		
		aAreaPr := GetArea()															
		U_fPotenEst(aBrowSUS[oBrowSUS:nAt,02] + aBrowSUS[oBrowSUS:nAt,03], cUSEstat, cEmLigac,"A",,,)			    
        RestArea(aAreaPr)
        
	    AtualBrw(cOpcao)
    
		MsgInfo ( OemToAnsi ( "Cliente Potencial distribuído com sucesso!" )  ) 
    EndIf


Return()


Static Function RoubaLig(cCodigSUS, cLojaSUS)  


	Local cQuery := ""
	Local cLista := ""
    
	// Verifica se está em alguma evolução em aberto.
	cQuery	:= " SELECT '01- CC' EMP,A3_COD CODV, A3_NOME VENDEDOR, AD1_NROPOR EVOLUCAO	" + CRLF
	cQuery  += " FROM AD1010 AD1 JOIN "+RetSqlName("SA3")+" SA3 ON A3_COD=AD1_VEND 		" + CRLF	
	cQuery  += " WHERE AD1.D_E_L_E_T_='' 									" + CRLF		 
	cQuery  += " AND SA3.D_E_L_E_T_='' 	  			  				 		" + CRLF		
	cQuery  += " AND AD1_STATUS='1'											" + CRLF 
	cQuery	+= " AND (AD1_PROSPE+AD1_LOJPRO) IN ('"+cCodigSUS+cLojaSUS+"') 	" + CRLF
	//!! 
	cQuery	+= " UNION ALL	" + CRLF	
	cQuery	+= " SELECT '13- ADM' EMP,A3_COD CODV, A3_NOME VENDEDOR, AD1_NROPOR EVOLUCAO	" + CRLF
	cQuery  += " FROM AD1130 AD1 JOIN "+RetSqlName("SA3")+" SA3 ON A3_COD=AD1_VEND 		" + CRLF	
	cQuery  += " WHERE AD1.D_E_L_E_T_='' 									" + CRLF		 
	cQuery  += " AND SA3.D_E_L_E_T_='' 	  			  				 		" + CRLF		
	cQuery  += " AND AD1_STATUS='1'											" + CRLF 
	cQuery	+= " AND (AD1_PROSPE+AD1_LOJPRO) IN ('"+cCodigSUS+cLojaSUS+"') 	" + CRLF				

	TCQuery cQuery Alias "VERAD1" New
	dbSelectArea("VERAD1") 			
	dbGoTop()       
		
	If !Eof()   
   		MsgBox("Cliente já se encontra Em Atendimento pelo Consultor de Vendas "+AllTrim(VERAD1->CODV)+"-"+AllTrim(VERAD1->VENDEDOR)+","+;
   			   " Evolução "+AllTrim(VERAD1->EVOLUCAO)+", Empresa: "+AllTrim(VERAD1->EMP)+". Aguarde o término do atendimento para iniciar um novo. ",;
   			   OemtoAnsi("Processo Exclusivo!"),"INFO")					
		VERAD1->(dbCloseArea())   				
   		Return("")	   		
	EndIf
	
	VERAD1->(dbCloseArea())
	
    // Verifica se está em alguma lista distribuída na CAT em aberto.
	cQuery	:= " SELECT '01- CC' EMP,U4_LISTA LISTA, U7_COD CODOP, U7_NOME OPERADOR, 		" + CRLF 
	cQuery  += "	CASE WHEN U4_ESTAGIO= '2' AND ISNULL(POTENCIAL,'')=''  THEN 'ASEMCONTATO'  		" + CRLF	
	cQuery  += "		 WHEN U4_ESTAGIO= '2' AND ISNULL(POTENCIAL,'')<>'' THEN 'REDISTRIBUIDO'		" + CRLF	
	cQuery  += "		 ELSE 'SEMAGENDAMENTO'						" + CRLF	                            
	cQuery  += "	END SITUACAO									" + CRLF 
	cQuery	+= " FROM SU4010 SU4 			  		" + CRLF
	cQuery	+= "	JOIN SU6010 SU6 ON (SU6.D_E_L_E_T_='' AND U4_LISTA = U6_LISTA)	" + CRLF		
	cQuery	+= "	JOIN "+RetSqlName("SU7")+" SU7 ON (SU7.D_E_L_E_T_='' AND U4_OPERAD=U7_COD)		" + CRLF
	cQuery	+= " 	LEFT JOIN (						 				" + CRLF 
	cQuery	+= "		SELECT UC_CHAVE	POTENCIAL					" + CRLF 
	cQuery	+= "   		FROM SUC010 UC 				" + CRLF 
	cQuery	+= "   		WHERE UC.D_E_L_E_T_=''		   				" + CRLF 
	cQuery	+= "   		GROUP BY UC_CHAVE 			 				" + CRLF   
	cQuery	+= " 		UNION						 				" + CRLF 
	cQuery	+= "		SELECT (AD1_PROSPE+AD1_LOJPRO) POTENCIAL	" + CRLF 
	cQuery	+= "   		FROM AD1010 AD1				" + CRLF 
	cQuery	+= "   		WHERE AD1.D_E_L_E_T_=''		   				" + CRLF 
	cQuery	+= "   		GROUP BY (AD1_PROSPE+AD1_LOJPRO)			" + CRLF 		
	cQuery	+= "	) EXISTE ON POTENCIAL=U6_CODENT					" + CRLF 			
	cQuery	+= " WHERE SU4.D_E_L_E_T_ <> '*'   						" + CRLF  
	cQuery	+= "    AND U4_ESTAGIO NOT IN ('6','8')					" + CRLF 
	cQuery	+= " 	AND U4_STATUS IN ('1') 	  		 				" + CRLF
	cQuery	+= " 	AND U6_CODENT IN ('"+cCodigSUS+cLojaSUS+"') 	" + CRLF	 
	//!!
	cQuery	+= " UNION ALL   					   		" + CRLF 	
	cQuery	+= " SELECT '13- ADM' EMP,U4_LISTA LISTA, U7_COD CODOP, U7_NOME OPERADOR,   	" + CRLF 
	cQuery  += "	CASE WHEN U4_ESTAGIO= '2' AND ISNULL(POTENCIAL,'')=''  THEN 'ASEMCONTATO'  		" + CRLF	
	cQuery  += "		 WHEN U4_ESTAGIO= '2' AND ISNULL(POTENCIAL,'')<>'' THEN 'REDISTRIBUIDO'		" + CRLF	
	cQuery  += "		 ELSE 'SEMAGENDAMENTO'						" + CRLF	                            
	cQuery  += "	END SITUACAO									" + CRLF 
	cQuery	+= " FROM SU4130 SU4 			  		" + CRLF
	cQuery	+= "	JOIN SU6130 SU6 ON (SU6.D_E_L_E_T_='' AND U4_LISTA = U6_LISTA)	" + CRLF		
	cQuery	+= "	JOIN "+RetSqlName("SU7")+" SU7 ON (SU7.D_E_L_E_T_='' AND U4_OPERAD=U7_COD)		" + CRLF
	cQuery	+= " 	LEFT JOIN (						 				" + CRLF 
	cQuery	+= "		SELECT UC_CHAVE	POTENCIAL					" + CRLF 
	cQuery	+= "   		FROM SUC130 UC 				" + CRLF 
	cQuery	+= "   		WHERE UC.D_E_L_E_T_=''		   				" + CRLF 
	cQuery	+= "   		GROUP BY UC_CHAVE 			 				" + CRLF   
	cQuery	+= " 		UNION						 				" + CRLF 
	cQuery	+= "		SELECT (AD1_PROSPE+AD1_LOJPRO) POTENCIAL	" + CRLF 
	cQuery	+= "   		FROM AD1130 AD1				" + CRLF 
	cQuery	+= "   		WHERE AD1.D_E_L_E_T_=''		   				" + CRLF 
	cQuery	+= "   		GROUP BY (AD1_PROSPE+AD1_LOJPRO)			" + CRLF 		
	cQuery	+= "	) EXISTE ON POTENCIAL=U6_CODENT					" + CRLF 			
	cQuery	+= " WHERE SU4.D_E_L_E_T_ <> '*'   						" + CRLF  
	cQuery	+= "    AND U4_ESTAGIO NOT IN ('6','8')					" + CRLF 
	cQuery	+= " 	AND U4_STATUS IN ('1') 	  		 				" + CRLF
	cQuery	+= " 	AND U6_CODENT IN ('"+cCodigSUS+cLojaSUS+"') 	" + CRLF	
		

	TCQuery cQuery Alias "VERSU4" New
	dbSelectArea("VERSU4") 			
	dbGoTop()       
	
	If Eof()	
		cLista := "999"
	EndIf
		
	While !Eof() 

			MsgBox("Cliente já se encontra Em Atendimento pelo Consultor de Atendimento CAT "+AllTrim(VERSU4->CODOP)+"-"+AllTrim(VERSU4->OPERADOR)+","+;
	   		   " Atendimento "+AllTrim(VERSU4->LISTA)+", Empresa: "+AllTrim(VERSU4->EMP)+". Aguarde o término do atendimento para iniciar um novo. ",OemtoAnsi("Processo Exclusivo!"),"INFO")					
			
			VERSU4->(dbCloseArea())
	   		Return("") 

		VERSU4->(dbSkip())		   		
	EndDo   
	
	VERSU4->(dbCloseArea())	
	
Return(cLista)


Static Function fTelaAgen(lLoop)
***********************************************************************
* 
* 
*****

	Local oDlgAgen, oLocaSUS, oLocDesc
	Local cDescLoc	:= ""	
	Local cHoraFim	:= "  :  "                          	
	Local oFtTxt    := TFont():New("Tahoma",,16,,.T.,,,,,.F.,.F.)
	Local lValida 	:= .F. 
	Local lSalva	:= .T.    
	Local aAreaAge	:= {} 
	Local aAreaGer	:= GetArea()	
	 
	Default lLoop 	:= .T.
	
	dDtAgSUS:= CtoD("")
	cHoraSUS:= "  :  "
	cLocaSUS:= Space(3) 	

	While !lValida             
	
		lValida := .T.
   
		Define MSDialog oDlgAgen Title "Agendamento" From 0,0 To 210,350 Pixel Style DS_MODALFRAME
			
		@ 015,030 Say "Data:" FONT oFtTxt Pixel Of oDlgAgen
		@ 013,050 Get dDtAgSUS Size 45,09 Pixel Of oDlgAgen 
		@ 033,010 Say "Hora Inicial:" FONT oFtTxt Pixel Of oDlgAgen
		@ 031,050 Get cHoraSUS Size 45,09 Pixel Of oDlgAgen Picture "99:99" Valid (cHoraFim	:= Ft320SomHr(cHoraSUS),TkHoraOk(cHoraSUS) .And. NaoVazio())
		@ 051,014 Say "Hora Final:" FONT oFtTxt Pixel Of oDlgAgen
		@ 049,050 Get cHoraFim Size 45,09 Picture "99:99" When .F. Pixel Of oDlgAgen
		@ 069,029 Say "Local:" FONT oFtTxt Pixel Of oDlgAgen
		@ 067,050 Get cLocaSUS  Size 025,11  F3 'CZ' Picture "@!" Valid (cDescLoc := AllTrim(Posicione("SX5",1,xFilial("SX5")+'CZ'+cLocaSUS,"X5_DESCRI")),ExistCpo('SX5','CZ'+cLocaSUS)) //
		@ 067,085 Get cDescLoc 	Size 076,09 When .F. Pixel Of oDlgAgen
                      
		@ 084,050 Button "Confirmar" Size 050,012 Action oDlgAgen:End() Pixel Of oDlgAgen 
		
		If !lLoop
		  	@ 084,109 Button "Cancelar" Size 050,012 Action (lSalva := .F., lValida := .T., oDlgAgen:End()) Pixel Of oDlgAgen 
		EndIf
				
		Activate MSDialog oDlgAgen Centered

		If lSalva         

			If (Empty(DtoS(dDtAgSUS)) .Or. Empty(cHoraSUS) .Or. AllTrim(cHoraSUS)==":" .Or. Empty(cLocaSUS))
			
				MsgBox("Os campos Data, Hora e Local do Agendamento Presencial são de preenchimento obrigatório. Revise seus lançamentos e tente novamente.",;
						OemtoAnsi("Campo em Branco!"),"INFO")					
				lValida := .F.
		
			ElseIf (cHoraSUS > '18:30' .Or. cHoraSUS < '09:00')
	
				MsgBox("Favor agendar o cliente em horário comercial válido, compreendido entre 09h e 18:30h!","Atenção!","INFO")								
				lValida := .F.       
            
			ElseIf (( DtoS(dDtAgSUS) == DtoS(dDatabase) .And. cHoraSUS < Time() ) .Or. DtoS(dDtAgSUS) < DtoS(dDatabase))
	
				MsgBox("Períodos passados não serão aceitos para agendamento. Revise seus lançamentos e tente novamente!","Atenção!","INFO")								
				lValida := .F.				
								
			ElseIf cOrigem == "CRM" .And. lValida
			    
				aAreaAge := GetArea()
				
				// Verifica duplicidade de agendamento e agendamento fora do horário permitido ( Entre 09:00 e 18:30 ).
				dbSelectArea("AD7")
				dbSetOrder(1)
				If dbSeek(xFilial("AD7")+cCodVend+DtoS(dDtAgSUS))
			
					While AD7->AD7_DATA == dDtAgSUS
						If Empty(AD7->AD7_DTEXEC) .And. ((cHoraFim <= AD7->AD7_HORA2 .And. cHoraFim >= AD7->AD7_HORA1) .Or.;
							 (cHoraSUS <= AD7->AD7_HORA2 .And. cHoraSUS >= AD7->AD7_HORA1) .Or. AllTrim(cHoraSUS) == AllTrim(AD7->AD7_HORA1))
							
							MsgBox("O intervalo de horário informado já está alocado para este representante!","Atenção!","INFO")			
							lValida := .F.
				            Exit
						EndIf							
						
						dbSkip()
					EndDo		
		        EndIf 	
		        
		        RestArea(aAreaAge)	        			
        	EndIf                 
        	
		EndIf // Fim - Salva
	EndDo

	RestArea(aAreaGer)

Return (lSalva)
         
                   
Static Function AtualBrw(cOpc)
*********************************************************************************
* Atualiza browse. Executado após uma mudança das informações.        
*
***                                           
   
	SeleDados(cOpc)  
	
	oBrowSUS:SetArray(aBrowSUS)
	oBrowSUS:Refresh()		

Return()  
      
         
User Function LegenSUS()
****************************************************************************************
* Legenda de Cores:
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
*	B=De Proposta Cancelada
****	

	Local aLegenda 	:= {{"BR_VERDE" 	, OemToAnsi("Cliente Sem Contato"  		)},;		// 1
						{"BR_MARROM"   	, OemToAnsi("Cliente Sem Agendamento"	)},; 		// 8		                 		                                                          		 
						{"BR_AMARELO" 	, OemToAnsi("Cliente Agendado" 	   		)},;        // 2
						{"BR_PINK"    	, OemToAnsi("Cliente Em Proposta"  		)},;  		// 7				
						{"BR_VERMELHO"  , OemToAnsi("Cliente Atendido"	   		)},;        // 3
						{"BR_AZUL" 		, OemToAnsi("Cliente Ativo" 	   		)},;        // 4
						{"BR_LARANJA"   , OemToAnsi("Cliente Inativo"	   		)},;        // 5
						{"BR_BRANCO" 	, OemToAnsi("Cliente Interesse Futuro"  )},;        // 6 
						{"BR_VIOLETA" 	, OemToAnsi("Cliente Proposta Cancelada")},;        // B
						{"BR_PRETO"    	, OemToAnsi("Cliente Substituído"  		)},;    	// A					
						{"BR_CANCEL" 	, OemToAnsi("Cliente Inapto"  	   		)}}         // 9
						  
	BrwLegenda("Classificação do Potencial","Legendas do Cliente Potencial", aLegenda)										
	
Return()      