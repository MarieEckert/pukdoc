{$mode objfpc}
unit util;

{$H+}
{$codepage utf8}
{$scopedenums on}

interface

procedure Debug(const msg: String);

function MakeHorSeperator(w: Integer): String;

implementation

procedure Debug(const msg: String);
begin
{$IFDEF HAVE_DEBUG_LOGS}
	WriteLn(StdErr, msg);
{$ENDIF}
end;

function MakeHorSeperator(w: Integer): String;
var
	i: Integer;
begin
	result := '';
	for i := 1 to w do
		result += UTF8String('─');
end;

end.
