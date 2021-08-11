program PUnsplit;

{$APPTYPE CONSOLE}

uses
  Classes, SysUtils, StrUtils;

var
  buffer: TStringList;
  currentline, copylabel: string;
  i: integer;

label endnow, nextline, loopline;

{ Get part of a string using a delimiter. }
function Explode(s, d: string; n: integer): string;
var n2: integer;
begin
  if (AnsiPos(d,s) = 0) and ((n = 0) or (n = -1)) then result := s // Output full string if delimiter not found.
  else
    begin
    if n > -1 then // Check for negative substring.
      begin
      s := s+d;
      n2 := n;
      end
    else
      begin
      d := AnsiReverseString(d);
      s := AnsiReverseString(s)+d; // Reverse string for negative.
      n2 := (n*-1)-1;
      end;
    while n2 > 0 do
      begin
      Delete(s,1,AnsiPos(d,s)+Length(d)-1); // Trim earlier substrings and delimiters.
      dec(n2);
      end;
    Delete(s,AnsiPos(d,s),Length(s)-AnsiPos(d,s)+1); // Trim later substrings and delimiters.
    if n < 0 then s := AnsiReverseString(s); // Un-reverse string if negative.
    result := s;
    end;
end;

{ Tidies a line. }
function CleanLine(s: string): string;
begin
  s := Explode(s,';',0); // Strip comments.
  s := ReplaceStr(s,':',' '); // Replace colons with spaces.
  s := ReplaceStr(s,#9,' '); // Replace tabs with spaces.
  s := ReplaceStr(s,#39,'"'); // Replace single quotes with double quotes.
  while AnsiPos('  ',s) <> 0 do s := ReplaceStr(s,'  ',' '); // Replace double spaces with single.
  Result := s;
end;

{ Inserts the contents of a file to the main file buffer. }
procedure InsertFile(filestr: string; linenum: integer);
var exfile: textfile;
  j: integer;
  s: string;
begin
  j := 0;
  AssignFile(exfile,ExtractFilePath(ParamStr(1))+filestr); // Open external file (read only).
  Reset(exfile);
  while not eof(exfile) do
    begin
    ReadLn(exfile,s); // Read from external file.
    buffer.Insert(linenum+j,s); // Write to buffer.
    inc(j); // Next line (in buffer).
    end;
  CloseFile(exfile); // Close external file.
end;

begin
  { Program start }

  if ParamStr(1) = '' then goto endnow; // End program if run without parameters.

  buffer := TStringList.Create;
  buffer.LoadFromFile(ParamStr(1)); // Copy main asm file to memory.

  i := 0;

  loopline:
  if AnsiPos('include',buffer[i]) = 0 then goto nextline; // Check if line contains "include".
  currentline := CleanLine(buffer[i]); // Get line without tabs, comments etc.
  if AnsiPos(' include "',currentline) = 0 then goto nextline; // Final check for positive "include".
  copylabel := Trim(Explode(currentline,' include "',0)); // Get label (if there is one).
  if copylabel <> '' then copylabel := copylabel+':'; // Add colon to label.
  buffer[i] := copylabel; // Replace line with label only.
  InsertFile(Explode(currentline,'"',1),i+1); // Insert external file at current line.

  nextline:
  inc(i); // Next line.
  if i < buffer.Count then goto loopline; // Repeat if there are more lines.
  
  if FileExists(ParamStr(1)+'_unsplit') then DeleteFile(ParamStr(1)+'_unsplit');
  buffer.SaveToFile(ParamStr(1)+'_unsplit'); // Save output file.
  buffer.Free;

  endnow:
end.