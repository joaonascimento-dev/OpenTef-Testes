unit uprincipal;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, System.StrUtils, Vcl.Graphics, IdHashMessageDigest,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Imaging.Pngimage, Vcl.Imaging.pnglang,
  Vcl.Imaging.Jpeg, System.NetEncoding;

type
  // enumerador padr�o
  TConexaoStatus  =(csNaoInicializado, csDesconectado, csLink, csChaveado, csChaveadoAssinado, csLogado);
  TransacaoStatus =(tsEfetivada, tsNegada, tsCancelada, tsProcessando, tsAguardandoComando, tsNaoLocalizada, tsInicializada, tsComErro, tsAbortada, tsAguardandoDadosPDV);

  // definicoes das funcoes que serao chamadas pela biblioteca dinamicamente
  TRetorno                = function(VP_DadosEntrada: PUTF8Char;var VO_DadosSaida: PUTF8Char)      : Integer; cdecl;
  TSolicitaDadosPDV       = function(VP_Menu: PUTF8Char;var VO_Botao, VO_Dados: PUTF8Char): Integer; cdecl;
  TSolicitaDadosTransacao = function(VP_Mensagem: PUTF8Char;var VO_Dados: PUTF8Char): Integer; cdecl;
  TImprime                = function(VP_Dados: PUTF8Char)                                          : Integer; cdecl;
  TMostraMenu             = function(VP_Menu: PUTF8Char;var VO_Botao: PUTF8Char)                : Integer; cdecl;
  TMensagemOperador       = function(VP_Dados: PUTF8Char)                                 : Integer; cdecl;

  // definicoes das funcoes de inicializacao e conexao
  TTefInicializar = function(VP_PinPadModelo: Integer;
    VP_PinPadModeloLib, VP_PinPadModeloPorta, VP_PinPadLib, VP_ArquivoLog: PUTF8Char;
    VP_RetornoCliente: TRetorno; VP_SolicitaDadosTransacao: TSolicitaDadosTransacao;
    VP_SolicitaDadosPDV: TSolicitaDadosPDV; VP_Imprime: TImprime;
    VP_MostraMenu: TMostraMenu; VP_MensagemOperador: TMensagemOperador;
    VP_AmbienteTeste: Integer): Integer; cdecl;
  TTLogin = function(VP_Host: PUTF8Char; VP_Porta, VP_ID: Integer; VP_Chave: PUTF8Char; VP_Versao_Comunicacao: Integer;
    VP_Identificador: PUTF8Char)                           : Integer; cdecl;
  TTFinalizar     = function()                                 : Integer; cdecl;
  TTDesconectar   = function()                               : Integer; cdecl;
  TTOpenTefStatus = function(var VO_StatusRetorno: Integer): Integer; cdecl;

  // definicoes das funcoes para tratar da transacao exclusiva de aprova��o
  TTransacaoCreate          = function(VP_Comando, VP_IdentificadorCaixa: PUTF8Char;var VO_TransacaID: PUTF8Char; VP_TempoAguarda: Integer): Integer; cdecl;
  TTransacaoStatus          = function(var VO_Status: Integer;var VO_TransacaoChave: PUTF8Char; VP_TransacaoID: PUTF8Char)                 : Integer; cdecl;
  TTransacaoStatusDescricao = function(var VO_Status: PUTF8Char; VP_TransacaoID: PUTF8Char)                                       : Integer; cdecl;
  TTransacaoCancela         = function(var VO_Resposta: Integer; VP_TransacaoChave, VP_TransacaoID: PUTF8Char)                            : Integer; cdecl;
  TTransacaoFree            = procedure(VP_TransacaoID: PUTF8Char); cdecl;
  TTransacaoGetTag          = function(VP_TransacaoID, VP_Tag: PUTF8Char;var VO_Dados: PUTF8Char): Integer; cdecl;

  // definicoes das demais funcoes auxilares
  TTAlterarNivelLog     = procedure(VP_Nivel: Integer); cdecl;
  TVersao               = function(var VO_Dados: PUTF8Char)                                                                                     : Integer; cdecl;
  TTSolicitacao         = function(VP_Transmissao_ID, VP_Dados: PUTF8Char; VP_Procedimento: TRetorno; VP_TempoAguarda: Integer)           : Integer; cdecl;
  TTSolicitacaoBlocante = function(var VO_Transmissao_ID, VP_Dados: PUTF8Char;var VO_Retorno: PUTF8Char; VP_TempoAguarda: Integer): Integer; cdecl;

  // definicoes das funcoes para tratar da mensageria auxiliar
  TTMensagemCreate        = function(var VO_Mensagem: Pointer)                          : Integer; cdecl;
  TTMensagemCarregaTags   = function(VP_Mensagem: Pointer; VP_Dados: PUTF8Char)    : Integer; cdecl;
  TTMensagemComando       = function(VP_Mensagem: Pointer;var VP_Dados: PUTF8Char)     : Integer; cdecl;
  TTMensagemComandoDados  = function(VP_Mensagem: Pointer;var VP_Dados: PUTF8Char): Integer; cdecl;
  TTMensagemFree          = procedure(VP_Mensagem: Pointer); cdecl;
  TTMensagemLimpar        = procedure(VP_Mensagem: Pointer); cdecl;
  TTMensagemAddtag        = function(VP_Mensagem: Pointer; VP_Tag, VP_Dados: PUTF8Char)                                          : Integer; cdecl;
  TTMensagemAddcomando    = function(VP_Mensagem: Pointer; VP_Tag, VP_Dados: PUTF8Char)                                      : Integer; cdecl;
  TTMensagemTagAsString   = function(VP_Mensagem: Pointer;var VO_PChar: PUTF8Char)                                          : Integer; cdecl;
  TTMensagemTagCount      = function(VO_Mensagem: Pointer)                                                                     : Integer; cdecl;
  TTMensagemGetTag        = function(VO_Mensagem: Pointer; VP_Tag: PUTF8Char;var VO_Dados: PUTF8Char)                            : Integer; cdecl;
  TTMensagemGetTagIdx     = function(VO_Mensagem: Pointer; VL_Idx: Integer;var VO_Tag: PUTF8Char;var VO_Dados: PUTF8Char)     : Integer; cdecl;
  TTMensagemTagToStr      = function(VO_Mensagem: Pointer;var VO_Dados: PUTF8Char)                                             : Integer; cdecl;
  TTMensagemerro          = function(VP_CodigoErro: Integer;var VO_RespostaMensagem: PUTF8Char)                                    : Integer; cdecl;
  TTMensagemGetTagPosicao = function(VP_Mensagem: Pointer; VP_Posicao: Integer; VP_Tag: PUTF8Char;var VO_Dados: PUTF8Char): Integer; cdecl;
  TTMensagemAddTagPosicao = function(VP_Mensagem: Pointer; VP_Posicao: Integer; VP_Tag, VP_Dados: PUTF8Char)              : Integer; cdecl;

  TFPrincipal = class(TForm)
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    BVenda: TButton;
    Label3: TLabel;
    Label9: TLabel;
    ENSU: TEdit;
    Label25: TLabel;
    EDesconto: TEdit;
    Label11: TLabel;
    ECaixa: TEdit;
    Label26: TLabel;
    EObservacao: TEdit;
    EOperador: TEdit;
    Label12: TLabel;
    Label8: TLabel;
    EParcela: TEdit;
    EValorParcela: TEdit;
    Label4: TLabel;
    Label31: TLabel;
    Label28: TLabel;
    LTefLib: TLabel;
    ETefLib: TEdit;
    LPinPadLib: TLabel;
    LPinPadLibHashMd5: TLabel;
    LPinPadModeloLib: TLabel;
    LPinPadModeloLibHashMd5: TLabel;
    LPinPadModelo: TLabel;
    LPinPadModeloPorta: TLabel;
    LTempo: TLabel;
    EPinPadLib: TEdit;
    EPinPadLibHashMd5: TEdit;
    EPinPadModeloLib: TEdit;
    EPinPadModeloLibHashMd5: TEdit;
    EPinPadModelo: TEdit;
    EPinPadModeloPorta: TEdit;
    ETempo: TEdit;
    BInicializar: TButton;
    EHost: TEdit;
    LHost: TLabel;
    LPorta: TLabel;
    EPorta: TEdit;
    EID: TEdit;
    LID: TLabel;
    EChave: TMemo;
    LChave: TLabel;
    LIdentificador: TLabel;
    EIdentificador: TMemo;
    BLogin: TButton;
    BDesconectar: TButton;
    cbxAmbienteTeste: TCheckBox;
    BLogGravacao: TButton;
    MChave: TMemo;
    MStatus: TMemo;
    Label1: TLabel;
    ECupomFiscal: TEdit;
    Label29: TLabel;
    Label30: TLabel;
    ELink: TEdit;
    EXml: TMemo;
    EDataHora: TDateTimePicker;
    IFundo: TImage;
    PTopo: TPanel;
    LTitulo: TLabel;
    lblStatusConexao: TLabel;
    GroupBox1: TGroupBox;
    EValorItens: TEdit;
    Label13: TLabel;
    EValorValeCultura: TEdit;
    Label16: TLabel;
    EValorRefeicao: TEdit;
    Label15: TLabel;
    EValorAlimentacao: TEdit;
    Label14: TLabel;
    procedure BInicializarClick(Sender: TObject);
    procedure BLoginClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure BLogGravacaoClick(Sender: TObject);
    procedure BVendaClick(Sender: TObject);
    procedure MontarMenu(VP_Mensagem: Pointer);
    procedure BDesconectarClick(Sender: TObject);
  private
    procedure CliqueDoBotao(VP_Botao: TObject);
  public

  end;

