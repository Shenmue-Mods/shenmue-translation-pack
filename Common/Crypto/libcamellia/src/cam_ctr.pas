unit CAM_CTR;

(*************************************************************************

 DESCRIPTION   : Camellia CTR mode functions
                 Because of buffering en/decrypting is associative
                 User can supply a custom increment function

 REQUIREMENTS  : TP5-7, D1-D7/D9-D10/D12, FPC, VP

 EXTERNAL DATA : ---

 MEMORY USAGE  : ---

 DISPLAY MODE  : ---

 REFERENCES    : B.Schneier, Applied Cryptography, 2nd ed., ch. 9.9

 REMARKS       : - If a predefined or user-supplied INCProc is used, it must
                   be set before using CAM_CTR_Seek.
                 - CAM_CTR_Seek may be time-consuming for user-defined
                   INCProcs, because this function is called many times.
                   See CAM_CTR_Seek how to provide user-supplied short-cuts.

 WARNING       : - CTR mode demands that the same key / initial CTR pair is
                   never reused for encryption. This requirement is especially
                   important for the CTR_Seek function. If different data is
                   written to the same position there will be leakage of
                   information about the plaintexts. Therefore CTR_Seek should
                   normally be used for random reads only.

 Version  Date      Author      Modification
 -------  --------  -------     ------------------------------------------
 0.10     16.06.08  W.Ehrhardt  Initial version analog TF_CTR
 0.11     21.06.08  we          Make IncProcs work with FPC -dDebug
 0.12     23.11.08  we          Uses BTypes
 0.13     28.07.10  we          CAM_CTR_Seek, CAM_CTR_Seek64
 0.14     29.07.10  we          Longint ILen in CAM_CTR_En/Decrypt
 0.15     31.07.10  we          Source CAM_CTR_Seek/64 moved to cam_seek.inc
**************************************************************************)


(*-------------------------------------------------------------------------
 (C) Copyright 2008-2010 Wolfgang Ehrhardt

 This software is provided 'as-is', without any express or implied warranty.
 In no event will the authors be held liable for any damages arising from
 the use of this software.

 Permission is granted to anyone to use this software for any purpose,
 including commercial applications, and to alter it and redistribute it
 freely, subject to the following restrictions:

 1. The origin of this software must not be misrepresented; you must not
    claim that you wrote the original software. If you use this software in
    a product, an acknowledgment in the product documentation would be
    appreciated but is not required.

 2. Altered source versions must be plainly marked as such, and must not be
    misrepresented as being the original software.

 3. This notice may not be removed or altered from any source distribution.
----------------------------------------------------------------------------*)

{$i STD.INC}

interface


uses
  BTypes, CAM_Base;


{$ifdef CONST}
function  CAM_CTR_Init(const Key; KeyBits: word; const CTR: TCAMBlock; var ctx: TCAMContext): integer;
  {-Camellia key expansion, error if inv. key size, encrypt CTR}
  {$ifdef DLL} stdcall; {$endif}

procedure CAM_CTR_Reset(const CTR: TCAMBlock; var ctx: TCAMContext);
  {-Clears ctx fields bLen and Flag, encrypt CTR}
  {$ifdef DLL} stdcall; {$endif}
{$else}
function  CAM_CTR_Init(var Key; KeyBits: word; var CTR: TCAMBlock; var ctx: TCAMContext): integer;
  {-Camellia key expansion, error if inv. key size, encrypt CTR}

procedure CAM_CTR_Reset(var CTR: TCAMBlock; var ctx: TCAMContext);
  {-Clears ctx fields bLen and Flag, encrypt CTR}
{$endif}


{$ifndef DLL}
function  CAM_CTR_Seek({$ifdef CONST}const{$else}var{$endif} iCTR: TCAMBlock;
                       SOL, SOH: longint; var ctx: TCAMContext): integer;
  {-Setup ctx for random access crypto stream starting at 64 bit offset SOH*2^32+SOL,}
  { SOH >= 0. iCTR is the initial CTR for offset 0, i.e. the same as in CAM_CTR_Init.}
{$ifdef HAS_INT64}
function CAM_CTR_Seek64(const iCTR: TCAMBlock; SO: int64; var ctx: TCAMContext): integer;
  {-Setup ctx for random access crypto stream starting at 64 bit offset SO >= 0;}
  { iCTR is the initial CTR value for offset 0, i.e. the same as in CAM_CTR_Init.}
{$endif}
{$endif}


