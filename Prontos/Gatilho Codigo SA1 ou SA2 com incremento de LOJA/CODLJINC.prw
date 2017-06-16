#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} CODLJINC

Função responsavel por incrementar o código do cliente
caso cliente já possui código será incrementado a loja.

Esse gatilho faz o incremento da código e loja, conforme a raiz do CNPJ/CPF.

Ou seja: 00001 Loja 01
caso tiver o a mesma raiz vai ficar
00001 com loja 02

Instalação:
1) basta bloquear os campos _COD e _LOJA para apenas visualizar.
2) Chamar a função U_CODLJINC("SA1") ou U_CODLJINC("SA2")
3) *Para SA1 deverá ser inserido no campo INI PADRAO  a função GetSXENum("SA1", "A1_COD")
4) Para SA2 o sistema não usa o controle de numeração, ele busca no banco, pois pode
existir UNIAO ou lixo na base, dessa forma ele vai pegar de 000000 ate 99999999
conforme o tamanho do campo A2_COD

Pendencia:
Não existe tratamento para fornecedor ou cliente de outro páís

@author CHARLES REITZ
@since 23/05/2016
@version 1.0

@return return, retorn o código do cliente a ser utilizado
/*/
user function CODLJINC(cAliasEmit)
	Local cCodCLiR	:=	""
	Local cAliasCGC	:=	"TRBSA1CLI"
	Local cWhere	:=	""
	Local cAliasVal	:=	"TRBVALCGC"
	LOCAL aAreaAnt := GETAREA()
	Default cAliasEmit	:=	"SA1"

	IF !INCLUI
		Return .T.
	EndIf

	//Tratamento quando for cliente
	If cAliasEmit == "SA1"
		If Empty(M->A1_PESSOA)
			MsgStop("Tipo do Cliente em branco","Atenção - "+ProcName())
			Return .F.
		EndIf

		If Empty(M->A1_CGC)
			Return .T.
		EndIf

		If !_SetAutoMode()
			Beginsql alias cAliasVal
				SELECT COUNT(1) COUNT
				FROM %table:SA1% SA1
				WHERE SA1.%notdel%
				AND SA1.A1_FILIAL = %xFilial:SA2%
				AND SA1.A1_CGC = %exp:M->A1_CGC%
			EndSql

			If (cAliasVal)->COUNT > 0
				(cAliasVal)->(dbCloseArea())
				MsgStop("CNPJ/CPF Já cadastrado na base de dados","Atenção - "+ProcName())
				Return .F.
			EndIf
			(cAliasVal)->(dbCloseArea())
		EndIf

		cWhere	:=	"%"
		If M->A1_PESSOA == 'F'
			cWhere +=	"AND SUBSTRING(SA1.A1_CGC,1,11) = '"+SubStr(M->A1_CGC,1,11)+"'"
		Else
			cWhere +=	"AND SUBSTRING(SA1.A1_CGC,1,8) = '"+SubStr(M->A1_CGC,1,08)+"'"
		EndIf
		cWhere +=	"%"

		BeginSql alias cAliasCGC
			SELECT A1_COD, MAX(A1_LOJA) A1_LOJA
			FROM %table:SA1% SA1
			WHERE SA1.%notdel%
			%exp:cWhere%
			AND SA1.A1_FILIAL = %xFilial:SA1%
			GROUP BY A1_COD
		EndSql

		If !(cAliasCGC)->(Eof())
			If ( __lSX8 )
				RollBackSX8()
			EndIf

			M->A1_COD	:=	(cAliasCGC)->A1_COD
			M->A1_LOJA	:=	SOMA1((cAliasCGC)->A1_LOJA)

			//Verifica se o codigo esta em uso
			While .T.
				If MayIUseCode("A1_COD+A1_LOJA"+xFilial("SA1")+M->A1_COD+M->A1_LOJA)
					Exit
				Else
					M->A1_LOJA	:=	Soma1(M->A1_LOJA)
				EndIf
			EndDo
		EndIf
		(cAliasCGC)->(dbCloseArea())

	//Tratamento quando for SA2
	ElseIf cAliasEmit == "SA2"

		If Empty(M->A2_TIPO)
			MsgStop("Tipo de Fornecedor em branco","Atenção - "+ProcName())
			Return .F.
		EndIf

		If Empty(M->A2_CGC)
			Return .T.
		EndIf

		If M->A2_TIPO $ 'F/J'

			Beginsql alias cAliasVal
				SELECT COUNT(1) COUNT
				FROM %table:SA2% SA2
				WHERE SA2.%notdel%
				AND SA2.A2_FILIAL = %xFilial:SA2%
				AND SA2.A2_CGC = %exp:M->A2_CGC%
			EndSql

			If (cAliasVal)->COUNT > 0
				(cAliasVal)->(dbCloseArea())
				MsgStop("CNPJ/CPF Já cadastrado na base de dados","Atenção - "+ProcName())
				Return .F.
			EndIf
			(cAliasVal)->(dbCloseArea())

			cWhere	:=	"%"
			If M->A2_TIPO == 'F'
				cWhere +=	"AND SUBSTRING(SA2.A2_CGC,1,11) = '"+SubStr(M->A2_CGC,1,11)+"'"
			ElseIf M->A2_TIPO == 'J'
				cWhere +=	"AND SUBSTRING(SA2.A2_CGC,1,8) = '"+SubStr(M->A2_CGC,1,08)+"'"
			EndIf
			cWhere +=	"%"

			BeginSql alias cAliasCGC
				SELECT A2_COD, MAX(A2_LOJA) A2_LOJA
				FROM %table:SA2% SA2
				WHERE SA2.%notdel%
				%exp:cWhere%
				AND SA2.A2_FILIAL = %xFilial:SA2%
				GROUP BY A2_COD
			EndSql

			If (cAliasCGC)->(Eof())
				cCdIniF	:=	Space(TamSX3("A2_COD")[1])
				cCdFimF	:=	Replicate("9",TamSX3("A2_COD")[1])
				cAliasLast	:=	GetNExtAlias()
				BeginSql alias cAliasLast
					SELECT MAX(A2_COD) A2_COD
					FROM %table:SA2% SA2
					WHERE SA2.%notdel%
					AND SA2.A2_FILIAL = %xFilial:SA2%
					AND SA2.A2_COD BETWEEN %exp:cCdIniF% AND %exp:cCdFimF%
				EndSql
				M->A2_COD	:=	SOMA1((cAliasLast)->A2_COD)
				M->A2_LOJA	:=	StrZero(1,TamSX3("A2_COD")[1])
				(cAliasLast)->(dbCloseArea())

				//Verifica se o codigo esta em uso
				While .T.
					If MayIUseCode("A2_COD+A2_LOJA"+xFilial("SA2")+M->A2_COD+M->A2_LOJA)
						Exit
					Else
						M->A2_COD	:=	Soma1(M->A2_COD)
					EndIf
				EndDo

			Else
				If ( __lSX8 )
					RollBackSX8()
				EndIf
				M->A2_COD	:=	(cAliasCGC)->A2_COD
				M->A2_LOJA	:=	SOMA1((cAliasCGC)->A2_LOJA)

				//Verifica se o codigo esta em uso
				While .T.
					If MayIUseCode("A2_COD+A2_LOJA"+xFilial("SA2")+M->A2_COD+M->A2_LOJA)
						Exit
					Else
						M->A2_LOJA	:=	Soma1(M->A2_LOJA)
					EndIf
				EndDo

			EndIf

			(cAliasCGC)->(dbCloseArea())
		EndIf
	EndIf

	RESTAREA(aAreaAnt)
return .T.