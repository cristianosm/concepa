#include 'protheus.ch'
#include 'parmtype.ch'

/*****************************************************************************\
**---------------------------------------------------------------------------**
** Ponto Entrada: MT097LOK  | AUTOR : Cristiano Machado | DATA : 15/01/2018  **
**---------------------------------------------------------------------------**
** DESCRIÇÃO: Function A097LIBERA - Função da Dialog de liberação e bloqueio ** 
**            dos documentos com alçada, A097SUPERI - Função da Dialog de    **
**            liberação e bloqueio dos documentos com alçada pelo superior   **
**            e A097TRANSF Função responsável pela transferência do registro **
**            de bloqueio para aprovação do Superior.                        **
**---------------------------------------------------------------------------**
** QUE PONTO: O ponto se encontra no inicio das funções A097LIBERA,          **
**            A097SUPERI e A097TRANSF , não passa parametros e não envia     **
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