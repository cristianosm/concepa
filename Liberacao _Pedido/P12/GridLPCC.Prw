#Include "totvs.ch"

//------------------------------------------------------------------
//Exemplo de configuração de TGrid em array com navegação por linha
//------------------------------------------------------------------
#define GRID_MOVEUP       0
#define GRID_MOVEDOWN     1
#define GRID_MOVEHOME     2
#define GRID_MOVEEND      3
#define GRID_MOVEPAGEUP   4
#define GRID_MOVEPAGEDOWN 5

#Define P_LIN 1 //| Posicao da Linha Inicial 
#Define P_COL 2 //| Posicao da Coluna Inicial
#Define P_WID 3 //| Comprimento do Grid
#Define P_HEI 4 //| Altura do Grid

#Define NPPC 08 //| Numero de Pixel por Caracter 

//#Define CONTROL_ALIGN_LEFT 	 -1
#Define CONTROL_ALIGN_CENTER  0
//#Define CONTROL_ALIGN_RIGHT   1

// GridLPCC ( Classe para encapsular acesso ao componente TGrid )
//------------------------------------------------------------------------------          
*******************************************************************************
Class GridLPCC
*******************************************************************************
	
	Data oGrid
	Data oFrame
	Data oButtonsFrame		//| Barra Lateral para incluir os Botoes
	Data oButtonHome		//| Botao ir ao Inicio do Grid
	Data oButtonPgUp		//| Botao Subir uma pagina no Grid
	Data oButtonUp			//| Botao subir um registro no Grid
	Data oButtonDown		//| Botao descer um registro no Grid
	Data oButtonPgDown		//| Botao descer uma pagina no Grid
	Data oButtonEnd			//| Botao ir ao Final do Grid
	Data aData				//| Array contendo Colunas do Grid
	Data nLenData			//| Numero Total de Linhas do Grid
	Data nRecNo				//| Armazena o registro do grid posicionado
	Data nCursorPos
	Data nVisibleRows		//| Define o Numero de linhas visíveis no Grid.
	Data nFreeze
	Data nHScroll

	Method New(oDlg, aHeader, aData, aPos, aTCol) Constructor 
	Method onMove( o,nMvType,nCurPos,nOffSet,nVisRows )
	Method isBof()			//| Verifica se esta no Primeiro Registro
	Method isEof()			//| Verifica se esta no Ultimo Registro
	Method ShowData( nFirstRec, nCount ) 
	
	Method SelectRow(n)		//| Posiciona na linha selecionada do objeto.
	
	Method ClearRows()
	
	Method GoHome()
	Method GoEnd()
	Method GoPgUp()
	Method GoPgDown()
	Method GoUp(nOffSet)
	Method GoDown(nOffSet)

