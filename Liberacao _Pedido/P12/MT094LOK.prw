#Include 'Totvs.ch' 

#Define CRLF Chr(13)+Chr(10) // Enter

#Define P_SALDO 1 //|Posicao do Saldo
#Define P_MOEDA 2 //| Posicao da Moeda
#Define P_DTSLD 3 //| Posicao Data do Saldo

// Status da Liberacao
#Define SL_AGUARDANDO "01" // Aguardando nivel anterior
#Define SL_PENDENTE	  "02" // Pendente
#Define SL_LIBERADO   "03" // Liberado
#Define SL_BLOQUEADO  "04" // Bloqueado
#Define SL_LIBOUTROU  "05" // Liberado por outro Usuario
#Define SL_REJEITADO  "06" // Rejeitado

// Posicoes Pedido
#Define _ITE_	1 // Item
#Define _COD_	2 // Codigo
#Define _DES_	3 // Descricao
#Define _QTD_	4 // Quantidade
#Define _VUN_	5 // Valor Unitario
#Define _VTO_	6 // Valot Total 
#Define _DTE_	7 // Data de Entrega

// Comandos Aprovador 
#Define LIBERAR 	2
#Define BLOQUEAR 	3

// Alinhamento Textos 
#Define CONTROL_ALIGN_LEFT 	 -1
#Define CONTROL_ALIGN_CENTER  0
#Define CONTROL_ALIGN_RIGHT   1

// Mascara para Numeros
#Define MASCARA "@E 9,999,999.99"

/*****************************************************************************\
**---------------------------------------------------------------------------**
** Ponto Entrada: MT094LOK  | AUTOR : Cristiano Machado | DATA : 15/01/2018  **
**---------------------------------------------------------------------------**
** DESCRIÇÃO: Function A097LIBERA - Função da Dialog de liberação e bloqueio **
**            dos documentos com alçada.                                     **
**---------------------------------------------------------------------------**
** QUE PONTO: O ponto se encontra no inicio da função A097LIBERA antes da    **
**            criação da dialog de liberação e bloqueio, pode ser utilizado  **
**            para validar se a operação deve continuar ou não conforme seu  **
**            retorno, ou ainda pode ser usado para substituir o programa de **
**            liberação por um especifico do usuario.                        **
**---------------------------------------------------------------------------**
** RETORNO  : Logico : .T. Continua a liberacao ou .F. retorna ao browse.   **
**---------------------------------------------------------------------------**
** USO      : Especifico para Concepa, Substituicao Liberacao de Compras     **
**---------------------------------------------------------------------------**
**---------------------------------------------------------------------------**
** ATUALIZACOES SOFRIDAS DESDE A CONSTRUCAO INICIAL.                         **
**---------------------------------------------------------------------------**
** PROGRAMADOR | DATA | MOTIVO DA ALTERACAO                                  **
**---------------------------------------------------------------------------**
**             |      |                                                      **
**             |      |                                                      **
\*---------------------------------------------------------------------------*/
*******************************************************************************
User Function MT094LOK()
*******************************************************************************

	
	//| Funcao para Declarar Variaveis Necessarias
	DecVar()

	//| Selecionar e Ordenar Tabelas Envolvidas
	TabSel()
	
	//| Posiciona as Tabelas Envolvidas
	PosReg()

	//| Funcao para Alimentar as Variaveis
	GetVar()

	//| Validações
	If ValLib()

		TelaLib() //|  Monta a Leta de Liberaçào
		
	EndIf

	//| Restaura o Ambiente
	ResEnv()

	Return ( lContinua  )
*******************************************************************************
Static Function DecVar() //| Deeclaracao das Variaveis utilizadas 
*******************************************************************************

	_SetOwnerPrvt( 'aGetATU'	, {}  ) //| Salva Area Atual
	_SetOwnerPrvt( 'aGetSC7'	, {}  ) //| Salva Area SC7
	_SetOwnerPrvt( 'aGetSCR'	, {}  ) //| Salva Area SCR
	_SetOwnerPrvt( 'aGetSAK'	, {}  ) //| Salva Area SAK
	_SetOwnerPrvt( 'aGetSAL'	, {}  ) //| Salva Area SAL

	_SetOwnerPrvt( 'cCR_NUM'	, Substr(SCR->CR_NUM,1,Len(SC7->C7_NUM))  ) //| Documento a ser Liberado
	_SetOwnerPrvt( 'cCR_FORNECE', ""  ) //| Codigo do Fornecedor
	
	_SetOwnerPrvt( 'cCR_TIPO'	, ""  ) //| Tipo do Documento
	_SetOwnerPrvt( 'cCR_APROV'	, SCR->CR_APROV  ) //| Codigo do Aprovador
	_SetOwnerPrvt( 'cCR_GRUPO'	, ""  ) //| Grupo de Aprovacao
	_SetOwnerPrvt( 'cCR_APRORI'	, ""  ) //| Codigo Aprovador Origem
	_SetOwnerPrvt( 'cCR_EMISSAO', ""  ) //| Data de emissao
	_SetOwnerPrvt( 'cCR_OBS'	, ""  ) //| Obsevacoes da Aprovacao
	_SetOwnerPrvt( 'cCR_TOTAL'	, ""  ) //| Valor Total Com Mascara
	_SetOwnerPrvt( 'nCR_TOTAL'	, ""  ) //| Valor Total Numerico
	
	_SetOwnerPrvt( 'cAK_APROSUP', ""  ) // Aprovador Superior
	_SetOwnerPrvt( 'cAK_Nome'	, ""  ) // Nome do Aprovador 

	_SetOwnerPrvt( 'cCUserLog'	, RetCodUsr()  ) // Usuario Logado 
	_SetOwnerPrvt( 'cCUserName'	, UsrRetName(cCUserLog)  ) // Nome do Usuario Logado 

	_SetOwnerPrvt( 'dDataRef'	, '' ) //| Data atual

	_SetOwnerPrvt( 'aRetSaldo'	, {} ) //| Retorna o saldo do aprovador.   Return {nSaldo,nMoeda,dDtSaldo}
	_SetOwnerPrvt( 'nSldDisp'	, 0  ) //| Armazena o saldo disponivel para liberacao ja contando  o documento a ser liberado

	_SetOwnerPrvt( 'lContinua'	, .F. ) //| Define se Substitui Liberação Padrao

	 aGetATU	:= GetArea()
	 aGetSC7 	:= SC7->( GetArea() )
	 aGetSCR 	:= SCR->( GetArea() )
	 aGetSAK 	:= SAL->( GetArea() )
	 aGetSAL 	:= SAL->( GetArea() )

	Return Nil
