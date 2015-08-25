unit AutoUpdate;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, IniFiles, DirTools, ShellAPI, Tlhelp32, StdCtrls;

type
  TForm1 = class(TForm)
    procedure FormCreate(Sender: TObject);
    function KillTask(ExeFileName:string):integer;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
var
  Updateini, Oldini: TIniFile;
  DefaultProcessName, IniDirName, NewVer, OldVer, OldPath, OldProcess, OldProcessName: string;
begin
  try
    Updateini := TIniFile.Create(ExtractFilePath(Application.ExeName) + 'Update.ini');
    NewVer := Updateini.ReadString('Update', 'Ver', '-1');
    DefaultProcessName := Updateini.ReadString('Update', 'DefaultProcessName', 'zhour.exe');
    IniDirName := Updateini.ReadString('Update', 'IniDirName', 'TempIni');
  finally
    Updateini.Free;
  end;

  try
    Oldini := TIniFile.Create(TDoDir.GetSysTempPath + IniDirName + '\Options.ini');
    OldVer := Oldini.ReadString('Update', 'Ver', '0');
    OldPath := Oldini.ReadString('Update', 'Path', '');
    OldProcess := Oldini.ReadString('Update', 'Process', '');
  finally
    Oldini.Free;
  end;

  if StrToFloat(NewVer) > StrToFloat(OldVer) then
  begin
    Sleep(2000);

    if TDoDir.CheckTask(OldProcess) then
    begin
      KillTask(OldProcess);
//    MessageBox(Handle, '杀进程结束', '提示', MB_OK + MB_ICONINFORMATION +
//      MB_TOPMOST);
      Sleep(2000);
    end;
    CopyFile(PChar(Extractfilepath(Application.ExeName) + DefaultProcessName), PChar(OldPath), False);
//    MessageBox(Handle, '复制文件结束', '提示', MB_OK + MB_ICONINFORMATION +
//      MB_TOPMOST);
    Sleep(2000);
    ShellExecute(Handle, 'open', PChar(OldPath), nil, nil, SW_SHOWNORMAL);
  end;
end;

function TForm1.KillTask(ExeFileName:string): Integer;
const
  PROCESS_TERMINATE = $0001;
var
  ContinueLoop: BOOLean;
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
begin
  Result := 0;
  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  FProcessEntry32.dwSize := SizeOf(FProcessEntry32);
  ContinueLoop := Process32First(FSnapshotHandle, FProcessEntry32);

  while Integer(ContinueLoop) <> 0 do
  begin
    if ((UpperCase(ExtractFileName(FProcessEntry32.szExeFile)) =
    UpperCase(ExeFileName)) or (UpperCase(FProcessEntry32.szExeFile) =
    UpperCase(ExeFileName))) then
      Result := Integer(TerminateProcess(
      OpenProcess(PROCESS_TERMINATE,
      BOOL(0),
      FProcessEntry32.th32ProcessID),
      0));
    ContinueLoop := Process32Next(FSnapshotHandle, FProcessEntry32);
  end;
  CloseHandle(FSnapshotHandle);
end;

end.
