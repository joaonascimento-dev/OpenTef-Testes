unit pinpad;

{$mode ObjFPC}{$H+}

interface

uses
    Classes, SysUtils, funcoes;

type


    { TTPinPad }

    TTPinPad = class(TThread)
        fMensagem: TMensagem;
        FProcessoID: integer;
        fRespostaPinPad: TRespostaPinPad;
    protected
        procedure Execute; override;
    public
        constructor Create(VP_Processo_ID: integer; VP_CreateSuspended: boolean; VP_Mensagem: TMensagem; var VO_TRespostaPinPad: TRespostaPinPad);

    end;

    { TPinPad }
    TPinPad = class
    private
        fRespostaPinPad: TRespostaPinPad;
    public
        function CarregaLib(): integer; virtual; abstract;
        function DescarregaLib(): integer; virtual; abstract;
        procedure SetConfig(VP_PinPad: TPinPadModelo; VP_CaminhoLib: ansistring; VP_Porta: ansistring); virtual; abstract;
        procedure PinPadErro(errCode: int16; msg: pansichar);
        function PinPadConecta(VO_Mensagem:TMensagem): integer; virtual; abstract;
        function PinPadDesconectar(VL_Mensagem: string): integer; virtual; abstract;
        function PinPadMensagem(VP_Mensagem: string): integer; virtual; abstract;
        function PinPadLerTarja(var VO_Tarja1, VO_Tarja2, VO_Tarja3: string; VP_TempoEspera: integer; var VO_Mensagem: TMensagem): integer; virtual; abstract;
        function PinPadLerSenha(var VO_Senha: string; VP_KW_Index: integer; VP_KW, VP_Pan: string; VP_DigMin, VP_DigMax: integer;
            VP_Mensagem: string; var VO_Mensagem: TMensagem;VP_TempoEspera: integer): integer; virtual; abstract;
    end;


    { TDPinPad }

    TDPinPad = class(TDataModule)

    private

    public

    end;

var
    D_PinPad: TDPinPad;
    F_PinPad:TPinPad;
    F_PinPaExecutando: boolean;
    F_PinPadCarregado: boolean;



function PinPadCarrega(VP_PinPadModelo: TPinPadModelo; VP_PinPadModeloLib, VP_PinPadModeloPorta: PChar; VP_RespostaPinPad: TRespostaPinPad): integer; stdcall;
function PinPadDescarrega(): integer; stdcall;
function PinPadConectar(var VO_Mensagem: PChar): integer; stdcall;
function PinPadDesconectar(VL_Mensagem: PChar): integer; stdcall;
function PinPadMensagem(VL_Mensagem: PChar): integer; stdcall;
function PinPadComando(VP_Processo_ID: integer; VP_Mensagem: PChar; var VO_Mensagem: PChar; VP_RespostaPinPad: TRespostaPinPad): integer; stdcall;
function PinPadExecutaComando(VP_Mensagem: TMensagem; var VO_Mensagem: TMensagem):integer;


implementation

{$R *.lfm}

uses
    gertec_ppc930;

{ TPinPad }



function PinPadCarrega(VP_PinPadModelo: TPinPadModelo; VP_PinPadModeloLib, VP_PinPadModeloPorta: PChar; VP_RespostaPinPad: TRespostaPinPad): integer; stdcall;
begin
    Result := 0;
    if F_PinPadCarregado then
        Exit;
    Result := 77;
    if VP_PinPadModelo = pGERTEC_PPC930 then
    begin
        F_PinPad := TGertec_ppc930.Create;
        F_PinPad.SetConfig(VP_PinPadModelo, VP_PinPadModeloLib, VP_PinPadModeloPorta);
        F_PinPad.fRespostaPinPad := VP_RespostaPinPad;
        Result := F_PinPad.CarregaLib();
        F_PinPaExecutando := False;
        if Result = 0 then
            F_PinPadCarregado := True;
    end;

end;

function PinPadDescarrega(): integer; stdcall;
begin
    F_PinPadCarregado := False;
    Result := F_PinPad.DescarregaLib();
    F_PinPad.Free;
end;

function PinPadConectar( var VO_Mensagem: PChar): integer; stdcall;
var
    VL_Mensgem: TMensagem;
begin
    try
        VL_Mensgem := TMensagem.Create;
        Result := F_PinPad.PinPadConecta(VL_Mensgem);
        VO_Mensagem := StrAlloc(Length(VL_Mensgem.TagsAsString) + 1);
        StrPCopy(VO_Mensagem, VL_Mensgem.TagsAsString);
        F_PinPaExecutando := False;

    finally
        VL_Mensgem.Free;
    end;
end;

function PinPadDesconectar(VL_Mensagem: PChar): integer; stdcall;
begin
    Result := F_PinPad.PinPadDesconectar(VL_Mensagem);
end;

function PinPadMensagem(VL_Mensagem: PChar): integer; stdcall;
begin
  result:=F_PinPad.PinPadMensagem(VL_Mensagem);
end;