*******************************************************************************
Static Function GetVar() //| Funcao para Alimentar as Variaveis
*******************************************************************************

	cCR_FORNECE := SC7->(Posicione("SA2",1,xFilial("SA2")+SC7->C7_FORNECE+SC7->C7_LOJA ,"A2_NOME"))
	cCR_EMISSAO := DtoC(SCR->CR_EMISSAO)
	cCR_GRUPO	:= GetUpdGrp(SCR->CR_GRUPO)
	cCR_APRORI  := SCR->CR_APRORI
	cCR_TIPO	:= SCR->CR_TIPO
	cCR_OBS		:= IIF(!Empty(SCR->CR_OBS),SCR->CR_OBS,CriaVar("CR_OBS"))
	cCR_OBS 	:= Alltrim(cCR_OBS) + Replicate( " " , 1000 - Len( Alltrim(cCR_OBS) ) )
	
	dDataRef 	:= dDataBase

	aRetSaldo   := MaSalAlc(cCR_APROV,dDataRef)

	nCR_TOTAL 	:= xMoeda(SCR->CR_TOTAL, SCR->CR_MOEDA, aRetSaldo[P_MOEDA], SCR->CR_EMISSAO, , SCR->CR_TXMOEDA)

	cCR_TOTAL   := Transform( nCR_TOTAL , MASCARA ) 
	
	cAK_Nome	:= cCR_APROV + " - " + SAK->AK_NOME
	
	nSldDisp 	:= aRetSaldo[P_SALDO] - IIF(SAL->AL_LIBAPR != "A",0,nCR_TOTAL)

	Return Nil
*******************************************************************************
Static Function GetUpdGrp(cCR_GRUPO) // Se o Grupo estiver em Branco Preenche e o Retorna
*******************************************************************************
	Local cSql 		:= ""
	Local cC7_APROV := SC7->(Posicione( "SC7", 1, xFilial("SC7")+cCR_NUM, "C7_APROV" ) )

	If Empty(cCR_GRUPO) 
	
		cSql += " UPDATE " + RetSqlname("SCR")		
		cSql += " SET CR_GRUPO = "+"'"+cC7_APROV+"'"
		cSql += " WHERE CR_FILIAL ='"+xFilial("SCR")+"' AND "
		cSql += " CR_NUM ='"+cCR_NUM+"' AND "
		cSql += " D_E_L_E_T_ = ' ' "  	 
	
		U_ExecMySql( cSql, cCursor := "", lModo := "E", lMostra := .F., lChange := .F. )
	
		cCR_GRUPO := C7_APROV
			
	Endif
	
Return cCR_GRUPO	
*******************************************************************************
Static Function TabSel()  //| Selecionar e Ordenar Tabelas Envolvidas
*******************************************************************************

	DbSelectarea("SCR") //| Documentos com Alcada
	DbSetOrder(1) //CR_FILIAL+CR_TIPO+CR_NUM+CR_NIVEL

	DbSelectArea("SC7")  //| Ped.Compra / Aut.Entrega
	DbSetOrder(1) //| C7_FILIAL+C7_NUM+C7_ITEM+C7_SEQUEN

	DbSelectArea("SAK") //| Aprovadores
	DbSetOrder(1) //| AK_FILIAL+AK_COD

	DbSelectArea("SAL")  //| Grupos de Aprovacao
	DbSetOrder(3) //| AL_FILIAL+AL_COD+AL_APROV
	
	Dbselectarea("SZG")
    Dbsetorder(1)

	Return Nil
*******************************************************************************
Static Function PosReg() //| Posiciona as Tabelas Envolvidas
*******************************************************************************

	DbSelectArea("SC7")
	MsSeek(xFilial("SC7")+cCR_NUM)

	DbSelectArea("SAK")
	dbSeek(xFilial("SAK")+cCR_APROV)

	DbSelectArea("SAL")
	MsSeek(xFilial("SAL")+SC7->C7_APROV+SAK->AK_COD)
	
	DbSelectArea("SZG")
	Dbseek( xFilial("SZG") + SC7->C7_CTAGER, .F.)

	Return Nil
