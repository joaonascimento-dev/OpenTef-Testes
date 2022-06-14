unit gertec_ppc930;

{$mode ObjFPC}{$H+}

interface

uses
    Classes, SysUtils, pinpad, funcoes;

type

    { TGertec_ppc930 }

    TAbecsSpePanMask = record
        leftOpenDigits: int8;
        rightOpenDigits: int8;
    end;

    TAbecsRspParamData = record
        szData: SIZE_T;
        Data: array of byte;
    end;

    TAbecsCmdGpnEntry_S = record
        min: uint8;
        max: uint8;
        msg: array[0 .. 31] of ansichar;
    end;

    TAbecsCmdGpn_S = record
        method: integer;
        keyIdx: uint8;
        wkEnc: array[0 .. 32] of ansichar;
        pan: array[0 .. 19] of ansichar;
        entryCount: uint8;
        entries: array[0 .. 9] of TAbecsCmdGpnEntry_S;
    end;

    TAbecsCmdGpnResponse_S = record
        pinBlk: array [0..16] of ansichar;
        ksn: array [0..20] of ansichar;
    end;

    TAbecsNotification_S = record
        msg:array of ansichar;
    end;

    TGpinpad_exception_handler = procedure(errCode: int16; msg: pansichar); stdcall;
    TPcl_exception_set_uncaught_handler = procedure(handler: TGpinpad_exception_handler); stdcall;
    Tabecs_comm_open = function(portName: ansistring): Pointer; stdcall;
    Tabecs_comm_close = procedure(pinpad: PPointer); stdcall;

    Tabecs_cmd_opn = function(pinpad: Pointer; secure: integer): integer; stdcall;
    Tabecs_cmd_dsp = function(pinpad: Pointer; msg: ansistring): integer; stdcall;
    Tabecs_cmd_clo = function(pinpad: Pointer; msg: ansistring): integer; stdcall;
    Tabecs_cmd_cex = procedure(pinpad: Pointer; cexOp: ansistring; timeout: Pointer; panMask: Pointer) stdcall;
    Tabecs_cmd_gpn = procedure(pinpad: Pointer; AbecsCmdGpn_S: Pointer) stdcall;

    Tabecs_cmd_cex_response = function(pinpad: Pointer; outmap: Pointer; outNotify: Pointer): integer; stdcall;
    //Tabecs_cmd_gcx_response = function(pinpad: Pointer; outmap: Pointer; outNotify: Pointer): integer; stdcall;
    //Tabecs_cmd_gox_response = function(pinpad: Pointer; outmap: Pointer; outNotify: Pointer): integer; stdcall;
    //Tabecs_cmd_fcx_response = function(pinpad: Pointer; outmap: Pointer; outNotify: Pointer): integer; stdcall;
    Tabecs_cmd_gpn_response = function(pinpad: Pointer; outmap: Pointer; outNotify: Pointer): integer; stdcall;
    Tabecs_rsp_param_map_new = function(): Pointer; stdcall;
    //Tabecs_rsp_param_map_begin = function(map: Pointer; outinterator: Pointer): Pointer; stdcall;
    //Tabecs_rsp_param_map_get = function(map: Pointer; id: int16): Pointer; stdcall;
    //Tabecs_rsp_param_map_next = function(outinterator: Pointer): Pointer; stdcall;

    Tabecs_cmd_cex_response_get_event = function(map: Pointer): integer; stdcall;
    Tabecs_cmd_cex_response_get_trk1inc = function(map: Pointer): pansichar; stdcall;
    Tabecs_cmd_cex_response_get_trk2inc = function(map: Pointer): pansichar; stdcall;
    Tabecs_cmd_cex_response_get_trk3inc = function(map: Pointer): pansichar; stdcall;

    TPcl_map_delete = procedure(map: Pointer); stdcall;


    TGertec_ppc930 = class(TPinPad)
    private
        fPinPadLib: THandle;
        fPinPad: Pointer;
        fModelo: TPinPadModelo;
        fPorta: ansistring;
        fCaminhoLib: ansistring;
    public
        constructor Create;
        function CarregaLib(): integer; override;
        function DescarregaLib(): integer; override;
        procedure SetConfig(VP_PinPad: TPinPadModelo; VP_CaminhoLib: ansistring; VP_Porta: ansistring); override;
        function PinPadConecta(VO_Mensagem: TMensagem): integer; override;
        function PinPadDesconectar(VL_Mensagem: string): integer; override;
        function PinPadMensagem(VP_Mensagem: string): integer; override;
        function PinPadLerTarja(var VO_Tarja1, VO_Tarja2, VO_Tarja3: string; VP_TempoEspera: integer; var VO_Mensagem: TMensagem): integer; override;
        function PinPadLerSenha(var VO_Senha: string; VP_KW_Index: integer; VP_KW, VP_Pan: string; VP_DigMin, VP_DigMax: integer;
            VP_Mensagem: string; var VO_Mensagem: TMensagem;VP_TempoEspera: integer): integer; override;


    end;

