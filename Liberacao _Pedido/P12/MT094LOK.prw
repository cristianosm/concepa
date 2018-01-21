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

	//| Funcao para Alimentar as Variaveis
	GetVar()

	//| Selecionar e Ordenar Tabelas Envolvidas
	TabSel()

	//| Posiciona as Tabelas Envolvidas
	PosReg()

	//| Validações
	If ValLib()

		TelaLib() //|  Monta a Leta de Liberaçào
		Libera()
		
	EndIf

	//| Restaura o Ambiente
	ResEnv()

	Return lContinua
*******************************************************************************
Static Function TelaLib() //|  Monta a Leta de Liberaçào
*******************************************************************************


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

	Return Nil

*******************************************************************************
Static Function DecVar() //| Deeclaracao das Variaveis utilizadas 
*******************************************************************************

	_SetOwnerPrvt( 'aGetATU'	, {}  ) //| Salva Area Atual
	_SetOwnerPrvt( 'aGetSC7'	, {}  ) //| Salva Area SC7
	_SetOwnerPrvt( 'aGetSCR'	, {}  ) //| Salva Area SCR
	_SetOwnerPrvt( 'aGetSAK'	, {}  ) //| Salva Area SAK
	_SetOwnerPrvt( 'aGetSAL'	, {}  ) //| Salva Area SAL

	_SetOwnerPrvt( 'cCR_NUM'	, ""  ) //| Documento a ser Liberado
	_SetOwnerPrvt( 'cCR_TIPO'	, ""  ) //| Tipo do Documento
	_SetOwnerPrvt( 'cCR_APROV'	, ""  ) //| Codigo do Aprovador
	_SetOwnerPrvt( 'cCR_GRUPO'	, ""  ) //| Grupo de Aprovacao
	_SetOwnerPrvt( 'cCR_APRORI'	, ""  ) //| Codigo Aprovador Origem
	_SetOwnerPrvt( 'cCR_STATUS'	, ""  ) //| Controle da Aprovacao

	_SetOwnerPrvt( 'cCR_OBS'	, ""  ) //| Obsevacoes da Aprovacao
	_SetOwnerPrvt( 'cCR_TOTAL'	, ""  ) //| Valor Total

	_SetOwnerPrvt( 'cAK_APROSUP', ""  ) // Aprovador Superior

	SAK->AK_APROSUP

	_SetOwnerPrvt( 'dDataAtual'	, dDataBase ) //| DataBase do sistema

	_SetOwnerPrvt( 'aDocALib'	, {} ) //| Array contendo o Documento a Liberar ...
	_SetOwnerPrvt( 'aRetSaldo'	, {} ) //| Retorna o saldo do aprovador.   Return {nSaldo,nMoeda,dDtSaldo}
	_SetOwnerPrvt( 'nSldDisp'	, 0  ) //| Armazena o saldo disponivel para liberacao ja contando  o documento a ser liberado

	_SetOwnerPrvt( 'lContinua'	, .F. ) //| Define se Substitui Liberação Padrao

	Return Nil
*******************************************************************************
Static Function GetVar() //| Funcao para Alimentar as Variaveis
*******************************************************************************
	Local lAprov := .F.

	aGetATU		:= GetArea()
	aGetSC7 	:= SC7->( GetArea() )
	aGetSCR 	:= SCR->( GetArea() )
	aGetSAK 	:= SAL->( GetArea() )
	aGetSAL 	:= SAL->( GetArea() )

	cCR_NUM 	:= Substr(SCR->CR_NUM,1,Len(SC7->C7_NUM))
	cCR_APROV 	:= SCR->CR_APROV
	cCR_GRUPO	:= SCR->CR_GRUPO
	cCR_APRORI  := SCR->CR_APRORI
	cCR_STATUS  := SCR->CR_STATUS
	cCR_TIPO	:= SCR->CR_TIPO
	cCR_OBS		:= IIF(!Empty(SCR->CR_OBS),SCR->CR_OBS,CriaVar("CR_OBS"))

	aRetSaldo   := MaSalAlc(cCR_APROV,dDataAtual)

	cCR_TOTAL 	:= xMoeda(SCR->CR_TOTAL, SCR->CR_MOEDA, aRetSaldo[P_MOEDA], SCR->CR_EMISSAO, , SCR->CR_TXMOEDA)

	cAK_APROSUP := SAK->AK_APROSUP

	aDocALib	:= {cCR_NUM,cCR_TIPO,cCR_TOTAL,cCR_APROV,,cCR_GRUPO,,,,,cCR_OBS}

	If SAL->AL_LIBAPR != "A"
		lAprov := .T.
	EndIf

	nSldDisp := aRetSaldo[P_SALDO] - IIF(lAprov,0,cCR_TOTAL)

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

	Return Nil
