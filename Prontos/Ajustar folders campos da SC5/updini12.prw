#INCLUDE "PROTHEUS.CH"

#DEFINE SIMPLES Char( 39 )
#DEFINE DUPLAS  Char( 34 )

#DEFINE CSSBOTAO	"QPushButton { color: #024670; "+;
"    border-image: url(rpo:fwstd_btn_nml.png) 3 3 3 3 stretch; "+;
"    border-top-width: 3px; "+;
"    border-left-width: 3px; "+;
"    border-right-width: 3px; "+;
"    border-bottom-width: 3px }"+;
"QPushButton:pressed {	color: #FFFFFF; "+;
"    border-image: url(rpo:fwstd_btn_prd.png) 3 3 3 3 stretch; "+;
"    border-top-width: 3px; "+;
"    border-left-width: 3px; "+;
"    border-right-width: 3px; "+;
"    border-bottom-width: 3px }"

//--------------------------------------------------------------------
/*/{Protheus.doc} UPDINI12
Função de update de dicionários para compatibilização

1 - Cria pasta na SC5
2 - Ajustar campos e atrela esses campos na SC5

@author TOTVS Protheus
@since  22/12/2016
@obs    Gerado por EXPORDIC - V.5.2.1.0 EFS / Upd. V.4.20.15 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
User Function UPDINI12( cEmpAmb, cFilAmb )

	Local   aSay      := {}
	Local   aButton   := {}
	Local   aMarcadas := {}
	Local   cTitulo   := "ATUALIZAÇÃO DE DICIONÁRIOS E TABELAS"
	Local   cDesc1    := "Esta rotina tem como função fazer  a atualização  dos dicionários do Sistema ( SX?/SIX )"
	Local   cDesc2    := "Este processo deve ser executado em modo EXCLUSIVO, ou seja não podem haver outros"
	Local   cDesc3    := "usuários  ou  jobs utilizando  o sistema.  É EXTREMAMENTE recomendavél  que  se  faça um"
	Local   cDesc4    := "BACKUP  dos DICIONÁRIOS  e da  BASE DE DADOS antes desta atualização, para que caso "
	Local   cDesc5    := "ocorram eventuais falhas, esse backup possa ser restaurado."
	Local   cDesc6    := ""
	Local   cDesc7    := ""
	Local   lOk       := .F.
	Local   lAuto     := ( cEmpAmb <> NIL .or. cFilAmb <> NIL )

	Private oMainWnd  := NIL
	Private oProcess  := NIL

	#IFDEF TOP
	TCInternal( 5, "*OFF" ) // Desliga Refresh no Lock do Top
	#ENDIF

	__cInterNet := NIL
	__lPYME     := .F.

	Set Dele On

	// Mensagens de Tela Inicial
	aAdd( aSay, cDesc1 )
	aAdd( aSay, cDesc2 )
	aAdd( aSay, cDesc3 )
	aAdd( aSay, cDesc4 )
	aAdd( aSay, cDesc5 )
	//aAdd( aSay, cDesc6 )
	//aAdd( aSay, cDesc7 )

	// Botoes Tela Inicial
	aAdd(  aButton, {  1, .T., { || lOk := .T., FechaBatch() } } )
	aAdd(  aButton, {  2, .T., { || lOk := .F., FechaBatch() } } )

	If lAuto
		lOk := .T.
	Else
		FormBatch(  cTitulo,  aSay,  aButton )
	EndIf

	If lOk
		If lAuto
			aMarcadas :={{ cEmpAmb, cFilAmb, "" }}
		Else
			aMarcadas := EscEmpresa()
		EndIf

		If !Empty( aMarcadas )
			If lAuto .OR. MsgNoYes( "Confirma a atualização dos dicionários ?", cTitulo )
				oProcess := MsNewProcess():New( { | lEnd | lOk := FSTProc( @lEnd, aMarcadas, lAuto ) }, "Atualizando", "Aguarde, atualizando ...", .F. )
				oProcess:Activate()

				If lAuto
					If lOk
						MsgStop( "Atualização Realizada.", "UPDUN01" )
					Else
						MsgStop( "Atualização não Realizada.", "UPDUN01" )
					EndIf
					dbCloseAll()
				Else
					If lOk
						Final( "Atualização Concluída." )
					Else
						Final( "Atualização não Realizada." )
					EndIf
				EndIf

			Else
				MsgStop( "Atualização não Realizada.", "UPDUN01" )

			EndIf

		Else
			MsgStop( "Atualização não Realizada.", "UPDUN01" )

		EndIf

	EndIf

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSTProc
Função de processamento da gravação dos arquivos

@author TOTVS Protheus
@since  22/12/2016
@obs    Gerado por EXPORDIC - V.5.2.1.0 EFS / Upd. V.4.20.15 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSTProc( lEnd, aMarcadas, lAuto )
	Local   aInfo     := {}
	Local   aRecnoSM0 := {}
	Local   cAux      := ""
	Local   cFile     := ""
	Local   cFileLog  := ""
	Local   cMask     := "Arquivos Texto" + "(*.TXT)|*.txt|"
	Local   cTCBuild  := "TCGetBuild"
	Local   cTexto    := ""
	Local   cTopBuild := ""
	Local   lOpen     := .F.
	Local   lRet      := .T.
	Local   nI        := 0
	Local   nPos      := 0
	Local   nRecno    := 0
	Local   nX        := 0
	Local   oDlg      := NIL
	Local   oFont     := NIL
	Local   oMemo     := NIL

	Private aArqUpd   := {}

	If ( lOpen := MyOpenSm0(.T.) )

		dbSelectArea( "SM0" )
		dbGoTop()

		While !SM0->( EOF() )
			// Só adiciona no aRecnoSM0 se a empresa for diferente
			If aScan( aRecnoSM0, { |x| x[2] == SM0->M0_CODIGO } ) == 0 ;
			.AND. aScan( aMarcadas, { |x| x[1] == SM0->M0_CODIGO } ) > 0
				aAdd( aRecnoSM0, { Recno(), SM0->M0_CODIGO } )
			EndIf
			SM0->( dbSkip() )
		End

		SM0->( dbCloseArea() )

		If lOpen

			For nI := 1 To Len( aRecnoSM0 )

				If !( lOpen := MyOpenSm0(.F.) )
					MsgStop( "Atualização da empresa " + aRecnoSM0[nI][2] + " não efetuada." )
					Exit
				EndIf

				SM0->( dbGoTo( aRecnoSM0[nI][1] ) )

				RpcSetType( 3 )
				RpcSetEnv( SM0->M0_CODIGO, SM0->M0_CODFIL )

				lMsFinalAuto := .F.
				lMsHelpAuto  := .F.

				AutoGrLog( Replicate( "-", 128 ) )
				AutoGrLog( Replicate( " ", 128 ) )
				AutoGrLog( "LOG DA ATUALIZAÇÃO DOS DICIONÁRIOS" )
				AutoGrLog( Replicate( " ", 128 ) )
				AutoGrLog( Replicate( "-", 128 ) )
				AutoGrLog( " " )
				AutoGrLog( " Dados Ambiente" )
				AutoGrLog( " --------------------" )
				AutoGrLog( " Empresa / Filial...: " + cEmpAnt + "/" + cFilAnt )
				AutoGrLog( " Nome Empresa.......: " + Capital( AllTrim( GetAdvFVal( "SM0", "M0_NOMECOM", cEmpAnt + cFilAnt, 1, "" ) ) ) )
				AutoGrLog( " Nome Filial........: " + Capital( AllTrim( GetAdvFVal( "SM0", "M0_FILIAL" , cEmpAnt + cFilAnt, 1, "" ) ) ) )
				AutoGrLog( " DataBase...........: " + DtoC( dDataBase ) )
				AutoGrLog( " Data / Hora Ínicio.: " + DtoC( Date() )  + " / " + Time() )
				AutoGrLog( " Environment........: " + GetEnvServer()  )
				AutoGrLog( " StartPath..........: " + GetSrvProfString( "StartPath", "" ) )
				AutoGrLog( " RootPath...........: " + GetSrvProfString( "RootPath" , "" ) )
				AutoGrLog( " Versão.............: " + GetVersao(.T.) )
				AutoGrLog( " Usuário TOTVS .....: " + __cUserId + " " +  cUserName )
				AutoGrLog( " Computer Name......: " + GetComputerName() )

				aInfo   := GetUserInfo()
				If ( nPos    := aScan( aInfo,{ |x,y| x[3] == ThreadId() } ) ) > 0
					AutoGrLog( " " )
					AutoGrLog( " Dados Thread" )
					AutoGrLog( " --------------------" )
					AutoGrLog( " Usuário da Rede....: " + aInfo[nPos][1] )
					AutoGrLog( " Estação............: " + aInfo[nPos][2] )
					AutoGrLog( " Programa Inicial...: " + aInfo[nPos][5] )
					AutoGrLog( " Environment........: " + aInfo[nPos][6] )
					AutoGrLog( " Conexão............: " + AllTrim( StrTran( StrTran( aInfo[nPos][7], Chr( 13 ), "" ), Chr( 10 ), "" ) ) )
				EndIf
				AutoGrLog( Replicate( "-", 128 ) )
				AutoGrLog( " " )

				If !lAuto
					AutoGrLog( Replicate( "-", 128 ) )
					AutoGrLog( "Empresa : " + SM0->M0_CODIGO + "/" + SM0->M0_NOME + CRLF )
				EndIf

				oProcess:SetRegua1( 8 )

				//------------------------------------
				// Atualiza o dicionário SX3
				//------------------------------------
				FSAtuSX3()

				oProcess:IncRegua1( "Dicionário de dados" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
				oProcess:IncRegua2( "Atualizando campos/índices" )

				// Alteração física dos arquivos
				__SetX31Mode( .F. )

				If FindFunction(cTCBuild)
					cTopBuild := &cTCBuild.()
				EndIf

				For nX := 1 To Len( aArqUpd )

					If cTopBuild >= "20090811" .AND. TcInternal( 89 ) == "CLOB_SUPPORTED"
						If ( ( aArqUpd[nX] >= "NQ " .AND. aArqUpd[nX] <= "NZZ" ) .OR. ( aArqUpd[nX] >= "O0 " .AND. aArqUpd[nX] <= "NZZ" ) ) .AND.;
						!aArqUpd[nX] $ "NQD,NQF,NQP,NQT"
							TcInternal( 25, "CLOB" )
						EndIf
					EndIf

					If Select( aArqUpd[nX] ) > 0
						dbSelectArea( aArqUpd[nX] )
						dbCloseArea()
					EndIf

					X31UpdTable( aArqUpd[nX] )

					If __GetX31Error()
						Alert( __GetX31Trace() )
						MsgStop( "Ocorreu um erro desconhecido durante a atualização da tabela : " + aArqUpd[nX] +;
						 ". Verifique a integridade do dicionário e da tabela.", "ATENÇÃO" )
						AutoGrLog( "Ocorreu um erro desconhecido durante a atualização da estrutura da tabela : " + aArqUpd[nX] )
					EndIf

					If cTopBuild >= "20090811" .AND. TcInternal( 89 ) == "CLOB_SUPPORTED"
						TcInternal( 25, "OFF" )
					EndIf

				Next nX

				//------------------------------------
				// Atualiza o dicionário SX6
				//------------------------------------
				oProcess:IncRegua1( "Dicionário de parâmetros" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
				FSAtuSX6()

				//------------------------------------
				// Atualiza o dicionário SXA
				//------------------------------------
				oProcess:IncRegua1( "Dicionário de pastas" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
				FSAtuSXA()

				//------------------------------------
				// Aloca os campos nas pastas
				//------------------------------------
				oProcess:IncRegua1( "Aloca campos nas pastas" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
				FSAtuA3()

				//------------------------------------
				// Aloca os campos nas pastas
				//------------------------------------
				oProcess:IncRegua1( "Ajustes Gerais SX3" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
				FSAtuGE()

				AutoGrLog( Replicate( "-", 128 ) )
				AutoGrLog( " Data / Hora Final.: " + DtoC( Date() ) + " / " + Time() )
				AutoGrLog( Replicate( "-", 128 ) )

				RpcClearEnv()

			Next nI

			If !lAuto

				cTexto := LeLog()

				Define Font oFont Name "Mono AS" Size 5, 12

				Define MsDialog oDlg Title "Atualização concluida." From 3, 0 to 340, 417 Pixel

				@ 5, 5 Get oMemo Var cTexto Memo Size 200, 145 Of oDlg Pixel
				oMemo:bRClicked := { || AllwaysTrue() }
				oMemo:oFont     := oFont

				Define SButton From 153, 175 Type  1 Action oDlg:End() Enable Of oDlg Pixel // Apaga
				Define SButton From 153, 145 Type 13 Action ( cFile := cGetFile( cMask, "" ), If( cFile == "", .T., ;
				MemoWrite( cFile, cTexto ) ) ) Enable Of oDlg Pixel

				Activate MsDialog oDlg Center

			EndIf

		EndIf

	Else

		lRet := .F.

	EndIf

Return lRet


//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuSX3
Função de processamento da gravação do SX3 - Campos

@author TOTVS Protheus
@since  22/12/2016
@obs    Gerado por EXPORDIC - V.5.2.1.0 EFS / Upd. V.4.20.15 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSAtuSX3()
	Local aEstrut   := {}
	Local aSX3      := {}
	Local cAlias    := ""
	Local cAliasAtu := ""
	Local cMsg      := ""
	Local cSeqAtu   := ""
	Local cX3Campo  := ""
	Local cX3Dado   := ""
	Local lTodosNao := .F.
	Local lTodosSim := .F.
	Local nI        := 0
	Local nJ        := 0
	Local nOpcA     := 0
	Local nPosArq   := 0
	Local nPosCpo   := 0
	Local nPosOrd   := 0
	Local nPosSXG   := 0
	Local nPosTam   := 0
	Local nPosVld   := 0
	Local nSeqAtu   := 0
	Local nTamSeek  := Len( SX3->X3_CAMPO )

	AutoGrLog( "Ínicio da Atualização" + " SX3" + CRLF )

	aEstrut := { { "X3_ARQUIVO", 0 }, { "X3_ORDEM"  , 0 }, { "X3_CAMPO"  , 0 }, { "X3_TIPO"   , 0 }, { "X3_TAMANHO", 0 }, { "X3_DECIMAL", 0 }, { "X3_TITULO" , 0 }, ;
	{ "X3_TITSPA" , 0 }, { "X3_TITENG" , 0 }, { "X3_DESCRIC", 0 }, { "X3_DESCSPA", 0 }, { "X3_DESCENG", 0 }, { "X3_PICTURE", 0 }, { "X3_VALID"  , 0 }, ;
	{ "X3_USADO"  , 0 }, { "X3_RELACAO", 0 }, { "X3_F3"     , 0 }, { "X3_NIVEL"  , 0 }, { "X3_RESERV" , 0 }, { "X3_CHECK"  , 0 }, { "X3_TRIGGER", 0 }, ;
	{ "X3_PROPRI" , 0 }, { "X3_BROWSE" , 0 }, { "X3_VISUAL" , 0 }, { "X3_CONTEXT", 0 }, { "X3_OBRIGAT", 0 }, { "X3_VLDUSER", 0 }, { "X3_CBOX"   , 0 }, ;
	{ "X3_CBOXSPA", 0 }, { "X3_CBOXENG", 0 }, { "X3_PICTVAR", 0 }, { "X3_WHEN"   , 0 }, { "X3_INIBRW" , 0 }, { "X3_GRPSXG" , 0 }, { "X3_FOLDER" , 0 }, ;
	{ "X3_CONDSQL", 0 }, { "X3_CHKSQL" , 0 }, { "X3_IDXSRV" , 0 }, { "X3_ORTOGRA", 0 }, { "X3_TELA"   , 0 }, { "X3_POSLGT" , 0 }, { "X3_IDXFLD" , 0 }, ;
	{ "X3_AGRUP"  , 0 }, { "X3_MODAL"  , 0 }, { "X3_PYME"   , 0 } }

	aEval( aEstrut, { |x| x[2] := SX3->( FieldPos( x[1] ) ) } )

	//
	// --- ATENÇÃO ---
	// Coloque .F. na 2a. posição de cada elemento do array, para os dados do SX3
	// que não serão atualizados quando o campo já existir.
	//

	//
	// Campos Tabela SC5
	//
	/*
	aAdd( aSX3, { ;
	{ 'SC5'																	, .T. }, ; //X3_ARQUIVO
	{ 'C8'																	, .T. }, ; //X3_ORDEM
	{ 'C5_ZIDESPE'															, .T. }, ; //X3_CAMPO
	{ 'C'																	, .T. }, ; //X3_TIPO
	{ 6																		, .T. }, ; //X3_TAMANHO
	{ 0																		, .T. }, ; //X3_DECIMAL
	{ 'N.Ped.Emp.D*'														, .T. }, ; //X3_TITULO
	{ 'N.Ped.Emp.D*'														, .T. }, ; //X3_TITSPA
	{ 'N.Ped.Emp.D*'														, .T. }, ; //X3_TITENG
	{ 'N.Ped.Emp.Destino'													, .T. }, ; //X3_DESCRIC
	{ 'N.Ped.Emp.Destino'													, .T. }, ; //X3_DESCSPA
	{ 'N.Ped.Emp.Destino'													, .T. }, ; //X3_DESCENG
	{ ''																	, .T. }, ; //X3_PICTURE
	{ ''																	, .T. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .T. }, ; //X3_USADO
	{ ''																	, .T. }, ; //X3_RELACAO
	{ ''																	, .T. }, ; //X3_F3
	{ 0																		, .T. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .T. }, ; //X3_RESERV
	{ ''																	, .T. }, ; //X3_CHECK
	{ ''																	, .T. }, ; //X3_TRIGGER
	{ 'U'																	, .T. }, ; //X3_PROPRI
	{ 'N'																	, .T. }, ; //X3_BROWSE
	{ 'V'																	, .T. }, ; //X3_VISUAL
	{ 'R'																	, .T. }, ; //X3_CONTEXT
	{ ''																	, .T. }, ; //X3_OBRIGAT
	{ ''																	, .T. }, ; //X3_VLDUSER
	{ ''																	, .T. }, ; //X3_CBOX
	{ ''																	, .T. }, ; //X3_CBOXSPA
	{ ''																	, .T. }, ; //X3_CBOXENG
	{ ''																	, .T. }, ; //X3_PICTVAR
	{ ''																	, .T. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ '4'																	, .T. }, ; //X3_FOLDER
	{ ''																	, .T. }, ; //X3_CONDSQL
	{ ''																	, .T. }, ; //X3_CHKSQL
	{ ''																	, .T. }, ; //X3_IDXSRV
	{ 'N'																	, .T. }, ; //X3_ORTOGRA
	{ ''																	, .T. }, ; //X3_TELA
	{ '2'																	, .T. }, ; //X3_POSLGT
	{ 'N'																	, .T. }, ; //X3_IDXFLD
	{ ''																	, .T. }, ; //X3_AGRUP
	{ ''																	, .T. }, ; //X3_MODAL
	{ ''																	, .T. }} ) //X3_PYME
	*/

		//
	// Atualizando dicionário
	//
	nPosArq := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_ARQUIVO" } )
	nPosOrd := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_ORDEM"   } )
	nPosCpo := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_CAMPO"   } )
	nPosTam := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_TAMANHO" } )
	nPosSXG := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_GRPSXG"  } )
	nPosVld := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_VALID"   } )

	aSort( aSX3,,, { |x,y| x[nPosArq][1]+x[nPosOrd][1]+x[nPosCpo][1] < y[nPosArq][1]+y[nPosOrd][1]+y[nPosCpo][1] } )

	oProcess:SetRegua2( Len( aSX3 ) )

	dbSelectArea( "SX3" )
	dbSetOrder( 2 )
	cAliasAtu := ""

	For nI := 1 To Len( aSX3 )

		//
		// Verifica se o campo faz parte de um grupo e ajusta tamanho
		//
		If !Empty( aSX3[nI][nPosSXG][1] )
			SXG->( dbSetOrder( 1 ) )
			If SXG->( MSSeek( aSX3[nI][nPosSXG][1] ) )
				If aSX3[nI][nPosTam][1] <> SXG->XG_SIZE
					aSX3[nI][nPosTam][1] := SXG->XG_SIZE
					AutoGrLog( "O tamanho do campo " + aSX3[nI][nPosCpo][1] + " NÃO atualizado e foi mantido em [" + ;
					AllTrim( Str( SXG->XG_SIZE ) ) + "]" + CRLF + ;
					" por pertencer ao grupo de campos [" + SXG->XG_GRUPO + "]" + CRLF )
				EndIf
			EndIf
		EndIf

		SX3->( dbSetOrder( 2 ) )

		If !( aSX3[nI][nPosArq][1] $ cAlias )
			cAlias += aSX3[nI][nPosArq][1] + "/"
			aAdd( aArqUpd, aSX3[nI][nPosArq][1] )
		EndIf

		If !SX3->( dbSeek( PadR( aSX3[nI][nPosCpo][1], nTamSeek ) ) )

			//
			// Busca ultima ocorrencia do alias
			//
			If ( aSX3[nI][nPosArq][1] <> cAliasAtu )
				cSeqAtu   := "00"
				cAliasAtu := aSX3[nI][nPosArq][1]

				dbSetOrder( 1 )
				SX3->( dbSeek( cAliasAtu + "ZZ", .T. ) )
				dbSkip( -1 )

				If ( SX3->X3_ARQUIVO == cAliasAtu )
					cSeqAtu := SX3->X3_ORDEM
				EndIf

				nSeqAtu := Val( RetAsc( cSeqAtu, 3, .F. ) )
			EndIf

			nSeqAtu++
			cSeqAtu := RetAsc( Str( nSeqAtu ), 2, .T. )

			RecLock( "SX3", .T. )
			For nJ := 1 To Len( aSX3[nI] )
				If     nJ == nPosOrd  // Ordem
					SX3->( FieldPut( FieldPos( aEstrut[nJ][1] ), cSeqAtu ) )

				ElseIf aEstrut[nJ][2] > 0
					SX3->( FieldPut( FieldPos( aEstrut[nJ][1] ), aSX3[nI][nJ][1] ) )

				EndIf
			Next nJ

			dbCommit()
			MsUnLock()

			AutoGrLog( "Criado campo " + aSX3[nI][nPosCpo][1] )

		Else

			//
			// Verifica se o campo faz parte de um grupo e ajsuta tamanho
			//
			If !Empty( SX3->X3_GRPSXG ) .AND. SX3->X3_GRPSXG <> aSX3[nI][nPosSXG][1]
				SXG->( dbSetOrder( 1 ) )
				If SXG->( MSSeek( SX3->X3_GRPSXG ) )
					If aSX3[nI][nPosTam][1] <> SXG->XG_SIZE
						aSX3[nI][nPosTam][1] := SXG->XG_SIZE
						AutoGrLog( "O tamanho do campo " + aSX3[nI][nPosCpo][1] + " NÃO atualizado e foi mantido em [" + ;
						AllTrim( Str( SXG->XG_SIZE ) ) + "]"+ CRLF + ;
						"   por pertencer ao grupo de campos [" + SX3->X3_GRPSXG + "]" + CRLF )
					EndIf
				EndIf
			EndIf

			//
			// Verifica todos os campos
			//
			For nJ := 1 To Len( aSX3[nI] )

				//
				// Se o campo estiver diferente da estrutura
				//
				If aSX3[nI][nJ][2]
					cX3Campo := AllTrim( aEstrut[nJ][1] )
					cX3Dado  := SX3->( FieldGet( aEstrut[nJ][2] ) )

					If  aEstrut[nJ][2] > 0 .AND. ;
					PadR( StrTran( AllToChar( cX3Dado ), " ", "" ), 250 ) <> ;
					PadR( StrTran( AllToChar( aSX3[nI][nJ][1] ), " ", "" ), 250 ) .AND. ;
					!cX3Campo == "X3_ORDEM"

						cMsg := "O campo " + aSX3[nI][nPosCpo][1] + " está com o " + cX3Campo + ;
						" com o conteúdo" + CRLF + ;
						"[" + RTrim( AllToChar( cX3Dado ) ) + "]" + CRLF + ;
						"que será substituído pelo NOVO conteúdo" + CRLF + ;
						"[" + RTrim( AllToChar( aSX3[nI][nJ][1] ) ) + "]" + CRLF + ;
						"Deseja substituir ? "

						If      lTodosSim
							nOpcA := 1
						ElseIf  lTodosNao
							nOpcA := 2
						Else
							nOpcA := Aviso( "ATUALIZAÇÃO DE DICIONÁRIOS E TABELAS", cMsg, ;
									{ "Sim", "Não", "Sim p/Todos", "Não p/Todos" }, 3, "Diferença de conteúdo - SX3" )
							lTodosSim := ( nOpcA == 3 )
							lTodosNao := ( nOpcA == 4 )

							If lTodosSim
								nOpcA := 1
								lTodosSim := MsgNoYes( "Foi selecionada a opção de REALIZAR TODAS alterações no "+;
								"SX3 e NÃO MOSTRAR mais a tela de aviso." + CRLF + "Confirma a ação [Sim p/Todos] ?" )
							EndIf

							If lTodosNao
								nOpcA := 2
								lTodosNao := MsgNoYes( "Foi selecionada a opção de NÃO REALIZAR "+;
								"nenhuma alteração no SX3 que esteja diferente da base e NÃO MOSTRAR mais a tela de aviso." +;
								 CRLF + "Confirma esta ação [Não p/Todos]?" )
							EndIf

						EndIf

						If nOpcA == 1
							AutoGrLog( "Alterado campo " + aSX3[nI][nPosCpo][1] + CRLF + ;
							"   " + PadR( cX3Campo, 10 ) + " de [" + AllToChar( cX3Dado ) + "]" + CRLF + ;
							"            para [" + AllToChar( aSX3[nI][nJ][1] )           + "]" + CRLF )

							RecLock( "SX3", .F. )
							FieldPut( FieldPos( aEstrut[nJ][1] ), aSX3[nI][nJ][1] )
							MsUnLock()
						EndIf

					EndIf

				EndIf

			Next

		EndIf

		oProcess:IncRegua2( "Atualizando Campos de Tabelas (SX3)..." )

	Next nI

	AutoGrLog( CRLF + "Final da Atualização" + " SX3" + CRLF + Replicate( "-", 128 ) + CRLF )

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuSX6
Função de processamento da gravação do SX6 - Parâmetros