procedure gpinpad_exception_handler(errCode: int16; msg: pansichar); stdcall;


implementation

var
    abecs_comm_open: Tabecs_comm_open;
    abecs_comm_close: Tabecs_comm_close;

    abecs_cmd_opn: Tabecs_cmd_opn;
    abecs_cmd_dsp: Tabecs_cmd_dsp;
    abecs_cmd_clo: Tabecs_cmd_clo;
    abecs_cmd_cex: Tabecs_cmd_cex;
    abecs_cmd_gpn: Tabecs_cmd_gpn;

    abecs_cmd_cex_response: Tabecs_cmd_cex_response;
    //abecs_cmd_gcx_response: Tabecs_cmd_gcx_response;
    //abecs_cmd_gox_response: Tabecs_cmd_gox_response;
    //abecs_cmd_fcx_response: Tabecs_cmd_fcx_response;
    abecs_cmd_gpn_response: Tabecs_cmd_gpn_response;
    abecs_rsp_param_map_new: Tabecs_rsp_param_map_new;
    //abecs_rsp_param_map_begin: Tabecs_rsp_param_map_begin;
    //abecs_rsp_param_map_get: Tabecs_rsp_param_map_get;
    //abecs_rsp_param_map_next: Tabecs_rsp_param_map_next;

    abecs_cmd_cex_response_get_trk1inc: Tabecs_cmd_cex_response_get_trk1inc;
    abecs_cmd_cex_response_get_trk2inc: Tabecs_cmd_cex_response_get_trk2inc;
    abecs_cmd_cex_response_get_trk3inc: Tabecs_cmd_cex_response_get_trk3inc;

    abecs_cmd_cex_response_get_event: Tabecs_cmd_cex_response_get_event;

    pcl_map_delete: TPcl_map_delete;
    pcl_exception_set_uncaught_handler: TPcl_exception_set_uncaught_handler;
    cbAux: Tgpinpad_exception_handler;
    VF_PinpadExecption: boolean;
    VF_PinpadExecptionCodigo: integer;
    VF_PinpadExecptionMensgem: string;


procedure gpinpad_exception_handler(errCode: int16; msg: pansichar); stdcall;
begin
    VF_PinpadExecption := True;
    VF_PinpadExecptionCodigo := errCode;
    VF_PinpadExecptionMensgem := msg;
end;


{ TGertec_ppc930 }

constructor TGertec_ppc930.Create;
begin
    fPinPad := nil;
    inherited Create;
end;

