codeunit 50102 "Single Instance Codeunit"
{
    SingleInstance = true;

    trigger OnRun()
    begin

    end;

    procedure GetPONumber(): text//Code[20]
    BEGIN
        exit(PONo);
    END;

    procedure SetPONumber(Number: Text)
    BEGIN
        IF PONo = '' THEN
            PONo := Number
        ELSE
            PONo += ',' + Number;
    END;

    procedure GetSalesDocNumber(): text
    BEGIN
        exit(SalesDocNo);
    END;

    procedure SetSalesDocNumber(Number: Text)
    BEGIN
        IF SalesDocNo = '' THEN
            SalesDocNo := Number
        ELSE
            SalesDocNo += ',' + Number;
    END;

    var
        PONo: text;//Code[20];
        SalesDocNo: text;
}