@author TOTVS Protheus
@since  22/12/2016
@obs    Gerado por EXPORDIC - V.5.2.1.0 EFS / Upd. V.4.20.15 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSAtuSX6()
	Local aEstrut   := {}
	Local aSX6      := {}
	Local cAlias    := ""
	Local cMsg      := ""
	Local lContinua := .T.
	Local lReclock  := .T.
	Local lTodosNao := .F.
	Local lTodosSim := .F.
	Local nI        := 0
	Local nJ        := 0
	Local nOpcA     := 0
	Local nTamFil   := Len( SX6->X6_FIL )
	Local nTamVar   := Len( SX6->X6_VAR )

	AutoGrLog( "Ínicio da Atualização" + " SX6" + CRLF )

	aEstrut := { "X6_FIL"    , "X6_VAR"    , "X6_TIPO"   , "X6_DESCRIC", "X6_DSCSPA" , "X6_DSCENG" , "X6_DESC1"  , ;
	"X6_DSCSPA1", "X6_DSCENG1", "X6_DESC2"  , "X6_DSCSPA2", "X6_DSCENG2", "X6_CONTEUD", "X6_CONTSPA", ;
	"X6_CONTENG", "X6_PROPRI" , "X6_VALID"  , "X6_INIT"   , "X6_DEFPOR" , "X6_DEFSPA" , "X6_DEFENG" , ;
	"X6_PYME"   }

	/*
	aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_ESPECIE'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Contém tipos de documentos fiscais utilizados na'						, ; //X6_DESCRIC
	'Contiene tipos de documentos fiscales usados en'						, ; //X6_DSCSPA
	'Contain categories of fiscal documents used in'						, ; //X6_DSCENG
	'emissão de notas fiscais'												, ; //X6_DESC1
	'la emision de facturas'												, ; //X6_DSCSPA1
	'the issuance of invoices.'												, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'UNI=NF;'																, ; //X6_CONTEUD
	'UNI=NF;'																, ; //X6_CONTSPA
	'UNI=NF;'																, ; //X6_CONTENG
	'S'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	'UNI=NF;'																, ; //X6_DEFPOR
	'UNI=NF;'																, ; //X6_DEFSPA
	'UNI=NF;'																, ; //X6_DEFENG
	'S'																		} ) //X6_PYME
	*/
	//
	// Atualizando dicionário
	//
	oProcess:SetRegua2( Len( aSX6 ) )

	dbSelectArea( "SX6" )
	dbSetOrder( 1 )

	For nI := 1 To Len( aSX6 )
		lContinua := .F.
		lReclock  := .F.

		If !SX6->( dbSeek( PadR( aSX6[nI][1], nTamFil ) + PadR( aSX6[nI][2], nTamVar ) ) )
			lContinua := .T.
			lReclock  := .T.
			AutoGrLog( "Foi incluído o parâmetro " + aSX6[nI][1] + aSX6[nI][2] + " Conteúdo [" + AllTrim( aSX6[nI][13] ) + "]" )
		Else
			lContinua := .T.
			lReclock  := .F.
			If !StrTran( SX6->X6_CONTEUD, " ", "" ) == StrTran( aSX6[nI][13], " ", "" )

				cMsg := "O parâmetro " + aSX6[nI][2] + " está com o conteúdo" + CRLF + ;
				"[" + RTrim( StrTran( SX6->X6_CONTEUD, " ", "" ) ) + "]" + CRLF + ;
				", que é será substituido pelo NOVO conteúdo " + CRLF + ;
				"[" + RTrim( StrTran( aSX6[nI][13]   , " ", "" ) ) + "]" + CRLF + ;
				"Deseja substituir ? "

				If      lTodosSim
					nOpcA := 1
				ElseIf  lTodosNao
					nOpcA := 2
				Else
					nOpcA := Aviso( "ATUALIZAÇÃO DE DICIONÁRIOS E TABELAS", cMsg, ;
					{ "Sim", "Não", "Sim p/Todos", "Não p/Todos" }, 3, "Diferença de conteúdo - SX6" )
					lTodosSim := ( nOpcA == 3 )
					lTodosNao := ( nOpcA == 4 )

					If lTodosSim
						nOpcA := 1
						lTodosSim := MsgNoYes( "Foi selecionada a opção de REALIZAR TODAS alterações no SX6 e "+;
						"NÃO MOSTRAR mais a tela de aviso." + CRLF + "Confirma a ação [Sim p/Todos] ?" )
					EndIf

					If lTodosNao
						nOpcA := 2
						lTodosNao := MsgNoYes( "Foi selecionada a opção de NÃO REALIZAR nenhuma alteração no SX6 que esteja "+;
						"diferente da base e NÃO MOSTRAR mais a tela de aviso." + CRLF + "Confirma esta ação [Não p/Todos]?" )
					EndIf

				EndIf

				lContinua := ( nOpcA == 1 )

				If lContinua
					AutoGrLog( "Foi alterado o parâmetro " + aSX6[nI][1] + aSX6[nI][2] + " de [" + ;
					AllTrim( SX6->X6_CONTEUD ) + "]" + " para [" + AllTrim( aSX6[nI][13] ) + "]" )
				EndIf

			Else
				lContinua := .F.
			EndIf
		EndIf

		If lContinua
			If !( aSX6[nI][1] $ cAlias )
				cAlias += aSX6[nI][1] + "/"
			EndIf

			RecLock( "SX6", lReclock )
			For nJ := 1 To Len( aSX6[nI] )
				If FieldPos( aEstrut[nJ] ) > 0
					FieldPut( FieldPos( aEstrut[nJ] ), aSX6[nI][nJ] )
				EndIf
			Next nJ
			dbCommit()
			MsUnLock()
		EndIf

		oProcess:IncRegua2( "Atualizando Arquivos (SX6)..." )

	Next nI

	AutoGrLog( CRLF + "Final da Atualização" + " SX6" + CRLF + Replicate( "-", 128 ) + CRLF )

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuSXA
Função de processamento da gravação do SXA - Pastas

