unit DynArrU;

{
  DynArrU.pas [Version 1.0.3c]
  (C) 2006-2018 by Yahe
}

{
//BEGIN changelog

11.07.2006: 1.0.3c
01.) added compiler-switch UseNilIfPossible

10.07.2006: 1.0.2c
01.) added High()- and Low()-Support
02.) new copyright-text

09.07.2006: 1.0.1c
01.) project DyArrU started
02.) beta testing
03.) initial release

//END changelog
}

interface

{$Define UseNilIfPossible}

type
  TDynamicArrayHelperType = LongInt;
  PDynamicArrayHelperType = ^TDynamicArrayHelperType;
  TDynamicArrayIndexType  = LongInt;
  TDynamicArrayType       = LongInt;

  TDynamicArray = PDynamicArrayHelperType;

function CopyArray(const ADynamicArray : TDynamicArray; const ABeginIndex : TDynamicArrayIndexType; const AEndIndex : TDynamicArrayIndexType; const ANewLength : TDynamicArrayIndexType; const AUseNewLength : Boolean; const ANilFields : Boolean; var ADone : Boolean) : TDynamicArray;

function GetArrayLength(const ADynamicArray : TDynamicArray; var ADone : Boolean) : TDynamicArrayIndexType;
procedure SetArrayLength(var ADynamicArray : TDynamicArray; const ALength : TDynamicArrayIndexType; const ANilFields : Boolean; var ADone : Boolean);
procedure SetArrayLengthCopy(var ADynamicArray : TDynamicArray; const ALength : TDynamicArrayIndexType; const ANilFields : Boolean; var ADone : Boolean);

function GetArrayValue(const ADynamicArray : TDynamicArray; const AIndex : TDynamicArrayIndexType; var ADone : Boolean) : TDynamicArrayType;
procedure SetArrayValue(const ADynamicArray : TDynamicArray; const AIndex : TDynamicArrayIndexType; const AValue : TDynamicArrayType; var ADone : Boolean);

function GetHighArrayIndex(const ADynamicArray : TDynamicArray; var ADone : Boolean) : TDynamicArrayIndexType;
function GetLowArrayIndex(const ADynamicArray : TDynamicArray; var ADone : Boolean) : TDynamicArrayIndexType;

procedure InitializeArray(var ADynamicArray : TDynamicArray; const ALength : TDynamicArrayIndexType; const ANilFields : Boolean; var ADone : Boolean);
procedure DeInitializeArray(var ADynamicArray : TDynamicArray; var ADone : Boolean);
procedure ReorganizeArray(var ADynamicArray : TDynamicArray; var ADone : Boolean);

implementation

type
  PDynamicArray          = ^TDynamicArray;
  PDynamicArrayIndexType = ^TDynamicArrayIndexType;
  PDynamicArrayType      = ^TDynamicArrayType;

function GetArrayValuePointer(const ADynamicArray : TDynamicArray; const AIndex : TDynamicArrayIndexType; var ADone : Boolean) : PDynamicArrayType; forward;

function GetArrayValuePointer(const ADynamicArray : TDynamicArray; const AIndex : TDynamicArrayIndexType; var ADone : Boolean) : PDynamicArrayType;
var
  CurrentArray : TDynamicArray;
  NoArray      : Boolean;
  TotalIndex   : TDynamicArrayIndexType;
  TotalValue   : TDynamicArrayHelperType;
