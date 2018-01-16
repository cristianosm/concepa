#include 'protheus.ch'
#include 'parmtype.ch'

/*****************************************************************************\
**---------------------------------------------------------------------------**
** Ponto Entrada: MT097LOK  | AUTOR : Cristiano Machado | DATA : 15/01/2018  **
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
User Function MT097LOK()
	*******************************************************************************
	cDoc := Substr(SCR->CR_NUM,1,Len(SC7->C7_NUM))

	lContinua := !Iw_Msgbox(" MT097LOK -> Deseja Substituir a Liberacao de Compras : ","Lib Compras Cuztomizada", "YESNO")

	Alert("Retorno: " + cValToChar(lContinua))

	Alert("SCR: " + cDoc )

	DbSelectArea("SC7")
	DbSetOrder(1)
	MsSeek(xFilial("SC7")+cDoc)
	Alert("SC7: " + cDoc)
	
	dbSelectArea("SAL")       
	dbSetOrder(3)
	MsSeek(xFilial("SAL")+SC7->C7_APROV+SAK->AK_COD) 
	If SAL->AL_LIBAPR != "A" //Tipo de Aprovacao -> V=Visto;A=Aprovador
		lAprov := .T.
		cAprov := OemToAnsi("VISTO / LIVRE") 
	EndIf	
	
	//| Verifica se o pedido de compra nao esta com lock
	//|    A097Lock(Codigo do Documento , Tipo de Documento "PC->Pedido de Compras")
	lLibOk := VerLock(cDoc,SCR->CR_TIPO)

	Alert("lLibOk: " + cValToChar(lLibOk))

	Pos_SALDO		:= 1 // Saldo Disponivel
	Pos_MOEDA   	:= 2 // Moeda Utilizada
	Pos_DATA		:= 3 // Data do Saldo
	cObs 			:= IIF(!Empty(SCR->CR_OBS),SCR->CR_OBS,CriaVar("CR_OBS"))
	cCodLiber 		:= SCR->CR_APROV // Codigo do Aprovador
	cAprovS 		:= SAK->AK_APROSUP // Aprovador Superior
	dDataRef 		:= dDataBase
	aRetSaldo 		:= MaSalAlc(cCodLiber,dDataRef)
	cGrupo 			:= SC7->C7_APROV
	nTotal 			:= xMoeda(SCR->CR_TOTAL,SCR->CR_MOEDA,aRetSaldo[Pos_MOEDA],SCR->CR_EMISSAO,,SCR->CR_TXMOEDA)
	nOpc := 2 // 2-> Liberar  1->Cancelar  3->Bloquear
	nSalDif 		:= aRetSaldo[Pos_SALDO] - IIF(lAprov,0,nTotal)
		
	aDocto 		:= 	{	cDoc ,; 		//| [1] Numero do documento
	SCR->CR_TIPO,; 	//| [2] Tipo de Documento
	nTotal,;		//| [3] Valor do Documento
	cCodLiber,;		//| [4] Codigo do Aprovador
	Nil,;			//| [5] Codigo do Usuario
	cGrupo,;		//| [6] Grupo do Aprovador
	Nil,;			//| [7] Aprovador Superior
	Nil,;			//| [8] Moeda do Documento
	Nil,;			//| [9] Taxa da Moeda
	Nil,;			//| [10] Data de Emissao do Documento
	cObs,;			//| [11] Grupo de Compras ou Oservacao
	Nil}			//| [12] Aprovador Original

	/*
	ExpN1 = Operacao a ser executada
	1 = Inclusao do documento
	2 = Transferencia para Superior
	3 = Exclusao do documento
	4 = Aprovacao do documento
	5 = Estorno da Aprovacao
	6 = Bloqueio Manual da Aprovacao
	*/
	nOpc := 4 // Aprovar/Liberar
	//nOpc := 6 // Bloqueio

	If nOpc == 4 .And. (nSalDif) < 0
		Help(" ",1,"A097SALDO") //Aviso(STR0040,STR0041,{STR0037},2) //"Saldo Insuficiente"###"Saldo na data insuficiente para efetuar a liberacao do pedido. Verifique o saldo disponivel para aprovacao na data e o valor total do pedido."###"Voltar"
		nOpc := 1  //Cancela Operação
	EndIf
	/*
	Descri‡…o ³ Controla a alcada dos documentos (SCS-Saldos/SCR-Bloqueios)
	Sintaxe   ³ MaAlcDoc(aDocto,dDataRef,nOpc,ExpC1,ExpL1)
	*/
	lLiberou := MaAlcDoc(aDocto,dDataRef,nOpc)

	// Envia e-mail ao comprador ref. Liberacao do pedido para compra- 034³
	If lLiberou
		cPCLib  := SC7->C7_NUM
		cPCUser := SC7->C7_USER
		Alert("Liberou Pedido - Send eamil ")
		MLibPed(lLiberou)
		//MEnviaMail("034",{cPCLib,SCR->CR_TIPO},cPCUser)
	Endif
	*/


SC7->(MsUnlockAll())

DbSelectArea("SC7")
If ExistBlock("MT097END")
	///ExecBlock("MT097END",.F.,.F.,{cDocto,cTipo,nOpc,cFilDoc})
EndIf

Return 

//Verifica se o pedido de compra nao esta com lock
*******************************************************************************
Static Function VerLock(cNumero,cTipo)
*******************************************************************************
	aArea := SC7->(GetArea())
	dbSelectArea("SC7")
	dbSetOrder(1)
	If MsSeek(xFilial("SC7")+cNumero)
		While !Eof() .And. SC7->C7_FILIAL+Substr(SC7->C7_NUM,1,len(SC7->C7_NUM)) == xFilial("SC7")+cNumero
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
// Marca o Pedido como Liberado ....
*******************************************************************************
Static Function MLibPed(lLiberou)
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

Return 