@author TOTVS Protheus
@since  22/12/2016
@obs    Gerado por EXPORDIC - V.5.2.1.0 EFS / Upd. V.4.20.15 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSAtuSXA()
	Local aEstrut   := {}
	Local aSXA      := {}
	Local cAlias    := ""
	Local nI        := 0
	Local nJ        := 0
	Local nPosAgr   := 0
	Local lAlterou  := .F.

	AutoGrLog( "Ínicio da Atualização" + " SXA" + CRLF )

	aEstrut := { "XA_ALIAS"  , "XA_ORDEM"  , "XA_DESCRIC", "XA_DESCSPA", "XA_DESCENG", "XA_AGRUP"  , "XA_TIPO"   , ;
	"XA_PROPRI" }


	//
	// Tabela SC5
	//
	aAdd( aSXA, { ;
	'SC5'																	, ; //XA_ALIAS
	'1'																		, ; //XA_ORDEM
	'Geral'																	, ; //XA_DESCRIC
	'Geral'																	, ; //XA_DESCSPA
	'Geral'																	, ; //XA_DESCENG
	''																		, ; //XA_AGRUP
	''																		, ; //XA_TIPO
	'U'																		} ) //XA_PROPRI

	aAdd( aSXA, { ;
	'SC5'																	, ; //XA_ALIAS
	'2'																		, ; //XA_ORDEM
	'Vendas'															, ; //XA_DESCRIC
	'Vendas'															, ; //XA_DESCSPA
	'Vendas'															, ; //XA_DESCENG
	''																		, ; //XA_AGRUP
	''																		, ; //XA_TIPO
	'U'																		} ) //XA_PROPRI

	aAdd( aSXA, { ;
	'SC5'																	, ; //XA_ALIAS
	'3'																		, ; //XA_ORDEM
	'Financeiro'																, ; //XA_DESCRIC
	'Financeiro'																, ; //XA_DESCSPA
	'Financeiro'																, ; //XA_DESCENG
	''																		, ; //XA_AGRUP
	''																		, ; //XA_TIPO
	'U'																		} ) //XA_PROPRI

	aAdd( aSXA, { ;
	'SC5'																	, ; //XA_ALIAS
	'4'																		, ; //XA_ORDEM
	'Transporte'															, ; //XA_DESCRIC
	'Transporte'															, ; //XA_DESCSPA
	'Transporte'															, ; //XA_DESCENG
	''																		, ; //XA_AGRUP
	''																		, ; //XA_TIPO
	'U'																		} ) //XA_PROPRI

	aAdd( aSXA, { ;
	'SC5'																	, ; //XA_ALIAS
	'5'																		, ; //XA_ORDEM
	'Fiscal/Contábil'															, ; //XA_DESCRIC
	'Fiscal/Contábil'															, ; //XA_DESCSPA
	'Fiscal/Contábil'															, ; //XA_DESCENG
	''																		, ; //XA_AGRUP
	''																		, ; //XA_TIPO
	'U'																		} ) //XA_PROPRI


	aAdd( aSXA, { ;
	'SC5'																	, ; //XA_ALIAS
	'6'																		, ; //XA_ORDEM
	'Integrações'															, ; //XA_DESCRIC
	'Integrações'															, ; //XA_DESCSPA
	'Integrações'															, ; //XA_DESCENG
	''																		, ; //XA_AGRUP
	''																		, ; //XA_TIPO
	'U'																		} ) //XA_PROPRI


	nPosAgr := aScan( aEstrut, { |x| AllTrim( x ) == "XA_AGRUP" } )

	//
	// Atualizando dicionário
	//
	oProcess:SetRegua2( Len( aSXA ) )

	dbSelectArea( "SXA" )
	dbSetOrder( 1 )

	For nI := 1 To Len( aSXA )

		If SXA->( dbSeek( aSXA[nI][1] + aSXA[nI][2] ) )

			lAlterou := .F.

			While !SXA->( EOF() ).AND.  SXA->( XA_ALIAS + XA_ORDEM ) == aSXA[nI][1] + aSXA[nI][2]

				If SXA->XA_AGRUP == aSXA[nI][nPosAgr]
					RecLock( "SXA", .F. )
					For nJ := 1 To Len( aSXA[nI] )
						If FieldPos( aEstrut[nJ] ) > 0 .AND. Alltrim(AllToChar(SXA->( FieldGet( nJ ) ))) <> Alltrim(AllToChar(aSXA[nI][nJ]))
							FieldPut( FieldPos( aEstrut[nJ] ), aSXA[nI][nJ] )
							lAlterou := .T.
						EndIf
					Next nJ
					dbCommit()
					MsUnLock()
				EndIf

				SXA->( dbSkip() )

			End

			If lAlterou
				AutoGrLog( "Foi alterada a pasta " + aSXA[nI][1] + "/" + aSXA[nI][2] + "  " + aSXA[nI][3] )
			EndIf

		Else

			RecLock( "SXA", .T. )
			For nJ := 1 To Len( aSXA[nI] )
				If FieldPos( aEstrut[nJ] ) > 0
					FieldPut( FieldPos( aEstrut[nJ] ), aSXA[nI][nJ] )
				EndIf
			Next nJ
			dbCommit()
			MsUnLock()

			AutoGrLog( "Foi incluída a pasta " + aSXA[nI][1] + "/" + aSXA[nI][2] + "  " + aSXA[nI][3] )

		EndIf

		oProcess:IncRegua2( "Atualizando Arquivos (SXA)..." )

	Next nI

	AutoGrLog( CRLF + "Final da Atualização" + " SXA" + CRLF + Replicate( "-", 128 ) + CRLF )