*******************************************************************************
Static Function ValLib() //| Validações para Ocorrer a Liberação...
*******************************************************************************
	Local lValido 	:= .T.
	Local lOGpaAprv := SuperGetMv("MV_OGPAPRV",.F.,.F.) // Obrigatorio Aprovador existir no Grupo Aprovacao para efetuar a liberacao de documentos    ?

	Local cMen001 := "O Aprovador nao foi encontrado no Grupo de Aprovacao deste Documeto, verifique . Se Necessario inclua novamente o Aprovador no Grupo..."
	Local cMen002 := "Este pedido ja foi liberado anteriormente. Somente os pedidos que estao aguardando liberacao (destacado em vermelho no Browse) poderao ser liberados."
	Local cMen003 := "Esta operacao nao pode ser realizada, pois este registro se encontra bloqueado pelo sistema (aguardando outros niveis)"
	Local cMen004 := "Saldo na data insuficiente para efetuar a liberacao do pedido. Verifique o saldo disponivel para aprovacao na data e o valor total do pedido."
	Local cMen005 := "Esta operacao nao pode ser realizada, pois o Pedido de Compras correspondente não foi localizado."
	Local cMen006 := "Esta operacao nao pode ser realizada, pois este registro se encontra bloqueado por outro Usuário. (Tente mais tarde)"
	Local cMen007 := "Esta operação não poderá ser realizada pois o usuário aprovador não confere com o registro selecionado. Selecione o registro correspondente ao usuário aprovador"	
	
	DbSelectArea("SCR")
	If lValido .And. !Empty(SCR->CR_DATALIB) .And. ( SCR->CR_STATUS = SL_LIBERADO .Or. SCR->CR_STATUS ==  SL_LIBOUTROU )
		Aviso("VAL002", cMen002 + CRLF + " Documento: " + cCR_NUM,{"Ok"})
		lValido := .F.
	EndIf

	If lValido .And. SCR->CR_STATUS == SL_AGUARDANDO
		Aviso("VAL003", cMen003 + CRLF + " Documento: "+ cCR_NUM,{"Ok"})
		lValido := .F.
	EndIf

	DbSelectArea("SAL")
	If !MsSeek(xFilial("SAL")+cCR_GRUPO+cCR_APROV) .And. !MsSeek(xFilial("SAL")+cCR_GRUPO+cCR_APRORI) .And. lOGpaAprv
		Aviso("VAL001", cMen001 + CRLF + " Grupo: "+ cCR_GRUPO,{"Ok"})
		lValido := .F.
	EndIf

	If lValido .And. nSldDisp < 0
		Aviso("VAL004", cMen004 + CRLF + " Saldo Disponivel: " + cValToChar(nSldDisp) ,{"Ok"})
		lValido := .F.
	EndIf

	//Verifica se o pedido de compra existe 
	//If lValido .And. !(Posicione( "SC7", 1, xFilial("SC7")+cCR_NUM,"C7_NUM" ) == cCR_NUM)
	If lValido .And. !( Alltrim(SC7->C7_NUM) == Alltrim(cCR_NUM) )
		Aviso("VAL005", cMen005 + CRLF + " Pedido: " + cCR_NUM,{"Ok"})
		lValido := .F.
	EndIf
	
	If lValido .And. !VerLock(cCR_NUM, cCR_TIPO) //Verifica se o pedido de compra nao esta com lock
		Aviso("VAL006", cMen006 + CRLF + " Pedido: " + cCR_NUM,{"Ok"})
		lValido := .F.
	EndIf

	If lValido .And. AllTrim(SCR->CR_USER) != AllTrim(cCUserLog)
		Aviso("VAL007", cMen007, {"Ok"} )
		lValido := .F.
	EndIf

	Return lValido
*******************************************************************************
Static Function VerLock(cCR_NUM,cTipo) //| Verifica se o pedido de compra nao esta com lock (Codigo do Documento , Tipo de Documento "PC->Pedido de Compras")
*******************************************************************************
	Local cNumPed 	:= ""
	Local lRet 		:= .F.

	aArea := SC7->(GetArea())
	DbSelectArea("SC7")
	If MsSeek(xFilial("SC7")+cCR_NUM)
		cNumPed := Substr(SC7->C7_NUM,1,len(SC7->C7_NUM))
		While !Eof() .And. SC7->C7_FILIAL + cNumPed == xFilial("SC7") + cCR_NUM
			If RecLock("SC7")
				lRet := .T.
			Else
				lRet := .F.
				Exit
			Endif
			dbSkip()
		EndDo
	EndIf

	RestArea(aArea)

	Return lRet
*******************************************************************************
Static Function ResEnv()// Restaura o Ambiente
*******************************************************************************

	SC7->(MsUnlockAll())
	RestArea(aGetSC7)
	RestArea(aGetSCR)
	RestArea(aGetSAK)
	RestArea(aGetSAL)
	RestArea(aGetATU)

