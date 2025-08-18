{$mode objfpc}
unit parser;

{$H+}
{$codepage utf8}
{$scopedenums on}

interface

uses
	elements,
	fgl,
	regexpr,
	StrUtils,
	SysUtils,
	Types,
	util;

type
	TSection = class
	private
		FName: String;
	public
		constructor Create(name: String);

		property Name: String read FName;
	end;

	TSections = specialize TFPGList<TSection>;

	TParser = class
	private
		FSections		: TSections;
		FElements		: TElements;
		FOpenElement	: Boolean;

		function	TryConsumption(const line: String): Boolean;
		procedure	NewElement(element: TElement; const line: String);
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

constructor TParser.Create;
begin
	FSections := TSections.Create;
	FElements := TElements.Create;
	FOpenElement := False;
end;

function TParser.TryConsumption(const line: String): Boolean;
begin
	if not FOpenElement then
		exit(False);

	if FElements.Last.ConsumeLine(line) then
		exit(True);

	Debug('open element didn''t consume line, closing it');
	FOpenElement := False;

	if FElements.Last.Kind = TElementKind.Heading then
		FSections.Add(TSection.Create(FElements.Last.Translate[0]));

	exit(False);
end;

procedure TParser.NewElement(element: TElement; const line: String);
begin
	FElements.Add(element);
	FOpenElement := True;
	TryConsumption(line);
end;

function TParser.ParseLine(const line: String): Boolean;
begin
	if ((FElements.Count > 0)
	and (FElements.Last.Kind <> TElementKind.Paragraph))
	and TryConsumption(line) then
		exit(True);

	if ExecRegExpr(HEADING_REGEX, line) then
	begin
		Debug('started a heading element');
		NewElement(THeading.Create, line);
	end else if ExecRegExpr(FENCED_CODE_REGEX, line) then
	begin
		Debug('started a fenced code element');
		NewElement(TFencedCode.Create, line);
	end else if ExecRegExpr(BLOCK_QUOTE_REGEX, line) then
	begin
		Debug('started a block quote element');
		NewElement(TBlockQuote.Create, line);
	end else if ExecRegExpr(LIST_ELEMENT_REGEX, line) then
	begin
		Debug('started a list element');
		NewElement(TList.Create, line);
	end else if ExecRegExpr(TABLE_START_REGEX, line) then
	begin
		Debug('started a table element');
		NewElement(TTable.Create, line);
	end else if Length(Trim(line)) > 0 then
	begin
		if (FElements.Count > 0)
		and (FElements.Last.Kind <> TElementKind.Paragraph) then
		begin
			Debug('started a paragraph element');
			NewElement(TParagraph.Create, line);
		end else
		begin
			FOpenElement := True;
			TryConsumption(line);
		end;
	end else
		Debug(Format('discarding line "%s"', [line]));

	exit(True);
end;

procedure TParser.Finish;
begin
end;

end.