Return NIL

Static Function FSAtuA3()
	Local aEstrut   := {}
	Local aSX3      := {}
	Local cAlias    := ""
	Local cAliasAtu := ""
	Local cMsg      := ""
	Local cSeqAtu   := ""
	Local cX3Campo  := ""
	Local cX3Dado   := ""
	Local lTodosNao := .F.
	Local lTodosSim := .F.
	Local nI        := 0
	Local nJ        := 0
	Local nOpcA     := 0
	Local nPosArq   := 0
	Local nPosCpo   := 0
	Local nPosOrd   := 0
	Local nPosSXG   := 0
	Local nPosTam   := 0
	Local nPosVld   := 0
	Local nSeqAtu   := 0
	Local nTamSeek  := Len( SX3->X3_CAMPO )
	//X3_FOLDER
	AutoGrLog( "Ínicio da Atualização" + " SX3" + CRLF )

	aFldCpo		:=	{}
	aFldAlias	:=	{"SC5"}

	//Folder 1 - SC5
	aadd(aFldCpo,{"C5_FILIAL ","1"})
	aadd(aFldCpo,{"C5_NUM    ","1"})
	aadd(aFldCpo,{"C5_TIPO   ","1"})
	aadd(aFldCpo,{"C5_CLIENTE","1"})
	aadd(aFldCpo,{"C5_LOJACLI","1"})
	aadd(aFldCpo,{"C5_CLIENT ","1"})
	aadd(aFldCpo,{"C5_LOJAENT","1"})
	aadd(aFldCpo,{"C5_TIPOCLI","1"})
	aadd(aFldCpo,{"C5_MSBLQL ","1"})
	aadd(aFldCpo,{"C5_TABELA ","1"})
	aadd(aFldCpo,{"C5_EMISSAO","1"})
	aadd(aFldCpo,{"C5_MENNOTA","1"})
	aadd(aFldCpo,{"C5_MENPAD ","1"})
	aadd(aFldCpo,{"C5_ZNOMECL","1"})
	aadd(aFldCpo,{"C5_ZSEPARA","1"})
	//Folder 2 - SC5
	aadd(aFldCpo,{"C5_VEND1  ","2"})
	aadd(aFldCpo,{"C5_COMIS1 ","2"})
	aadd(aFldCpo,{"C5_VEND2  ","2"})
	aadd(aFldCpo,{"C5_COMIS2 ","2"})
	aadd(aFldCpo,{"C5_VEND3  ","2"})
	aadd(aFldCpo,{"C5_COMIS3 ","2"})
	aadd(aFldCpo,{"C5_VEND4  ","2"})
	aadd(aFldCpo,{"C5_COMIS4 ","2"})
	aadd(aFldCpo,{"C5_VEND5  ","2"})
	aadd(aFldCpo,{"C5_COMIS5 ","2"})
	//Folder 3 - SC5
	aadd(aFldCpo,{"C5_CONDPAG","3"})
	aadd(aFldCpo,{"C5_DESC1  ","3"})
	aadd(aFldCpo,{"C5_DESC2  ","3"})
	aadd(aFldCpo,{"C5_DESC3  ","3"})
	aadd(aFldCpo,{"C5_DESC4  ","3"})
	aadd(aFldCpo,{"C5_BANCO  ","3"})
	aadd(aFldCpo,{"C5_DESCFI ","3"})
	aadd(aFldCpo,{"C5_PARC1  ","3"})
	aadd(aFldCpo,{"C5_DATA1  ","3"})
	aadd(aFldCpo,{"C5_PARC2  ","3"})
	aadd(aFldCpo,{"C5_DATA2  ","3"})
	aadd(aFldCpo,{"C5_PARC3  ","3"})
	aadd(aFldCpo,{"C5_DATA3  ","3"})
	aadd(aFldCpo,{"C5_PARC4  ","3"})
	aadd(aFldCpo,{"C5_DATA4  ","3"})
	aadd(aFldCpo,{"C5_MOEDA  ","3"})
	aadd(aFldCpo,{"C5_ACRSFIN","3"})
	aadd(aFldCpo,{"C5_TXMOEDA","3"})
	aadd(aFldCpo,{"C5_NATUREZ","3"})
	aadd(aFldCpo,{"C5_DTTXREF","3"})
	aadd(aFldCpo,{"C5_TXREF  ","3"})
	aadd(aFldCpo,{"C5_MOEDTIT","3"})
	//Folder 4 - SC5
	aadd(aFldCpo,{"C5_TRANSP ","4"})
	aadd(aFldCpo,{"C5_TPFRETE","4"})
	aadd(aFldCpo,{"C5_FRETE  ","4"})
	aadd(aFldCpo,{"C5_SEGURO ","4"})
	aadd(aFldCpo,{"C5_DESPESA","4"})
	aadd(aFldCpo,{"C5_FRETAUT","4"})
	aadd(aFldCpo,{"C5_PESOL  ","4"})
	aadd(aFldCpo,{"C5_PBRUTO ","4"})
	aadd(aFldCpo,{"C5_REIMP  ","4"})
	aadd(aFldCpo,{"C5_REDESP ","4"})
	aadd(aFldCpo,{"C5_VOLUME1","4"})
	aadd(aFldCpo,{"C5_VOLUME2","4"})
	aadd(aFldCpo,{"C5_VOLUME3","4"})
	aadd(aFldCpo,{"C5_VOLUME4","4"})
	aadd(aFldCpo,{"C5_ESPECI1","4"})
	aadd(aFldCpo,{"C5_ESPECI2","4"})
	aadd(aFldCpo,{"C5_ESPECI3","4"})
	aadd(aFldCpo,{"C5_ESPECI4","4"})
	aadd(aFldCpo,{"C5_TPCARGA","4"})
	aadd(aFldCpo,{"C5_VLR_FRT","4"})
	aadd(aFldCpo,{"C5_FECENT ","4"})
	aadd(aFldCpo,{"C5_SUGENT ","4"})
	aadd(aFldCpo,{"C5_VEICULO","4"})
	aadd(aFldCpo,{"C5_PREPEMB","4"})
	//Folder 5 - SC5
	aadd(aFldCpo,{"C5_INCISS ","5"})
	aadd(aFldCpo,{"C5_NOTA   ","5"})
	aadd(aFldCpo,{"C5_SERIE  ","5"})
	aadd(aFldCpo,{"C5_DTLANC ","5"})
	aadd(aFldCpo,{"C5_FORNISS","5"})
	aadd(aFldCpo,{"C5_SOLFRE ","5"})
	aadd(aFldCpo,{"C5_RECISS ","5"})

	oProcess:SetRegua2(0)
	oProcess:IncRegua2("Zerando a tabela folder")


	//Limpa a pasta folder
	dbSelectArea( "SX3" )
	dbSetOrder( 1 )
	For nI := 1 To Len( aFldAlias )

		If SX3->(dbSeek(aFldAlias[nI]))

			While SX3->(!Eof()) .AND. SX3->X3_ARQUIVO == aFldAlias[nI]

				RecLock( "SX3", .F. )
					SX3->X3_FOLDER	:= space(len(SX3->X3_FOLDER))
				dbCommit()
				MsUnLock()

				SX3->(dbSkip())
			Enddo

			AutoGrLog( "Limpo o campo Folder do campo " + aFldCpo[nI][1] )
		EndIF

	Next

	oProcess:IncRegua2( "Atualizando Campos de Tabelas (SX3)..." )


	oProcess:SetRegua2( Len( aFldCpo ) )

	dbSelectArea( "SX3" )
	dbSetOrder( 2 )
	cAliasAtu := ""

	For nI := 1 To Len( aFldCpo )

		SX3->( dbSetOrder( 2 ) )

		If SX3->( dbSeek( PadR( aFldCpo[nI][1], nTamSeek ) ) )
			RecLock( "SX3", .F. )
				SX3->X3_FOLDER	:= aFldCpo[nI][2]
			dbCommit()
			MsUnLock()

			AutoGrLog( "Ajustado Folder campo " + aFldCpo[nI][1] )
		EndIF


		oProcess:IncRegua2( "Atualizando Campos de Tabelas (SX3)..." )

	Next nI

	AutoGrLog( CRLF + "Final da Atualização" + " SX3" + CRLF + Replicate( "-", 128 ) + CRLF )