function PinPadComando(VP_Processo_ID: integer; VP_Mensagem: PChar; var VO_Mensagem: PChar; VP_RespostaPinPad: TRespostaPinPad): integer; stdcall;
var
    VL_Mensagem: TMensagem;
    VL_Dados, VL_Comando: string;
    VL_TPinPad: TTPinPad;
    VL_MensagemO: TMensagem;
begin
    try
        VL_Mensagem := TMensagem.Create;
        VL_MensagemO := TMensagem.Create;
        VL_Mensagem.CarregaTags(VP_Mensagem);
        VL_Comando := '';
        VL_Dados := '';
        Result:=0;
        VL_Mensagem.GetComando(VL_Comando, VL_Dados);
        case VL_Comando of
            '0047':
            begin
               Result:= F_PinPad.PinPadMensagem(VL_Dados);
            end;
            '0048':
            begin
                if VP_Processo_ID = -1 then
                begin
                   Result:= PinPadExecutaComando(VL_Mensagem, VL_MensagemO);
                    VO_Mensagem := StrAlloc(Length(VL_MensagemO.TagsAsString) + 1);
                    StrPCopy(VO_Mensagem, VL_MensagemO.TagsAsString);
                end
                else
                begin
                    VL_TPinPad := TTPinPad.Create(VP_Processo_ID, True, VL_Mensagem, VP_RespostaPinPad);
                    VL_TPinPad.Start;
                end;
            end;
            '005A':
                if VP_Processo_ID = -1 then
                begin
                   Result:= PinPadExecutaComando(VL_Mensagem, VL_MensagemO);
                    VO_Mensagem := StrAlloc(Length(VL_MensagemO.TagsAsString) + 1);
                    StrPCopy(VO_Mensagem, VL_MensagemO.TagsAsString);
                end
                else
                begin
                    VL_TPinPad := TTPinPad.Create(VP_Processo_ID, True, VL_Mensagem, VP_RespostaPinPad);
                    VL_TPinPad.Start;
                end
            else
            begin
                VL_MensagemO.AddComando('0026', 'R');
                VL_MensagemO.AddTag('004D', 78);
                VO_Mensagem := StrAlloc(Length(VL_MensagemO.TagsAsString) + 1);
                StrPCopy(VO_Mensagem, VL_MensagemO.TagsAsString);
            end;
        end;

    finally
        VL_Mensagem.Free;
        VL_MensagemO.Free;

    end;
end;


function PinPadExecutaComando(VP_Mensagem: TMensagem; var VO_Mensagem: TMensagem):integer;
var
    VL_Comando, VL_Dados: string;
    VL_Tk1, VL_Tk2, VL_Tk3: string;
begin
    Result:=0;
    VL_Dados := '';
    VL_Comando := '';
    VL_Tk1 := '';
    VL_Tk2 := '';
    VL_Tk3 := '';
    VP_Mensagem.GetComando(VL_Comando, VL_Dados);
    VO_Mensagem.Limpar;
    if VL_Comando = '0048' then     //ler tarja magnetica
    begin
        VO_Mensagem.AddComando('0048', 'R');
        while True do
        begin
            if VL_Dados = 'S' then
            begin
                F_PinPad.PinPadMensagem(' Passe o cartao');
                Result := F_PinPad.PinPadLerTarja(VL_Tk1, VL_Tk2, VL_Tk3, VP_Mensagem.GetTagAsInteger('0051'),VO_Mensagem);
                if Result <> 0 then
                begin
                    VO_Mensagem.AddTag('004D', Result);
                    F_PinPad.PinPadMensagem('    Operacao       cancelada    ');
                    sleep(2000);
                    F_PinPad.PinPadMensagem('    OpenTef    ');
                    Exit;
                end;
                VO_Mensagem.AddTag('004D', 0);
                VO_Mensagem.AddTag('0046', Result);
                VO_Mensagem.AddTag('004E', VL_Tk1);
                VO_Mensagem.AddTag('004F', VL_Tk2);
                VO_Mensagem.AddTag('0050', VL_Tk3);
                Exit;
            end
            else
            begin
                VO_Mensagem.AddComando('004D', '51');
                Exit;
            end;
        end;
    end;
    if VL_Comando = '005A' then     //ler senha
    begin
        VO_Mensagem.AddComando('005A', 'R');
        while True do
        begin
            Result := F_PinPad.PinPadLerSenha(VL_Dados, VP_Mensagem.GetTagAsInteger('005B'), VP_Mensagem.GetTagAsAstring(
                '005F'), VP_Mensagem.GetTagAsAstring('00D9'), VP_Mensagem.GetTagAsInteger('005D'), VP_Mensagem.GetTagAsInteger('005E'),
                VP_Mensagem.GetTagAsAstring('005C'),VO_Mensagem,VP_Mensagem.GetTagAsInteger('0051'));
            if Result <> 0 then
            begin
                VO_Mensagem.AddTag('0046', Result);
                VO_Mensagem.AddTag('004D', '6');
                F_PinPad.PinPadMensagem('    Operacao       cancelada    ');
                sleep(2000);
                F_PinPad.PinPadMensagem('    OpenTef    ');
                Exit;
            end;
            VO_Mensagem.AddTag('0046', Result);
            VO_Mensagem.AddTag('004D', 0);
            VO_Mensagem.AddTag('0060', VL_Dados);
            F_PinPad.PinPadMensagem('    OpenTef    ');
            Exit;
        end;
    end;
