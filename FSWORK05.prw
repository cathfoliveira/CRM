#Include 'Protheus.ch'
#Include "rwmake.ch"      
#Include "TopConn.ch"

/*
+-----------+------------+----------------+-------------------+-------+---------------+
| Programa  | FSWORK05   | Desenvolvedor  | Catharina Oliveira| Data  | 14.07.2016    |       
+-----------+------------+----------------+-------------------+-------+---------------+
| Descricao | Função para Marcar ou Desmarcar todas as opções de um vetor MarkBrowse. |
+-----------+-------------------------------------------------------------------------+
|   USO     | Usado no Relatórios de Resultado Financeiro e Despesas x Provisão.      |
+-----------+-------------------------------------------------------------------------+
| Modulos   | SIGAFIN                                                                 |
+-----------+-------------------------------------------------------------------------+
|           ALTERACOES FEITAS DESDE A CRIACAO                            		      |
+----------+-----------+--------------------------------------------------------------+
|Autor     | Data      | Descricao                                       			  |
+----------+-----------+--------------------------------------------------------------+
|          |           |                                                              |
+----------+-----------+--------------------------------------------------------------+
*/

User Function MarkBrow(lOpc,aBrowTmp,oBrowse,nQtd)
***********************************************************************
* Marca ou desmarca todas as opções do array passado como REFERÊNCIA.
* 
*****

	Local nX :=1                 
	Local nMarca:= 0
	Local cLine := ""
	Local oNoMarked  := LoadBitmap( GetResources(), "LBNO" )       	
	Local oMarked    := LoadBitmap( GetResources(), "LBOK" )   
	Local aAreaPr 	 := GetArea()
	
	Default nQtd := -1
	
	If Empty(aBrowTmp)
		Return
	EndIf
	
	// Desmarca todos
	If nQtd == 0
		lOpc := .F.
		nMarca := Len(aBrowTmp)		
	ElseIf nQtd > 0 .And. nQtd < Len(aBrowTmp)

		For nX:=1 to Len(aBrowTmp)
		    aBrowTmp[nX,01] :=.F.
		Next nX	
 		nMarca := nQtd
 	Else
	 	nMarca := Len(aBrowTmp)
	EndIf
	
	For nX:=1 to nMarca //Len(aBrowTmp)
	    aBrowTmp[nX,01] :=lOpc
	Next nX
	
	oBrowse:SetArray(aBrowTmp)

   	cLine	:= " {||{If(aBrowTmp[oBrowse:nAt,01],oMarked,oNoMarked),"		
		
   	For nX:= 2 To Len(aBrowTmp[1])
  		cLine += "aBrowTmp[oBrowse:nAt,"+AllTrim(Str(nX))+"],"   
  	Next nX 
  	
  	cLine := Substr(cLine,1,Len(cLine)-1)+"}}"  

    oBrowse:bLine := &cLine 

	oBrowse:Refresh()   							
	
	RestArea(aAreaPr)
Return