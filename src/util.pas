{$mode objfpc}
unit util;

{$H+}
{$codepage utf8}
{$scopedenums on}

interface

procedure Debug(const msg: String);

implementation

procedure Debug(const msg: String);
begin
{$IFDEF HAVE_DEBUG_LOGS}
	WriteLn(StdErr, '[DEBUG] ', msg);
{$ENDIF}
end;

end.