var
  F_Principal : TFPrincipal;
  F_ArquivoLog:string;
  F_Mensagem  : Pointer;

  F_TefLib        : THandle;
  F_TefInicializar: TTefInicializar;
  F_Login         : TTLogin;
  F_Desconectar   : TTDesconectar;
  F_Finalizar     : TTFinalizar;
  F_StatusOpenTef : TTOpenTefStatus;

  F_MensagemCreate       : TTMensagemCreate;
  F_MensagemCarregaTags  : TTMensagemCarregaTags;
  F_MensagemComando      : TTMensagemComando;
  F_MensagemComandoDados : TTMensagemComandoDados;
  F_MensagemFree         : TTMensagemFree;
  F_MensagemLimpar       : TTMensagemLimpar;
  F_MensagemAddTag       : TTMensagemAddtag;
  F_MensagemAddComando   : TTMensagemAddcomando;
  F_MensagemTagAsString  : TTMensagemTagAsString;
  F_MensagemTagCount     : TTMensagemTagCount;
  F_MensagemGetTag       : TTMensagemGetTag;
  F_MensagemGetTagIdx    : TTMensagemGetTagIdx;
  F_MensagemTagToStr     : TTMensagemTagToStr;
  F_MensagemGetTagPosicao: TTMensagemGetTagPosicao;
  F_MensagemAddTagPosicao: TTMensagemAddTagPosicao;

  F_TransacaoCancela        : TTransacaoCancela;
  F_TransacaoCreate         : TTransacaoCreate;
  F_TransacaoFree           : TTransacaoFree;
  F_TransacaoStatus         : TTransacaoStatus;
  F_TransacaoStatusDescricao: TTransacaoStatusDescricao;
  F_TransacaoGetTag         : TTransacaoGetTag;

  F_Erro               : TTMensagemerro;
  F_Versao             : TVersao;
  F_AlterarNivelLog    : TTAlterarNivelLog;
  F_SolicitacaoBlocante: TTSolicitacaoBlocante;
  F_Solicitacao        : TTSolicitacao;

  // as funcoes que serao chamadas pela biblioteca
function Retorno(VP_DadosEntrada: PUTF8Char;var VO_DadosSaida: PUTF8Char): Integer; cdecl;
function SolicitaDadosPdv(VP_Mensagem: PUTF8Char;var VO_Botao, VO_Dados: PUTF8Char): Integer; cdecl;
function SolicitaDadosTransacao(VP_Mensagem: PUTF8Char;var VO_Dados: PUTF8Char): Integer; cdecl;
function Imprime(VP_Dados: PUTF8Char): Integer; cdecl;
function MostraMenu(VP_Menu: PUTF8Char;var VO_Botao: PUTF8Char): Integer; cdecl;
function MensagemOperador(VP_Dados: PUTF8Char): Integer; cdecl;

const
  C_VersaoComunicacao = 1;

function Md5(const texto:string):string;
function Md5File(const fileName:string):string;
function StrToBase64(VP_Str:string):string;
function Base64ToStr(VP_Bse64:string):string;

implementation

{$R *.dfm}

uses
  umenu_venda, uimpressao;

// implementacao das funcoes que serao chamadas pela biblioteca

// quando o opentef envia alguma solicita��o ao PDV
function Retorno(VP_DadosEntrada: PUTF8Char;var VO_DadosSaida: PUTF8Char): Integer; cdecl;
var
  VL_Dados                 : PUTF8Char;
  VL_Comando               : PUTF8Char;
  VL_ComandoDados          : PUTF8Char;
  VL_Mensagem              : Pointer;
  VL_String                :string;
  VL_Erro                  : Integer;
  VL_DescricaoErro         : PUTF8Char;
  VL_TransacaoID           : PUTF8Char;
  VL_DescricaoErroTransacao: PUTF8Char;
  VL_TransacaoChave        : PUTF8Char;
  VL_Bin                   : PUTF8Char;
  VL_TransacaoStatus       : Integer; // numerador  (tsEfetivada,tsNegada,tsCancelada,tsProcessando,tsNaoLocalizada,tsInicializada);