begin
  Result := nil;
  ADone  := false;

  try
    if (AIndex >= 0) then
    begin
      CurrentArray := ADynamicArray;
      NoArray      := (CurrentArray = nil);
      TotalValue   := 0;
      if (not(NoArray)) then
      begin
        TotalIndex := AIndex - TotalValue;
        TotalValue := CurrentArray^;
        while ((TotalValue <= AIndex) and not(NoArray)) do
        begin
          CurrentArray := TDynamicArray(PDynamicArrayHelperType(TDynamicArrayHelperType(CurrentArray) + ((CurrentArray^ * SizeOf(TDynamicArrayType) + SizeOf(TDynamicArrayHelperType))))^);
          NoArray      := (CurrentArray = nil);

          if (not(NoArray)) then
          begin
            TotalIndex := AIndex - TotalValue;
            TotalValue := TotalValue + CurrentArray^;
          end;
        end;

        if (not(NoArray)) then
        begin
          Result := PDynamicArrayType(TDynamicArrayHelperType(CurrentArray) + ((TotalIndex * SizeOf(TDynamicArrayType) + SizeOf(TDynamicArrayHelperType))));
          ADone  := true;
        end;
      end;
    end;
  except
    Result := nil;
    ADone  := false;
  end;
end;

function CopyArray(const ADynamicArray : TDynamicArray; const ABeginIndex : TDynamicArrayIndexType; const AEndIndex : TDynamicArrayIndexType; const ANewLength : TDynamicArrayIndexType; const AUseNewLength : Boolean; const ANilFields : Boolean; var ADone : Boolean) : TDynamicArray;
var
  Counter       : TDynamicArrayIndexType;
  CurrentLength : TDynamicArrayIndexType;
  CurrentValue  : TDynamicArrayType;
  Done          : Boolean;
  Index         : TDynamicArrayIndexType;
  ResultLength  : TDynamicArrayIndexType;
begin
  Result := nil;
  ADone  := false;

  try
    CurrentLength := GetArrayLength(ADynamicArray, ADone);
    if (ADone) then
    begin
      ADone := ((ABeginIndex >= 0) and (AEndIndex < CurrentLength));
      if (ADone) then
      begin
        if (AUseNewLength) then
          ResultLength := ANewLength
        else
        begin
          ResultLength := 0;
          if (AEndIndex >= ABeginIndex) then
            ResultLength := Succ(AEndIndex - ABeginIndex)
        end;

{$IfDef UseNilIfPossible}
        if (ResultLength = 0) then
        begin
          Result := nil;
          ADone  := true;
        end
        else
        begin
{$EndIf UseNilIfPossible}
          InitializeArray(Result, ResultLength, ANilFields, ADone);
          if (ADone) then
          begin
            Counter := 0;
            Index   := ABeginIndex;
            while ((Counter < ResultLength) and (Index <= AEndIndex)) do
            begin
              Done := false;

              CurrentValue := GetArrayValue(ADynamicArray, Index, Done);
              if (Done) then
                SetArrayValue(Result, Counter, CurrentValue, Done);

              Inc(Counter);
              Inc(Index);

              ADone := (ADone and Done);
            end;
          end
          else
          begin
            DeInitializeArray(Result, ADone);

            Result := nil;
            ADone  := false;
          end;
{$IfDef UseNilIfPossible}
        end;
{$EndIf UseNilIfPossible}
      end;
    end;
  except
    DeInitializeArray(Result, ADone);

    Result := nil;
    ADone  := false;
  end;
end;

function GetArrayLength(const ADynamicArray : TDynamicArray; var ADone : Boolean) : TDynamicArrayIndexType;
var
  CurrentArray : TDynamicArray;
  NoArray      : Boolean;
  TotalValue   : TDynamicArrayHelperType;
begin
  Result := 0;
  ADone  := false;

  try
    CurrentArray := ADynamicArray;
    NoArray      := (CurrentArray = nil);
    if (not(NoArray)) then
    begin
      TotalValue := CurrentArray^;
      while (not(NoArray)) do
      begin
        CurrentArray := TDynamicArray(PDynamicArrayHelperType(TDynamicArrayHelperType(CurrentArray) + ((CurrentArray^ * SizeOf(TDynamicArrayType) + SizeOf(TDynamicArrayHelperType))))^);
        NoArray      := (CurrentArray = nil);

        if (not(NoArray)) then
          TotalValue := TotalValue + CurrentArray^;
      end;

      if (NoArray) then
      begin
        Result := TotalValue;
        ADone  := true;
      end;
{$IfDef UseNilIfPossible}
    end
    else
    begin
      Result := 0;
      ADone  := true;
{$EndIf UseNilIfPossible}
    end;
  except
    Result := 0;
    ADone  := false;
  end;
