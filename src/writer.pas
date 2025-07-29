{$mode objfpc}
unit writer;

{$H+}
{$codepage utf8}
{$scopedenums on}

interface

uses
	elements,
	parser;

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
var
	i		: Integer;
	s		: String;
	element	: TElement;
begin
	result := '';

	for i := 0 to parser.Elements.Count - 1 do
	begin
		element := parser.Elements.Items[i];

		case element.Kind of
		TElementKind.Header: begin
				result += element.Translate[0] + sLineBreak;

				if (i + 1 < parser.Elements.Count)
				and (parser.Elements.Items[i + 1].Kind <> TElementKind.Header)
				then
					result += MakeHorSeperator(MAX_WIDTH) + sLineBreak
							  + sLineBreak;
			end;
		TElementKind.Table,
		TElementKind.Paragraph: begin
				for s in element.Translate do
					result += INDENT + s + sLineBreak;

				result += sLineBreak;
			end;
		TElementKind.Block: begin
				for s in element.Translate do
					result += s + sLineBreak;

				result += sLineBreak;
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