begin
  Result                    := 0;
  VL_Erro                   := 0;
  VL_String                 := '';
  VL_Dados                  := '';
  VL_DescricaoErro          := '';
  VL_Comando                := '';
  VL_ComandoDados           := '';
  VL_Comando                := '';
  VL_TransacaoID            := '';
  VL_DescricaoErroTransacao := '';
  VL_TransacaoChave         := '';
  VL_Bin                    := '';
  VL_Mensagem               := nil;
  try
    F_MensagemCreate(VL_Mensagem);

    VL_Erro := F_MensagemCarregaTags(VL_Mensagem, VP_DadosEntrada); // carrega a mensagem recebida
    if VL_Erro <> 0 then
    begin
      F_MensagemAddComando(VL_Mensagem, '0026', PUTF8Char(UTF8Encode(IntToStr(VL_Erro)))); // retorno com erro pois nao conseguiu carregar a mensagem recebida
      F_MensagemTagAsString(VL_Mensagem, VO_DadosSaida);
      Exit;
    end;

    F_MensagemComando(VL_Mensagem, VL_Comando);
    F_MensagemComandoDados(VL_Mensagem, VL_ComandoDados);

    if VL_Comando = '0026' then // retorno com erro
    begin
      if VL_ComandoDados = '96' then // desconectado
      begin
        F_Principal.lblStatusConexao.Caption    := 'Desconectado';
        F_Principal.lblStatusConexao.Font.Color := clRed;
      end;

      F_Erro(StrToInt(VL_ComandoDados), VL_DescricaoErro);
      ShowMessage('Erro: ' + UTF8Decode(VL_ComandoDados)+ #13 + 'Descri��o: ' + UTF8Decode(VL_DescricaoErro));
      Exit;
    end;

    if VL_Comando = '0018' then // Veio pedido de mostrar menu de venda
    begin
      F_Principal.MontarMenu(VL_Mensagem); // monta o menu e aguarda a escolha pelo operador
      Exit;
    end;

    if VL_Comando = '010C' then // solicitacao de atualizacao da biblioteca tef
    begin
      VL_Dados := '';
      F_MensagemGetTag(VL_Mensagem, '00FD', VL_Dados); // atualizacao obrigatoria
      if VL_Dados = 'S' then
      begin
        // comando de retorno deve conter o caminho onde sera baixada a nova versao
        F_MensagemAddComando(VL_Mensagem, '010C', PUTF8Char(UTF8Encode(ExtractFilePath(ParamStr(0))+ '..\..\tef_lib\win64\')));
        F_MensagemTagAsString(VL_Mensagem, VO_DadosSaida);
      end;

      VL_Dados := '';
      F_MensagemGetTag(VL_Mensagem, '010A', VL_Dados); // atualizacao opcional
      if VL_Dados = 'S' then
      begin
        if Application.MessageBox('Nova atualiza��o do tef, deseja atualizar?', 'PDV', MB_ICONQUESTION + MB_YESNO)= idYes then
        begin
          // comando de retorno deve conter o caminho onde sera baixada a nova versao
          F_MensagemAddComando(VL_Mensagem, '010C', PUTF8Char(UTF8Encode(ExtractFilePath(ParamStr(0))+ '..\..\tef_lib\win64\')));
          F_MensagemTagAsString(VL_Mensagem, VO_DadosSaida);
        end;
      end;

      Exit;
    end;

    if VL_Comando = '00A4' then // houve uma alterarcao no status da transacao
    begin
      VL_TransacaoStatus := StrToInt(VL_ComandoDados);
      F_MensagemGetTag(VL_Mensagem, '0034', VL_TransacaoID);    // transacao id
      F_MensagemGetTag(VL_Mensagem, '00F1', VL_TransacaoChave); // chave da transacao

      if Ord(tsComErro)= VL_TransacaoStatus then
      begin
        VL_Erro := F_TransacaoStatusDescricao(VL_DescricaoErroTransacao, VL_TransacaoID); // consulta o codigo do erro vindo do opentef e descricao vinda da operadora
        F_Erro(VL_Erro, VL_DescricaoErro);
        ShowMessage('Transa��o com erro ' + UTF8Decode(VL_TransacaoID)+ ' ' + UTF8Decode(VL_DescricaoErro));
        F_Principal.MStatus.Lines.Add('Transa��o com erro ' + UTF8Decode(VL_TransacaoID)+ ' ' + UTF8Decode(VL_DescricaoErro));
        F_TransacaoFree(VL_TransacaoID);
      end;

      if Ord(tsCancelada)= VL_TransacaoStatus then
      begin
        VL_Erro := F_TransacaoStatusDescricao(VL_DescricaoErroTransacao, VL_TransacaoID); // consulta o codigo do erro vindo do opentef e descricao vinda da operadora
        F_Erro(VL_Erro, VL_DescricaoErro);
        ShowMessage('Transa��o cancelada ' + UTF8Decode(VL_TransacaoID)+ ' ' + UTF8Decode(VL_DescricaoErro));
        F_Principal.MStatus.Lines.Add('Transa��o cancelada ' + UTF8Decode(VL_TransacaoID)+ ' ' + UTF8Decode(VL_DescricaoErro));
        F_TransacaoFree(VL_TransacaoID);
      end;

      if Ord(tsNegada)= VL_TransacaoStatus then
      begin
        VL_Erro := F_TransacaoStatusDescricao(VL_DescricaoErroTransacao, VL_TransacaoID); // consulta o codigo do erro vindo do opentef e descricao vinda da operadora
        F_Erro(VL_Erro, VL_DescricaoErro);
        ShowMessage('Transa��o negada ' + UTF8Decode(VL_TransacaoID)+ ' ' + UTF8Decode(VL_DescricaoErro));
        F_Principal.MStatus.Lines.Add('Transa��o negada ' + UTF8Decode(VL_TransacaoID)+ ' ' + UTF8Decode(VL_DescricaoErro));
        F_TransacaoFree(VL_TransacaoID);
      end;

      if Ord(tsNaoLocalizada)= VL_TransacaoStatus then
      begin
        VL_Erro := F_TransacaoStatusDescricao(VL_DescricaoErroTransacao, VL_TransacaoID); // consulta o codigo do erro vindo do opentef e descricao vinda da operadora
        F_Erro(VL_Erro, VL_DescricaoErro);
        ShowMessage('Transa��o n�o localizada ' + UTF8Decode(VL_TransacaoID)+ ' ' + UTF8Decode(VL_DescricaoErro));
        F_Principal.MStatus.Lines.Add('Transa��o n�o localizada ' + UTF8Decode(VL_TransacaoID)+ ' ' + UTF8Decode(VL_DescricaoErro));
        F_TransacaoFree(VL_TransacaoID);
      end;

      if Ord(tsAbortada)= VL_TransacaoStatus then
      begin
        VL_Erro := F_TransacaoStatusDescricao(VL_DescricaoErroTransacao, VL_TransacaoID); // consulta o codigo do erro vindo do opentef e descricao vinda da operadora
        F_Erro(VL_Erro, VL_DescricaoErro);
        ShowMessage('Transa��o abortada ' + UTF8Decode(VL_TransacaoID)+ ' ' + UTF8Decode(VL_DescricaoErro));
        F_Principal.MStatus.Lines.Add('Transa��o abortada ' + UTF8Decode(VL_TransacaoID)+ ' ' + UTF8Decode(VL_DescricaoErro));
        F_TransacaoFree(VL_TransacaoID);
      end;

      if Ord(tsEfetivada)= VL_TransacaoStatus then
      begin
        ShowMessage('Transa��o aprovada ' + VL_TransacaoID);
        F_Principal.MChave.Lines.Add(VL_TransacaoChave);
        F_Principal.MStatus.Lines.Add('Transacao ID: ' + UTF8Decode(VL_TransacaoID)+ ' Efetivada');
        F_TransacaoGetTag(VL_TransacaoID, '0036', VL_Bin); // bin do cartao
        F_Principal.MStatus.Lines.Add('Bin: ' + UTF8Decode(VL_Bin));
        F_TransacaoFree(VL_TransacaoID);
      end;

      case VL_TransacaoStatus of // status da transacao em andamento
        Ord(tsProcessando):
          F_Principal.MStatus.Lines.Add('Transacao ID:' + UTF8Decode(VL_TransacaoID)+ 'Estado de processamento');
        Ord(tsInicializada):
          F_Principal.MStatus.Lines.Add('Transacao ID:' + UTF8Decode(VL_TransacaoID)+ 'Estado de inicializada');
        Ord(tsAguardandoComando):
          F_Principal.MStatus.Lines.Add('Transacao ID:' + UTF8Decode(VL_TransacaoID)+ 'Estado de aguardando comando');
        Ord(tsAguardandoDadosPDV):
          F_Principal.MStatus.Lines.Add('Transacao ID:' + UTF8Decode(VL_TransacaoID)+ 'Estado de aguardando dados do pdv');
      end;

      Exit;
    end;

    F_MensagemAddComando(VL_Mensagem, '0026', '1'); // retorna erro pois a resposta desse comando ainda nao foi implementada
    F_MensagemTagAsString(VL_Mensagem, VO_DadosSaida);

  finally
    F_MensagemFree(VL_Mensagem);
  end;
end;

// quando o opentef pede informa��o ao operador do caixa
function SolicitaDadosPdv(VP_Mensagem: PUTF8Char;var VO_Botao, VO_Dados: PUTF8Char): Integer; cdecl;
var
  VL_btn      : TMButton;
  VL_I        : Integer;
  VL_Tag      : PUTF8Char;
  VL_Dados    : PUTF8Char;
  VL_String   :string;
  VL_MenuVenda: TF_MenuVenda;
  VL_Imagem   :string;

  procedure StrToImagem(Dados:string;var Imagem: TImage);
  var
    VL_JPG                           : TJPEGImage;
    VL_PNG                           : TPngImage;
    VL_BPM                           : TBitmap;
    VL_ImagemMemoria                 : TStringStream;
    VL_I                             : Integer;
    VL_Tipo_Imagem, VL_ImagemDados, L:string;
  begin
    VL_ImagemDados := '';
    L              := '';
    VL_Tipo_Imagem := 'TI_JPG';

    if Dados = '' then
    begin
      Imagem.Picture.Graphic := nil;
      Exit;
    end;

    VL_ImagemDados   := Base64ToStr(Dados);
    VL_ImagemMemoria := TStringStream.Create(VL_ImagemDados);

    if Length(VL_ImagemDados)> 5 then // verifica o tipo da imagem
    begin
      if((char(VL_ImagemDados[2])= 'P')and(char(VL_ImagemDados[3])= 'N')and(char(VL_ImagemDados[4])= 'G'))then
        VL_Tipo_Imagem := 'TI_Png';
      if((char(VL_ImagemDados[1])= 'B')and(char(VL_ImagemDados[2])= 'M'))then
        VL_Tipo_Imagem := 'TI_BMP';
    end;

    // carrega a imagem de acordo com o tipo

    if VL_Tipo_Imagem = 'TI_JPG' then
    begin
      VL_JPG := TJPEGImage.Create;
      VL_JPG.LoadFromStream(VL_ImagemMemoria);
      Imagem.Picture.Assign(VL_JPG);
      VL_JPG.Free;
      VL_ImagemMemoria.Free;
    end
    else
      if VL_Tipo_Imagem = 'TI_Png' then
    begin
      VL_PNG := TPngImage.Create;
      VL_PNG.LoadFromStream(VL_ImagemMemoria);
      Imagem.Picture.Assign(VL_PNG);
      VL_PNG.Free;
      VL_ImagemMemoria.Free;
    end
    else
      if VL_Tipo_Imagem = 'TI_BMP' then
    begin
      VL_BPM := TBitmap.Create;
      VL_BPM.LoadFromStream(VL_ImagemMemoria);
      Imagem.Picture.Assign(VL_BPM);
      VL_BPM.Free;
      VL_ImagemMemoria.Free;
    end;
  end;

begin
  Result    := 0;
  VL_Tag    := '';
  VL_Dados  := '';
  VL_String := '';
  F_MensagemCarregaTags(F_Mensagem, VP_Mensagem);

  VL_MenuVenda := TF_MenuVenda.Create(F_Principal);

  VL_MenuVenda.Height := 120;

  F_MensagemGetTag(F_Mensagem, '00DA', VL_Dados); // verifica se veio mensagem a ser mostrada
  if VL_Dados <> '' then
  begin
    VL_MenuVenda.PMensagem.Visible := True;
    VL_MenuVenda.LMensagem.Caption := UTF8Decode(VL_Dados);
    VL_MenuVenda.Height            := VL_MenuVenda.Height + 100;
  end;

  VL_Dados := '';
  VL_I     := F_MensagemGetTag(F_Mensagem, '0033', VL_Dados); // VERIFICA SE � PARA CAPTURAR ALGUMA INFORMA��O
  if(VL_I = 0)and(VL_Dados <> '')then
  begin
    if VL_Dados = 'M' then
      // VERIFICA SE � PARA ESCONDER A DIGITA��O "SENHA POR EXEMPLO"
      VL_MenuVenda.EDados.PasswordChar := '*';
    VL_MenuVenda.PDados.Visible        := True;
    VL_MenuVenda.Height                := VL_MenuVenda.Height + 80;
  end;

  VL_Dados := '';
  VL_I     := F_MensagemGetTag(F_Mensagem, '002E', VL_Dados);
  // VERIFICA SE VEIO IMAGEM A SER MOSTRADA "QR CODE, FOTO..."
  if(VL_I = 0)and(VL_Dados <> '')then
  begin
    VL_Imagem := UTF8Decode(VL_Dados);
    StrToImagem(VL_Imagem, VL_MenuVenda.Imagem);
    VL_MenuVenda.PImagem.Visible := True;
    VL_MenuVenda.Height          := VL_MenuVenda.Height + 300;
  end;

  VL_Dados := '';
  F_MensagemGetTag(F_Mensagem, '00DD', VL_Dados); // CONTEM A LISTA DE BOTOES
  F_MensagemCarregaTags(F_Mensagem, VL_Dados);

  // SEMPRE COLOCAR BOTAO DE CANCELAMENTO
  VL_btn                := TMButton.Create(VL_MenuVenda.PBotao);
  VL_btn.V_tag          := '0030';
  VL_btn.Caption        := 'Cancela';
  VL_btn.Align          := alTop;
  VL_btn.Height         := 20;
  VL_btn.Margins.Left   := 20;
  VL_btn.Margins.Right  := 20;
  VL_btn.Margins.Top    := 20;
  VL_btn.Margins.Bottom := 20;
  VL_btn.Parent         := VL_MenuVenda.PBotao;
  VL_btn.TabOrder       := 0;
  VL_btn.OnClick        := F_Principal.CliqueDoBotao;

  // cria dinamicamente a lista de botoes
  for VL_I := 1 to F_MensagemTagCount(F_Mensagem)do
  begin
    F_MensagemGetTagIdx(F_Mensagem, VL_I, VL_Tag, VL_Dados);
    if VL_Tag <> '0030' then
    // PULA SE TIVER BOTAO DE CANCELAMENTO POIS JA FOI COLOCADO ACIMA
    begin
      VL_btn := TMButton.Create(VL_MenuVenda.PBotao);
      F_MensagemGetTagIdx(F_Mensagem, VL_I, VL_Tag, VL_Dados);
      VL_btn.V_tag          := VL_Tag;
      VL_btn.Caption        := UTF8Decode(VL_Dados);
      VL_btn.Align          := alTop;
      VL_btn.Height         := 20;
      VL_btn.Margins.Left   := 20;
      VL_btn.Margins.Right  := 20;
      VL_btn.Margins.Top    := 20;
      VL_btn.Margins.Bottom := 20;
      VL_btn.Parent         := VL_MenuVenda.PBotao;
      VL_btn.TabOrder       := 0;
      VL_MenuVenda.Height   := VL_MenuVenda.Height + 40;
      VL_btn.OnClick        := F_Principal.CliqueDoBotao;
    end;
  end;
  VL_MenuVenda.Height := VL_MenuVenda.Height + 40;

  F_MensagemComandoDados(F_Mensagem, VL_Dados);
  VL_MenuVenda.ShowModal;

  // devolve os dados informados
  VO_Dados := PUTF8Char(UTF8Encode(VL_MenuVenda.EDados.Text));

  // devolve a tag do botao selecionado
  VO_Botao := PUTF8Char(UTF8Encode(VL_MenuVenda.V_Botao));

  VL_MenuVenda.Free;
end;

// quando o opentef pede dados da venda para concluir a transa��o
function SolicitaDadosTransacao(VP_Mensagem: PUTF8Char;var VO_Dados: PUTF8Char): Integer; cdecl;
var
  VL_I                          : Integer;
  VL_Tag                        : PUTF8Char;
  VL_Dados                      : PUTF8Char;
  VL_PChar                      : PUTF8Char;
  VL_Resposta, VL_TagConciliacao: Pointer;
  VL_DadosEnviados              : PUTF8Char;
begin
  Result           := 0;
  VL_Tag           := '';
  VL_Dados         := '';
  VL_PChar         := '';
  VL_DadosEnviados := '';
  VL_Resposta      := nil;
  F_MensagemCreate(VL_Resposta);
  F_MensagemAddComando(VL_Resposta, '00E1', 'R'); // retorno da solicitacao de dados
  F_MensagemCarregaTags(F_Mensagem, VP_Mensagem);

  // A OPERADORA DE CART�O POR SOLICITAR OS DADOS PARA APROVA��O
  // DEVE TESTAR TODOS OS POSSIVEIS DADOS SOLICITADOS PARA RESPONDER A OPERADORA
  // SE ALGUM DADO SOLICITADO N�O FOR RESPONDIDO PODE HAVER A NEGA��O DA TRANSA��O PELA OPERADORA
  // OBSERVER SEMPRE AS TAGS DE CADA VERS�O DO OPEN TEF

  for VL_I := 1 to F_MensagemTagCount(F_Mensagem)do
  begin
    F_MensagemGetTagIdx(F_Mensagem, VL_I, VL_Tag, VL_Dados);

    if VL_Tag = '0011' then // IDENTIFICA��O DO CAIXA
      F_MensagemAddTag(VL_Resposta, '0011', PUTF8Char(UTF8Encode(F_Principal.ECaixa.Text)));

    if VL_Tag = '0012' then // IDENTIFICA��O DO OPERADOR DO CAIXA
      F_MensagemAddTag(VL_Resposta, '0012', PUTF8Char(UTF8Encode(F_Principal.EOperador.Text)));

    if VL_Tag = '0010' then // NUMERO DO CUPOM FISCAL
      F_MensagemAddTag(VL_Resposta, '0010', PUTF8Char(UTF8Encode(F_Principal.ECupomFiscal.Text)));

    if VL_Tag = '000E' then // VALOR DA PARCELA
      F_MensagemAddTag(VL_Resposta, '000E', PUTF8Char(UTF8Encode(F_Principal.EValorParcela.Text)));

    if VL_Tag = '000F' then // NUMERO DE PARCELAS
      F_MensagemAddTag(VL_Resposta, '000F', PUTF8Char(UTF8Encode(F_Principal.EParcela.Text)));

    if VL_Tag = '0013' then // VALOR TOTAL
      F_MensagemAddTag(VL_Resposta, '0013', PUTF8Char(UTF8Encode(F_Principal.EValorItens.Text)));

    if VL_Tag = '0014' then // VALOR TOTAL REFERENTE A PRODUTOS PERTECENTES AO PAT ALIMENTO IN NATURA
      F_MensagemAddTag(VL_Resposta, '0014', PUTF8Char(UTF8Encode(F_Principal.EValorAlimentacao.Text)));

    if VL_Tag = '0015' then // VALOR TOTAL REFERENTE A PRODUTOS PERTECENTES AO PAT ALIMENTO PRONTO
      F_MensagemAddTag(VL_Resposta, '0015', PUTF8Char(UTF8Encode(F_Principal.EValorRefeicao.Text)));

    if VL_Tag = '0016' then // VALOR TOTAL REFERENTE A PRODUTOS PERTECENTES AO VALE CULTURA
      F_MensagemAddTag(VL_Resposta, '0016', PUTF8Char(UTF8Encode(F_Principal.EValorValeCultura.Text)));

    if VL_Tag = '0017' then // XML DO CUPOM FISCAL N�O PRECISA ASSINAR E A FORMATA��O � LIVRE
      F_MensagemAddTag(VL_Resposta, '0017', PUTF8Char(UTF8Encode(F_Principal.EXml.Lines.Text)));

    if VL_Tag = '000B' then // NSU OU IDENTIFICADOR DA TRANSA��O GERADO PELO PDV
      F_MensagemAddTag(VL_Resposta, '000B', PUTF8Char(UTF8Encode(F_Principal.ENSU.Text)));

    if VL_Tag = '000C' then // DATA DA VENDA
      F_MensagemAddTag(VL_Resposta, '000C', PUTF8Char(UTF8Encode(DateToStr(F_Principal.EDataHora.Date))));

    if VL_Tag = '000D' then // HORA DA VENDA
      F_MensagemAddTag(VL_Resposta, '000D', PUTF8Char(UTF8Encode(TimeToStr(F_Principal.EDataHora.Time))));

    if VL_Tag = '00E5' then // LINK DA VALIDA��O DA NOTA/CUPOM FISCAL
      F_MensagemAddTag(VL_Resposta, '00E5', PUTF8Char(UTF8Encode(F_Principal.ELink.Text)));

    if VL_Tag = '00E6' then // VALOR DO DESCONTO
      F_MensagemAddTag(VL_Resposta, '00E6', PUTF8Char(UTF8Encode(F_Principal.EDesconto.Text)));

    if VL_Tag = '0040' then // OBSERVA��O SOBRE A VENDA
      F_MensagemAddTag(VL_Resposta, '0040', PUTF8Char(UTF8Encode(F_Principal.EObservacao.Text)));
  end;

  F_MensagemTagAsString(VL_Resposta, VO_Dados);
  F_MensagemFree(VL_Resposta);
end;

// quando o opentef solicita que seja impresso alguma coisa
function Imprime(VP_Dados: PUTF8Char): Integer; cdecl;
var
  VL_Texto:string;
begin
  Result   := 0;
  VL_Texto := UTF8Decode(VP_Dados);
  VL_Texto := ReplaceStr(VL_Texto, '<br>', #13); // ajusta quebra de linha seguindo formata��o do open tef a tag <br> indica quebra de linha

  Application.CreateForm(TFImpressao, FImpressao);

  FImpressao.MImpressao.Lines.Text := VL_Texto;
  FImpressao.ShowModal;
  FImpressao.Free;
end;

// quando o opentef quer que seja exibido o menu din�mico
function MostraMenu(VP_Menu: PUTF8Char;var VO_Botao: PUTF8Char): Integer; cdecl;
var
  VL_btn      : TMButton;
  VL_I        : Integer;
  VL_Tag      : PUTF8Char;
  VL_Dados    : PUTF8Char;
  VL_MenuVenda: TF_MenuVenda;
begin
  Result   := 0;
  VL_Tag   := '';
  VL_Dados := '';
  F_MensagemCarregaTags(F_Mensagem, VP_Menu);

  VL_MenuVenda        := TF_MenuVenda.Create(F_Principal);
  VL_MenuVenda.Height := 170;

  // cria botao padrao de cancelar
  VL_btn                := TMButton.Create(VL_MenuVenda.PBotao);
  VL_btn.V_tag          := '0030';
  VL_btn.Caption        := 'Cancela';
  VL_btn.Align          := alTop;
  VL_btn.Height         := 20;
  VL_btn.Margins.Left   := 20;
  VL_btn.Margins.Right  := 20;
  VL_btn.Margins.Top    := 20;
  VL_btn.Margins.Bottom := 20;
  VL_btn.Parent         := VL_MenuVenda.PBotao;
  VL_btn.TabOrder       := 0;
  VL_btn.OnClick        := F_Principal.CliqueDoBotao;

  // cria dinamicamente a lista de botao selecinado
  for VL_I := 1 to F_MensagemTagCount(F_Mensagem)do
  begin
    F_MensagemGetTagIdx(F_Mensagem, VL_I, VL_Tag, VL_Dados);
    if VL_Tag <> '0030' then // pula se tiver tag 0030 que � de cancelamento pois ja foi criada acima
    begin
      VL_btn := TMButton.Create(VL_MenuVenda.PBotao);
      F_MensagemGetTagIdx(F_Mensagem, VL_I, VL_Tag, VL_Dados);
      VL_btn.V_tag          := VL_Tag;
      VL_btn.Caption        := UTF8Decode(VL_Dados);
      VL_btn.Align          := alTop;
      VL_btn.Height         := 20;
      VL_btn.Margins.Left   := 20;
      VL_btn.Margins.Right  := 20;
      VL_btn.Margins.Top    := 20;
      VL_btn.Margins.Bottom := 20;
      VL_btn.Parent         := VL_MenuVenda.PBotao;
      VL_btn.TabOrder       := 0;
      VL_MenuVenda.Height   := VL_MenuVenda.Height + 40;
      VL_btn.OnClick        := F_Principal.CliqueDoBotao;
    end;
  end;

  VL_MenuVenda.Height := VL_MenuVenda.Height + 40;
  F_MensagemComandoDados(F_Mensagem, VL_Dados);
  VL_MenuVenda.ShowModal;

  // devolve qual a tag do botao selecionado
  VO_Botao := PUTF8Char(UTF8Encode(VL_MenuVenda.V_Botao));

  VL_MenuVenda.Free;
end;

// quando o opentef quer exibir alguma informa��o ao operador do caixa
function MensagemOperador(VP_Dados: PUTF8Char): Integer; cdecl;
var
  VL_String:string;
begin
  Result    := 0;
  VL_String := UTF8Decode(VP_Dados);
  VL_String := ReplaceStr(VL_String, '<br>', #13); // ajusta quebra de linha seguindo formata��o do open tef a tag <br> indica quebra de linha
  ShowMessage(VL_String);
end;

procedure TFPrincipal.BDesconectarClick(Sender: TObject);
var
  VL_Codigo       : Integer;
  VL_DescricaoErro: PUTF8Char;
begin
  VL_Codigo := F_Desconectar();

  if VL_Codigo <> 0 then
  begin
    F_Erro(VL_Codigo, VL_DescricaoErro);
    ShowMessage('Erro: ' + IntToStr(VL_Codigo)+ #13 + 'Descri��o: ' + UTF8Decode(VL_DescricaoErro));
    Exit;
  end;

  lblStatusConexao.Caption    := 'Desconectado';
  lblStatusConexao.Font.Color := clRed;
end;

procedure TFPrincipal.BInicializarClick(Sender: TObject);
var
  VL_Codigo       : Integer;
  VL_AmbienteTeste: Integer;
  VL_PinpadModelo : Integer;
  VL_DescricaoErro: PUTF8Char;
begin
  try
    VL_DescricaoErro := '';

    // se ativado a biblioteca simulara um ambiente de teste sem se comunicar o opentef
    if cbxAmbienteTeste.Checked then
      VL_AmbienteTeste := 1 // ativado
    else
      VL_AmbienteTeste := 0; // desativado

    // defini o modelo do pinpad a ser utilizado
    if EPinPadModelo.Text = 'GERTEC_PPC930' then
      VL_PinpadModelo := 1
    else
      VL_PinpadModelo := 0; // sem pinpad

    // para garantir que os arquivos sao oficias do opentef e recomendado a verificacao do hash
    if EPinPadLibHashMd5.Text <> '' then
    begin
      if EPinPadLibHashMd5.Text <> Md5File(ExtractFilePath(ParamStr(0))+ ETefLib.Text)then
        ShowMessage('O Arquivo PinPad lib n�o esta com o Hash V�lido');
    end
    else
      EPinPadLibHashMd5.Text := Md5File(ExtractFilePath(ParamStr(0))+ ETefLib.Text);

    if EPinPadModeloLibHashMd5.Text <> '' then
    begin
      if EPinPadModeloLibHashMd5.Text <> Md5File(ExtractFilePath(ParamStr(0))+ EPinPadLib.Text)then
        ShowMessage('O Arquivo Modelo lib n�o esta com o Hash V�lido');
    end
    else
      EPinPadModeloLibHashMd5.Text := Md5File(ExtractFilePath(ParamStr(0))+ EPinPadLib.Text);

    F_TefLib := LoadLibrary(PChar(ExtractFilePath(ParamStr(0))+ ETefLib.Text));

    // carregando as funcoes de inicializacao e conexao
    F_TefInicializar := GetProcAddress(F_TefLib, 'inicializar');
    F_Login          := GetProcAddress(F_TefLib, 'login');
    F_Desconectar    := GetProcAddress(F_TefLib, 'desconectar');
    F_StatusOpenTef  := GetProcAddress(F_TefLib, 'opentefstatus');
    F_Finalizar      := GetProcAddress(F_TefLib, 'finalizar');

    // carregando as funcoes para tratar a mensageria
    F_MensagemCreate        := GetProcAddress(F_TefLib, 'mensagemcreate');
    F_MensagemCarregaTags   := GetProcAddress(F_TefLib, 'mensagemcarregatags');
    F_MensagemComando       := GetProcAddress(F_TefLib, 'mensagemcomando');
    F_MensagemComandoDados  := GetProcAddress(F_TefLib, 'mensagemcomandodados');
    F_MensagemFree          := GetProcAddress(F_TefLib, 'mensagemfree');
    F_MensagemLimpar        := GetProcAddress(F_TefLib, 'mensagemlimpar');
    F_MensagemAddTag        := GetProcAddress(F_TefLib, 'mensagemaddtag');
    F_MensagemAddComando    := GetProcAddress(F_TefLib, 'mensagemaddcomando');
    F_MensagemTagAsString   := GetProcAddress(F_TefLib, 'mensagemtagasstring');
    F_MensagemTagCount      := GetProcAddress(F_TefLib, 'mensagemtagcount');
    F_MensagemGetTag        := GetProcAddress(F_TefLib, 'mensagemgettag');
    F_MensagemGetTagIdx     := GetProcAddress(F_TefLib, 'mensagemgettagidx');
    F_MensagemTagToStr      := GetProcAddress(F_TefLib, 'mensagemtagtostr');
    F_MensagemGetTagPosicao := GetProcAddress(F_TefLib, 'mensagemgettagposicao');
    F_MensagemAddTagPosicao := GetProcAddress(F_TefLib, 'mensagemaddtagposicao');

    // carregando as funcoes para tratar a transacao
    F_TransacaoCancela         := GetProcAddress(F_TefLib, 'transacaocancela');
    F_TransacaoCreate          := GetProcAddress(F_TefLib, 'transacaocreate');
    F_TransacaoFree            := GetProcAddress(F_TefLib, 'transacaofree');
    F_TransacaoStatus          := GetProcAddress(F_TefLib, 'transacaostatus');
    F_TransacaoStatusDescricao := GetProcAddress(F_TefLib, 'transacaostatusdescricao');
    F_TransacaoGetTag          := GetProcAddress(F_TefLib, 'transacaogettag');

    // carregando as demais funcoes auxilares
    F_AlterarNivelLog     := GetProcAddress(F_TefLib, 'alterarnivellog');
    F_Versao              := GetProcAddress(F_TefLib, 'versao');
    F_Erro                := GetProcAddress(F_TefLib, 'mensagemerro');
    F_SolicitacaoBlocante := GetProcAddress(F_TefLib, 'solicitacaoblocante');
    F_Solicitacao         := GetProcAddress(F_TefLib, 'solicitacao');

    // iniciliza a comunicacao com a biblioteca passando as funcoes a serem chamadas por ela e demais informacoes como log,pinpad
    VL_Codigo := F_TefInicializar(VL_PinpadModelo,
      PUTF8Char(UTF8Encode(ExtractFilePath(ParamStr(0))+ EPinPadModeloLib.Text)),
      PUTF8Char(UTF8Encode(EPinPadModeloPorta.Text)), PUTF8Char(UTF8Encode(ExtractFilePath(ParamStr(0))+
      EPinPadLib.Text)), PUTF8Char(UTF8Encode(F_ArquivoLog)),@uprincipal.Retorno,
      @uprincipal.SolicitaDadosTransacao,@uprincipal.SolicitaDadosPdv,
      @uprincipal.Imprime,@uprincipal.MostraMenu,@uprincipal.MensagemOperador,
      VL_AmbienteTeste);

    if VL_Codigo <> 0 then
    begin
      F_Erro(VL_Codigo, VL_DescricaoErro);
      ShowMessage('Erro: ' + IntToStr(VL_Codigo)+ #13 + 'Descri��o:' + UTF8Decode(VL_DescricaoErro));
      Exit;
    end;

    F_MensagemCreate(F_Mensagem);

  except
    on e: Exception do
      ShowMessage('Erro ao carregar a Lib ' + e.ClassName + '/' + e.Message);
  end;
end;

procedure TFPrincipal.BLoginClick(Sender: TObject);
var
  VL_Codigo       : Integer;
  VL_DescricaoErro: PUTF8Char;
begin
  VL_DescricaoErro := '';

  if not Assigned(F_Login)then
  begin
    ShowMessage('Inicialize a lib');
    Exit;
  end;

  VL_Codigo := F_Login(PUTF8Char(UTF8Encode(EHost.Text)), StrToInt(EPorta.Text),
    StrToInt(EID.Text), PUTF8Char(UTF8Encode(Trim(EChave.Lines.Text))), C_VersaoComunicacao,
    PUTF8Char(UTF8Encode(Trim(EIdentificador.Lines.Text))));

  if VL_Codigo <> 0 then
  begin
    F_Erro(VL_Codigo, VL_DescricaoErro);
    ShowMessage('Erro: ' + IntToStr(VL_Codigo)+ #13 + 'Descri��o: ' + UTF8Decode(VL_DescricaoErro));
    Exit;
  end;

  lblStatusConexao.Caption    := 'Conectado';
  lblStatusConexao.Font.Color := clGreen;
end;

procedure TFPrincipal.MontarMenu(VP_Mensagem: Pointer);
var
  VL_btn  : TMButton;
  VL_I    : Integer;
  VL_Tag  : PAnsiChar;
  VL_Dados: PAnsiChar;
begin
  VL_Tag                  := '';
  VL_Dados                := '';
  F_MenuVenda             := TF_MenuVenda.Create(F_Principal);
  F_MenuVenda.V_Mensagem  := VP_Mensagem;
  VL_btn                  := TMButton.Create(F_MenuVenda.PBotao);
  VL_btn.V_tag            := '0030';
  VL_btn.Caption          := 'Cancela';
  VL_btn.Align            := alTop;
  VL_btn.Height           := 20;
  VL_btn.Margins.Top      := 20;
  VL_btn.Margins.Bottom   := 20;
  VL_btn.Margins.Left     := 20;
  VL_btn.Margins.Right    := 20;
  VL_btn.alignWithMargins := True;
  VL_btn.Parent           := F_MenuVenda.PBotao;
  VL_btn.TabOrder         := 0;
  VL_btn.OnClick          := CliqueDoBotao;

  for VL_I := 1 to F_MensagemTagCount(VP_Mensagem)do
  begin
    F_MensagemGetTagIdx(VP_Mensagem, VL_I, VL_Tag, VL_Dados);
    if VL_Tag <> '0030' then
    begin
      VL_btn := TMButton.Create(F_MenuVenda.PBotao);
      F_MensagemGetTagIdx(VP_Mensagem, VL_I, VL_Tag, VL_Dados);
      VL_btn.V_tag            := VL_Tag;
      VL_btn.Caption          := UTF8Decode(VL_Dados);
      VL_btn.Align            := alTop;
      VL_btn.Height           := 20;
      VL_btn.Margins.Top      := 20;
      VL_btn.Margins.Bottom   := 20;
      VL_btn.Margins.Left     := 20;
      VL_btn.Margins.Right    := 20;
      VL_btn.alignWithMargins := True;
      VL_btn.Parent           := F_MenuVenda.PBotao;
      VL_btn.TabOrder         := 0;
      VL_btn.OnClick          := CliqueDoBotao;
      F_MenuVenda.Height      := F_MenuVenda.Height + 40;
    end;
  end;
  F_MenuVenda.Height := F_MenuVenda.Height + 40;
  F_MensagemComandoDados(VP_Mensagem, VL_Dados);
  F_MenuVenda.Position := poDesktopCenter;
  F_MenuVenda.ShowModal;
  F_MenuVenda.Free;
end;

procedure TFPrincipal.CliqueDoBotao(VP_Botao: TObject);
var
  VL_Botao: ansistring;
begin
  VL_Botao                                                       := TMButton(VP_Botao).V_tag;
  TF_MenuVenda(TPanel(TMButton(VP_Botao).Parent).Parent).V_Botao := VL_Botao;
  TForm(TPanel(TMButton(VP_Botao).Parent).Parent).Close;
end;

procedure TFPrincipal.BVendaClick(Sender: TObject);
var
  VL_Erro         : Integer;
  VL_Status       : Integer;
  VL_TransacaoID  : PUTF8Char;
  VL_DescricaoErro: PUTF8Char;
  VL_Tempo        : Integer;
begin
  VL_TransacaoID   := '';
  VL_Status        := 0;
  VL_DescricaoErro := '';
  VL_Tempo         := StrToInt(ETempo.Text); // tempo de espera

  if not Assigned(F_StatusOpenTef)then
  begin
    ShowMessage('Inicialize a lib');
    Exit;
  end;

  VL_Erro := F_StatusOpenTef(VL_Status);

  if VL_Erro <> 0 then
  begin
    F_Erro(VL_Erro, VL_DescricaoErro);
    ShowMessage('Erro: ' + IntToStr(VL_Erro)+ #13 + 'Descri��o: ' + UTF8Decode(VL_DescricaoErro));
    Exit;
  end;

  if VL_Status <> Ord(csLogado)then
  begin
    MStatus.Lines.Add('Fa�a o login');
    Exit;
  end;

  if not Assigned(F_TransacaoCreate)then
  begin
    ShowMessage('Inicialize a lib');
    Exit;
  end;

  MStatus.Clear;
  MStatus.Lines.Add('Inicia transacao de venda');

  // CRIA UMA TRANSACAO PARA APROVACAO DA VENDA
  VL_Erro := F_TransacaoCreate('000A', PUTF8Char(UTF8Encode(ECaixa.Text)), VL_TransacaoID, VL_Tempo);

  if VL_Erro <> 0 then
  begin
    F_Erro(VL_Erro, VL_DescricaoErro);
    ShowMessage('Erro: ' + IntToStr(VL_Erro)+ #13 + 'Descri��o:' +
      UTF8Decode(VL_DescricaoErro));
    Exit;
  end;

  MChave.Lines.Clear; // limpando memo para nao gerar conflitos entre chaves
  MStatus.Lines.Add('Transacao ID: ' + VL_TransacaoID);

  // ha duas formas de verificar o status da transacao(aprovada,negada)
  // atraves dos eventos enviado para a funcao Retorno toda vez que a transacao mudar de status(forma recomendada)
  // ou atraves de um loop que verifica o status da transacao a cada intervalo de tempo, o codigo abaixo e um exemplo
  {
    while ((TimeStampToMSecs(DateTimeToTimeStamp(now)) - TimeStampToMSecs(DateTimeToTimeStamp(VL_Data))) < VL_Tempo) do
    begin
    VL_Erro := F_TransacaoStatus(VL_TransacaoStatus, VL_TransacaoChave, VL_TransacaoID);

    if VL_Erro <> 0 then
    begin
    F_Erro(VL_Erro, VL_DescricaoErro);
    F_TransacaoStatusDescricao(VL_DescricaoErroTransacao, VL_TransacaoID);
    ShowMessage('Erro: ' + IntToStr(VL_Erro) + #13 + 'Descri��o:' + VL_DescricaoErro + '  ' + VL_DescricaoErroTransacao);
    F_TransacaoFree(VL_TransacaoID);
    Exit;
    end;

    if Ord(tsCancelada) = VL_TransacaoStatus then
    begin
    F_TransacaoStatusDescricao(VL_DescricaoErroTransacao, VL_TransacaoID);
    ShowMessage('Transa��o cancelada ' + VL_TransacaoID + ' ' + VL_DescricaoErroTransacao);
    MStatus.Lines.Add('Transa��o cancelada ' + VL_TransacaoID + ' ' + VL_DescricaoErroTransacao);
    F_TransacaoFree(VL_TransacaoID);
    Exit;
    end;

    if Ord(tsNegada) = VL_TransacaoStatus then
    begin
    F_TransacaoStatusDescricao(VL_DescricaoErroTransacao, VL_TransacaoID);
    ShowMessage('Transa��o negada ' + VL_TransacaoID + ' ' + VL_DescricaoErroTransacao);
    MStatus.Lines.Add('Transa��o negada ' + VL_TransacaoID + ' ' + VL_DescricaoErroTransacao);
    F_TransacaoFree(VL_TransacaoID);
    Exit;
    end;


    if Ord(tsNaoLocalizada) = VL_TransacaoStatus then
    begin
    F_TransacaoStatusDescricao(VL_DescricaoErroTransacao, VL_TransacaoID);
    ShowMessage('Transa��o n�o localizada ' + VL_TransacaoID + ' ' + VL_DescricaoErroTransacao);
    MStatus.Lines.Add('Transa��o n�o localizada ' + VL_TransacaoID + ' ' + VL_DescricaoErroTransacao);
    F_TransacaoFree(VL_TransacaoID);
    Exit;
    end;


    if Ord(tsEfetivada) = VL_TransacaoStatus then
    begin
    ShowMessage('Transa��o aprovada ' + VL_TransacaoID);
    MChave.Lines.Add(VL_TransacaoChave);
    MStatus.Lines.Add('Transacao ID: ' + VL_TransacaoID + ' Efetivada');
    F_TransacaoFree(VL_TransacaoID);
    Exit;
    end;

    if Ord(tsAbortada) = VL_TransacaoStatus then
    begin
    F_TransacaoStatusDescricao(VL_DescricaoErroTransacao, VL_TransacaoID);
    ShowMessage('Transa��o abortada ' + VL_TransacaoID + ' ' + VL_DescricaoErroTransacao);
    MStatus.Lines.Add('Transa��o abortada ' + VL_TransacaoID + ' ' + VL_DescricaoErroTransacao);
    F_TransacaoFree(VL_TransacaoID);
    Exit;
    end;


    Application.ProcessMessages;
    sleep(100);
    case VL_TransacaoStatus of
    Ord(tsProcessando): MStatus.Lines.Add('Transacao ID:' + VL_TransacaoID + 'Estado de processamento');
    Ord(tsInicializada): MStatus.Lines.Add('Transacao ID:' + VL_TransacaoID + 'Estado de inicializada');
    Ord(tsAguardandoComando): MStatus.Lines.Add('Transacao ID:' + VL_TransacaoID + 'Estado de aguardando comando');
    end;
    end;

    if ((TimeStampToMSecs(DateTimeToTimeStamp(now)) - TimeStampToMSecs(DateTimeToTimeStamp(VL_Data))) > 5000) then
    begin
    MStatus.Lines.Add('Transacao ID:' + VL_TransacaoID + 'N�o foi respondida em tempo h�bil');
    F_TransacaoFree(VL_TransacaoID);
    end;

  }

end;

procedure TFPrincipal.BLogGravacaoClick(Sender: TObject);
begin
  if not Assigned(F_AlterarNivelLog)then
  begin
    ShowMessage('Inicialize a lib');
    Exit;
  end;

  F_AlterarNivelLog(5);
end;

procedure TFPrincipal.FormCreate(Sender: TObject);
begin
  F_ArquivoLog := ExtractFilePath(ParamStr(0))+ 'appopentef.log';
end;

{ TTransacao }

function Md5(const texto:string):string;
var
  idmd5: TIdHashMessageDigest5;
begin
  idmd5 := TIdHashMessageDigest5.Create;
  try
    Result := idmd5.HashStringAsHex(texto);
  finally
    idmd5.Free;
  end;
end;

function Md5File(const fileName:string):string;
var
  idmd5: TIdHashMessageDigest5;
  fs   : TFileStream;
begin
  idmd5 := TIdHashMessageDigest5.Create;

  fs := TFileStream.Create(fileName, fmOpenRead OR fmShareDenyWrite);
  try
    Result := idmd5.HashStreamAsHex(fs);
  finally
    fs.Free;
    idmd5.Free;
  end;
end;

function StrToBase64(VP_Str:string):string;
begin
  Result := StringReplace(TNetEncoding.Base64.Encode(VP_Str), #$D#$A, '',[RfReplaceAll]);
end;

function Base64ToStr(VP_Bse64:string):string;
begin
  Result := TNetEncoding.Base64.Decode(VP_Bse64);
end;

end.