Return Nil
*******************************************************************************
Static Function TelaLib() //|  Monta a Leta de Liberaçào
*******************************************************************************

  	Local oDlg		:= Nil
    Local oGrid		:= Nil
    Local oGrouB	:= Nil
    Local oGrouC	:= Nil
    
    Local oTGDocto 	:= Nil
    Local oTGEmiss 	:= Nil
    Local oTGForne 	:= Nil
    Local oTGAprov 	:= Nil
    Local oTGDataR 	:= Nil
    Local oTGObser	:= Nil
    Local oTGVlTot	:= Nil
   
    Local aPos 	:= {075,05,568,246}			//| Acols Posicao do Grid (Lin, Col, Comp, Altura)
    Local aTCol := {0,0,0,0,0,0,0,0,0,0}	//| Acols contendo Largura das Colunas
       
    Local aHeader 	:= {}
    Local aCols		:= {}
  
    GetAHeader( @aHeader, @aTCol ) 	//| Monta o AHeader
    GetAcols( 	@aCols,	 @aTCol )	//| Monta o ACols
     
    oFontG := TFont():New('Calibri',,18,.T.,lBolt := .F.) // Fonte para uso no Get
    oFontS := TFont():New('Calibri',,12,.T.,lBolt := .T.) // Fonte para uso no Say
	
	// Objetos Visuais  	
	oDlg 	:= TDialog():New(050,050,700,1200,'Liberação de Documento',,,,,CLR_BLACK,CLR_WHITE,,,.T.,,,,,,)
    
    oGrouC	:= TGroup():New(005,005,070,500,'',oDlg,,,.T.)
    oGrouB	:= TGroup():New(005,505,070,571,'',oDlg,,,.T.)
    
    MTGet( @oTGDocto, 010, 010, @cCR_NUM		, 'cCR_NUM'		, oDlg, 060, 015, oFontG, "Número do Dcto : "	, oFontS, .T. , CONTROL_ALIGN_CENTER , "@!" 	)
    MTGet( @oTGAprov, 010, 140, @cAK_Nome		, 'cAK_Nome'	, oDlg, 201, 015, oFontG, "Aprovador : "		, oFontS, .T. , CONTROL_ALIGN_LEFT   , "@!" 	)
    MTGet( @oTGVlTot, 010, 390, @cCR_TOTAL		, 'cCR_TOTAL'	, oDlg, 065, 015, oFontG, "Total Dcto : "		, oFontS, .T. , CONTROL_ALIGN_RIGHT  , ''	 	)
    
    MTGet( @oTGEmiss, 030, 010, @cCR_EMISSAO	, 'cCR_EMISSAO'	, oDlg, 090, 015, oFontG, "Emissão : "			, oFontS, .T. , CONTROL_ALIGN_CENTER , "" 		)
    MTGet( @oTGForne, 030, 140, @cCR_FORNECE	, 'cCR_FORNECE'	, oDlg, 200, 015, oFontG, "Fornecedor : "		, oFontS, .T. , CONTROL_ALIGN_LEFT   , "@!" 	)
    MTGet( @oTGDataR, 030, 390, @dDataRef		, 'dDataRef'	, oDlg, 064, 015, oFontG, "Data Refer : "		, oFontS, .F. , CONTROL_ALIGN_CENTER , ""  		)
    
    MTGet( @oTGObser, 050, 010, @cCR_OBS		, 'cCR_OBS'		, oDlg, 440, 015, oFontG, "Observação : "		, oFontS, .F. , CONTROL_ALIGN_LEFT   , "" 		)
     
    oTBApro := TButton():New( 010, 513, "Aprovar"  ,oDlg,{|| LibBloq(LIBERAR) , oDlg:End()	} , 50,15,,,.F.,.T.,.F.,,.F.,,,.F. )   
    oTBBloq := TButton():New( 030, 513, "Bloquear" ,oDlg,{|| LibBloq(BLOQUEAR), oDlg:End()	}, 50,15,,,.F.,.T.,.F.,,.F.,,,.F. )   
    oTBCanc := TButton():New( 050, 513, "Cancelar" ,oDlg,{|| oDlg:End()						}, 50,15,,,.F.,.T.,.F.,,.F.,,,.F. )
    
    oGrid  	:= GridLPCC():New(oDlg,aHeader,aCols,aPos,aTCol)
        
    oDlg:Activate(,,,.T.,{||},,{||} )
       
Return
*******************************************************************************
Static Function GetAHeader(aHeader, aTCol) // Monta o AHeader
*******************************************************************************
	
	aTCol[01] := Len("ITEM" )  
    aTCol[02] := Len("CONTA GERENCIAL")  
    aTCol[03] := Len("CENTRO DE CUSTO")  
    aTCol[04] := Len("QUANTIDADE")  
    aTCol[05] := Len("UNI")  
    aTCol[06] := Len("PREÇO")  
    aTCol[07] := Len("TOTAL")  
    aTCol[08] := Len("DESCRIÇÃO")  
    aTCol[09] := Len("OBSERVAÇÃO")  
	
	AAdd(aHeader, "ITEM" )
	AAdd(aHeader, "CONTA GERENCIAL" )
	AAdd(aHeader, "CENTRO DE CUSTO" )
	AAdd(aHeader, "QUANTIDADE" )
	AAdd(aHeader, "UNI" )
	AAdd(aHeader, "PREÇO" )
	AAdd(aHeader, "TOTAL" )
	AAdd(aHeader, "DESCRIÇÃO" )
	AAdd(aHeader, "OBSERVAÇÃO" )
	AAdd(aHeader, " " )
	
