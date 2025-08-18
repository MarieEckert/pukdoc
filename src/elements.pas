{$mode objfpc}
unit elements;

{$H+}
{$codepage utf8}
{$scopedenums on}

interface

uses
	fgl,
	regexpr,
	StrUtils,
	SysUtils,
	Types,
	util;

type
	TElementKind = (
		Heading,
		IndentedCode,
		FencedCode,
		Paragraph,
		BlockQuote,
		ListItem,
		List,
		Table
	);

	TElement = interface
		function	GetKind: TElementKind;
		{ Consume a line and parse it into the element.
		  Should return True if the line has actually been consumed. }
		function	ConsumeLine(line: String): Boolean;
		{ Transforms the abstract representation into an array of lines }
		function	Translate: TStringDynArray;

		property	Kind: TElementKind read GetKind;
	end;

	PElement = ^TElement;

	TElements = specialize TFPGList<TElement>;

	THeading = class(TInterfacedObject, TElement)
	private
		FLevel		: Integer;
		FContent	: String;
	public
		constructor	Create;
		function	GetKind: TElementKind;
		function	ConsumeLine(line: String): Boolean;
		function	Translate: TStringDynArray;

		property	Kind: TElementKind read GetKind;
	end;

	TIndentedCode = class(TInterfacedObject, TElement)
	public
		constructor	Create;
		function	GetKind: TElementKind;
		function	Translate: TStringDynArray;
		function	ConsumeLine(line: String): Boolean;
	end;

	TFencedCode = class(TInterfacedObject, TElement)
	type
		TState = (Start, Content, Closed);
	private
		FState	: TState;
		FChar	: Char;
		FInfo	: String;
		FLines	: TStringDynArray;
	public
		constructor	Create;
		function	GetKind: TElementKind;
		function	Translate: TStringDynArray;
		function	ConsumeLine(line: String): Boolean;
	end;

	TParagraph = class(TInterfacedObject, TElement)
	private
		FLines	: TStringDynArray;
	public
		constructor	Create;
		function	GetKind: TElementKind;
		function	Translate: TStringDynArray;
		function	ConsumeLine(line: String): Boolean;

		property	Kind: TElementKind read GetKind;
	end;

	TBlockQuote = class(TInterfacedObject, TElement)
	private
		FLines	: TStringDynArray;
	public
		constructor	Create;
		function	GetKind: TElementKind;
		function	Translate: TStringDynArray;
		function	ConsumeLine(line: String): Boolean;
	end;

	TListItemStyle = (Bullet, Number);

	TListItem = class(TInterfacedObject, TElement)
	private
		FText	: String;
		FStyle	: TListItemStyle;
		FDepth	: Integer;
	public
		constructor	Create;
		function	GetKind: TElementKind;
		function	Translate: TStringDynArray;
		function	ConsumeLine(line: String): Boolean;

		property	Text: String read FText write FText;
		property	Style: TListItemStyle read FStyle write FStyle;
		property	Depth: Integer read FDepth write FDepth;
	end;

	TListItems = specialize TFPGList<TListItem>;

	TList = class(TInterfacedObject, TElement)
	private
		FItems	: TListItems;
	public
		constructor	Create;
		function	GetKind: TElementKind;
		function	Translate: TStringDynArray;
		function	ConsumeLine(line: String): Boolean;

		procedure	AddItem(
						text: String;
						style: TListItemStyle;
						depth: Integer
					);
	end;

	TTable = class(TInterfacedObject, TElement)
	type
		TTableState = (Header, Seperator, Body);
	private
		FState		: TTableState;
		FHeaders	: TStringDynArray;
		FRows		: array of TStringDynArray;
	public
		constructor	Create;
		function	GetKind: TElementKind;
		function	Translate: TStringDynArray;
		function	ConsumeLine(line: String): Boolean;

		property	Kind: TElementKind read GetKind;
	end;

const
	HEADING_REGEX		: UnicodeString = '[ ]{0,3}[#]{1,6}.*';
	FENCED_CODE_REGEX	: UnicodeString = '[ ]{0,3}(```|~~~).*';
	BLOCK_QUOTE_REGEX	: UnicodeString = '[ ]{0,3}>.*';
	LIST_ELEMENT_REGEX	: UnicodeString = '[ ]*([-+*]|[0-9]+[\.\)])[ ]+.*';
	TABLE_START_REGEX	: UnicodeString = '[ ]{0,3}\|.*\|';

implementation

{ class THeading }

constructor THeading.Create;
begin
	FLevel := -1;
	FContent := '';
end;

function THeading.GetKind: TElementKind;
begin
	exit(TElementKind.Heading);
end;

function THeading.ConsumeLine(line: String): Boolean;
var
	n: Integer;
begin
	Debug(Format('heading attempting to consume line (FLevel = %d)', [FLevel]));
	if FLevel <> -1 then
		exit(False);

	line := Trim(line);
	n := 1;
	while (line[n] = '#') do
		Inc(n);

	FContent := Copy(line, n, Length(line) - 1 + 1);
	FLevel := n - 1;

	Debug(Format(
		'parsed heading'#13#10'  -> content: %s'#13#10'  -> level: %d',
		[
			FContent,
			FLevel
		]
	));

	exit(True);
