#include 'protheus.ch'
#include 'parmtype.ch'

#Define CRLF Chr(13)+Chr(10)

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

#define CLR_GRAY RGB( 220, 220, 220 )

#Define CONTROL_ALIGN_LEFT 	 -1
#Define CONTROL_ALIGN_CENTER  0
#Define CONTROL_ALIGN_RIGHT   1

#Define MASCARA "@E 999,999.99"

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
	
	//| Funcao para Alimentar as Variaveis
	GetVar()

	//| Posiciona as Tabelas Envolvidas
	PosReg()

	//| Validações
	If ValLib()

		TelaLib() //|  Monta a Leta de Liberaçào
		
	EndIf

	//| Restaura o Ambiente
	ResEnv()

	Return lContinua


*******************************************************************************
Static Function DecVar() //| Deeclaracao das Variaveis utilizadas 
*******************************************************************************

	_SetOwnerPrvt( 'aGetATU'	, {}  ) //| Salva Area Atual
	_SetOwnerPrvt( 'aGetSC7'	, {}  ) //| Salva Area SC7
	_SetOwnerPrvt( 'aGetSCR'	, {}  ) //| Salva Area SCR
	_SetOwnerPrvt( 'aGetSAK'	, {}  ) //| Salva Area SAK
	_SetOwnerPrvt( 'aGetSAL'	, {}  ) //| Salva Area SAL

	_SetOwnerPrvt( 'cCR_NUM'	, ""  ) //| Documento a ser Liberado
	_SetOwnerPrvt( 'cCR_FORNECE', ""  ) //| Codigo do Fornecedor
	
	_SetOwnerPrvt( 'cCR_TIPO'	, ""  ) //| Tipo do Documento
	_SetOwnerPrvt( 'cCR_APROV'	, ""  ) //| Codigo do Aprovador
	_SetOwnerPrvt( 'cCR_GRUPO'	, ""  ) //| Grupo de Aprovacao
	_SetOwnerPrvt( 'cCR_APRORI'	, ""  ) //| Codigo Aprovador Origem
	_SetOwnerPrvt( 'cCR_STATUS'	, ""  ) //| Controle da Aprovacao
	_SetOwnerPrvt( 'cCR_EMISSAO', ""  ) //| Data de emissao
	_SetOwnerPrvt( 'cCR_OBS'	, ""  ) //| Obsevacoes da Aprovacao
	_SetOwnerPrvt( 'cCR_TOTAL'	, ""  ) //| Valor Total Com Mascara
	_SetOwnerPrvt( 'nCR_TOTAL'	, ""  ) //| Valor Total Numerico
	
	_SetOwnerPrvt( 'cAK_APROSUP', ""  ) // Aprovador Superior
	_SetOwnerPrvt( 'cAK_Nome', ""  ) // Nome do Aprovador 

	_SetOwnerPrvt( 'cCUserLog', RetCodUsr()  ) // Usuario Logado 
	_SetOwnerPrvt( 'cCUserName', UsrRetName(cCUserLog)  ) // Nome do Usuario Logado 


	// SAK->AK_APROSUP

	_SetOwnerPrvt( 'dDataAtual'	, dDataBase ) //| DataBase do sistema
	_SetOwnerPrvt( 'cDataRef'	, '' ) //| Data caracter atual 

	_SetOwnerPrvt( 'aDocALib'	, {} ) //| Array contendo o Documento a Liberar ...
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
	Local lAprov := .F.


	cCR_NUM 	:= Substr(SCR->CR_NUM,1,Len(SC7->C7_NUM))
	cCR_FORNECE := Posicione("SA2",1,xFilial("SA2")+SC7->C7_FORNECE+SC7->C7_LOJA ,"A2_NOME")
	cCR_EMISSAO := DtoC(SCR->CR_EMISSAO)
	cCR_APROV 	:= SCR->CR_APROV
	cCR_GRUPO	:= SCR->CR_GRUPO
	cCR_APRORI  := SCR->CR_APRORI
	cCR_STATUS  := SCR->CR_STATUS
	cCR_TIPO	:= SCR->CR_TIPO
	cCR_OBS		:= IIF(!Empty(SCR->CR_OBS),SCR->CR_OBS,CriaVar("CR_OBS"))
	
	cDataRef 	:= DtoC(dDataBase)

	aRetSaldo   := MaSalAlc(cCR_APROV,dDataAtual)

	nCR_TOTAL 	:= xMoeda(SCR->CR_TOTAL, SCR->CR_MOEDA, aRetSaldo[P_MOEDA], SCR->CR_EMISSAO, , SCR->CR_TXMOEDA)

	cCR_TOTAL   := Transform( nCR_TOTAL , MASCARA ) 
	
	cAK_APROSUP := SAK->AK_APROSUP
	cAK_Nome	:= SAK->AK_NOME
	
	aDocALib	:= {cCR_NUM,cCR_TIPO,nCR_TOTAL,cCR_APROV,,cCR_GRUPO,,,,,cCR_OBS}

	If SAL->AL_LIBAPR != "A"
		lAprov := .T.
	EndIf

	nSldDisp := aRetSaldo[P_SALDO] - IIF(lAprov,0,nCR_TOTAL)

	Return Nil
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

	DbSelectArea("SC7")
	If ExistBlock("MT097END")
		///ExecBlock("MT097END",.F.,.F.,{cDocto,cTipo,nOpc,cFilDoc})
	EndIf

