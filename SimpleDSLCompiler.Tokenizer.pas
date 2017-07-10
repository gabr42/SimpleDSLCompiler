unit SimpleDSLCompiler.Tokenizer;

interface

uses
  System.Types,
  System.Classes;

type
  TTokenKind = (tkUnknown, tkNewLine, tkWhitespace,
                tkIdent,
                tkLeftParen, tkRightParen,
                tkLessThan, tkPlus, tkMinus, tkComma);

  ISimpleDSLTokenizer = interface ['{086E9EFE-DB1E-4D81-A16A-C9F1F0F06D2B}']
    function  CurrentLocation: TPoint;
    function  GetToken(var kind: TTokenKind; var identifier: string): boolean;
    procedure Initialize(const code: string);
    function  IsAtEnd: boolean;
  end; { ISimpleDSLTokenizer }

  TSimpleDSLTokenizerFactory = reference to function: ISimpleDSLTokenizer;

function CreateSimpleDSLTokenizer: ISimpleDSLTokenizer;

implementation

uses
  System.SysUtils,
  System.Character,
  SimpleDSLCompiler.Base;

type
  TSimpleDSLTokenizer = class(TSimpleDSLCompilerBase, ISimpleDSLTokenizer)
  strict private
    FCurrentLine: string;
    FLastLine   : integer;
    FLastLineLen: integer;
    FLookahead  : char;
    FNextChar   : integer;
    FNextLine   : integer;
    FProgram    : TStringList;
  strict protected
    procedure PushBack(ch: char);
    procedure SkipWhitespace;
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    function  CurrentLocation: TPoint; inline;
    function  GetChar(var ch: char): boolean;
    function  GetIdent: string;
    function  GetToken(var kind: TTokenKind; var identifier: string): boolean;
    procedure Initialize(const code: string);
    function  IsAtEnd: boolean;
  end; { TSimpleDSLTokenizer }

{ exports }

function CreateSimpleDSLTokenizer: ISimpleDSLTokenizer;
begin
  Result := TSimpleDSLTokenizer.Create;
end; { CreateSimpleDSLTokenizer }

procedure TSimpleDSLTokenizer.AfterConstruction;
begin
  inherited;
  FProgram := TStringList.Create;
end; { TSimpleDSLTokenizer.AfterConstruction }

procedure TSimpleDSLTokenizer.BeforeDestruction;
begin
  FreeAndNil(FProgram);
  inherited;
end; { TSimpleDSLTokenizer.BeforeDestruction }

function TSimpleDSLTokenizer.CurrentLocation: TPoint;
begin
  Result := Point(FNextLine + 1, FNextChar);
end; { TSimpleDSLTokenizer.CurrentLocation }

function TSimpleDSLTokenizer.GetChar(var ch: char): boolean;
begin
  if FLookahead <> #0 then begin
    ch := FLookahead;
    FLookahead := #0;
    Result := true;
  end
  else begin
    Result := not IsAtEnd;
    if Result then begin
      if FNextChar > Length(FCurrentLine) then begin
        ch := #13;
        Inc(FNextLine);
        if FNextLine < FProgram.Count then
          FCurrentLine := FProgram[FNextLine];
        FNextChar := 1;
      end
      else begin
        ch := FCurrentLine[FNextChar];
        Inc(FNextChar);
      end;
    end;
  end;
end; { TSimpleDSLTokenizer.GetChar }

function TSimpleDSLTokenizer.GetIdent: string;
var
  ch: char;
begin
  Result := '';
  while GetChar(ch) do begin
    if ch.IsLetter then
      Result := Result + ch
    else begin
      PushBack(ch);
      Exit;
    end;
  end;
end; { TSimpleDSLTokenizer.GetIdent }

function TSimpleDSLTokenizer.GetToken(var kind: TTokenKind; var identifier: string): boolean;
var
  ch: char;
begin
  identifier := '';
  Result := GetChar(ch);
  if not Result then begin
    LastError := 'Premature end of program';
    Exit;
  end;
  case ch of
    '(': kind := tkLeftParen;
    ')': kind := tkRightParen;
    '+': kind := tkPlus;
    '-': kind := tkMinus;
    '<': kind := tkLessThan;
    ',': kind := tkComma;
    #13: kind := tkNewLine;
    else if ch.IsLetter then begin
      kind := tkIdent;
      identifier := ch + GetIdent;
    end
    else if ch.IsWhiteSpace then begin
      kind := tkWhitespace;
      SkipWhitespace;
    end
    else kind := tkUnknown;
  end;
end; { TSimpleDSLTokenizer.GetToken }

procedure TSimpleDSLTokenizer.Initialize(const code: string);
begin
  FProgram.Text := code;
  FNextLine := 0;
  FNextChar := 1;
  FLookahead := #0;
  FLastLine := FProgram.Count - 1;
  if FLastLine >= 0 then begin
    FLastLineLen := Length(FProgram[FLastLine]);
    FCurrentLine := FProgram[FNextLine];
  end;
end; { TSimpleDSLTokenizer.Initialize }

function TSimpleDSLTokenizer.IsAtEnd: boolean;
begin
  Result :=
    (FNextLine > FLastLine) or
    ((FNextLine = FLastLine) and (FNextChar > (FLastLineLen+1)));
end; { TSimpleDSLTokenizer.IsAtEnd }

procedure TSimpleDSLTokenizer.PushBack(ch: char);
begin
  Assert(FLookahead = #0, 'TSimpleDSLTokenizer: Lookahead buffer is not empty');
  FLookahead := ch;
end; { TSimpleDSLTokenizer.PushBack }

procedure TSimpleDSLTokenizer.SkipWhitespace;
var
  ch: char;
begin
  while GetChar(ch) do
    if (ch = #13) or (not ch.IsWhiteSpace) then begin
      PushBack(ch);
      Exit;
    end;
end; { TSimpleDSLTokenizer.SkipWhitespace }

end.