end;

function THeading.Translate: TStringDynArray;
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

function TParagraph.ConsumeLine(line: String): Boolean;
begin
	if Length(line) = 0 then
	begin
		Debug('line is empty, closing paragraph');
		exit(False);
	end;

	SetLength(FLines, Length(FLines) + 1);
	FLines[High(FLines)] := line;

	Debug('appended one line to paragraph');

	exit(True);
end;

{ class TBlockQuote }

constructor TBlockQuote.Create;
begin
end;

function TBlockQuote.GetKind: TElementKind;
begin
	exit(TElementKind.BlockQuote);
end;

function TBlockQuote.Translate: TStringDynArray;
begin
	exit([]);
end;

function TBlockQuote.ConsumeLine(line: String): Boolean;
var
	ix: Integer;
begin
	if not ExecRegExpr(BLOCK_QUOTE_REGEX, line) then
		exit(False);

	ix := Pos('>', line);

	SetLength(FLines, Length(FLines) + 1);
	FLines[High(FLines)] := Copy(line, ix + 1, Length(line) - ix);

	Debug(Format(
		'added one line to block quote'#13#10'  -> line: %s',
		[FLines[High(FLines)]]
	));

	exit(True);
end;

{ class TListItem }

constructor TListItem.Create;
begin
end;

function TListItem.GetKind: TElementKind;
begin
	exit(TElementKind.ListItem);
end;

function TListItem.Translate: TStringDynArray;
begin
	exit([]);
end;

function TListItem.ConsumeLine(line: String): Boolean;
begin
	exit(False);
end;

{ class TList }

constructor TList.Create;
begin
	FItems := TListItems.Create;
end;

function TList.GetKind: TElementKind;
begin
	exit(TElementKind.List);
end;

function TList.Translate: TStringDynArray;
begin
	exit([]);
end;

function TList.ConsumeLIne(line: String): Boolean;
begin
	exit(False);
end;

procedure TList.AddItem(text: String; style: TListItemStyle; depth: Integer);
begin
	//FItems.Add(TListItem.Create(text, style, depth));
end;

{ class TIndentedCode }

constructor TIndentedCode.Create;
begin
end;

function TIndentedCode.GetKind: TElementKind;
begin
	exit(TElementKind.IndentedCode);
end;

function TIndentedCode.Translate: TStringDynArray;
begin
	exit([]);
end;

function TIndentedCode.ConsumeLine(line: String): Boolean;
begin
	//SetLength(FLines, Length(FLines) + 1);
	//FLines[High(FLines)] := line;
	exit(False);
end;

{ class TFencedCode }

constructor TFencedCode.Create;
begin
	FState := TState.Start;
end;

function TFencedCode.GetKind: TElementKind;
begin
	exit(TElementKind.FencedCode);
end;

function TFencedCode.Translate: TStringDynArray;
begin
	exit(FLines);
end;

function TFencedCode.ConsumeLine(line: String): Boolean;
var
	ix		: Integer;
	trimmed	: String;
begin
	if FState = TState.Closed then
		exit(False);

	if FState = TState.Start then
	begin
		line := Trim(line);
		FChar := line[1];
		ix := 1;
		while line[ix] = line[1] do
			Inc(ix);

		if ix < Length(line) then
			FInfo := Copy(line, ix, Length(line) - ix);

		FState := TState.Content;
		exit(True);
	end;

	trimmed := Trim(line);
	if Length(trimmed) > 0 then
	begin
		if trimmed[1] = FChar then
		begin
			ix := 1;
			while line[ix] = FChar do
				Inc(ix);

			Debug(Format('encountered closing char, amount: %d', [ix]));
			if ix >= 3 then
			begin
				FState := TState.Closed;
				exit(True);
			end;
		end;
	end;

	SetLength(FLines, Length(FLines) + 1);
	FLines[High(FLines)] := line;

	Debug(Format(
		'added one line to fenced code'#13#10'  -> line: %s',
		[FLines[High(FLines)]]
	));

	exit(True);
end;

{ class TTable }

constructor TTable.Create;
begin
	FState := TTableState.Header;
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

function TTable.ConsumeLine(line: String): Boolean;
var
	ix		: Integer;
	strs	: TStringDynArray;
begin
	if not ExecRegExpr(TABLE_START_REGEX, line) then
		exit(False);

	if FState = TTableState.Seperator then
	begin
		FState := TTableState.Body;
		exit(True);
	end;

	strs := SplitString(Copy(line, 2, RPos('|', line) - 2), '|');
	for ix := 0 to Length(strs) - 1 do
		strs[ix] := Trim(strs[ix]);

	if FState = TTableState.Header then
	begin
		FHeaders := strs;
		FState := TTableState.Seperator;
	end else
	begin
		SetLength(FRows, Length(FRows) + 1);
		FRows[High(FRows)] := strs;
	end;

	exit(True);
end;

end.
