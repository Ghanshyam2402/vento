codeunit 50101 "Purchase Doc WS"
{
    trigger OnRun()
    var

    begin

    end;

    procedure PostPurchaseDoc(DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20]): Code[50]
    var
        PurchaseHeader: Record "Purchase Header";
        PostingNo: Code[50];
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        NoSeriesMgt: Codeunit "No. Series";
        PurchPost: Codeunit "Purch.-Post";
    begin
        PurchaseHeader.GET(DocumentType, DocumentNo);

        IF PurchaseHeader."Posting No." = '' THEN BEGIN
            PurchasesPayablesSetup.GET;
            PurchaseHeader.VALIDATE("Posting No.", NoSeriesMgt.GetNextNo(PurchasesPayablesSetup."Posted Invoice Nos.", PurchaseHeader."Posting Date", TRUE));
            PurchaseHeader.MODIFY;
            Commit();
        END;

        if DocumentType = DocumentType::Order then begin

            PurchaseHeader.Validate(Receive, true);
            PurchaseHeader.Validate(Invoice, true);
            PurchaseHeader.MODIFY(false);
        end;

        PostingNo := PurchaseHeader."Posting No.";

        PurchPost.RUN(PurchaseHeader);

        exit(PostingNo);
    end;

    procedure SupplyPurchaseOrderCreation(RecImportOrder: XmlPort "Supply Purchase Order Creation"): text
    var
        SingleInstanceCodeunit: Codeunit "Single Instance Codeunit";
    begin
        IF RecImportOrder.Import() THEN BEGIN
            exit(SingleInstanceCodeunit.GetPONumber());
        END
        ELSE
            Error(GetLastErrorText);
    end;




    procedure PurchaseInvoiceCreation(RecImportOrder: XmlPort "Purchase Invoice Creation"): text
    var
        SingleInstanceCodeunit: Codeunit "Single Instance Codeunit";
    begin
        IF RecImportOrder.Import() THEN BEGIN
            exit(SingleInstanceCodeunit.GetPONumber());
        END
        ELSE
            Error(GetLastErrorText);
    end;

    procedure XMLGRNPosting(RecGRNPosting: XmlPort "GRN Posting WS XML"): text
    BEGIN
        IF RecGRNPosting.Import() THEN
            exit(SingleInstanceCodeunit.GetPONumber())
        ELSE
            error(GetLastErrorText);
    END;

    var
        SingleInstanceCodeunit: Codeunit "Single Instance Codeunit";
}