Return Nil
*******************************************************************************
Static Function TelaLib() //|  Monta a Leta de Liberaçào
*******************************************************************************

  	Local oDlg	:= Nil
    Local oGrid	:= Nil
    Local oGrouB:= Nil
    Local oGrouC:= Nil
    Local oFont := Nil
    Local oSay  := Nil
    
    Local oTGDocto := Nil
    Local oTGEmiss := Nil
    Local oTGForne := Nil
    Local oTGAprov := Nil
    Local oTGDataR := Nil
    Local oTGObser := Nil
    Local oTGVlTot := Nil
   
    Local aPos 	:= {075,05,568,246}			//| Acols Posicao do Grid (Lin, Col, Comp, Altura)
    Local aTCol := {0,0,0,0,0,0,0,0,0,0}	//| Acols contendo Largura das Colunas
       
    Local aHeader 	:= {}
    Local aCols		:= {}
  
    GetAHeader( @aHeader, @aTCol ) 	//| Monta AHeader
    GetAcols( @aCols, @aTCol )		//| Monta ACols
     
	oDlg 	:= TDialog():New(050,050,700,1200,'Liberação de Docto',,,,,CLR_BLACK,CLR_WHITE,,,.T.,,,,,,)
    
    oGrouC	:= TGroup():New(005,005,070,500,'',oDlg,,,.T.)
    oGrouB	:= TGroup():New(005,505,070,571,'',oDlg,,,.T.)
    
    oFontS := TFont():New('Calibri',,-15,.T.,lBolt := .T.) // Fonte Say
    oFontG := TFont():New('Calibri',,-15,.T.,lBolt := .F.) // Fonte Get
    
    oSay := TSay():New(013,014,{||"Número do Dcto : "}	,oDlg,,oFontS,,,,.T.,,,400,300,,,,,,.F.)
    oSay := TSay():New(013,152,{||"Aprovador : "}		,oDlg,,oFontS,,,,.T.,,,400,300,,,,,,.F.)
    oSay := TSay():New(013,375,{||"Total Dcto : "}		,oDlg,,oFontS,,,,.T.,,,400,300,,,,,,.F.)

    oSay := TSay():New(033,014,{||"Emissão : "}			,oDlg,,oFontS,,,,.T.,,,400,300,,,,,,.F.)
    oSay := TSay():New(033,152,{||"Fornecedor : "}		,oDlg,,oFontS,,,,.T.,,,400,300,,,,,,.F.)
    oSay := TSay():New(033,375,{||"Data de Ref : "}		,oDlg,,oFontS,,,,.T.,,,400,300,,,,,,.F.)
    
    oSay := TSay():New(053,014,{||"Observação : "}		,oDlg,,oFontS,,,,.T.,,,400,300,,,,,,.F.)
    
    cTexto := ""
    oTGDocto := TGet():New( 010,075,{||cCR_NUM}		,oDlg,070,015,"",,CLR_GRAY,,oFontG,.F.,,.T.,,.F.,,.F.,.F.,,.T.,.F.,,cCR_NUM,,,, 		)
    oTGAprov := TGet():New( 010,197,{||cCR_APROV+" - "+cAK_Nome}	,oDlg,170,015,"",,CLR_GRAY,,oFontG,.F.,,.T.,,.F.,,.F.,.F.,,.T.,.F.,,cCR_APROV+" - "+cAK_Nome,,,, 	)
    oTGVlTot := TGet():New( 010,420,{||cCR_TOTAL}	,oDlg,070,015,"" ,,CLR_GRAY,,oFontG,.F.,,.T.,,.F.,,.F.,.F.,,.T.,.F.,,cCR_TOTAL,,,,	)
    
    oTGEmiss := TGet():New( 030,075,{||cCR_EMISSAO}	,oDlg,070,015,"",,CLR_GRAY,,oFontG,.F.,,.T.,,.F.,,.F.,.F.,,.T.,.F.,,cCR_EMISSAO,,,, 	)
    oTGForne := TGet():New( 030,197,{||cCR_FORNECE}	,oDlg,170,015,"",,CLR_GRAY,,oFontG,.F.,,.T.,,.F.,,.F.,.F.,,.T.,.F.,,cCR_FORNECE,,,,		)
    oTGDataR := TGet():New( 030,420,{||cDataRef}	,oDlg,070,015,"",,CLR_GRAY,,oFontG,.F.,,.T.,,.F.,,.F.,.F.,,.T.,.F.,,cDataRef,,,,		)
    
    oTGObser := TGet():New( 050,075,{||cCR_OBS}		,oDlg,415,015,"",,CLR_GRAY,,oFontG,.F.,,.T.,,.F.,,.F.,.F.,,.T.,.F.,,cCR_OBS,,,, 		)
    
    oTBApro := TButton():New( 010, 513, "Aprovar"  ,oDlg,{|| Libera() 			} , 50,15,,,.F.,.T.,.F.,,.F.,,,.F. )   
    oTBBloq := TButton():New( 030, 513, "Bloquear" ,oDlg,{|| alert("Bloquear")	}, 50,15,,,.F.,.T.,.F.,,.F.,,,.F. )   
    oTBCanc := TButton():New( 050, 513, "Cancelar" ,oDlg,{|| alert("Cancelar")	}, 50,15,,,.F.,.T.,.F.,,.F.,,,.F. )
    
    oTGDocto:SetContentAlign( CONTROL_ALIGN_CENTER )
    oTGAprov:SetContentAlign( CONTROL_ALIGN_LEFT )
    oTGVlTot:SetContentAlign( CONTROL_ALIGN_RIGHT )
    oTGEmiss:SetContentAlign( CONTROL_ALIGN_CENTER )
    oTGForne:SetContentAlign( CONTROL_ALIGN_LEFT )
    oTGDataR:SetContentAlign( CONTROL_ALIGN_CENTER )
    oTGObser:SetContentAlign( CONTROL_ALIGN_LEFT )
    
    
    oGrid  	:= GridLPCC():New(oDlg,aHeader,aCols,aPos,aTCol)
        
    oDlg:Activate(,,,.T.,{||},,{||} )
       
