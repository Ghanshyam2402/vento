codeunit 50103 "General BBQ Functions"
{
    trigger OnRun();
    begin
    end;


    procedure UpdateDimension(var TempDimSetEntry: Record 480 temporary; DimensionCode: Code[50]; DimensionValueCode: Code[50]): TableConnectionType;
    var
        DimMngt: Codeunit 408;
        OldDimSetID: Integer;
        NewDimSetID: Integer;
    begin

        OldDimSetID := 0;
        NewDimSetID := 0;

        TempDimSetEntry.RESET;
        TempDimSetEntry.SETRANGE("Dimension Code", DimensionCode);
        IF TempDimSetEntry.FINDFIRST THEN BEGIN
            TempDimSetEntry.VALIDATE("Dimension Value Code", DimensionValueCode);
            TempDimSetEntry.MODIFY;
        END ELSE BEGIN
            TempDimSetEntry.INIT;
            TempDimSetEntry.VALIDATE("Dimension Code", DimensionCode);
            TempDimSetEntry.VALIDATE("Dimension Value Code", DimensionValueCode);
            TempDimSetEntry.INSERT;
        END;

    end;





}