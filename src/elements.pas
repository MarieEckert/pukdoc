{$mode objfpc}
unit elements;

{$H+}
{$codepage utf8}
{$scopedenums on}

interface

uses
	fgl,
	SysUtils,
	Types;

type
	TElementKind = (Header, Paragraph, Block, Table);

	TElement = interface
		function GetKind: TElementKind;
		{ Transforms the abstract representation into an array of lines }
		function Translate: TStringDynArray;

		property Kind: TElementKind read GetKind;
	end;

	TElements = specialize TFPGList<TElement>;

	THeader = class(TInterfacedObject, TElement)
	private
		FLevel		: Integer;
		FContent	: String;
	public
		constructor	Create(level: Integer; content: String);
		function	GetKind: TElementKind;
		function	Translate: TStringDynArray;

		property	Kind: TElementKind read GetKind;
	end;

	TParagraph = class(TInterfacedObject, TElement)
	private
		FLines	: TStringDynArray;
	public
		constructor	Create;
		function	GetKind: TElementKind;
		function	Translate: TStringDynArray;
		procedure	AddLine(line: String);

		property	Kind: TElementKind read GetKind;
	end;

	TBlock = class(TInterfacedObject, TElement)
	private
		FLanguage	: String;
		FLines		: TStringDynArray;
	public
		constructor	Create(language: String);
		function	GetKind: TElementKind;
		function	Translate: TStringDynArray;
		procedure	AddLine(line: String);

		property	Kind: TElementKind read GetKind;
	end;

	TTable = class(TInterfacedObject, TElement)
	private
		FHeaders	: TStringDynArray;
		FRows		: array of TStringDynArray;
	public
		constructor	Create(headers: TStringDynArray);
		function	GetKind: TElementKind;
		function	Translate: TStringDynArray;
		procedure	AddRow(row: TStringDynArray);

		property	Kind: TElementKind read GetKind;
	end;

function MakeHorSeperator(w: Integer): String;

implementation

function MakeHorSeperator(w: Integer): String;
var
	i: Integer;
begin
	result := '';
	for i := 1 to w do
		result += UTF8String('─');
end;

{ class THeader }

constructor THeader.Create(level: Integer; content: String);
begin
	FLevel := level;
	FContent := content;
end;

function THeader.GetKind: TElementKind;
begin
	exit(TElementKind.Header);
end;

function THeader.Translate: TStringDynArray;
begin
	exit([UpperCase(FContent)]);
end;

{ class TParagraph }

constructor TParagraph.Create;
begin
end;

function TParagraph.GetKind: TElementKind;
begin
	exit(TElementKind.Paragraph);
end;

function TParagraph.Translate: TStringDynArray;
begin
	exit(FLines);
end;

procedure TParagraph.AddLine(line: String);
begin
	SetLength(FLines, Length(FLines) + 1);
	FLines[High(FLines)] := line;
end;

{ class TBlock }

constructor TBlock.Create(language: String);
begin
	FLanguage := language;
end;

function TBlock.GetKind: TElementKind;
begin
	exit(TElementKind.Block);
end;

function TBlock.Translate: TStringDynArray;
begin
	exit(FLines);
end;

procedure TBlock.AddLine(line: String);
begin
	SetLength(FLines, Length(FLines) + 1);
	FLines[High(FLines)] := line;
end;

{ class TTable }

constructor TTable.Create(headers: TStringDynArray);
begin
	FHeaders := headers;
end;

function TTable.GetKind: TElementKind;
begin
	exit(TElementKind.Table);
end;

function TTable.Translate: TStringDynArray;

	function MakeRow(data: TStringDynArray; widths: array of Integer): String;
	var
		i	: Integer;
		tmp	: String;
	begin
		result := '│';
		for i := 0 to Length(data) - 1 do
		begin
			tmp := data[i];
			result += ' ' + tmp
					+ StringOfChar(' ', widths[i] - Length(tmp))
					+ UTF8String(' │');
		end;
	end;

var
	columnWidths					: array of Integer;
	row								: TStringDynArray;
	tmp, upper, lower, sep, header	: String;
	i								: Integer;
begin
	SetLength(columnWidths, Length(FHeaders));
	for i := 0 to Length(FHeaders) - 1 do
	begin
		columnWidths[i] := Length(FHeaders[i]);
	end;

	for row in FRows do
	begin
		for i := 0 to Length(row) do
			if Length(row[i]) > columnWidths[i] then
				columnWidths[i] := Length(row[i]);
	end;

	upper := '┌';
	lower := '└';
	sep := '├';
	for i := 0 to Length(columnWidths) - 1 do
	begin
		tmp := MakeHorSeperator(columnWidths[i] + 2);
		upper += tmp;
		lower += tmp;
		sep += tmp;
		if i + 1 < Length(columnWidths) then
		begin
			upper += UTF8String('┬');
			lower += UTF8String('┴');
			sep += UTF8String('┼');
		end else
		begin
			upper += UTF8String('┐');
			lower += UTF8String('┘');
			sep += UTF8String('┤');
		end;
	end;

	header := MakeRow(FHeaders, columnWidths);
	result := [upper, header, sep, sep];

	for row in FRows do
	begin
		SetLength(result, Length(result) + 2);
		result[High(result) - 1] := MakeRow(row, columnWidths);
		result[High(result)] := sep;
	end;

	result[High(result)] := lower;
end;

procedure TTable.AddRow(row: TStringDynArray);
begin
	SetLength(FRows, Length(FRows) + 1);
	FRows[High(FRows)] := row;
end;

end.
