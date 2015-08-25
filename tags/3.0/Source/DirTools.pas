{*******************************************************}
{                                                       }
{       GGJ2009���ٰ�װ����  Ŀ¼������Ԫ               }
{                                                       }
{       ��Ȩ���� (C) 2011 Glodon                        }
{                                                       }
{*******************************************************}

unit DirTools;

interface
uses
  Windows, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, GAEARegExpr, ExtCtrls, jpeg, msxmldom,
  Registry, ShellAPI, TLhelp32;

type
  TDoDir = class
    class var SysTempPath: string;
    class function IsValidDir(ASearchRec: TSearchRec): Boolean;
    class function DelTree(ADirName: string): Boolean;
    class function DeleteDir(sDirectory:String): Boolean;
    class function DeleteDir2(fn:string): Boolean;
    class function CopyDirectory(const ASource, ADest: string): boolean;
    class function GetShellFolderPath(const ARoot: HKEY; const AKey, AName: string;
      out AFolderPath: string): Boolean;
    class function GetCommonDocumentsPath: string;
    class procedure FindSubDir(ADirName: string; AFileString: TStrings);
    class function CheckTask(AExeFileName: string; IsExpr: Boolean = False): Boolean;
    class function GetSysTempPath: string;
    class function GetFolderSize(vFolder: String): Int64;
  end;

implementation
{-------------------------------------------------------------------------------
  ������:    TDoDir.IsValidDir
  ����:      Zhour
  ����:      2011.11.21
  ����:      ASearchRec: TSearchRec
  ����ֵ:    Boolean
  ���ã�     �ж��Ƿ�Ϊ�ļ���
-------------------------------------------------------------------------------}

class function TDoDir.IsValidDir(ASearchRec: TSearchRec): Boolean;
begin
  if (ASearchRec.Attr = 16) and (ASearchRec.Name <> '.') and (ASearchRec.Name <> '..') then
    Result := True
  else
    Result := False;
end;

{-------------------------------------------------------------------------------
  ������:    TDoDir.DelTree
  ����:      Zhour
  ����:      2011.11.21
  ����:      ADirName: string
  ����ֵ:    Boolean
  ���ã�     ɾ������Ŀ¼
-------------------------------------------------------------------------------}

class function TDoDir.DelTree(ADirName: string): Boolean;
var
  SHFileOpStruct: TSHFileOpStruct;
  DirBuf: array[0..255] of char;

begin
  try
    Fillchar(SHFileOpStruct, Sizeof(SHFileOpStruct), 0);
    FillChar(DirBuf, Sizeof(DirBuf), 0);
    StrPCopy(DirBuf, ADirName);
    with SHFileOpStruct do begin
      Wnd := 0;
      pFrom := @DirBuf;
      wFunc := FO_DELETE;
      fFlags := fFlags or FOF_NOCONFIRMATION;
      fFlags := fFlags or FOF_SILENT;
      fFlags := fFlags or FOF_NOERRORUI;
    end;
    Result := (SHFileOperation(SHFileOpStruct) = 0);
  except
    Result := False;
  end;
end;

{-------------------------------------------------------------------------------
  ������:    TDoDir.DeleteDir
  ����:      zhour
  ����:      2012.12.11
  ����:      sDirectory:String
  ����ֵ:    ��
  ����:      ɾ������Ŀ¼���·���������
-------------------------------------------------------------------------------}
class function TDoDir.DeleteDir(sDirectory:String): Boolean;
var
  sr:TSearchRec;
  sPath,sFile:String;
begin
  Result := False;
  //���Ŀ¼�������Ƿ���'\'
  try
    if Copy(sDirectory,Length(sDirectory),1)<>'\'then
      sPath:=sDirectory+'\'
    else
      sPath:=sDirectory;
    //------------------------------------------------------------------
    if FindFirst(sPath+'*.*',faAnyFile,sr)=0 then
    begin
      repeat
        sFile:=Trim(sr.Name);
        if sFile='.' then Continue;
        if sFile='..' then Continue;
        sFile:=sPath+sr.Name;
        if(sr.Attr and faDirectory)<>0 then
          DeleteDir(sFile)
        else if(sr.Attr and faAnyFile)=sr.Attr then
          DeleteFile(sFile);//ɾ���ļ�
      until FindNext(sr)<>0;
      FindClose(sr);
    end;
    RemoveDir(sPath);
    Result := True;
  except
    Result := False;
  end;