end;

procedure SetArrayLength(var ADynamicArray : TDynamicArray; const ALength : TDynamicArrayIndexType; const ANilFields : Boolean; var ADone : Boolean);
var
  CurrentArray  : TDynamicArray;
  CurrentLength : TDynamicArrayIndexType;
  CurrentNext   : PDynamicArrayHelperType;
  Index         : TDynamicArrayIndexType;
  LastArray     : TDynamicArray;
  LastNext      : PDynamicArrayHelperType;
  LastValue     : TDynamicArrayHelperType;
  NextValue     : TDynamicArrayType;
  NewArray      : TDynamicArray;
  NoArray       : Boolean;
  TotalValue    : TDynamicArrayHelperType;
begin
  ADone := false;

  try
    if (ALength >= 0) then
    begin
      CurrentLength := GetArrayLength(ADynamicArray, ADone);
      if (ADone) then
      begin
        ADone := (CurrentLength = ALength);
        if (not(ADone)) then
        begin
          if ((CurrentLength = 0) or (ALength = 0) or (ADynamicArray^ >= ALength)) then
          begin
{$IfDef UseNilIfPossible}
            if (ADynamicArray = nil) then
              InitializeArray(ADynamicArray, ALength, true, ADone)
            else
            begin
{$EndIf UseNilIfPossible}
              if (ADynamicArray^ = ALength) then
              begin
                CurrentArray := ADynamicArray;
                CurrentNext  := PDynamicArrayHelperType(TDynamicArrayHelperType(CurrentArray) + ((CurrentArray^ * SizeOf(TDynamicArrayType) + SizeOf(TDynamicArrayHelperType))));
                DeInitializeArray(TDynamicArray(CurrentNext), ADone);
                if (ADone) then
                  CurrentNext^ := 0;
              end
              else
              begin
{$IfDef UseNilIfPossible}
                if (ALength = 0) then
                  DeInitializeArray(ADynamicArray, ADone)
                else
                begin
{$EndIf UseNilIfPossible}
                  NewArray := nil;
                  InitializeArray(NewArray, ALength, ANilFields, ADone);
                  if (ADone) then
                  begin
                    if ((ADynamicArray^ >= ALength) and (ALength <> 0)) then
                    begin
                      for Index := 0 to Pred(ALength) do
                      begin
                        NextValue := GetArrayValue(ADynamicArray, Index, ADone);
                        if (ADone) then
                          SetArrayValue(NewArray, Index, NextValue, ADone);

                        if (not(ADone)) then
                          Break;
                      end;
                    end;

                    if (ADone) then
                    begin
                      DeInitializeArray(ADynamicArray, ADone);
                      if (ADone) then
                        ADynamicArray := NewArray
                      else
                      begin
                        DeInitializeArray(NewArray, ADone);

                        ADone := false;
                      end;
                    end;
                  end;
{$IfDef UseNilIfPossible}
                end;
{$EndIf UseNilIfPossible}
              end;
{$IfDef UseNilIfPossible}
            end;
{$EndIf UseNilIfPossible}
          end
          else
          begin
            if (CurrentLength < ALength) then
            begin
              CurrentArray := ADynamicArray;
              LastArray    := nil;
              NoArray      := (CurrentArray = nil);
              if (not(NoArray)) then
              begin
                while (not(NoArray)) do
                begin
                  LastArray    := CurrentArray;
                  CurrentArray := TDynamicArray(PDynamicArrayHelperType(TDynamicArrayHelperType(CurrentArray) + ((CurrentArray^ * SizeOf(TDynamicArrayType) + SizeOf(TDynamicArrayHelperType))))^);
                  NoArray      := (CurrentArray = nil);
                end;

                NewArray := nil;
                InitializeArray(NewArray, ALength - CurrentLength, ANilFields, ADone);
                if (ADone) then
                begin
                  LastNext  := PDynamicArrayHelperType(TDynamicArrayHelperType(LastArray) + ((LastArray^ * SizeOf(TDynamicArrayType) + SizeOf(TDynamicArrayHelperType))));
                  LastNext^ := TDynamicArrayHelperType(NewArray);
                end;
              end
              else
                ADone := false; 
            end
            else
            begin
              CurrentArray := ADynamicArray;
              LastArray    := nil;
              LastValue    := 0;
              NoArray      := (CurrentArray = nil);

              ADone := (not(NoArray));
              if (ADone) then
              begin
                TotalValue := CurrentArray^;
                while ((TotalValue < ALength) and not(NoArray)) do
                begin
                  LastArray    := CurrentArray;
                  CurrentArray := TDynamicArray(PDynamicArrayHelperType(TDynamicArrayHelperType(CurrentArray) + ((CurrentArray^ * SizeOf(TDynamicArrayType) + SizeOf(TDynamicArrayHelperType))))^);
                  NoArray      := (CurrentArray = nil);

                  if (not(NoArray)) then
                  begin
                    LastValue  := TotalValue;
                    TotalValue := TotalValue + CurrentArray^;
                  end;
                end;

                ADone := ((TotalValue >= ALength) and not(NoArray));
                if (ADone) then
                begin
                  if (TotalValue <> ALength) then
                  begin
                    NewArray := nil;
                    InitializeArray(NewArray, (ALength - LastValue), ANilFields, ADone);
                    if (ADone) then
                    begin
                      for Index := 0 to Pred(ALength - LastValue) do
                      begin
                        NextValue := GetArrayValue(CurrentArray, Index, ADone);
                        if (ADone) then
                          SetArrayValue(NewArray, Index, NextValue, ADone);

                        if (not(ADone)) then
                          Break;
                      end;

                      if (ADone) then
                      begin
                        LastNext := PDynamicArrayHelperType(TDynamicArrayHelperType(LastArray) + ((LastArray^ * SizeOf(TDynamicArrayType) + SizeOf(TDynamicArrayHelperType))));
                        DeInitializeArray(TDynamicArray(LastNext), ADone);
                        if (ADone) then
                          LastNext^ := TDynamicArrayHelperType(NewArray)
                        else
                        begin
                          DeInitializeArray(NewArray, ADone);

                          ADone := false;
                        end;
                      end;
                    end;
                  end;

                  if (ADone) then
                  begin
                    CurrentNext := PDynamicArrayHelperType(TDynamicArrayHelperType(CurrentArray) + ((CurrentArray^ * SizeOf(TDynamicArrayType) + SizeOf(TDynamicArrayHelperType))));
                    DeInitializeArray(TDynamicArray(CurrentNext), ADone);
                    if (ADone) then
                      CurrentNext^ := 0;
                  end;
                end;
              end;
            end;
          end;
        end;
      end;
    end;
  except
    ADone := false;
  end;