*******************************************************************************
Static Function PosReg() //| Posiciona as Tabelas Envolvidas
*******************************************************************************

	MsSeek(xFilial("SC7")+cCR_NUM)

	SAK->(dbSeek(xFilial("SAK")+cCR_APROV))

	MsSeek(xFilial("SAL")+SC7->C7_APROV+SAK->AK_COD)

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
	
	DbSelectArea("SCR")
	If lValido .And. !Empty(SCR->CR_DATALIB) .And. ( SCR->CR_STATUS = SL_LIBERADO .Or. SCR->CR_STATUS ==  SL_LIBOUTROU )
		Aviso("VAL002",cMen002 + CRLF + " Documento: " + cCR_NUM,{"Ok"})
		lValido := .F.
	EndIf

	If lValido .And. SCR->CR_STATUS == SL_AGUARDANDO
		Aviso("VAL003",cMen003 + CRLF + " Documento: "+ cCR_NUM,{"Ok"})
		lValido := .F.
	EndIf

	DbSelectArea("SAL")
	If !MsSeek(xFilial("SAL")+cCR_GRUPO+cCR_APROV) .And. !MsSeek(xFilial("SAL")+cCR_GRUPO+cCR_APRORI) .And. lOGpaAprv
		Aviso("VAL001",cMen001 + CRLF + " Grupo: "+ cCR_GRUPO,{"Ok"})
		lValido := .F.
	EndIf

	If lValido .And. nSldDisp < 0
		Aviso("VAL004",cMen004 + CRLF + " Saldo Disponivel: " + cValToChar(nSldDisp) ,{"Ok"})
		lValido := .F.
	EndIf

	//Verifica se o pedido de compra existe 
	If lValido .And. !(Posicione( "SC7", 1, xFilial("SC7")+cCR_NUM,"C7_NUM" ) == cCR_NUM)
		Aviso("VAL005",cMen005 + CRLF + " Pedido: " + cCR_NUM,{"Ok"})
	EndIf
	
	If lValido .And. !VerLock(cCR_NUM, cCR_TIPO) //Verifica se o pedido de compra nao esta com lock
		Aviso("VAL006",cMen006 + CRLF + " Pedido: " + cCR_NUM,{"Ok"})
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
Static Function MLibPed(lLiberou)//| Marca o Pedido como Liberado ....
*******************************************************************************
	If (SCR->CR_TIPO == "PC" .Or. SCR->CR_TIPO == "AE")
		dbSelectArea("SC7")
		cPCLib := SC7->C7_NUM
		cPCUser:= SC7->C7_USER
		While !SC7->(Eof()) .And. SC7->C7_FILIAL+Substr(SC7->C7_NUM,1,len(SC7->C7_NUM)) == xFilial("SC7")+Substr(SCR->CR_NUM,1,len(SC7->C7_NUM))
			If lLiberou
				Reclock("SC7",.F.)
				SC7->C7_CONAPRO := "L"
				MsUnlock()
			EndIf
			SC7->(dbSkip())
		EndDo
	EndIf

	Return Nil 
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