function  CAM_CTR_Encrypt(ptp, ctp: Pointer; ILen: longint; var ctx: TCAMContext): integer;
  {-Encrypt ILen bytes from ptp^ to ctp^ in CTR mode}
  {$ifdef DLL} stdcall; {$endif}

function  CAM_CTR_Decrypt(ctp, ptp: Pointer; ILen: longint; var ctx: TCAMContext): integer;
  {-Decrypt ILen bytes from ctp^ to ptp^ in CTR mode}
  {$ifdef DLL} stdcall; {$endif}

function  CAM_SetIncProc(IncP: TCAMIncProc; var ctx: TCAMContext): integer;
  {-Set user supplied IncCTR proc}
  {$ifdef DLL} stdcall; {$endif}

procedure CAM_IncMSBFull(var CTR: TCAMBlock);
  {-Increment CTR[15]..CTR[0]}
  {$ifdef DLL} stdcall; {$endif}

procedure CAM_IncLSBFull(var CTR: TCAMBlock);
  {-Increment CTR[0]..CTR[15]}
  {$ifdef DLL} stdcall; {$endif}

procedure CAM_IncMSBPart(var CTR: TCAMBlock);
  {-Increment CTR[15]..CTR[8]}
  {$ifdef DLL} stdcall; {$endif}

procedure CAM_IncLSBPart(var CTR: TCAMBlock);
  {-Increment CTR[0]..CTR[7]}
  {$ifdef DLL} stdcall; {$endif}


implementation


{---------------------------------------------------------------------------}
procedure CAM_IncMSBPart(var CTR: TCAMBlock);
  {-Increment CTR[15]..CTR[8]}
var
  j: integer;
begin
  for j:=15 downto 8 do begin
    if CTR[j]=$FF then CTR[j] := 0
    else begin
      inc(CTR[j]);
      exit;
    end;
  end;
end;


{---------------------------------------------------------------------------}
procedure CAM_IncLSBPart(var CTR: TCAMBlock);
  {-Increment CTR[0]..CTR[7]}
var
  j: integer;
begin
  for j:=0 to 7 do begin
    if CTR[j]=$FF then CTR[j] := 0
    else begin
      inc(CTR[j]);
      exit;
    end;
  end;
end;


{---------------------------------------------------------------------------}
procedure CAM_IncMSBFull(var CTR: TCAMBlock);
  {-Increment CTR[15]..CTR[0]}
var
  j: integer;
begin
  for j:=15 downto 0 do begin
    if CTR[j]=$FF then CTR[j] := 0
    else begin
      inc(CTR[j]);
      exit;
    end;
  end;
end;


{---------------------------------------------------------------------------}
procedure CAM_IncLSBFull(var CTR: TCAMBlock);
  {-Increment CTR[0]..CTR[15]}
var
  j: integer;
begin
  for j:=0 to 15 do begin
    if CTR[j]=$FF then CTR[j] := 0
    else begin
      inc(CTR[j]);
      exit;
    end;
  end;
end;


{---------------------------------------------------------------------------}
function CAM_SetIncProc(IncP: TCAMIncProc; var ctx: TCAMContext): integer;
  {-Set user supplied IncCTR proc}
begin
  CAM_SetIncProc := CAM_Err_MultipleIncProcs;
  with ctx do begin
    {$ifdef FPC}
      if IncProc=nil then begin
        IncProc := IncP;
        CAM_SetIncProc := 0;
      end;
    {$else}
      if @IncProc=nil then begin
        IncProc := IncP;
        CAM_SetIncProc := 0;
      end;
    {$endif}
  end;
end;


