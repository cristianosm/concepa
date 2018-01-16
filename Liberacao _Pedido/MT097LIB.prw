#include 'protheus.ch'
#include 'parmtype.ch'

/*****************************************************************************\
**---------------------------------------------------------------------------**
** Ponto Entrada: MT097LOK  | AUTOR : Cristiano Machado | DATA : 15/01/2018  **
**---------------------------------------------------------------------------**
** DESCRI��O: Function A097LIBERA - Fun��o da Dialog de libera��o e bloqueio ** 
**            dos documentos com al�ada, A097SUPERI - Fun��o da Dialog de    **
**            libera��o e bloqueio dos documentos com al�ada pelo superior   **
**            e A097TRANSF Fun��o respons�vel pela transfer�ncia do registro **
**            de bloqueio para aprova��o do Superior.                        **
**---------------------------------------------------------------------------**
** QUE PONTO: O ponto se encontra no inicio das fun��es A097LIBERA,          **
**            A097SUPERI e A097TRANSF , n�o passa parametros e n�o envia     **
**            retorno, usado conforme necessidades do usuario para diversos  **
**            fins.                                                          **
**---------------------------------------------------------------------------**
** RETORNO  : Nulo                                                           **
**---------------------------------------------------------------------------**
** USO      : Especifico para Concepa, Customizacao tela de liberacao de     ** 
**            Pedidos de compra, com informacoes mais relevantes.            **
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
User Function MT097LIB()
*******************************************************************************
	
	_SetOwnerPrvt( 'lContinua'	, .F. ) //| Objeto para uso na Regua de processamento
	Public lContinua := .F.
	
return lContinua