end;

procedure SetArrayLengthCopy(var ADynamicArray : TDynamicArray; const ALength : TDynamicArrayIndexType; const ANilFields : Boolean; var ADone : Boolean);
var
  ArrayCopy     : TDynamicArray;
  CurrentLength : TDynamicArrayIndexType;
begin
  ADone := false;

  try
    CurrentLength := GetArrayLength(ADynamicArray, ADone);
    if (ADone) then
    begin
      ADone := (CurrentLength = ALength);

      if (not(ADone)) then
      begin
        ArrayCopy := CopyArray(ADynamicArray, 0, Pred(CurrentLength), ALength, true, ANilFields, ADone);
        if (ADone) then
        begin
          DeInitializeArray(ADynamicArray, ADone);
          if (ADone) then
            ADynamicArray := ArrayCopy
          else
          begin
            DeInitializeArray(ArrayCopy, ADone);

            ADone := false;
          end;
        end;
      end;
    end;
  except
    ADone := false;
  end;
end;

function GetArrayValue(const ADynamicArray : TDynamicArray; const AIndex : TDynamicArrayIndexType; var ADone : Boolean) : TDynamicArrayType;
var
  ValuePointer : PDynamicArrayType;
begin
  Result := 0;
  ADone  := false;

  try
    ValuePointer := GetArrayValuePointer(ADynamicArray, AIndex, ADone);
    if (ADone) then
      Result := ValuePointer^;
  except
    Result := 0;
    ADone  := false;
  end;