{---------------------------------------------------------------------------}
{$ifdef CONST}
function CAM_CTR_Init(const Key; KeyBits: word; const CTR: TCAMBlock; var ctx: TCAMContext): integer;
{$else}
function CAM_CTR_Init(var Key; KeyBits: word; var CTR: TCAMBlock; var ctx: TCAMContext): integer;
{$endif}
  {-Camellia key expansion, error if inv. key size, encrypt CTR}
var
  err: integer;
begin
  err := CAM_Init(Key, KeyBits, ctx);
  if err=0 then begin
    ctx.IV := CTR;
    {encrypt CTR}
    CAM_Encrypt(ctx, CTR, ctx.buf);
  end;
  CAM_CTR_Init := err;
end;


{---------------------------------------------------------------------------}
procedure CAM_CTR_Reset({$ifdef CONST}const {$else} var {$endif}  CTR: TCAMBlock; var ctx: TCAMContext);
  {-Clears ctx fields bLen and Flag, encrypt CTR}
begin
  CAM_Reset(ctx);
  ctx.IV := CTR;
  CAM_Encrypt(ctx, CTR, ctx.buf);
end;


{---------------------------------------------------------------------------}
function CAM_CTR_Encrypt(ptp, ctp: Pointer; ILen: longint; var ctx: TCAMContext): integer;
  {-Encrypt ILen bytes from ptp^ to ctp^ in CTR mode}
begin
  CAM_CTR_Encrypt := 0;

  if (ptp=nil) or (ctp=nil) then begin
    if ILen>0 then begin
      CAM_CTR_Encrypt := CAM_Err_NIL_Pointer; {nil pointer to block with nonzero length}
      exit;
    end;
  end;

  {$ifdef BIT16}
    if (ofs(ptp^)+ILen>$FFFF) or (ofs(ctp^)+ILen>$FFFF) then begin
      CAM_CTR_Encrypt := CAM_Err_Invalid_16Bit_Length;
      exit;
    end;
  {$endif}

  if ctx.blen=0 then begin
    {Handle full blocks first}
    while ILen>=CAMBLKSIZE do with ctx do begin
      {Cipher text = plain text xor encr(CTR)}
      CAM_XorBlock(PCAMBlock(ptp)^, buf, PCAMBlock(ctp)^);
      inc(Ptr2Inc(ptp), CAMBLKSIZE);
      inc(Ptr2Inc(ctp), CAMBLKSIZE);
      dec(ILen, CAMBLKSIZE);
      {use CAM_IncMSBFull if IncProc=nil}
      {$ifdef FPC}
        if IncProc=nil then CAM_IncMSBFull(IV) else IncProc(IV);
      {$else}
        if @IncProc=nil then CAM_IncMSBFull(IV) else IncProc(IV);
      {$endif}
      CAM_Encrypt(ctx, IV, buf);
    end;
  end;

  {Handle remaining bytes}
  while ILen>0 do with ctx do begin
    {Refill buffer with encrypted CTR}
    if bLen>=CAMBLKSIZE then begin
      {use CAM_IncMSBFull if IncProc=nil}
      {$ifdef FPC}
        if IncProc=nil then CAM_IncMSBFull(IV) else IncProc(IV);
      {$else}
        if @IncProc=nil then CAM_IncMSBFull(IV) else IncProc(IV);
      {$endif}
      CAM_Encrypt(ctx, IV, buf);
      bLen := 0;
    end;
    {Cipher text = plain text xor encr(CTR)}
    pByte(ctp)^ := buf[bLen] xor pByte(ptp)^;
    inc(bLen);
    inc(Ptr2Inc(ptp));
    inc(Ptr2Inc(ctp));
    dec(ILen);
  end;
end;


{---------------------------------------------------------------------------}
function CAM_CTR_Decrypt(ctp, ptp: Pointer; ILen: longint; var ctx: TCAMContext): integer;
  {-Decrypt ILen bytes from ctp^ to ptp^ in CTR mode}
begin
  {Decrypt = encrypt for CTR mode}
  CAM_CTR_Decrypt := CAM_CTR_Encrypt(ctp, ptp, ILen, ctx);
end;

{$ifndef DLL}
{$i cam_seek.inc}
{$endif}

end.