end;


{ TTPinPad }



procedure TTPinPad.Execute;
var
    VL_Comando, VL_Dados: string;
    VL_Tk1, VL_Tk2, VL_Tk3: string;
    VL_Retorno: integer;
    VL_Mensagem:TMensagem;
begin
    try
        VL_Mensagem:=TMensagem.Create;
    VL_Dados := '';
    VL_Comando := '';
    VL_Tk1 := '';
    VL_Tk2 := '';
    VL_Tk3 := '';
    VL_Retorno := 0;
    fMensagem.GetComando(VL_Comando, VL_Dados);
    if VL_Comando = '0048' then     //ler tarja magnetica
    begin
        while True do
        begin
            if VL_Dados = '0' then
            begin
                F_PinPad.PinPadMensagem(' Passe o cartao');
                VL_Retorno := F_PinPad.PinPadLerTarja(VL_Tk1, VL_Tk2, VL_Tk3, fMensagem.GetTagAsInteger('0051'),VL_Mensagem);
                if VL_Retorno <> 0 then
                begin
                    fMensagem.CarregaTags(VL_Mensagem.TagsAsString);
                    if Assigned(fRespostaPinPad) then
                        fRespostaPinPad(FProcessoID, fMensagem);
                    F_PinPad.PinPadMensagem('    Operacao       cancelada    ');
                    sleep(2000);
                    F_PinPad.PinPadMensagem('    OpenTef    ');
                    Exit;
                end;

                fMensagem.AddComando('0052', VL_Comando);
                fMensagem.AddTag('004D', VL_Retorno);
                fMensagem.AddTag('004E', VL_Tk1);
                fMensagem.AddTag('004F', VL_Tk2);
                fMensagem.AddTag('0050', VL_Tk3);
                if Assigned(fRespostaPinPad) then
                    fRespostaPinPad(FProcessoID, fMensagem);
                F_PinPad.PinPadMensagem('    OpenTef    ');
                Exit;
            end
            else
            begin
                fMensagem.AddComando('004D', '51');
                if Assigned(fRespostaPinPad) then
                    fRespostaPinPad(FProcessoID, fMensagem);
                Exit;
            end;
        end;
    end;
    if VL_Comando = '005A' then     //ler senha
    begin
        while True do
        begin
            VL_Retorno := F_PinPad.PinPadLerSenha(VL_Dados, fMensagem.GetTagAsInteger('005B'), fMensagem.GetTagAsAstring(
                '005F'), fMensagem.GetTagAsAstring('0062'), fMensagem.GetTagAsInteger('005D'), fMensagem.GetTagAsInteger('005E'),
                fMensagem.GetTagAsAstring('005C'),VL_Mensagem,fMensagem.GetTagAsInteger('0051'));
            if VL_Retorno <> 0 then
            begin
                fMensagem.CarregaTags(VL_Mensagem.TagsAsString);
                if Assigned(fRespostaPinPad) then
                    fRespostaPinPad(FProcessoID, fMensagem);
                F_PinPad.PinPadMensagem('    Operacao       cancelada    ');
                sleep(2000);
                F_PinPad.PinPadMensagem('    OpenTef    ');
                Exit;
            end;

            fMensagem.AddComando('0052', VL_Comando);
            fMensagem.AddTag('004D', VL_Retorno);
            fMensagem.AddTag('0060', VL_Dados);
            if Assigned(fRespostaPinPad) then
                fRespostaPinPad(FProcessoID, fMensagem);
            F_PinPad.PinPadMensagem('    OpenTef    ');
            Exit;
        end;
    end;

    finally
    VL_Mensagem.Free;
    end;
end;


constructor TTPinPad.Create(VP_Processo_ID: integer; VP_CreateSuspended: boolean; VP_Mensagem: TMensagem; var VO_TRespostaPinPad: TRespostaPinPad);
begin
    fMensagem := VP_Mensagem;
    fProcessoID := VP_Processo_ID;
    fRespostaPinPad := VO_TRespostaPinPad;
    FreeOnTerminate := True;
    inherited Create(VP_CreateSuspended);
end;

procedure TPinPad.PinPadErro(errCode: int16; msg: pansichar);
var
    VL_Mensagem: TMensagem;
begin
    VL_Mensagem := TMensagem.Create;
    try
        VL_Mensagem.AddComando('0049', IntToStr(errCode));
        VL_Mensagem.AddTag('004A', msg);
        if Assigned(fRespostaPinPad) then
            fRespostaPinPad(0, VL_Mensagem);
    finally
        VL_Mensagem.Free;
    end;

end;

initialization
    F_PinPadCarregado := False;

end.