EndClass
*******************************************************************************
Method New(oDlg, aHeader, aData, aPos, aTCol) Class GridLPCC
*******************************************************************************
	Local oFont	:= Nil
	Local nC	:= 0
	
	::oFrame		:= tPanel():New(aPos[P_LIN],aPos[P_COL],,oDlg,,,,,,aPos[P_WID],aPos[P_HEI] )
	::nRecNo		:= 1
	::nCursorPos	:= 0
	::nVisibleRows 	:= 23		//| Define o Numero de linhas visíveis no Grid.

	::aData			:= aData
	::nLenData		:= Len(aData)
	
	::oGrid			:= TGrid():New( ::oFrame,aPos[P_LIN],aPos[P_COL],aPos[P_WID],aPos[P_HEI]) // Criacao do GRID
	
	::oGrid:Align	:= CONTROL_ALIGN_ALLCLIENT //| Indica o alinhamento do texto na coluna.

	oFont := TFont():New('Arial',,16,.T.)
	::oGrid:SetFont(oFont)
	
	// Define o a Altura da Linha do Grid
	::oGrid:setRowHeight(20)

	// Criacao e Definicao da Barra Lateral para receber botoes de Controle... 
	::oButtonsFrame			:= tPanel():New(0,0,, ::oFrame,,,,,, 10,aPos[P_HEI],.F.,.T. )
	::oButtonsFrame:Align 	:= CONTROL_ALIGN_RIGHT
	
	// Criacao e Definicao do Botao da  Lateral para ... 
	::oButtonHome			:= tBtnBmp():NewBar( "VCTOP.BMP"	,,,,, {||::GoHome()}	,,::oButtonsFrame )
	::oButtonHome:Align		:= CONTROL_ALIGN_TOP
	
	// Criacao e Definicao do Botao da  Lateral para ... 
	::oButtonPgUp			:= tBtnBmp():NewBar( "VCPGUP.BMP"	,,,,, {||::GoPgUp()}	,,::oButtonsFrame )
	::oButtonPgUp:Align		:= CONTROL_ALIGN_TOP
	
	// Criacao e Definicao do Botao da  Lateral para ... 
	::oButtonUp				:= tBtnBmp():NewBar( "VCUP.BMP"		,,,,,{||::GoUp(1)}		,,::oButtonsFrame )
	::oButtonUp:Align		:= CONTROL_ALIGN_TOP
	
	// Criacao e Definicao do Botao da  Lateral para ... 
	::oButtonEnd			:= tBtnBmp():NewBar( "VCBOTTOM.BMP"	,,,,, {||::GoEnd()}		,,::oButtonsFrame )
	::oButtonEnd:Align		:= CONTROL_ALIGN_BOTTOM
	
	// Criacao e Definicao do Botao da  Lateral para ... 
	::oButtonPgDown			:= tBtnBmp():NewBar( "VCPGDOWN.BMP"	,,,,, {||::GoPgDown()}	,,::oButtonsFrame )
	::oButtonPgDown:Align	:= CONTROL_ALIGN_BOTTOM
	
	// Criacao e Definicao do Botao da  Lateral para ... 
	::oButtonDown			:= tBtnBmp():NewBar( "VCDOWN.BMP"	,,,,, {||::GoDown(1)}	,,::oButtonsFrame )
	::oButtonDown:Align		:= CONTROL_ALIGN_BOTTOM
	
	// Adiciona colunas no objeto.
	For nC := 1 To len(aHeader)
		If nC == 1 .Or. nC == 5 
			::oGrid:addColumn( nC, aHeader[nC] , aTCol[nC] * 11 , CONTROL_ALIGN_CENTER ) // Especifico para o Item
		ElseIf nC == 2 .Or. nC == 3 .or. nC == 8 .Or. nC == 9
			::oGrid:addColumn( nC, aHeader[nC] , Round(aTCol[nC] * 7.8,0) , CONTROL_ALIGN_LEFT   )
		ElseIf nC == 4 .Or. nC == 6 .Or. nC == 7
			::oGrid:addColumn( nC, aHeader[nC] , aTCol[nC] * NPPC , CONTROL_ALIGN_RIGHT  )
		Else
			::oGrid:addColumn( nC, aHeader[nC] , aTCol[nC] * NPPC , CONTROL_ALIGN_CENTER )
		EndIf
	Next
	
	// Configura o Movimento do Scroll do Mause 
	::oGrid:bCursorMove:= {|o,nMvType,nCurPos,nOffSet,nVisRows| ::onMove(o,nMvType,nCurPos,nOffSet,nVisRows) }
	
	//| Confgura os dados que serão apresentados em determinada linha do objeto.
	::ShowData(1)
	
	::SelectRow( ::nCursorPos )
	// configura acionamento do duplo clique
	::oGrid:bLDblClick:= {|| MsgStop("oi") }

