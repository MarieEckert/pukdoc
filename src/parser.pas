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

constructor TParser.Create;
begin
	FSections := TSections.Create;
	FElements := TElements.Create;
	FOpenElement := False;
end;

function TParser.TryConsumption(const line: String): Boolean;
begin
	if FOpenElement then
	begin
		if FElements.Last.ConsumeLine(line) then
		begin
			Debug('open element consumed one line');
			exit(True);
		end;

		Debug('open element didn''t consume line, closing it');
		FOpenElement := False;
	end;

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
	if TryConsumption(line) then
		exit(True);

	if ExecRegExpr('[ ]{0,3}[#]{1,6}.*', line) then
	begin
		Debug('started a heading element');
		NewElement(THeading.Create, line);
	end else if ExecRegExpr('[ ]{0,3}(```|~~~).*', line) then
	begin
		Debug('started a fenced code element');
		NewElement(TFencedCode.Create, line);
	end else if ExecRegExpr('[ ]{0,3}>.*', line) then
	begin
		Debug('started a block quote element');
		NewElement(TBlockQuote.Create, line);
	end else if ExecRegExpr('[ ]*([-+*]|[0-9]+[\.\)])[ ]+.*', line) then
	begin
		Debug('started a list element');
		NewElement(TList.Create, line);
	end;

	exit(True);
end;

procedure TParser.Finish;
begin
end;

end.