function TGertec_ppc930.CarregaLib(): integer;
begin
    VF_PinpadExecption := False;
    fPinPadLib := LoadLibrary(fCaminhoLib + 'gpinpad3.dll');
    if fPinPadLib <= 0 then
    begin
        Result := 50;
        Exit;
    end;

    Pointer(pcl_exception_set_uncaught_handler) :=
        GetProcAddress(fPinPadLib, 'pcl_exception_set_uncaught_handler');

    cbAux := Tgpinpad_exception_handler(@gpinpad_exception_handler);
    pcl_exception_set_uncaught_handler(cbAux);

    Pointer(abecs_comm_open) := GetProcAddress(fPinPadLib, 'abecs_comm_open');
    Pointer(abecs_comm_close) := GetProcAddress(fPinPadLib, 'abecs_comm_close');

    Pointer(abecs_cmd_opn) := GetProcAddress(fPinPadLib, 'abecs_cmd_opn');
    Pointer(abecs_cmd_dsp) := GetProcAddress(fPinPadLib, 'abecs_cmd_dsp');
    Pointer(abecs_cmd_clo) := GetProcAddress(fPinPadLib, 'abecs_cmd_clo');
    Pointer(abecs_cmd_cex) := GetProcAddress(fPinPadLib, 'abecs_cmd_cex');
    Pointer(abecs_cmd_gpn) := GetProcAddress(fPinPadLib, 'abecs_cmd_gpn');

    Pointer(abecs_cmd_cex_response) := GetProcAddress(fPinPadLib, 'abecs_cmd_cex_response');

    Pointer(abecs_rsp_param_map_new) := GetProcAddress(fPinPadLib, 'abecs_rsp_param_map_new');

    Pointer(pcl_map_delete) := GetProcAddress(fPinPadLib, 'pcl_map_delete');

    Pointer(abecs_cmd_cex_response_get_event) := GetProcAddress(fPinPadLib, 'abecs_cmd_cex_response_get_event');
    Pointer(abecs_cmd_cex_response_get_trk1inc) := GetProcAddress(fPinPadLib, 'abecs_cmd_cex_response_get_trk1inc');
    Pointer(abecs_cmd_cex_response_get_trk2inc) := GetProcAddress(fPinPadLib, 'abecs_cmd_cex_response_get_trk2inc');
    Pointer(abecs_cmd_cex_response_get_trk3inc) := GetProcAddress(fPinPadLib, 'abecs_cmd_cex_response_get_trk3inc');
    Pointer(abecs_cmd_gpn_response) := GetProcAddress(fPinPadLib, 'abecs_cmd_gpn_response');

    //  //  // Gertec - Manipulação de mapas e leitura de resposta de CEX
    //  //  abecs_rsp_param_map_new   := GetProcAddress(LibHandle, 'abecs_rsp_param_map_new');
    //  //  abecs_rsp_param_map_begin := GetProcAddress(LibHandle, 'abecs_rsp_param_map_begin');
    //  //  abecs_rsp_param_map_get   := GetProcAddress(LibHandle, 'abecs_rsp_param_map_get');
    //  //  abecs_rsp_param_map_next  := GetProcAddress(LibHandle, 'abecs_rsp_param_map_next');
    //  //
    //  //  abecs_cmd_gcx_builder_new     := GetProcAddress(LibHandle, 'abecs_cmd_gcx_builder_new');
    //  //  abecs_cmd_gcx_builder_delete  := GetProcAddress(LibHandle, 'abecs_cmd_gcx_builder_delete');
    //  //  abecs_cmd_gcx_builder_gcxopt  := GetProcAddress(LibHandle, 'abecs_cmd_gcx_builder_gcxopt');
    //  //  abecs_cmd_gcx_builder_aidlist := GetProcAddress(LibHandle, 'abecs_cmd_gcx_builder_aidlist');
    //  //  abecs_cmd_gcx_builder_amount  := GetProcAddress(LibHandle, 'abecs_cmd_gcx_builder_amount');
    //  //  abecs_cmd_gcx_builder_taglist := GetProcAddress(LibHandle, 'abecs_cmd_gcx_builder_taglist');


    //  //  abecs_cmd_gcx_response        := GetProcAddress(LibHandle, 'abecs_cmd_gcx_response');
    //  //  abecs_cmd_gox_response        := GetProcAddress(LibHandle, 'abecs_cmd_gox_response');
    //  //  abecs_cmd_fcx_response        := GetProcAddress(LibHandle, 'abecs_cmd_fcx_response');
    //  //  abecs_cmd_gpn_response        := GetProcAddress(LibHandle, 'abecs_cmd_gpn_response');
    //  //  // michel
    //  //  abecs_cmd_cex                      := GetProcAddress(LibHandle, 'abecs_cmd_cex');
    //  //  abecs_cmd_gcx                      := GetProcAddress(LibHandle, 'abecs_cmd_gcx');
    //  //  abecs_cmd_gox                      := GetProcAddress(LibHandle, 'abecs_cmd_gox');
    //  //  abecs_cmd_fcx                      := GetProcAddress(LibHandle, 'abecs_cmd_fcx');
    //  //  abecs_cmd_gpn                      := GetProcAddress(LibHandle, 'abecs_cmd_gpn');
    //  //  abecs_cmd_cex_response_get_trk2inc := GetProcAddress(LibHandle, 'abecs_cmd_cex_response_get_trk2inc');
    //  //  abecs_cmd_cex_response_get_event   := GetProcAddress(LibHandle, 'abecs_cmd_cex_response_get_event');
    //  //  abecs_cmd_tli                      := GetProcAddress(LibHandle, 'abecs_cmd_tli');
    //  //  abecs_cmd_tlr                      := GetProcAddress(LibHandle, 'abecs_cmd_tlr');
    //  //  abecs_cmd_tle                      := GetProcAddress(LibHandle, 'abecs_cmd_tle');
    //  //
    //  //  abecs_cmd_gox_builder_new    := GetProcAddress(LibHandle, 'abecs_cmd_gox_builder_new');
    //  //  abecs_cmd_gox_builder_delete := GetProcAddress(LibHandle, 'abecs_cmd_gox_builder_delete');
    //  //
    //  //  abecs_cmd_fcx_builder_new    := GetProcAddress(LibHandle, 'abecs_cmd_fcx_builder_new');
    //  //  abecs_cmd_fcx_builder_delete := GetProcAddress(LibHandle, 'abecs_cmd_fcx_builder_delete');
    //  //  abecs_cmd_fcx_builder_arc    := GetProcAddress(LibHandle, 'abecs_cmd_fcx_builder_arc');
    //  //


    Result := 0;