Return NIL


Static Function FSAtuGE()
	Local aParSX6	:=	{}
	Local aSCX3CPO	:=	{}

	//Insira aqui o que será ajustado, campo, coluna e o avlaor a ser ajustado

	//aadd(aSCX3CPO,{"C5_CLIENTE","X3_VLDUSER",'Iif(EMPTY(&(ReadVar()):=PADL(AllTrim(&(ReadVar())),Len(&(ReadVar())),"0")),.T.,.T.)'})
	//aadd(aSCX3CPO,{"C5_LOJA","X3_VLDUSER",'Iif(EMPTY(&(ReadVar()):=PADL(AllTrim(&(ReadVar())),Len(&(ReadVar())),"0")),.T.,.T.)'})
	//aadd(aSCX3CPO,{"C5_NUM","X3_VISUAL",'V'}) //Define que o código do pedido de venda, não poderá ser alterado
	//aadd(aSCX3CPO,{"A1_COD","X3_RELACAO",'GetSxeNum("SA1","A1_COD")'}) //Definie como Ini padrão
	//aadd(aSCX3CPO,{"A1_LOJA","X3_RELACAO",'GetSxeNum("SA1","A1_COD")'}) //Definie como Ini padrão


	//aadd(aSCX3CPO,{"E1_PREFIXO","X3_VLDUSER",'If(_SetAutoMode(),.T.,ExistCpo("SX5","Z1"+M->E1_PREFIXO,1))'})
	//aadd(aSCX3CPO,{"E2_PREFIXO","X3_VLDUSER",'If(_SetAutoMode(),.T.,ExistCpo("SX5","Z1"+M->E2_PREFIXO,1))'})

	//Insira aqui os parametros que serão ajustados
	//aadd(aParSX6,{"MV_NATSINT","1"})
	//aadd(aParSX6,{"MV_MULNATR","T"})

	For nXU	:=	 1 To Len(aSCX3CPO)

		dbSelectArea("SX3")
		dbSetOrder(2)
		If dbSeek(aSCX3CPO[nXU][1])
			xValue	:=	&(aSCX3CPO[nXU][2])
			If alltrim(xValue)<> aSCX3CPO[nXU][3]
				AutoGrLog("SX3-> Empt/Fil:"+SM0->M0_CODFIL+" "+aSCX3CPO[nXU][1]+" "+aSCX3CPO[nXU][2]+":= De:"+xValue+" Para:"+aSCX3CPO[nXU][3])
				SX3->(RecLock("SX3",.F.))
				&(aSCX3CPO[nXU][2])	:= aSCX3CPO[nXU][3]
				SX3->(msUnlock())
			Else
				AutoGrLog("SX3-> Empt/Fil:"+SM0->M0_CODFIL+" "+aSCX3CPO[nXU][1]+" Não Alterado")
			EndIf
		Else
			AutoGrLog("SX3-> Empt/Fil:"+SM0->M0_CODFIL+" "+aSCX3CPO[nXU][1]+" "+aSCX3CPO[nXU][2]+":="+aParSX6[nXU][3]+" Não localizado")
		EndIf


	Next

	For nXU	:=	1 to Len(aParSX6)
		dbSelectArea("SX6")
		dbSetOrder(1)
		If dbSeek(SM0->M0_CODFIL+aParSX6[nXU][1])
			If  Alltrim(aParSX6[nXU][2]) <> Alltrim(SX6->X6_CONTEUD)

				AutoGrLog("SX6-> Empt/Fil:"+SM0->M0_CODFIL+" "+aParSX6[nXU][1]+":=De:"+Alltrim(SX6->X6_CONTEUD)+" Para:"+alltrim(aParSX6[nXU][2]))
				SX6->(RecLock("SX6",.F.))
				SX6->X6_CONTEUD	:= aParSX6[nXU][2]
				SX6->X6_CONTSPA	:= aParSX6[nXU][2]
				SX6->X6_CONTENG	:= aParSX6[nXU][2]
				SX6->(msUnlock())
			Else
				AutoGrLog("SX6-> Empt/Fil:"+SM0->M0_CODFIL+" Não Alterado")
			EndIf
		Else
			AutoGrLog("INFO","SX6-> Empt/Fil:"+SM0->M0_CODFIL+" "+aParSX6[nXU][1]+":="+aParSX6[nXU][2]+" Não Localizado")
		EndIf
	next

