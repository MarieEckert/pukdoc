{$ifndef dcc}
{$mode delphi}
{$endif}
program pukdoc;

{$H+}
{$codepage utf8}
{$scopedenums on}

uses
	parser,
	writer;

var
	f: TextFile;
	parser: TParser;
	s: String;
begin
	parser := TParser.Create;

	Assign(f, ParamStr(1));
	ReSet(f);

	while not eof(f) do
	begin
		ReadLn(f, s);
		if not parser.ParseLine(s) then
			halt(1);
	end;

	if not parser.ParseLine('') then
		halt(2);

	Close(f);

	WriteParsed(parser, StdOut);
end.