end;

{-------------------------------------------------------------------------------
  ������:    TDoDir.DeleteDir2
  ����:      zhour
  ����:      2012.12.11
  ����:      fn:string
  ����ֵ:    Boolean
  ����:      ����APIɾ������Ŀ¼���·���������
-------------------------------------------------------------------------------}
class function TDoDir.DeleteDir2(fn:string): Boolean;
var
  T:TSHFileOpStruct;
begin
  Result := False;
  try
    With T do
    Begin
      Wnd:=0;
      wFunc:=FO_DELETE;
      pFrom:=Pchar(fn);
      pTo:=nil;
      //��־��������ȷ�ϲ�����ʾ������Ϣ
      fFlags:=FOF_NOCONFIRMATION+FOF_NOERRORUI;
      hNameMappings:=nil;
      lpszProgressTitle:='����ɾ���ļ���';
      fAnyOperationsAborted:=False;
    End;
    SHFileOperation(T);
    Result := True;
  except
    Result := False;
  end;
end;

{-------------------------------------------------------------------------------
  ������:    TDoDir.CopyDirectory
  ����:      Zhour
  ����:      2011.11.21
  ����:      const ASource, ADest: string
  ����ֵ:    boolean
  ���ã�     �����ļ���
-------------------------------------------------------------------------------}

class function TDoDir.CopyDirectory(const ASource, ADest: string): boolean;
var
  fo: TSHFILEOPSTRUCT;