end;

procedure SetArrayValue(const ADynamicArray : TDynamicArray; const AIndex : TDynamicArrayIndexType; const AValue : TDynamicArrayType; var ADone : Boolean);
var
  ValuePointer : PDynamicArrayType;
begin
  ADone := false;

  try
    ValuePointer := GetArrayValuePointer(ADynamicArray, AIndex, ADone);
    if (ADone) then
      ValuePointer^ := AValue;
  except
    ADone := false;
  end;
end;

function GetHighArrayIndex(const ADynamicArray : TDynamicArray; var ADone : Boolean) : TDynamicArrayIndexType;
var
  CurrentLength : TDynamicArrayIndexType;
begin
  Result := - 1;
  ADone  := false;

  try
    CurrentLength := GetArrayLength(ADynamicArray, ADone);
    if (ADone) then
    begin
      if (CurrentLength > 0) then
        Result := Pred(CurrentLength);
    end;
  except
    Result := - 1;
    ADone  := false;
  end;
end;

function GetLowArrayIndex(const ADynamicArray : TDynamicArray; var ADone : Boolean) : TDynamicArrayIndexType;
var
  CurrentLength : TDynamicArrayIndexType;
begin
  Result := - 1;
  ADone  := false;

  try
    CurrentLength := GetArrayLength(ADynamicArray, ADone);
    if (ADone) then
    begin
      if (CurrentLength > 0) then
        Result := 0;
    end;
  except
    Result := - 1;
    ADone  := false;
  end;
end;

procedure InitializeArray(var ADynamicArray : TDynamicArray; const ALength : TDynamicArrayIndexType; const ANilFields : Boolean; var ADone : Boolean);
var
  Index     : TDynamicArrayIndexType;
  NextArray : PDynamicArrayHelperType;
begin
  ADone := false;

  try
    if ((ADynamicArray = nil) and (ALength >= 0)) then
    begin
      try
        GetMem(ADynamicArray, ((ALength * SizeOf(TDynamicArrayType)) + (2 * SizeOf(TDynamicArrayHelperType))));
        ADynamicArray^ := ALength;

        if (ANilFields) then
        begin
          for Index := 0 to Pred(ALength) do
            SetArrayValue(ADynamicArray, Index, 0, ADone);
        end;

        NextArray  := PDynamicArrayHelperType(TDynamicArrayType(ADynamicArray) + ((ADynamicArray^ * SizeOf(TDynamicArrayType)) + SizeOf(TDynamicArrayHelperType)));
        NextArray^ := 0;

        ADone := true;
      except
        FreeMem(ADynamicArray, ((ALength * SizeOf(TDynamicArrayType)) + (2 * SizeOf(TDynamicArrayHelperType))));
        ADynamicArray := nil;
      end;
    end;
  except
    ADone := false;
  end;
end;

procedure DeInitializeArray(var ADynamicArray : TDynamicArray; var ADone : Boolean);
var
  CurrentArray : TDynamicArray;
  NextArrayA   : TDynamicArray;
  NextArrayB   : TDynamicArray;
  NextArrayC   : PDynamicArrayHelperType;