Return nil

//--------------------------------------------------------------------
/*/{Protheus.doc} EscEmpresa
Função genérica para escolha de Empresa, montada pelo SM0

@return aRet Vetor contendo as seleções feitas. Se não for marcada nenhuma o vetor volta vazio

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function EscEmpresa()

	//---------------------------------------------
	// Parâmetro  nTipo
	// 1 - Monta com Todas Empresas/Filiais
	// 2 - Monta só com Empresas
	// 3 - Monta só com Filiais de uma Empresa
	//
	// Parâmetro  aMarcadas
	// Vetor com Empresas/Filiais pré marcadas
	//
	// Parâmetro  cEmpSel
	// Empresa que será usada para montar seleção
	//---------------------------------------------
	Local   aRet      := {}
	Local   aSalvAmb  := GetArea()
	Local   aSalvSM0  := {}
	Local   aVetor    := {}
	Local   cMascEmp  := "??"
	Local   cVar      := ""
	Local   lChk      := .F.
	Local   lOk       := .F.
	Local   lTeveMarc := .F.
	Local   oNo       := LoadBitmap( GetResources(), "LBNO" )
	Local   oOk       := LoadBitmap( GetResources(), "LBOK" )
	Local   oDlg, oChkMar, oLbx, oMascEmp, oSay
	Local   oButDMar, oButInv, oButMarc, oButOk, oButCanc

	Local   aMarcadas := {}


	If !MyOpenSm0(.F.)
		Return aRet
	EndIf


	dbSelectArea( "SM0" )
	aSalvSM0 := SM0->( GetArea() )
	dbSetOrder( 1 )
	dbGoTop()

	While !SM0->( EOF() )

		If aScan( aVetor, {|x| x[2] == SM0->M0_CODIGO} ) == 0
			aAdd(  aVetor, { aScan( aMarcadas, {|x| x[1] == SM0->M0_CODIGO .and. x[2] == SM0->M0_CODFIL} ) > 0, ;
			SM0->M0_CODIGO, SM0->M0_CODFIL, SM0->M0_NOME, SM0->M0_FILIAL } )
		EndIf

		dbSkip()
	End

	RestArea( aSalvSM0 )

	Define MSDialog  oDlg Title "" From 0, 0 To 280, 395 Pixel

	oDlg:cToolTip := "Tela para Múltiplas Seleções de Empresas/Filiais"

	oDlg:cTitle   := "Selecione a(s) Empresa(s) para Atualização"

	@ 10, 10 Listbox  oLbx Var  cVar Fields Header " ", " ", "Empresa" Size 178, 095 Of oDlg Pixel
	oLbx:SetArray(  aVetor )
	oLbx:bLine := {|| {IIf( aVetor[oLbx:nAt, 1], oOk, oNo ), ;
	aVetor[oLbx:nAt, 2], ;
	aVetor[oLbx:nAt, 4]}}
	oLbx:BlDblClick := { || aVetor[oLbx:nAt, 1] := !aVetor[oLbx:nAt, 1], VerTodos( aVetor, @lChk, oChkMar ), oChkMar:Refresh(), oLbx:Refresh()}
	oLbx:cToolTip   :=  oDlg:cTitle
	oLbx:lHScroll   := .F. // NoScroll

	@ 112, 10 CheckBox oChkMar Var  lChk Prompt "Todos" Message "Marca / Desmarca"+ CRLF + "Todos" Size 40, 007 Pixel Of oDlg;
	on Click MarcaTodos( lChk, @aVetor, oLbx )

	// Marca/Desmarca por mascara
	@ 113, 51 Say   oSay Prompt "Empresa" Size  40, 08 Of oDlg Pixel
	@ 112, 80 MSGet oMascEmp Var  cMascEmp Size  05, 05 Pixel Picture "@!"  Valid (  cMascEmp := StrTran( cMascEmp, " ", "?" ), oMascEmp:Refresh(), .T. ) ;
	Message "Máscara Empresa ( ?? )"  Of oDlg
	oSay:cToolTip := oMascEmp:cToolTip

	@ 128, 10 Button oButInv    Prompt "&Inverter"  Size 32, 12 Pixel Action ( InvSelecao( @aVetor, oLbx, @lChk, oChkMar ), VerTodos( aVetor, @lChk, oChkMar ) ) ;
	Message "Inverter Seleção" Of oDlg
	oButInv:SetCss( CSSBOTAO )
	@ 128, 50 Button oButMarc   Prompt "&Marcar"    Size 32, 12 Pixel Action ( MarcaMas( oLbx, aVetor, cMascEmp, .T. ), VerTodos( aVetor, @lChk, oChkMar ) ) ;
	Message "Marcar usando" + CRLF + "máscara ( ?? )"    Of oDlg
	oButMarc:SetCss( CSSBOTAO )
	@ 128, 80 Button oButDMar   Prompt "&Desmarcar" Size 32, 12 Pixel Action ( MarcaMas( oLbx, aVetor, cMascEmp, .F. ), VerTodos( aVetor, @lChk, oChkMar ) ) ;
	Message "Desmarcar usando" + CRLF + "máscara ( ?? )" Of oDlg
	oButDMar:SetCss( CSSBOTAO )
	@ 112, 157  Button oButOk   Prompt "Processar"  Size 32, 12 Pixel Action (  RetSelecao( @aRet, aVetor ), oDlg:End()  ) ;
	Message "Confirma a seleção e efetua" + CRLF + "o processamento" Of oDlg
	oButOk:SetCss( CSSBOTAO )
	@ 128, 157  Button oButCanc Prompt "Cancelar"   Size 32, 12 Pixel Action ( IIf( lTeveMarc, aRet :=  aMarcadas, .T. ), oDlg:End() ) ;
	Message "Cancela o processamento" + CRLF + "e abandona a aplicação" Of oDlg
	oButCanc:SetCss( CSSBOTAO )

	Activate MSDialog  oDlg Center

	RestArea( aSalvAmb )
	dbSelectArea( "SM0" )
	dbCloseArea()

Return  aRet


//--------------------------------------------------------------------
/*/{Protheus.doc} MarcaTodos
Função auxiliar para marcar/desmarcar todos os ítens do ListBox ativo

