#include 'protheus.ch'
#include 'parmtype.ch'


*******************************************************************************
User Function GetForSCR()// Busca o Nome do Fornecedor para Dsponibilizar no Browse da Liberacao de Compras. Inicializa o Campo CR_
*******************************************************************************

	Local cCodFor := ""
	Local cNomFor := ""
	
	//If !INCLUI
	
		cCodFor := SC7->(Posicione( "SC7", 1, xFilial("SC7")+Alltrim(SCR->CR_NUM), "C7_FORNECE" ) )       
		
		cNomFor := SA2->(Posicione( "SA2", 1, xFilial("SA2")+cCodFor, "A2_NOME" ) )
	
	//EndIf

	
Return (cNomFor)