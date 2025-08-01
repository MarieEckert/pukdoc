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

const
	VERSION = '0.1';

type
	TParams = record
		Help	: Boolean;
		Version	: Boolean;
		InPath	: String;
		OutPath	: String;
	end;

function HandleArgument(
	const ix: Integer;
	var dest: String;
	const name: String
): Integer;
begin
	result := 0;
	if ix + 1 > ParamCount then
	begin
		writeln(stderr, 'Argument Error');
		writeln(stderr, '==> Missing parameter for argument "', name,'"');
		Halt(1);
	end;

	dest := ParamStr(ix + 1);

	Inc(result);
end;

function ParseParams: TParams;
var
	i, skip: Integer;
	s: String;
begin
	result.InPath := '';
	result.OutPath := '';
	result.Help := False;
	result.Version := False;

	skip := 0;
	for i := 1 to ParamCount do
	begin
		if skip > 0 then
		begin
			Dec(skip);
			continue;
		end;

		s := ParamStr(i);
		if (s = '-o') or (s = '--out') then
			skip := HandleArgument(i, result.OutPath, '-o')
		else if (s = '-h') or (s = '--help') then
			result.Help := True
		else if (s = '-v') or (s = '--version') then
			result.Version := True
		else if i = 1 then
			result.InPath := s
		else begin
			WriteLn(StdErr, 'Argument Error');
			WriteLn(StdErr, '==> Invalid argument "', s, '" at position ', i);
			Halt(1);
		end;
	end;
end;

procedure ShowHelp;
begin
	WriteLn(StdErr, 'usage: pukdoc [input file] [additional arguments]');
	WriteLn(StdErr);
	WriteLn(StdErr, 'if no input file is provided, input is read from stdin.');
	WriteLn(
		StdErr,
		'if no output file is provided, output is written to stdout.'
	);
	WriteLn(StdErr);
	WriteLn(StdErr, 'ARGUMENTS');
	WriteLn(StdErr, '  --out | -o <file>');
	WriteLn(StdErr, '    Specify an output file');
	WriteLn(StdErr, '  --version | -v');
	WriteLn(StdErr, '    Show the version of the program');
	WriteLn(StdErr, '  --help | -h');
	WriteLn(StdErr, '    Show this help text');

	halt;
end;

procedure Convert(const src: String; const dest: String);
var
	inFile, outFile: TextFile;
	parser: TParser;
	s: String;
begin
	parser := TParser.Create;

	Assign(inFile, src);
	ReSet(inFile);

	while not eof(inFile) do
	begin
		ReadLn(inFile, s);
		if not parser.ParseLine(s) then
			Halt(1);
	end;

	parser.Finish;

	Close(inFile);

	Assign(outFile, dest);
	ReWrite(outFile);
	WriteParsed(parser, outFile);
	Close(outFile);
end;

var
	params: TParams;
begin
	params := ParseParams;

	if params.Help then
		ShowHelp;

	if params.Version then
	begin
		WriteLn('pukdoc version ', VERSION);
		Halt;
	end;

	Convert(params.InPath, params.OutPath);
end.