Return Nil
*******************************************************************************
Static Function GetAcols(aCols, aTCol)// Obtem os Dados do Pedido e Alimenta o Acols
*******************************************************************************
	Local cSql := ""

	cSql += "SELECT C7_FILIAL, C7_NUM, C7_ITEM, RTrim(C7_CTAGER) + ' - ' + RTrim(ZG_DESCR) AS C7_CTAGER, RTrim(C7_CC) + ' - ' + Ltrim(RTrim(CTT_DESC01)) AS C7_CC , C7_QUANT, C7_UM, C7_PRECO, C7_TOTAL, C7_DESCRI, " 
	cSql += "Convert( Varchar(1000) , Convert( Varbinary(1000), C7_OBSPRO) ) AS C7_OBSPRO "
	
	cSql += "FROM "+RetSqlName("SC7")+" SC7 FULL JOIN "+RetSqlName("SZG")+" SZG "
	cSql += "ON  SC7.C7_CTAGER = ZG_COD "
	cSql += "AND ' '           = SZG.D_E_L_E_T_ "
	cSql += "				FULL JOIN "+RetSqlName("CTT")+" CTT "
	cSql += "ON  SC7.C7_CC = CTT_CUSTO "
	cSql += "AND ' '           = CTT.D_E_L_E_T_ "

	cSql += "WHERE SC7.D_E_L_E_T_ = ' ' " 
	cSql += "AND   SC7.C7_NUM = '"+cCR_NUM+"' " 
	cSql += "AND   SC7.C7_FILIAL = '"+xFilial("SC7")+"' " 
	
	U_ExecMySql( cSql, cCursor := "TPED" , lModo := "Q", lMostra := .F., lChange := .F. )
	
    DbSelectArea(cCursor)
    DbGoTop()
    While !EOF()
    
       cItemPC := Alltrim( TPED->C7_ITEM) 	//| Item Pedido de Compra	
       cCtaGer := Alltrim( Transform( TPED->C7_CTAGER, "@!") ) 		//| Conta Gerente
       cCenCus := Alltrim( Transform( TPED->C7_CC, "@!") ) 		//| Contro de Custo
       cQtdPed := Transform( TPED->C7_QUANT, MASCARA )	//| Quantidade
       cUniMed := Alltrim( TPED->C7_UM) 		//| Unidade de Medida
       cPrecoU := Transform( TPED->C7_PRECO, MASCARA ) 	//| Preço Unitario
       cValTot := Transform( TPED->C7_TOTAL, MASCARA ) 	//| Total 
       cDescri := Alltrim( Transform( TPED->C7_DESCRI, "@!") ) 	//| Descricao
       cObsPro := Alltrim( Transform( TPED->C7_OBSPRO, "@!") ) 	//| Observação Produto
       
 
       // Defini o Tamanho Maximo de Cada Coluna
       aTCol[01] := If( Len(cItemPC) > aTCol[01] , Len(cItemPC) , aTCol[01] ) 
       aTCol[02] := If( Len(cCtaGer) > aTCol[02] , Len(cCtaGer) , aTCol[02] ) 
       aTCol[03] := If( Len(cCenCus) > aTCol[03] , Len(cCenCus)	, aTCol[03] ) 
       aTCol[04] := If( Len(cQtdPed) > aTCol[04] , Len(cQtdPed) , aTCol[04] ) 
       aTCol[05] := If( Len(cUniMed) > aTCol[05] , Len(cUniMed) , aTCol[05] ) 
       aTCol[06] := If( Len(cPrecoU) > aTCol[06] , Len(cPrecoU)	, aTCol[06] ) 
       aTCol[07] := If( Len(cValTot) > aTCol[07] , Len(cValTot) , aTCol[07] ) 
       aTCol[08] := If( Len(cDescri) > aTCol[08] , Len(cDescri)	, aTCol[08] ) 
       aTCol[09] := If( Len(cObsPro) > aTCol[09] , Len(cObsPro)	, aTCol[09] ) 
       aTCol[10] := 2 
       
       AADD( aCols, { cItemPC, cCtaGer, cCenCus, cQtdPed, cUniMed, cPrecoU, cValTot, cDescri, cObsPro, ' ' } )
       
       DbSelectArea(cCursor)
       DbSkip()
       
      EndDo
      
      DbSelectArea(cCursor)
      DbCloseArea()

Return Nil 	

*******************************************************************************
Static Function LibBloq(nOpc) // Executa a Liberacao do Pedido ...
*******************************************************************************
	
	Local lLiberou := .F. // Define se o Pedido foi Liberado ... 


	Begin Transaction
		//nOpc := 2-> Liberar  1->Cancelar  3->Bloquear
		lLiberou := A097ProcLib(SCR->(Recno()),nOpc,nCR_TOTAL,cCR_APROV,cCR_GRUPO,cCR_OBS,dDataRef,NIL)
	End Transaction
	

	// Mensagem de Aprovacao ou Bloqueio
	If SCR->CR_STATUS == SL_LIBERADO .And. nOpc == LIBERAR 

		Iw_MsgBox( "Aprovado com Sucesso !!!", "Documento : " + cCR_NUM, "INFO"  )

		If !lLiberou //| Documento Aprovado mas Pedido Nao... Deve enviar Email para o Proximo Aprovador  
		
			NextAprov() // Verifica o Proximo Aprovador Pendente 
		
		EndIf


	ElseIf SCR->CR_STATUS == SL_BLOQUEADO .And. nOpc == BLOQUEAR

		Iw_MsgBox( "Bloqueado com Sucesso !!!", "Documento : " + cCR_NUM, "INFO"  )
	
	EndIf
	
	

