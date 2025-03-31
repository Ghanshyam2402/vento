codeunit 50104 "Web Services"
{
    trigger OnRun()
    begin

    end;

    procedure CreateCustomer(RecImportOrder: XmlPort "Create Customer WS XML"): text
    var
        SingleInstanceCodeunit: Codeunit "Single Instance Codeunit";
    begin
        IF RecImportOrder.Import() THEN BEGIN
            exit(SingleInstanceCodeunit.GetPONumber());
        END
        ELSE
            Error(GetLastErrorText);
    end;

    procedure CreateContact(RecImportOrder: XmlPort "Create Customer WS XML"): text
    var
        SingleInstanceCodeunit: Codeunit "Single Instance Codeunit";
    begin
        IF RecImportOrder.Import() THEN BEGIN
            exit(SingleInstanceCodeunit.GetPONumber());
        END
        ELSE
            Error(GetLastErrorText);
    end;

    procedure BinChange(RecBinChange: XmlPort "Bin Change WS XML"): text
    var
        SingleInstanceCodeunit: Codeunit "Single Instance Codeunit";
    begin
        IF RecBinChange.Import() THEN BEGIN

            exit(SingleInstanceCodeunit.GetPONumber());
        END
        ELSE
            Error(GetLastErrorText);
    end;
}