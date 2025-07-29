{$mode objfpc}
unit writer;

{$H+}
{$codepage utf8}
{$scopedenums on}

interface

uses
	Character,
	elements,
	parser,
	StrUtils,
	SysUtils,
	Types;

procedure WriteParsed(constref parser: TParser; var dest: TextFile);

implementation

const
	MAX_WIDTH	= 80;
	INDENT		= '  ';

function GenerateHeader(constref parser: TParser): String;
var
	spacing	: Integer;
	title	: String;
begin
	title := parser.Sections.First.Name;
	spacing := (MAX_WIDTH - Length(title)) div 2;
	result := sLineBreak + StringOfChar(' ', spacing) + title + sLineBreak;
end;

function GenerateTOC(constref parser: TParser): String;
var
	i: Integer;
begin
	result := 'CONTENTS' + sLineBreak + MakeHorSeperator(MAX_WIDTH);

	result += sLineBreak + sLineBreak;
	for i := 1 to parser.Sections.Count - 1 do
		result += INDENT + parser.Sections.Items[i].Name + sLineBreak;
end;

function GenerateBody(constref parser: TParser): String;

	function DoWrapping(constref str: String): String;
	var
		rem						: String;
		ix, lastWhite, width	: Integer;
		initialIndent			: Integer;
		firstNonSpaceHit		: Boolean;
		split					: TStringDynArray;
	begin
		width := 0;
		lastWhite := Length(str);

		if Length(str) <= MAX_WIDTH then
			exit(str + sLineBreak);

		initialIndent := 0;
		firstNonSpaceHit := False;

		for ix := 1 to Length(str) do
		begin
			Inc(width);
			if width > MAX_WIDTH then
			begin
				result := TrimRight(Copy(str, 1, lastWhite));

				rem := StringOfChar(' ', initialIndent)
					 + Trim(Copy(str, lastWhite + 1, Length(str) - lastWhite));
				result += sLineBreak + DoWrapping(rem);
				exit;
			end;

			if IsWhiteSpace(str[ix]) then
				if firstNonSpaceHit then
					lastWhite := ix
				else
					Inc(initialIndent)
			else
				firstNonSpaceHit := True;
		end;
	end;

var
	i			: Integer;
	s, tmp		: String;
	rem			: TStringDynArray;
	element		: TElement;
	firstHeader	: Boolean;
begin
	result := '';

	firstHeader := True;
	for i := 0 to parser.Elements.Count - 1 do
	begin
		element := parser.Elements.Items[i];

		case element.Kind of
		TElementKind.Header: begin
				if firstHeader then
				begin
					firstHeader := False;
					continue;
				end;

				result += element.Translate[0] + sLineBreak;

				if (i + 1 >= parser.Elements.Count)
				or (parser.Elements.Items[i + 1].Kind <> TElementKind.Header)
				then
					result += MakeHorSeperator(MAX_WIDTH) + sLineBreak;
			end;
		TElementKind.Paragraph: begin
				for s in element.Translate do
					result += DoWrapping(INDENT + s);
			end;
		TElementKind.Block: begin
				for s in element.Translate do
					result += s + sLineBreak;

				result += sLineBreak;
			end;
		TElementKind.Table: begin
				for s in element.Translate do
					result += INDENT + s + sLineBreak;

				result += sLineBreak;;
			end;
		end;
	end;
end;

procedure WriteParsed(constref parser: TParser; var dest: TextFile);
begin
	WriteLn(dest, GenerateHeader(parser));
	WriteLn(dest, GenerateTOC(parser));
	WriteLn(dest, GenerateBody(parser));
end;

end.