Return Nil
*******************************************************************************
Static Function MTGet( _oGet, _nRow, _nCol, _bSetGet, _cVAr,  _oWnd, _nWidth, _nHeight, _oFont, _cLabelText, _oLabelFont , _lReadOnly, _nAlign, _cMasc ) 
*******************************************************************************

Local nRow				:= _nRow		//| numérico		Indica a coordenada Vertical em pixels ou caracteres.
Local nCol				:= _nCol		//| numérico		Indica a coordenada horizontal em pixels ou caracteres.
Local bSetGet			:= {|u| if( Pcount()>0, _bSetGet:=u, _bSetGet)} //{||_bSetGet}	//| bloco de código	Indica o bloco de código, no formato {|u| if( Pcount( )>0, := u, ) }, que será executado para atualizar a variável (essa variável deve ser do tipo caracter). Desta forma, se a lista for sequencial, o controle atualizará com o conteúdo do item selecionado, se for indexada, será atualizada com o valor do índice do item selecionado.
Local oWnd				:= _oWnd		//| objeto			Indica a janela ou controle visual onde o objeto será criado.
Local nWidth			:= _nWidth		//| numérico		Indica a largura em pixels do objeto.
Local nHeight			:= _nHeight		//| numérico		Indica a altura em pixels do objeto.
Local cPict				:= _cMasc 		//| caractere		Indica a máscara de formatação do conteúdo que será apresentada. Verificar Tabela de Pictures de Formatação
Local bValid			:= Nil			//| bloco de código	Indica o bloco de código de validação que será executado quando o conteúdo do objeto for modificado. Retorna verdadeiro (.T.), se o conteúdo é válido; caso contrário, falso (.F.).
Local nClrFore			:= Nil			//| numérico		Indica a cor do texto do objeto.
Local nClrBack			:= CLR_GRAY		//| numérico		Indica a cor de fundo do objeto.
Local oFont				:= _oFont		//| objeto			Indica o objeto, do tipo TFont, que será utilizado para definir as características da fonte aplicada na exibição do conteúdo do controle visual.
Local lPixel			:= .T.			//| lógico			Indica se considera as coordenadas passadas em pixels (.T.) ou caracteres (.F.).
Local bWhen				:= Nil			//| bloco de código	Indica o bloco de código que será executado quando a mudança de foco da entrada de dados no objeto criado estiver sendo realizada. Se o retorno for verdadeiro (.T.), o objeto continua habilitado; caso contrário, falso (.F.).
Local bChange			:= Nil			//| bloco de código	Indica o bloco de código que será executado quando o estado ou conteúdo do objeto é modificado pela ação sobre o controle visual.
Local lReadOnly			:= _lReadOnly	//| lógico			Indica se o objeto pode ser editado.
Local lPassword			:= .F.			//| lógico			Indica se, verdadeiro (.T.), o objeto apresentará asterisco (*) para entrada de dados de senha; caso contrário, falso (.F.).
Local cReadVar			:= _cVAr		//| caractere		Indica o nome da variável, configurada no parâmetro bSetGet, que será manipulada pelo objeto. Além disso, esse parâmetro será o retorno da função ReadVar().
Local lHasButton		:= .T.			//| lógico			Indica se, verdadeiro (.T.), o uso dos botões padrão, como calendário e calculadora.
Local lNoButton			:= .T.			//| lógico			Oculta o botão F3 (HasButton).
Local cLabelText		:= _cLabelText	//| caractere		indica o texto que será apresentado na Label.
Local nLabelPos			:=  2			//| numérico		Indica a posição da label, sendo 1=Topo e 2=Esquerda
Local oLabelFont		:= _oLabelFont	//| objeto			Indica o objeto, do tipo TFont, que será utilizado para definir as características da fonte aplicada na exibição da label.
Local nLabelColor 		:= Nil			//| numérico		Indica a cor do texto da Label.
Local cPlaceHold		:= Nil			//| caractere		Define o texto a ser utilizado como place holder, ou seja, o texto que ficará escrito em cor mais opaca quando nenhuma informação tiver sido digitada no campo. (disponível em builds superiores a 7.00.121227P)
Local lPicturePriority	:= Nil			//| lógico	Quando .T. define que a quantidade de caracteres permitidos no TGet será baseada no tamanho da máscara (Picture) definida, mesmo que isto exceda a quantidade de caracteres definida na variável bSetGet, até mesmo se ela for vazia (essa variável deve ser do tipo caracter). Além disso este parâmetro ativa o controle dos espaços em branco, não incluindo na variável bSetGet os espaços inseridos automaticamente pela Picture. Ou seja, o TGet retornará somente os espaços em branco efetivamente digitados pelo usuário ou aqueles espaços que já foram inicializados na variável bSetGet. Disponível somente a partir da build 7.00.170117A.
Local nAlign			:= _nAlign		//| Numerico 		Define o alinhamento LEFT = -1, CENTER = 0, RIGHT = 1
 
    _oGet := TGet():New(nRow,nCol,bSetGet,oWnd,nWidth,nHeight,cPict,bValid,nClrFore,nClrBack,oFont,Nil,Nil,lPixel,Nil,Nil,bWhen,Nil,Nil,bChange,lReadOnly,lPassword,Nil,cReadVar,Nil,Nil,Nil,lHasButton,lNoButton,Nil,cLabelText,nLabelPos,oLabelFont,nLabelColor,cPlaceHold,lPicturePriority)

    _oGet:SetContentAlign( nAlign )
     
