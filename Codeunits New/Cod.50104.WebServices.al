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
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
        SingleInstanceCodeunit: Codeunit "Single Instance Codeunit";
        ItemJnlLine: Record "Item Journal Line";
    begin
        IF RecBinChange.Import() THEN BEGIN
            ItemJnlLine.Reset();
            ItemJnlLine.SetRange("Journal Template Name", 'ITEMRECLASS');
            ItemJnlLine.SetRange("Journal Batch Name", 'ITEMRECLASS');
            ItemJnlLine.SetRange("Document No.", SingleInstanceCodeunit.GetPONumber());

            if ItemJnlLine.FindSet() then
                ItemJnlPostBatch.Run(ItemJnlLine);

            exit(SingleInstanceCodeunit.GetPONumber());
        END
        ELSE
            Error(GetLastErrorText);
    end;
}