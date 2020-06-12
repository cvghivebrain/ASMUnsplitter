program PUnsplit;

{$APPTYPE CONSOLE}

uses
  SysUtils, StrUtils;

var
  infile, outfile, exfile: textfile;
  actualline, cleanline, copylabel, exline: string;

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

begin
  { Program start }
  if ParamCount = 1 then
    begin
    AssignFile(infile, ParamStr(1)); // open input file (read only)
    Reset(infile);                    
    AssignFile(outfile, ParamStr(1)+'_unsplit'); // open output file (read/write)
    ReWrite(outfile);
    while not eof(infile) do
      begin
      ReadLn(infile,actualline); // read line from file
      if AnsiPos('include',actualline) <> 0 then // check if line contains "include"
        begin
        cleanline := Explode(actualline,';',0); // strip comments
        cleanline := StringReplace(cleanline,#9,' ',[rfReplaceAll]); // replace tabs with spaces
        if AnsiPos(':',cleanline) <> 0 then // check for label
          begin
          copylabel := Explode(cleanline,':',0); // save label
          cleanline := Explode(cleanline,':',1); // remove label
          end
        else copylabel := '';
        cleanline := Trim(cleanline); // remove excess spaces
        if AnsiPos('include',cleanline) = 1 then
          begin
          { Include external file }
          if copylabel <> '' then WriteLn(outfile,copylabel+':'); // write label
          Delete(cleanline,1,7); // remove "include"
          cleanline := Trim(cleanline); // remove excess spaces again   
          cleanline := StringReplace(cleanline,'"','',[rfReplaceAll]); // remove quotes
          cleanline := ExtractFilePath(ParamStr(1))+cleanline; // add full file path
          if FileExists(cleanline) = true then // check if file exists
            begin
            AssignFile(exfile, cleanline); // open external file (read only)
            Reset(exfile);
            while not eof(exfile) do
              begin
              ReadLn(exfile,exline); // read from external file
              WriteLn(outfile,exline); // write to output file
              end;
            CloseFile(exfile); // close external file
            end;

          end
        else WriteLn(outfile,actualline); // "include" was false positive, copy line as-is instead
        end
      else WriteLn(outfile,actualline); // no "include" found, copy line as-is
      end;
    CloseFile(infile);
    CloseFile(outfile);
    end
  else
    begin
    WriteLn('ASM Unsplitter by Hivebrain');
    ReadLn;
    end;

end.