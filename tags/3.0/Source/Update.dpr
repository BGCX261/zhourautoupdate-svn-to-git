program Update;

uses
  Forms,
  AutoUpdate in 'AutoUpdate.pas' {Form1},
  DirTools in 'DirTools.pas',
  GAEARegExpr in 'GAEARegExpr.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Terminate;
end.