Return Nil
*******************************************************************************
Static Function NextAprov() // Verifica o Proximo Aprovador Pendente e Envia o email com Pedido Pendente 
*******************************************************************************

	Local cBody 	:= ""		// Corpo da mensagem
	Local cSubject 	:= "Aprovar Pedido de Compra" // Assunto da Mensagem 
	Local cTo		:= ""		// Destinatario da Mensagem
	Local lSend		:= .F.		// Se deve ou nao enviar o email
	
	// Cores Utilizadas no CSS 
	Static Cor_Border := '#646464' // Cinza Escuro 	//| Cor das Bordas da Tabela
	Static Cor_TitTot := '#B4AABE' // Cinza 		//| Cor de Fundo do Titulo e Totais da Tabela
	Static Cor_LinImp := '#EBEBEB' // Cinza Claro 	//| Cor Utilizada nas Linhas Impares para Zebra
	Static Cor_FraCab := '#FF6E6E' // Vermelho		//| Cor Utilizada na Fresa Inicial e Cabecalho da Tabela
	
	GetPed()  // Obtem o Pedido
	
	MntBody(@cBody, @lSend) // Monta o Corpo da Mensagem  
	
	If lSend // So envia se houver itens do Pedido.... 
		GetTo(@cTo) // Verifica pra Quem vai o email 
	
		// Envia o Email 
		U_EnviaMail(cTo,'',cSubject,cBody)
	EndIf
	
Return Nil
*******************************************************************************
Static Function GetPed(cFornece)  // Obtem o Pedido
*******************************************************************************
	Local cSql := ""
	
	cSql += " SELECT C7_FILIAL, C7_NUM, C7_ITEM, C7_PRODUTO, C7_DESCRI, C7_QUANT, C7_TOTAL, C7_DATPRF, C7_PRECO, C7_CONAPRO, C7_FORNECE, C7_LOJA " 
	cSql += " FROM "+RetSqlName("SC7")+" SC7 " 
	cSql += " WHERE SC7.C7_NUM = '"+cCR_NUM+"' " 
	cSql += " AND   SC7.C7_FILIAL = '"+xFilial("SC7")+"' "
	cSql += " AND   SC7.D_E_L_E_T_ = ' ' "

	U_ExecMySql( cSql, cCursor := "TPED", lModo := "Q", lMostra := .F., lChange := .F. )

Return Nil
*******************************************************************************
Static Function MntBody(cBody, lSend) // Monta o Corpo da Mensagem  
*******************************************************************************
	Local cFornece 	:= TPED->C7_FORNECE + " - " + cCR_FORNECE 

	StartBody(@cBody) // Inicializa o Corpo do e-mail 

	ImpCab(@cBody, cCR_NUM, cFornece) //  Monta Html com Cabecalho dos itens 
	
	DbSelectArea("TPED");DbGoTop()
	While !EOF()
	
		aItem := {}
		
		AAdd( aItem, Alltrim( TPED->C7_ITEM ) )
		AAdd( aItem, Alltrim( TPED->C7_PRODUTO ) )
		AAdd( aItem, Alltrim( TPED->C7_DESCRI ) ) 
		AAdd( aItem, Transform( TPED->C7_QUANT, MASCARA ) )
		AAdd( aItem, Transform( TPED->C7_PRECO, MASCARA ) )
		AAdd( aItem, Transform( TPED->C7_TOTAL, MASCARA ) )
		AAdd( aItem, DToC( SToD(C7_DATPRF ) ) )
	
		ImpItem(@cBody, aItem) // Monta Html do Item 
		
		lSend := .T.
		
		DbSelectArea("TPED")
		DbSkip()
		
	EndDo
	// Linha Total ao Final 
	aItem := {'','','','','',cCR_TOTAL, ''  } 
	
	ImpItem(@cBody, aItem) // Monta Html do Item 
	
	EndBody(@cBody)
	 
	DbSelectArea("TPED")
	DbCloseArea()

Return Nil 
*******************************************************************************
Static Function GetTo(cTo) // Verifica pra Quem vai o email 
*******************************************************************************

	Local cSql 	:= ""
	Local cUser := ""
	
	// Obtem o Codigo de Usuario do proximo aprovador 
	cSql += " SELECT TOP 1 CR_USER FROM "+RetSqlName("SCR")
	cSql += " WHERE CR_FILIAL  = '" + xFilial("SCR") +  "' "
	cSql += " AND   CR_NUM     = '" + cCR_NUM  +  "' "
	cSql += " AND   CR_TIPO    = 'PC' "
	cSql += " AND   CR_USERLIB = ' ' "
	cSql += " AND   D_E_L_E_T_ = ' ' "
	cSql += " ORDER BY CR_NIVEL "
	
	U_ExecMySql( cSql, cCursor := "NUSE", lModo := "Q", lMostra := .F., lChange := .F. )
	
	cUser := Alltrim(NUSE->CR_USER)

	DBSelectArea("NUSE");Dbclosearea()

	PswOrder(1)
	If PswSeek(cUser,.T.)
		aUser := PswRet(1)
	Endif
		
	If !Empty(aUser[1][14]) // Campo Email do Usuario 
		cTo := Alltrim(aUser[1][14])
	Endif

