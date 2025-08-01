{$mode objfpc}
unit elements;

{$H+}
{$codepage utf8}
{$scopedenums on}

interface

uses
	fgl,
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
	private
		FHeaders	: TStringDynArray;
		FRows		: array of TStringDynArray;
	public
		constructor	Create(headers: TStringDynArray);
		function	GetKind: TElementKind;
		function	Translate: TStringDynArray;
		function	ConsumeLine(line: String): Boolean;

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

{ class THeading }

constructor THeading.Create;
begin
	FLevel := -1;
end;

function THeading.GetKind: TElementKind;
begin
	exit(TElementKind.Heading);
end;

function THeading.ConsumeLine(line: String): Boolean;
begin
	Debug(Format('heading attempting to consume line (FLevel = %d)', [FLevel]));
	if FLevel <> -1 then
		exit(False);

	FContent := line;
	FLevel := 1;
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
		exit(True);

	SetLength(FLines, Length(FLines) + 1);
	FLines[High(FLines)] := line;
	exit(False);
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
begin
	//SetLength(FLines, Length(FLines) + 1);
	//FLines[High(FLines)] := line;
	exit(False);
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
end;

function TFencedCode.GetKind: TElementKind;
begin
	exit(TElementKind.FencedCode);
end;

function TFencedCode.Translate: TStringDynArray;
begin
	exit([]);
end;

function TFencedCode.ConsumeLine(line: String): Boolean;
begin
	//SetLength(FLines, Length(FLines) + 1);
	//FLines[High(FLines)] := line;
	exit(False);
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
{
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
}
end;

function TTable.ConsumeLine(line: String): Boolean;
begin
	exit(False);
end;

end.