@param lMarca  Contéudo para marca .T./.F.
@param aVetor  Vetor do ListBox
@param oLbx    Objeto do ListBox

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function MarcaTodos( lMarca, aVetor, oLbx )
	Local  nI := 0

	For nI := 1 To Len( aVetor )
		aVetor[nI][1] := lMarca
	Next nI

	oLbx:Refresh()

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} InvSelecao
Função auxiliar para inverter a seleção do ListBox ativo

@param aVetor  Vetor do ListBox
@param oLbx    Objeto do ListBox

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function InvSelecao( aVetor, oLbx )
	Local  nI := 0

	For nI := 1 To Len( aVetor )
		aVetor[nI][1] := !aVetor[nI][1]
	Next nI

	oLbx:Refresh()

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} RetSelecao
Função auxiliar que monta o retorno com as seleções

@param aRet    Array que terá o retorno das seleções (é alterado internamente)
@param aVetor  Vetor do ListBox

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function RetSelecao( aRet, aVetor )
	Local  nI    := 0

	aRet := {}
	For nI := 1 To Len( aVetor )
		If aVetor[nI][1]
			aAdd( aRet, { aVetor[nI][2] , aVetor[nI][3], aVetor[nI][2] +  aVetor[nI][3] } )
		EndIf
	Next nI

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} MarcaMas
Função para marcar/desmarcar usando máscaras

