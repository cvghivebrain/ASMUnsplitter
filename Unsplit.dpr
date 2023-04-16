program PUnsplit;

{$APPTYPE CONSOLE}

uses
  Classes, SysUtils, StrUtils;

var
  buffer, incbuffer: TStringList;
  currentline, copylabel, incname: string;
  i: integer;
  logfile: textfile;

label endnow, nextline, loopline;

{ Get part of a string using a delimiter. }
function Explode(str, delimiter: string; n: integer): string; // Get substring from string using delimiter.
begin
  if (AnsiPos(delimiter,str) = 0) and ((n = 0) or (n = -1)) then result := str // Output full string if delimiter not found.
  else
    begin
    str := str+delimiter;
    while n > 0 do
      begin
      Delete(str,1,AnsiPos(delimiter,str)+Length(delimiter)-1); // Trim earlier substrings and delimiters.
      dec(n);
      end;
    Delete(str,AnsiPos(delimiter,str),Length(str)-AnsiPos(delimiter,str)+1); // Trim later substrings and delimiters.
    result := str;
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

begin
  { Program start }

  if ParamStr(1) = '' then goto endnow; // End program if run without parameters.

  buffer := TStringList.Create;
  buffer.LoadFromFile(ParamStr(1)); // Copy main asm file to memory.
  AssignFile(logfile,'Unsplit.log'); // Create logfile.
  ReWrite(logfile);
  WriteLn(logfile,IntToStr(buffer.Count)+' lines in original file.');

  i := 0;

  loopline:
  if AnsiPos('include',buffer[i]) = 0 then goto nextline; // Check if line contains "include".
  currentline := CleanLine(buffer[i]); // Get line without tabs, comments etc.
  if AnsiPos(' include "',currentline) = 0 then goto nextline; // Final check for positive "include".

  incbuffer := TStringList.Create;
  incname := Explode(currentline,'"',1);
  try
    incbuffer.LoadFromFile(incname); // Get contents of included file.
    WriteLn(logfile,incname+' opened.');
    WriteLn(logfile,IntToStr(incbuffer.Count)+' lines in included file.');
  except
    WriteLn(logfile,incname+' failed to load.');
  end;
  copylabel := Trim(Explode(currentline,' include "',0)); // Get label (if there is one).
  if copylabel <> '' then
    begin
    copylabel := copylabel+':'; // Add colon to label.
    buffer.Insert(i,copylabel); // Add line with label only.
    buffer[i+1] := incbuffer.Text; // Replace original line with included file.
    end
  else buffer[i] := incbuffer.Text;
  buffer.SetText(PChar(buffer.Text)); // Reset buffer to accomodate new lines.
  incbuffer.Free;
  WriteLn(logfile,IntToStr(buffer.Count)+' lines in updated file.');

  nextline:
  inc(i); // Next line.
  if i < buffer.Count then goto loopline; // Repeat if there are more lines.
  
  if FileExists(ParamStr(1)+'.unsplit') then DeleteFile(ParamStr(1)+'.unsplit');
  buffer.SaveToFile(ParamStr(1)+'.unsplit'); // Save output file.
  buffer.Free;
  WriteLn(logfile,IntToStr(i)+' lines written.');
  CloseFile(logfile);

  endnow:
end.