Return
*******************************************************************************
Static Function StartBody(cBody) // Inicializa o Corpo do e-mail 
*******************************************************************************

	cBody += '<!DOCTYPE html>'
	cBody += '<html>'
	cBody += '<head><style></style></head>'
	cBody += '<body>'
	cBody += '<br><br><font color="' + Cor_FraCab + '" face="Arial" size="5"><strong>Pedido de Compra Pendente de liberação...</strong></font><br><br>'

Return Nil
*******************************************************************************
Static Function ImpCab(cBody, cPed, cFornece) //| Monta Html com Cabecalho dos itens 
*******************************************************************************


	cBody += '<table style="font-family: Lucida Grande, sans-serif; border-collapse: collapse; width: 100%; background-color: white; border: 2px solid ' + Cor_Border+ '; max-width: 1000px; align: center; ">'
	
	cBody += '  <tr style="border: 1px solid ' + Cor_Border+ '; background-color: ' + Cor_FraCab + '; color: black; height: 30px;">'
	cBody += '    <td colspan="3" Style="text-align: left; padding: 6px;" ><strong>PEDIDO DE COMPRA : </strong>' +  cPed + '</td>'
	cBody += '    <td colspan="4" Style="text-align: right; padding: 6px;" ><strong>FORNECEDOR : </strong>' +  cFornece + '</td>'
	cBody += '  </tr>'
	
	cBody += '  <tr style="text-transform: uppercase; background-color: ' + Cor_TitTot + '; color: white; border: 2px solid ' + Cor_Border+ '; height: 27px;">'
	cBody += '    <th>Item</th>'
	cBody += '    <th>Codigo</th>'
	cBody += '    <th>Descricao</th>'
	cBody += '    <th>Quantidade</th>'
	cBody += '    <th>Valor Unit</th>'
	cBody += '    <th>Valor Total</th>'    
	cBody += '    <th>Data Entrega</th>'
	cBody += '  </tr>'

Return Nil
*******************************************************************************
Static Function ImpItem(cBody, aItem) //| Monta Html do Item 
*******************************************************************************

	Local lPar    := Mod( Val(aItem[_ITE_]) , 2 ) == 0 // Retorna ZERO se o Numero eh PAR 
	Local cCssTrP := 'style="border: 1px solid ' + Cor_Border+ '; background-color: ' + Cor_LinImp + '; height: 25px;"' //| CSS para Linhas Pares 
	Local cCssTrI := 'style="border: 1px solid ' + Cor_Border+ '; height: 25px;"' //| CSS para Linhas Impares
	Local cCssTdC := 'style="border: 1px solid ' + Cor_Border+ '; padding: 6px; text-align: ' //| CSS cada Campo
	Local lLinTot := Empty(aItem[_ITE_]) // Retorna .T. caso seja a Linha Totais... 
	
	If !lLinTot

		cBody += '<tr '+If(lPar,cCssTrP,cCssTrI)+'> '
		cBody += '	<td ' + cCssTdC + 'center";>' + aItem[_ITE_] + '</td>'
		cBody += '	<td ' + cCssTdC + 'center";>' + aItem[_COD_] + '</td>'
		cBody += '	<td ' + cCssTdC + 'Left";>' + aItem[_DES_] + '</td>'
		cBody += '	<td ' + cCssTdC + 'right";>'  + aItem[_QTD_] + '</td>'
		cBody += '	<td ' + cCssTdC + 'right";>'  + aItem[_VUN_] + '</td>'
		cBody += '	<td ' + cCssTdC + 'right";>'  + aItem[_VTO_] + '</td>'
		cBody += '	<td ' + cCssTdC + 'center";>' + aItem[_DTE_] + '</td>'
		cBody += '</tr>'
	
	Else // Linha Total 
		If lPar
			cBody += '<tr style="text-transform: uppercase; background-color: ' + Cor_LinImp + '; color: white; border: 2px solid ' + Cor_Border+ '; height: 27px;">'
		Else
			cBody += '<tr style="text-transform: uppercase; background-color: white; color: white; border: 2px solid ' + Cor_Border+ '; height: 27px;">'
		EndIf
		cBody += '<td colspan="5" style="text-align: right; padding: 6px;color: ' + 'Black ' /*Cor_FraCab*/ + '"><strong>VALOR TOTAL : </strong></td>'
		cBody += '<td colspan="1" style="text-align: right; padding: 6px;color: ' + 'Black ' /*Cor_FraCab*/ + '"><strong>'+cCR_TOTAL+'</strong></td>'
		cBody += '<td></td>'
    	cBody += '</tr>'

	EndIf
	

Return Nil
*******************************************************************************
Static Function EndBody(cBody) // Finaliza o Corpo do e-mail 
*******************************************************************************

cBody += '</table>'
cBody += '</body>'
cBody += '<br><br><br><br><br><br>'
cBody += '</html>'

Return Nil 