Return
*******************************************************************************
Method isBof() Class GridLPCC
*******************************************************************************
Return  ( ::nRecno==1 )
*******************************************************************************
Method isEof() Class GridLPCC
*******************************************************************************
Return ( ::nRecno == ::nLenData )
*******************************************************************************
Method GoHome() Class GridLPCC
*******************************************************************************
	if ::isBof()
		Return
	EndIf
	::nRecno = 1
	::oGrid:ClearRows()
	::ShowData( 1, ::nVisibleRows )
	::nCursorPos:= 0
	::SelectRow( ::nCursorPos )
	
Return
*******************************************************************************
Method GoEnd() Class GridLPCC
*******************************************************************************
	if ::isEof()
		Return
	EndIf

	::nRecno := ::nLenData
	::oGrid:ClearRows()
	::ShowData( ::nRecno - ::nVisibleRows + 1, ::nVisibleRows )
	::nCursorPos:= ::nVisibleRows - 1
	::SelectRow( ::nCursorPos )
	
Return
*******************************************************************************
Method GoPgUp() Class GridLPCC
*******************************************************************************
	if ::isBof()
		Return
	EndIf

	// força antes ir para a 1a linha da grid
	if ::nCursorPos != 0
		::nRecno -= ::nCursorPos
		if ::nRecno <= 0
			::nRecno:=1
		EndIf
		::nCursorPos := 0
		//::oGrid:setRowData( ::nCursorPos, {|o| { ::aData[::nRecno,1], ::aData[::nRecno,2], ::aData[::nRecno,3] } } )
		
		::oGrid:setRowData( ::nCursorPos, {|o| {::aData[::nRecno][01],;
												::aData[::nRecno][02],; 
												::aData[::nRecno][03],; 
												::aData[::nRecno][04],; 
												::aData[::nRecno][05],; 
												::aData[::nRecno][06],; 
												::aData[::nRecno][07],; 
												::aData[::nRecno][08],; 
												::aData[::nRecno][09],; 
												::aData[::nRecno][10] } } )
	else
		::nRecno -= ::nVisibleRows
		if ::nRecno <= 0
			::nRecno:=1
		EndIf
		::oGrid:ClearRows()
		::ShowData( ::nRecno, ::nVisibleRows )
		::nCursorPos:= 0
	EndIf
	::SelectRow( ::nCursorPos )
	
Return
*******************************************************************************
Method GoPgDown() Class GridLPCC
*******************************************************************************
	Local nLastVisRow

	if ::isEof()
		Return
	EndIf

	// força antes ir para a última linha da grid
	nLastVisRow:= ::nVisibleRows-1

	if ::nCursorPos!=nLastVisRow

		if ::nRecno+nLastVisRow > ::nLenData
			nLastVisRow:= ( ::nRecno+nLastVisRow ) - ::nLenData
			::nRecno:= ::nLenData
		else
			::nRecNo += nLastVisRow
		EndIf

		::nCursorPos:= nLastVisRow
		::ShowData( ::nRecNo - ::nVisibleRows + 1, ::nVisibleRows )
	else
		::oGrid:ClearRows()
		::nRecno += ::nVisibleRows

		if ::nRecno > ::nLenData
			::nVisibleRows = ::nRecno-::nLenData
			::nRecno:= ::nLenData
		EndIf

		::ShowData( ::nRecNo - ::nVisibleRows + 1, ::nVisibleRows )
		::nCursorPos:= ::nVisibleRows-1
	EndIf

	::SelectRow( ::nCursorPos )
	
Return
*******************************************************************************
Method GoUp(nOffSet) Class GridLPCC
*******************************************************************************
	Local lAdjustCursor:= .F.
	if ::isBof()
		Return
	EndIf
	if ::nCursorPos==0
		::oGrid:scrollLine(-1)
		lAdjustCursor:= .T.
	else
		::nCursorPos -= nOffSet
	EndIf
	::nRecno -= nOffSet

	// atualiza linha corrente

	::oGrid:setRowData( ::nCursorPos, {|o| {::aData[::nRecno][01],;
											::aData[::nRecno][02],; 
											::aData[::nRecno][03],; 
											::aData[::nRecno][04],; 
											::aData[::nRecno][05],; 
											::aData[::nRecno][06],; 
											::aData[::nRecno][07],; 
											::aData[::nRecno][08],; 
											::aData[::nRecno][09],; 
											::aData[::nRecno][10] } } )
	if lAdjustCursor
		::nCursorPos:= 0
	EndIf
	::SelectRow( ::nCursorPos )
	