end;

function TGertec_ppc930.DescarregaLib: integer;
begin
    Result := 0;
    if fPinPad = nil then
        Exit;
    abecs_cmd_clo(fPinPad, 'Open Tef');
    abecs_comm_close(@fPinPad);
    UnloadLibrary(fPinPadLib);
    fPinPad := nil;
end;

procedure TGertec_ppc930.SetConfig(VP_PinPad: TPinPadModelo; VP_CaminhoLib: ansistring; VP_Porta: ansistring);
begin
    fPorta := VP_Porta;
    fCaminhoLib := VP_CaminhoLib;
    fModelo := VP_PinPad;
end;

function TGertec_ppc930.PinPadConecta(VO_Mensagem: TMensagem): integer;
begin
    Result := 1;
    VF_PinpadExecption := False;
    fPinPad := abecs_comm_open(fPorta);
    if VF_PinpadExecption then
    begin
        VO_Mensagem.AddComando('0049', 'R');
        VO_Mensagem.AddTag('004D', VF_PinpadExecptionCodigo);
        VO_Mensagem.AddTag('004A', VF_PinpadExecptionMensgem);
        Result:=VF_PinpadExecptionCodigo;
        Exit;
    end;
    Result := abecs_cmd_opn(fPinPad, 1);
    if VF_PinpadExecption then
    begin
        VO_Mensagem.AddComando('0049', 'R');
        VO_Mensagem.AddTag('004D', VF_PinpadExecptionCodigo);
        VO_Mensagem.AddTag('004A', VF_PinpadExecptionMensgem);
        Result:=VF_PinpadExecptionCodigo;
        Exit;
    end;

    Result := 0;
end;

function TGertec_ppc930.PinPadDesconectar(VL_Mensagem: string): integer;
begin
    abecs_cmd_clo(fPinPad, ansistring(VL_Mensagem));
    abecs_comm_close(@fPinPad);
    Result := 0;
end;

function TGertec_ppc930.PinPadMensagem(VP_Mensagem: string): integer;
begin
    abecs_cmd_dsp(fPinPad, VP_Mensagem);
    Result := 0;
end;

function TGertec_ppc930.PinPadLerTarja(var VO_Tarja1, VO_Tarja2, VO_Tarja3: string; VP_TempoEspera: integer; var VO_Mensagem: TMensagem): integer;
var
    VL_PanMask: TAbecsSpePanMask;
    VL_Timeout: PInteger;
    VL_Map: Pointer;
    VL_Retorno: integer;
    VL_Agora:TDateTime;
    VL_Notificacao:^TAbecsNotification_S;
    VL_Dados:String;
    VL_I:Integer;

begin
    try
        VL_Agora:=now;
        VL_Retorno := -1;
        new(VL_Timeout);
        new(VL_Notificacao);
        VL_Timeout^ := VP_TempoEspera;
        VL_Dados:='';

        VL_PanMask.leftOpenDigits := 19;
        VL_PanMask.rightOpenDigits := 19;

        VL_Map := abecs_rsp_param_map_new();

        VF_PinpadExecption := False;
        abecs_cmd_cex(fPinPad, '110000', VL_Timeout, @VL_PanMask);

        if VP_TempoEspera=0 then
        VP_TempoEspera:=30000;

        while (VL_Retorno = -1) and  (VF_PinpadExecption = False) do
        begin
            sleep(10);
            VL_Retorno := abecs_cmd_cex_response(fPinPad, VL_Map, VL_Notificacao);
            if TempoPassouMiliSegundos(VL_Agora)>VP_TempoEspera then
            begin
                Result:=85;
                VO_Mensagem.AddComando('0049', 'R');
                VO_Mensagem.AddTag('004D', 85);

                for VL_I:=0 to Length(VL_Notificacao^.msg) -1 do
                VL_Dados:=VL_Dados+VL_Notificacao^.msg[VL_I];
                VO_Mensagem.AddTag('004A', VL_Dados);
                pcl_map_delete(@VL_Map);
                Exit;
            end;

        end;

        if VF_PinpadExecption then
        begin
            Result := VF_PinpadExecptionCodigo;
            VO_Mensagem.AddComando('0049', 'R');
            VO_Mensagem.AddTag('004D', VF_PinpadExecptionCodigo);
            VO_Mensagem.AddTag('004A', VF_PinpadExecptionMensgem);
            pcl_map_delete(@VL_Map);
            Exit;
        end;


        VO_Tarja1 := abecs_cmd_cex_response_get_trk1inc(VL_Map);
        VO_Tarja2 := abecs_cmd_cex_response_get_trk2inc(VL_Map);
        VO_Tarja3 := abecs_cmd_cex_response_get_trk3inc(VL_Map);

        pcl_map_delete(@VL_Map);

        Result := VL_Retorno;

    finally
    Dispose(VL_Timeout);
    Dispose(VL_Notificacao);
    end;