begin
  ADone := false;

  try
    if (ADynamicArray <> nil) then
    begin
      try
        CurrentArray := ADynamicArray;
        NextArrayA   := TDynamicArray(PDynamicArrayHelperType(TDynamicArrayHelperType(CurrentArray) + ((CurrentArray^ * SizeOf(TDynamicArrayType) + SizeOf(TDynamicArrayHelperType))))^);
        if (NextArrayA <> nil) then
        begin
          NextArrayB := TDynamicArray(PDynamicArrayHelperType(TDynamicArrayHelperType(NextArrayA) + ((NextArrayA^ * SizeOf(TDynamicArrayType) + SizeOf(TDynamicArrayHelperType))))^);
          while (NextArrayB <> nil) do
          begin
            while (NextArrayB <> nil) do
            begin
              CurrentArray := NextArrayA;
              NextArrayA   := NextArrayB;
              NextArrayB   := TDynamicArray(PDynamicArrayHelperType(TDynamicArrayHelperType(NextArrayB) + ((NextArrayB^ * SizeOf(TDynamicArrayType) + SizeOf(TDynamicArrayHelperType))))^);
            end;

            if (NextArrayB = nil) then
            begin
              FreeMem(NextArrayA, ((NextArrayA^ * SizeOf(TDynamicArrayType) + (2 * SizeOf(TDynamicArrayHelperType)))));
              NextArrayC  := PDynamicArrayHelperType(TDynamicArrayType(CurrentArray) + ((CurrentArray^ * SizeOf(TDynamicArrayType)) + SizeOf(TDynamicArrayHelperType)));
              NextArrayC^ := 0;
            end;

            CurrentArray := ADynamicArray;
            NextArrayA   := TDynamicArray(PDynamicArrayHelperType(TDynamicArrayHelperType(CurrentArray) + ((CurrentArray^ * SizeOf(TDynamicArrayType) + SizeOf(TDynamicArrayHelperType))))^);
            NextArrayB   := TDynamicArray(PDynamicArrayHelperType(TDynamicArrayHelperType(NextArrayA) + ((NextArrayA^ * SizeOf(TDynamicArrayType) + SizeOf(TDynamicArrayHelperType))))^);
          end;

          if (NextArrayB = nil) then
          begin
            FreeMem(NextArrayA, ((NextArrayA^ * SizeOf(TDynamicArrayType) + (2 * SizeOf(TDynamicArrayHelperType)))));
            NextArrayC  := PDynamicArrayHelperType(TDynamicArrayType(CurrentArray) + ((CurrentArray^ * SizeOf(TDynamicArrayType)) + SizeOf(TDynamicArrayHelperType)));
            NextArrayC^ := 0;
          end;
        end;

        FreeMem(ADynamicArray, ((ADynamicArray^ * SizeOf(TDynamicArrayType) + (2 * SizeOf(TDynamicArrayHelperType)))));
        ADynamicArray := nil;

        ADone := true;
      except
      end;
{$IfDef UseNilIfPossible}
    end
    else
    begin
      ADone := true;
{$EndIf UseNilIfPossible}
    end;
  except
    ADone := false;
  end;
end;

procedure ReorganizeArray(var ADynamicArray : TDynamicArray; var ADone : Boolean);
var
  ArrayCopy     : TDynamicArray;
  CurrentLength : TDynamicArrayIndexType;
begin
  ADone := false;

  try
    CurrentLength := GetArrayLength(ADynamicArray, ADone);
    if (ADone) then
    begin
      ArrayCopy := CopyArray(ADynamicArray, 0, Pred(CurrentLength), 0, false, false, ADone);
      if (ADone) then
      begin
        DeInitializeArray(ADynamicArray, ADone);
        if (ADone) then
          ADynamicArray := ArrayCopy
        else
        begin
          DeInitializeArray(ArrayCopy, ADone);

          ADone := false;
        end;
      end;
    end;
  except
    ADone := false;
  end;
end;

end.