Return
*******************************************************************************
Method GoDown(nOffSet) Class GridLPCC
*******************************************************************************
	Local lAdjustCursor:= .F.
	if ::isEof()
		Return
	EndIf

	if ::nCursorPos==::nVisibleRows-1
		::oGrid:scrollLine(1)
		lAdjustCursor:= .T.
	else
		::nCursorPos += nOffSet
	EndIf
	::nRecno += nOffSet

	// atualiza linha corrente
	
	::oGrid:setRowData( ::nCursorPos, {|o| {::aData[::nRecno][01],;
											::aData[::nRecno][02],; 
											::aData[::nRecno][03],; 
											::aData[::nRecno][04],; 
											::aData[::nRecno][05],; 
											::aData[::nRecno][06],; 
											::aData[::nRecno][07],; 
											::aData[::nRecno][08],; 
											::aData[::nRecno][09],; 
											::aData[::nRecno][10] } } )
	if lAdjustCursor
		::nCursorPos:= ::nVisibleRows-1
	EndIf
	::SelectRow( ::nCursorPos )
	
Return
*******************************************************************************
Method onMove( oGrid,nMvType,nCurPos,nOffSet,nVisRows ) Class GridLPCC
*******************************************************************************
	::nCursorPos	:= nCurPos
	::nVisibleRows	:= nVisRows

	if nMvType == GRID_MOVEUP
		::GoUp(nOffSet)
	ElseIf nMvType == GRID_MOVEDOWN
		::GoDown(nOffSet)
	ElseIf nMvType == GRID_MOVEHOME
		::GoHome()
	ElseIf nMvType == GRID_MOVEEND
		::GoEnd()
	ElseIf nMvType == GRID_MOVEPAGEUP
		::GoPgUp()
	ElseIf nMvType == GRID_MOVEPAGEDOWN
		::GoPgDown()
	EndIf
	
Return
*******************************************************************************
Method ShowData( nFirstRec, nCount ) Class GridLPCC
*******************************************************************************
	Local  i, nRec, ci
	Default nCount:=30

	for i := 0 to ( nCount - 1 )
		nRec := nFirstRec + i
		if nRec > ::nLenData
			Return
		EndIf
		ci := cValToChar( nRec )
		//cb:= "{|o| { Self:aData["+ci+",1], Self:aData["+ci+",2], Self:aData["+ci+",3] } }"
		
		//SetRowData ( < nRow>, < bData> ) : Confgura os dados que serão apresentados em determinada linha do objeto.
		::oGrid:setRowData( i, {|o| { 	Self:aData[&ci][01],; 
										Self:aData[&ci][02],; 
										Self:aData[&ci][03],; 
										Self:aData[&ci][04],; 
										Self:aData[&ci][05],; 
										Self:aData[&ci][06],; 
										Self:aData[&ci][07],; 
										Self:aData[&ci][08],; 
										Self:aData[&ci][09],; 	
										Self:aData[&ci][10] } } )

	Next i
Return
*******************************************************************************
Method ClearRows() Class GridLPCC
*******************************************************************************

	::oGrid:ClearRows()
	::nRecNo := 1
	
Return
*******************************************************************************
Method SelectRow(n) Class GridLPCC //| Posiciona na linha selecionada do objeto para apresentar os dados 
*******************************************************************************

	valor := n - ::nCursorPos
	::nRecno += valor
	if ::nRecno <= 0
		::nRecno = 1
	EndIf
	::nCursorPos := n
	::oGrid:setSelectedRow(n) 
	
Return