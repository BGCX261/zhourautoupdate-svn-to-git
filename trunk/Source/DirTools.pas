{*******************************************************}
{                                                       }
{       GGJ2009快速安装工具  目录操作单元               }
{                                                       }
{       版权所有 (C) 2011 Glodon                        }
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
  过程名:    TDoDir.IsValidDir
  作者:      Zhour
  日期:      2011.11.21
  参数:      ASearchRec: TSearchRec
  返回值:    Boolean
  作用：     判断是否为文件夹
-------------------------------------------------------------------------------}

class function TDoDir.IsValidDir(ASearchRec: TSearchRec): Boolean;
begin
  if (ASearchRec.Attr = 16) and (ASearchRec.Name <> '.') and (ASearchRec.Name <> '..') then
    Result := True
  else
    Result := False;
end;

{-------------------------------------------------------------------------------
  过程名:    TDoDir.DelTree
  作者:      Zhour
  日期:      2011.11.21
  参数:      ADirName: string
  返回值:    Boolean
  作用：     删除整个目录
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
  过程名:    TDoDir.DeleteDir
  作者:      zhour
  日期:      2012.12.11
  参数:      sDirectory:String
  返回值:    无
  作用:      删除整个目录，新方法试验中
-------------------------------------------------------------------------------}
class function TDoDir.DeleteDir(sDirectory:String): Boolean;
var
  sr:TSearchRec;
  sPath,sFile:String;
begin
  Result := False;
  //检查目录名后面是否有'\'
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
          DeleteFile(sFile);//删除文件
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
  过程名:    TDoDir.DeleteDir2
  作者:      zhour
  日期:      2012.12.11
  参数:      fn:string
  返回值:    Boolean
  作用:      调用API删除整个目录，新方法试验中
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
      //标志表明无须确认并不显示出错信息
      fFlags:=FOF_NOCONFIRMATION+FOF_NOERRORUI;
      hNameMappings:=nil;
      lpszProgressTitle:='正在删除文件夹';
      fAnyOperationsAborted:=False;
    End;
    SHFileOperation(T);
    Result := True;
  except
    Result := False;
  end;
end;

{-------------------------------------------------------------------------------
  过程名:    TDoDir.CopyDirectory
  作者:      Zhour
  日期:      2011.11.21
  参数:      const ASource, ADest: string
  返回值:    boolean
  作用：     复制文件夹
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
  过程名:    TDoDir.GetShellFolderPath
  作者:      Zhour
  日期:      2011.11.21
  参数:      const ARoot: HKEY; const AKey, AName: string; out AFolderPath: string
  返回值:    Boolean
  作用：     读取特殊目录地址
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
  过程名:    TDoDir.GetCommonDocumentsPath
  作者:      Zhour
  日期:      2011.11.21
  参数:      无
  返回值:    string
  作用：     读取公共文档目录地址
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
  过程名:    TDoDir.FindSubDir
  作者:      Zhour
  日期:      2011.11.21
  参数:      ADirName: string; AFileString: TStrings
  返回值:    无
  作用：     找下级子目录
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
  过程名:    CheckTask
  作者:      Zhour
  日期:      2011.11.22
  参数:      AExeFileName: string
  返回值:    Boolean
  作用：     判断进程是否存在
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
  过程名:    TDoDir.GetSysTempPath
  作者:      Zhour
  日期:      2011.11.22
  参数:      无
  返回值:    string
  作用：     取系统临时目录
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
  过程名:    TDoDir.GetFolderSize
  作者:      zhour
  日期:      2012.07.06
  参数:      vFolder: String
  返回值:    Int64
  作用:      获得文件夹大小
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






