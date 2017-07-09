unit SimpleDSLCompiler.AST;

interface

type
  ISimpleDSLAST = interface ['{114E494C-8319-45F1-91C8-4102AED1809E}']
  end; { ISimpleDSLAST }

  TSimpleDSLASTFactory = reference to function: ISimpleDSLAST;

function CreateSimpleDSLAST: ISimpleDSLAST;

implementation

type
  TSimpleDSLAST = class(TInterfacedObject, ISimpleDSLAST)
  end; { TSimpleDSLAST }

{ exports }

function CreateSimpleDSLAST: ISimpleDSLAST;
begin
  Result := TSimpleDSLAST.Create;
end; { CreateSimpleDSLAST }

end.