@param oLbx     Objeto do ListBox
@param aVetor   Vetor do ListBox
@param cMascEmp Campo com a máscara (???)
@param lMarDes  Marca a ser atribuída .T./.F.

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function MarcaMas( oLbx, aVetor, cMascEmp, lMarDes )
	Local cPos1 := SubStr( cMascEmp, 1, 1 )
	Local cPos2 := SubStr( cMascEmp, 2, 1 )
	Local nPos  := oLbx:nAt
	Local nZ    := 0

	For nZ := 1 To Len( aVetor )
		If cPos1 == "?" .or. SubStr( aVetor[nZ][2], 1, 1 ) == cPos1
			If cPos2 == "?" .or. SubStr( aVetor[nZ][2], 2, 1 ) == cPos2
				aVetor[nZ][1] := lMarDes
			EndIf
		EndIf
	Next

	oLbx:nAt := nPos
	oLbx:Refresh()

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} VerTodos
Função auxiliar para verificar se estão todos marcados ou não

@param aVetor   Vetor do ListBox
@param lChk     Marca do CheckBox do marca todos (referncia)
@param oChkMar  Objeto de CheckBox do marca todos

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function VerTodos( aVetor, lChk, oChkMar )
	Local lTTrue := .T.
	Local nI     := 0

	For nI := 1 To Len( aVetor )
		lTTrue := IIf( !aVetor[nI][1], .F., lTTrue )
	Next nI

	lChk := IIf( lTTrue, .T., .F. )
	oChkMar:Refresh()

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} MyOpenSM0
Função de processamento abertura do SM0 modo exclusivo

@author TOTVS Protheus
@since  22/12/2016
@obs    Gerado por EXPORDIC - V.5.2.1.0 EFS / Upd. V.4.20.15 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function MyOpenSM0(lShared)

	Local lOpen := .F.
	Local nLoop := 0

	//For nLoop := 1 To 20
	//dbUseArea( .T., , "SIGAMAT.EMP", "SM0", lShared, .F. )
	If OpenSM0Excl()
		lOpen	:=	.T.
	EndIf
	//If !Empty( Select( "SM0" ) )
	//	Sleep( 500 )
	//	lOpen := .T.
	//		dbSetIndex( "SIGAMAT.IND" )
	//		Exit
	//	EndIf

	Sleep( 500 )

	//Next nLoop

	//If !lOpen
	//	MsgStop( "Não foi possível a abertura da tabela " + ;
	//	IIf( lShared, "de empresas (SM0).", "de empresas (SM0) de forma exclusiva." ), "ATENÇÃO" )
	//EndIf

Return lOpen


//--------------------------------------------------------------------
/*/{Protheus.doc} LeLog
Função de leitura do LOG gerado com limitacao de string

@author TOTVS Protheus
@since  22/12/2016
@obs    Gerado por EXPORDIC - V.5.2.1.0 EFS / Upd. V.4.20.15 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function LeLog()
	Local cRet  := ""
	Local cFile := NomeAutoLog()
	Local cAux  := ""

	FT_FUSE( cFile )
	FT_FGOTOP()

	While !FT_FEOF()

		cAux := FT_FREADLN()

		If Len( cRet ) + Len( cAux ) < 1048000
			cRet += cAux + CRLF
		Else
			cRet += CRLF
			cRet += Replicate( "=" , 128 ) + CRLF
			cRet += "Tamanho de exibição maxima do LOG alcançado." + CRLF
			cRet += "LOG Completo no arquivo " + cFile + CRLF
			cRet += Replicate( "=" , 128 ) + CRLF
			Exit
		EndIf

		FT_FSKIP()
	End

	FT_FUSE()

Return cRet


/////////////////////////////////////////////////////////////////////////////