end;

function TGertec_ppc930.PinPadLerSenha(var VO_Senha: string; VP_KW_Index: integer; VP_KW, VP_Pan: string; VP_DigMin, VP_DigMax: integer;
    VP_Mensagem: string; var VO_Mensagem: TMensagem;VP_TempoEspera: integer): integer;
var
    VL_cmdData: ^TAbecsCmdGpn_S;
    VL_Retorno: integer;
    VL_rspDataOut: ^TAbecsCmdGpnResponse_S;
    VL_I: integer;
    VL_Agora:TDateTime;
    VL_Dados:string;
    VL_Notificacao:^TAbecsNotification_S;
begin
        VL_Agora:=now;
        VL_Dados:='';
        New(VL_cmdData);
        New(VL_rspDataOut);
        New(VL_Notificacao);

        try

        for VL_I:=0 to 31 do
        VL_cmdData^.entries[0].msg[VL_I]:=#0;

        VL_cmdData^.method := 1;
        VL_cmdData^.keyIdx := VP_KW_Index;

        for VL_I := 0 to 31 do
            VL_cmdData^.wkEnc[VL_I] := VP_KW[VL_I + 1];
        VL_cmdData^.wkEnc[32] := #0;

        for VL_I := 0 to 18 do
            VL_cmdData^.pan[VL_I] := VP_Pan[VL_I + 1];
        VL_cmdData^.pan[19] := #0;

        VL_cmdData^.entryCount := 1;
        VL_cmdData^.entries[0].min := VP_DigMin;
        VL_cmdData^.entries[0].max := VP_DigMax;

        for VL_I := 0 to Length(VP_Mensagem) do
            VL_cmdData^.entries[0].msg[VL_I] := VP_Mensagem[VL_I + 1];

        VL_cmdData^.entries[0].msg[VL_I + 1] := #0;

        VL_Retorno := -1;
        VF_PinpadExecption := False;

        if VP_TempoEspera=0 then
        VP_TempoEspera:=30000;

        abecs_cmd_gpn(fPinPad, VL_cmdData);

        SetLength(VL_Notificacao^.msg,1);
        VL_Notificacao^.msg[0]:=#0;

        while (VL_Retorno = -1) and (VF_PinpadExecption = False) and (VL_Notificacao^.msg[0]=#0) do
        begin
            VL_Retorno := abecs_cmd_gpn_response(fPinPad, VL_rspDataOut, VL_Notificacao);
            sleep(500);

            if TempoPassouMiliSegundos(VL_Agora)>VP_TempoEspera then
            begin
                Result:=85;
                VO_Mensagem.AddComando('0049', 'R');
                VO_Mensagem.AddTag('004D', 85);

                for VL_I:=0 to Length(VL_Notificacao^.msg) -1 do
                VL_Dados:=VL_Dados+VL_Notificacao^.msg[VL_I];
                VO_Mensagem.AddTag('004A', VL_Dados);

                Exit;
            end;
        end;

        if VF_PinpadExecption then
        begin
            Result := VF_PinpadExecptionCodigo;
            VO_Mensagem.AddComando('0049', 'R');
            VO_Mensagem.AddTag('004D', VF_PinpadExecptionCodigo);
            VO_Mensagem.AddTag('004A', VF_PinpadExecptionMensgem);
            Exit;
        end;


        Result := VL_Retorno;
        if VL_Retorno = 0 then
            VO_Senha := VL_rspDataOut^.pinBlk;



        finally
        Dispose(VL_rspDataOut);
        Dispose(VL_cmdData);
        Dispose(VL_Notificacao);
        end;
end;




end.