begin
  try
    FillChar(fo, SizeOf(fo), 0);
    with fo do
    begin
      Wnd := 0;
      wFunc := FO_COPY;
      pFrom := PChar(ASource + #0);
      pTo := PChar(ADest + #0);
      fFlags := FOF_NOCONFIRMATION + FOF_NOCONFIRMMKDIR + FOF_SILENT;
    end;
    Result := (SHFileOperation(fo) = 0);
  except
    Result := False;
  end;
end;

{-------------------------------------------------------------------------------
  ������:    TDoDir.GetShellFolderPath
  ����:      Zhour
  ����:      2011.11.21
  ����:      const ARoot: HKEY; const AKey, AName: string; out AFolderPath: string
  ����ֵ:    Boolean
  ���ã�     ��ȡ����Ŀ¼��ַ
-------------------------------------------------------------------------------}

class function TDoDir.GetShellFolderPath(const ARoot: HKEY; const AKey, AName: string;
  out AFolderPath: string): Boolean;
begin
  with TRegistry.Create do
  try
    Access := KEY_READ;
    RootKey := ARoot;
    if OpenKey(AKey, False) then
    begin
      AFolderPath := ReadString(AName);
      CloseKey;
    end;
  finally
    Free;
  end;
  Result := DirectoryExists(AFolderPath);
  if Result then
  begin
    AFolderPath := IncludeTrailingPathDelimiter(AFolderPath);
  end
  else AFolderPath := '';
end;

{-------------------------------------------------------------------------------
  ������:    TDoDir.GetCommonDocumentsPath
  ����:      Zhour
  ����:      2011.11.21
  ����:      ��
  ����ֵ:    string
  ���ã�     ��ȡ�����ĵ�Ŀ¼��ַ
-------------------------------------------------------------------------------}

class function TDoDir.GetCommonDocumentsPath: string;
var
  conShellFolderKey, conCommonDocumentsName: string;
begin
  conShellFolderKey := '\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders';
  conCommonDocumentsName := 'Common Documents';
  if not GetShellFolderPath(HKEY_LOCAL_MACHINE, conShellFolderKey, conCommonDocumentsName, Result) then
    Result := '';
end;

{-------------------------------------------------------------------------------
  ������:    TDoDir.FindSubDir
  ����:      Zhour
  ����:      2011.11.21
  ����:      ADirName: string; AFileString: TStrings
  ����ֵ:    ��
  ���ã�     ���¼���Ŀ¼
-------------------------------------------------------------------------------}

class procedure TDoDir.FindSubDir(ADirName: string; AFileString: TStrings);
var
  ASearchRec: TsearchRec;
begin
  if (FindFirst(ADirName + '*.*', faDirectory, ASearchRec) = 0) then
  begin
    if IsValidDir(ASearchRec) then
      AFileString.Add(ADirName + ASearchRec.Name);
    while (FindNext(ASearchRec) = 0) do
    begin
      if IsValidDir(ASearchRec) then
        AFileString.Add(ADirName + ASearchRec.Name);
    end;
  end;
  FindClose(ASearchRec);
end;

{-------------------------------------------------------------------------------
  ������:    CheckTask
  ����:      Zhour
  ����:      2011.11.22
  ����:      AExeFileName: string
  ����ֵ:    Boolean
  ���ã�     �жϽ����Ƿ����
-------------------------------------------------------------------------------}

class function TDoDir.CheckTask(AExeFileName: string; IsExpr: Boolean = False): Boolean;
const
  PROCESS_TERMINATE = $0001;
var
  ContinueLoop: BOOL;
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
  ProcessExpr: TRegExpr;
begin
  Result := False;
  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  FProcessEntry32.dwSize := Sizeof(FProcessEntry32);
  ContinueLoop := Process32First(FSnapshotHandle, FProcessEntry32);
  if IsExpr then
  begin
    ProcessExpr := TRegExpr.Create;
    ProcessExpr.Expression := UpperCase(AExeFileName);
    while integer(ContinueLoop) <> 0 do
    begin
      if ProcessExpr.Exec(UpperCase(ExtractFileName(FProcessEntry32.szExeFile))) then
      begin
        Result := True;
        Break;
      end;
      ContinueLoop := Process32Next(FSnapshotHandle, FProcessEntry32);
    end;
    ProcessExpr.Free;
  end
  else
  begin
    while integer(ContinueLoop) <> 0 do
    begin
      if ((UpperCase(ExtractFileName(FProcessEntry32.szExeFile)) = UpperCase(AExeFileName))
        or (UpperCase(FProcessEntry32.szExeFile) = UpperCase(AExeFileName))) then
      begin
        Result := True;
        Break;
      end;
      ContinueLoop := Process32Next(FSnapshotHandle, FProcessEntry32);
    end;
  end;
end;

{-------------------------------------------------------------------------------
  ������:    TDoDir.GetSysTempPath
  ����:      Zhour
  ����:      2011.11.22
  ����:      ��
  ����ֵ:    string
  ���ã�     ȡϵͳ��ʱĿ¼
-------------------------------------------------------------------------------}

class function TDoDir.GetSysTempPath: string;
var
  SysTempPath: string;
  nPathLength: Cardinal;
begin
  try
    SetLength(SysTempPath, 255);
    nPathLength := Windows.GetTempPath(255, PChar(SysTempPath));
    SetLength(SysTempPath, nPathLength);
    Result := SysTempPath;
  except
    Result := 'C:\';
  end;
  TDoDir.SysTempPath := Result;
end;

{-------------------------------------------------------------------------------
  ������:    TDoDir.GetFolderSize
  ����:      zhour
  ����:      2012.07.06
  ����:      vFolder: String
  ����ֵ:    Int64
  ����:      ����ļ��д�С
-------------------------------------------------------------------------------}

class function TDoDir.GetFolderSize(vFolder: String): Int64;
var
  sr: TSearchRec;
begin
  Result := 0;
  if FindFirst(vFolder + '*.*', faAnyFile, sr) = 0 then
  repeat
    if (sr.Name <> '.') and (sr.Name <> '..') then
    begin
      Result := Result + sr.Size;
      if (sr.Attr and faDirectory) <> 0 then
        Result := Result + GetFolderSize(vFolder + sr.Name + '\');
    end;
  until FindNext(sr) <> 0;
  FindClose(sr);
end;
end.






