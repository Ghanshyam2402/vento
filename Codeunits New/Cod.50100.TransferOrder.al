codeunit 50100 "Transfer Order API"
{
    trigger OnRun()
    begin

    end;

    Procedure XMLTransferOrder(RecTransferOrder: XmlPort "Transfer Order WS XML"): text
    VAR
        SingleInstanceCodeunit: Codeunit "Single Instance Codeunit";
    BEGIN
        IF RecTransferOrder.Import() THEN
            exit(SingleInstanceCodeunit.GetPONumber())
        ELSE
            error(GetLastErrorText);

    END;

}