{$A+,B-,D+,E+,F-,G+,I+,L+,N+,O-,P-,Q-,R-,S+,T-,V+,X+,Y+}
program IDE;

uses IApp, IProcs;

procedure About;
begin
  Writeln('IDE for Data Recovery  Version 2.01  Copyright (c) 2001,02 by Mateusz Janda');
end;

begin
  About;
  GetDir(0, AppDir);
  if not IsPathDelimiter(AppDir) then
    AppDir := AppDir + '\';

  IDEApplication.Init;
  IDEApplication.Run;
  IDEApplication.Done;

  AppDir := Copy(AppDir, 1, Length(AppDir) - 1);
  {$I-}
  ChDir(AppDir);
end.