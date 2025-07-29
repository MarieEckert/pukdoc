{$mode objfpc}
unit parser;

{$H+}
{$codepage utf8}
{$scopedenums on}

interface

uses
	elements,
	fgl,
	StrUtils,
	SysUtils,
	Types;

type
	TSection = class
	private
		FName: String;
	public
		constructor Create(name: String);

		property Name: String read FName;
	end;

	TSections = specialize TFPGList<TSection>;

	TParserState = (Paragraph, TableSeperator, TableBody, Block);

	TParser = class
	private
		FState		: TParserState;
		FSections	: TSections;
		FElements	: TElements;

		FCurrentTable		: TTable;
		FCurrentBlock		: TBlock;
		FCurrentParagraph	: TParagraph;

		function ParseHeader(const line: String): Boolean;
		function ParseTableHeader(const line: String): Boolean;
		function ParseTableSeperator(const line: String): Boolean;
		function ParseTableBodyLine(const line: String): Boolean;
		function ParseBlockStart(const line: String): Boolean;
		function ParseBlockLine(const line: String): Boolean;
	public
		constructor	Create;
		function	ParseLine(const line: String): Boolean;
		procedure	Finish;

		property	Sections: TSections read FSections;
		property	Elements: TElements read FElements;
	end;

implementation

{ class TSection }

constructor TSection.Create(name: String);
begin
	FName := name;
end;

{ class TParser }

{
	Document
		Element[Header]
			Level: 2
			Content: Introduction
		Element[Paragraph]
			Content: ...
		Element[Table]
			Content
				Headers
					Arch
					return
					arg1
				Rows
					0
						x64
						rdx:rax
						rdi
}

function TParser.ParseHeader(const line: String): Boolean;
var
	n: Integer;
	s: String;
begin
	n := 1;
	while (line[n] = '#') do
		Inc(n);

	s := Trim(Copy(line, n, Length(line) - n + 1));

	FSections.Add(TSection.Create(s));
	FElements.Add(THeader.Create(n - 1, s));

	exit(True);
end;

function TParser.ParseTableHeader(const line: String): Boolean;
var
	headers: TStringDynArray;
	ix: SizeUInt;
begin
	if FCurrentTable <> Nil then
	begin
		WriteLn(StdErr, 'invalid state 1');
		exit(False);
	end;

	headers := SplitString(Copy(line, 2, RPos('|', line) - 2), '|');
	for ix := 0 to Length(headers) - 1 do
		headers[ix] := Trim(headers[ix]);

	FCurrentTable := TTable.Create(headers);
	exit(True);
end;

function TParser.ParseTableSeperator(const line: String): Boolean;
begin
	if FCurrentTable = Nil then
	begin
		WriteLn(StdErr, 'invalid state 2');
		exit(False);
	end;

	{ todo: do more with this? }

	exit(True);
end;

function TParser.ParseTableBodyLine(const line: String): Boolean;
var
	trimmed	: String;
	columns	: TStringDynArray;
	ix		: SizeUInt;
begin
	if FCurrentTable = Nil then
	begin
		WriteLn(StdErr, 'invalid state 3');
		exit(False);
	end;

	trimmed := Trim(line);
	if (Length(trimmed) = 0) or (trimmed[1] <> '|') then
	begin
		FState := TParserState.Paragraph;
		FElements.Add(FCurrentTable);
		FCurrentTable := Nil;
		exit(ParseLine(line));
	end;

	columns := SplitString(Copy(line, 2, RPos('|', line) - 2), '|');
	for ix := 0 to Length(columns) - 1 do
		columns[ix] := Trim(columns[ix]);

	FCurrentTable.AddRow(columns);

	exit(True);
end;

function TParser.ParseBlockStart(const line: String): Boolean;
begin
	if FCurrentBlock <> Nil then
	begin
		WriteLn(StdErr, 'invalid state 4');
		exit(False);
	end;

	FCurrentBlock := TBlock.Create(Trim(SplitString(line, '```')[1]));
	exit(True);
end;

function TParser.ParseBlockLine(const line: String): Boolean;
begin
	if FCurrentBlock = Nil then
	begin
		WriteLn(StdErr, 'invalid state 5');
		exit(False);
	end;

	if StartsStr('```', Trim(line)) then
	begin
		FState := TParserState.Paragraph;
		FElements.Add(FCurrentBlock);
		FCurrentBlock := Nil;
		exit(True);
	end;

	FCurrentBlock.AddLine(line);
	exit(True);
end;

constructor TParser.Create;
begin
	FSections := TSections.Create;
	FElements := TElements.Create;
	FState := TParserState.Paragraph;
end;

function TParser.ParseLine(const line: String): Boolean;
var
	trimmed: String;
begin
	trimmed := Trim(line);

	case FState of
	TParserState.Paragraph: begin
		if Length(trimmed) = 0 then
		begin
			if FCurrentParagraph = Nil then
				FCurrentParagraph := TParagraph.Create;

			FCurrentParagraph.AddLine('');
			exit(True);
		end;

		if trimmed[1] = '#' then
		begin
			if FCurrentParagraph <> Nil then
				FElements.Add(FCurrentParagraph);
			FCurrentParagraph := Nil;
			exit(ParseHeader(line));
		end;

		if trimmed[1] = '|' then
		begin
			if FCurrentParagraph <> Nil then
				FElements.Add(FCurrentParagraph);
			FCurrentParagraph := Nil;
			FState := TParserState.TableSeperator;
			exit(ParseTableHeader(line));
		end;

		if StartsStr('```', trimmed) then
		begin
			if FCurrentParagraph <> Nil then
				FElements.Add(FCurrentParagraph);
			FCurrentParagraph := Nil;
			FState := TParserState.Block;
			exit(ParseBlockStart(line));
		end;

		if FCurrentParagraph = Nil then
			FCurrentParagraph := TParagraph.Create;

		FCurrentParagraph.AddLine(line);
	end;
	TParserState.TableSeperator: begin
		FState := TParserState.TableBody;
		exit(ParseTableSeperator(line));
	end;
	TParserState.TableBody: begin
		exit(ParseTableBodyLine(line));
	end;
	TParserState.Block: begin
		exit(ParseBlockLine(line));
	end;
	end;

	exit(true);
end;

procedure TParser.Finish;
begin
	if FCurrentParagraph <> Nil then
		FElements.Add(FCurrentParagraph);

	if FCurrentBlock <> Nil then
		FElements.Add(FCurrentBlock);

	if FCurrentTable <> Nil then
		FElements.Add(FCurrentTable);
end;

end.