Return
*******************************************************************************
Static Function GetAHeader(aHeader, aTCol)
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
Static Function GetAcols(aCols, aTCol)// Obtem os Dados e Alimento o Acols
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
	
	U_ExecMySql( cSql, cCursor := "TPED" , lModo := "Q", lMostra := .T., lChange := .F. )
	
     
    // Cria os Dados                     
                             
    DbSelectArea(cCursor)
    DbGoTop()
    While !EOF()
    
       cItemPC := Alltrim(TPED->C7_ITEM) 	//| Item Pedido de Compra	
       cCtaGer := Alltrim(TPED->C7_CTAGER) 		//| Conta Gerente
       cCenCus := Alltrim(TPED->C7_CC) 		//| Contro de Custo
       cQtdPed := Transform(TPED->C7_QUANT, MASCARA )	//| Quantidade
       cUniMed := Alltrim(TPED->C7_UM) 		//| Unidade de Medida
       cPrecoU := Transform(TPED->C7_PRECO, MASCARA ) 	//| Preço Unitario
       cValTot := Transform(TPED->C7_TOTAL, MASCARA ) 	//| Total 
       cDescri := Alltrim(TPED->C7_DESCRI) 	//| Descricao
       cObsPro := Alltrim(TPED->C7_OBSPRO) 	//| Observação Produto
       
 
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
      

Return Nil 	

*******************************************************************************
Static Function Libera() // Executa a Liberacao do Pedido ...
*******************************************************************************

	// Liberacao
	nOpc := 2 // 2-> Liberar  1->Cancelar  3->Bloquear
	/*
	ExpN1 = Operacao a ser executada
	1 = Inclusao do documento
	2 = Transferencia para Superior
	3 = Exclusao do documento
	4 = Aprovacao do documento
	5 = Estorno da Aprovacao
	6 = Bloqueio Manual da Aprovacao
	*/
	lLiberou := MaAlcDoc(aDocALib,dDataAtual,If(nOpc==2,4,6))

	MLibPed(lLiberou)
	
	If lLiberou
		Iw_MsgBox("Liberado com Sucesso !!!", "Documento : " + cCR_NUM, "INFO"  )
	EndIf

	Return Nil
*******************************************************************************
Static Function MLibPed(lLiberou)//| Marca o Pedido como Liberado ....
*******************************************************************************

	If lLiberou .And. (SCR->CR_TIPO == "PC" .Or. SCR->CR_TIPO == "AE") 
		dbSelectArea("SC7")
		cPCLib := SC7->C7_NUM
		cPCUser:= SC7->C7_USER
		While !SC7->(Eof()) .And. SC7->C7_FILIAL+Substr(SC7->C7_NUM,1,len(SC7->C7_NUM)) == xFilial("SC7")+Substr(SCR->CR_NUM,1,len(SC7->C7_NUM))
			Reclock("SC7",.F.)
			SC7->C7_CONAPRO := "L"
			MsUnlock()
			SC7->(dbSkip())
		EndDo
	EndIf

Return Nil 