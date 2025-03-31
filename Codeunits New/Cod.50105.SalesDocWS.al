codeunit 50105 "Sales Doc WS"
{
    trigger OnRun()
    begin
    end;

    // Create Sales Quotation
    procedure CreateSalesQuotation(RecImportDoc: XmlPort "Sales Quotation Creation"): text
    var
        SingleInstanceCodeunit: Codeunit "Single Instance Codeunit";
    begin
        IF RecImportDoc.Import() THEN BEGIN
            exit(SingleInstanceCodeunit.GetSalesDocNumber());
        END
        ELSE
            Error(GetLastErrorText);
    end;

    // Create Sales Order
    procedure CreateSalesOrder(RecImportDoc: XmlPort "Sales Order Creation"): text
    var
        SingleInstanceCodeunit: Codeunit "Single Instance Codeunit";
    begin
        IF RecImportDoc.Import() THEN BEGIN
            exit(SingleInstanceCodeunit.GetSalesDocNumber());
        END
        ELSE
            Error(GetLastErrorText);
    end;

    // Create Sales Order from Quotation
    procedure CreateOrderFromQuotation(QuotationNo: Code[20]): text
    var
        SalesHeader: Record "Sales Header";
        SalesQuoteToOrder: Codeunit "Sales-Quote to Order";
        SalesOrderHeader: Record "Sales Header";
        SingleInstanceCodeunit: Codeunit "Single Instance Codeunit";
    begin
        SalesHeader.Reset();
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Quote);
        SalesHeader.SetRange("No.", QuotationNo);

        if not SalesHeader.FindFirst() then
            Error('Sales Quotation %1 not found.', QuotationNo);

        Clear(SalesQuoteToOrder);
        if SalesQuoteToOrder.Run(SalesHeader) then begin
            // Find the created order
            SalesOrderHeader.Reset();
            SalesOrderHeader.SetRange("Document Type", SalesOrderHeader."Document Type"::Order);
            SalesOrderHeader.SetRange("Quote No.", QuotationNo);

            if SalesOrderHeader.FindFirst() then begin
                SingleInstanceCodeunit.SetSalesDocNumber(SalesOrderHeader."No.");
                exit(SalesOrderHeader."No.");
            end;
        end;

        Error(GetLastErrorText);
    end;

    // Ship Sales Order
    procedure ShipSalesOrder(RecImportDoc: XmlPort "Sales Shipment Creation"): text
    var
        SingleInstanceCodeunit: Codeunit "Single Instance Codeunit";
    begin
        IF RecImportDoc.Import() THEN BEGIN
            exit(SingleInstanceCodeunit.GetSalesDocNumber());
        END
        ELSE
            Error(GetLastErrorText);
    end;

    // Post Sales Invoice
    procedure PostSalesInvoice(RecImportDoc: XmlPort "Sales Invoice Posting"): text
    var
        SingleInstanceCodeunit: Codeunit "Single Instance Codeunit";
    begin
        IF RecImportDoc.Import() THEN BEGIN
            exit(SingleInstanceCodeunit.GetSalesDocNumber());
        END
        ELSE
            Error(GetLastErrorText);
    end;

    // Post Sales Document
    procedure PostSalesDoc(DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]; Ship: Boolean; Invoice: Boolean): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesPost: Codeunit "Sales-Post";
        PostingNo: Code[20];
        SalesSetup: Record "Sales & Receivables Setup";
        NoSeriesMgt: Codeunit "No. Series";
    begin
        SalesHeader.GET(DocumentType, DocumentNo);

        IF SalesHeader."Posting No." = '' THEN BEGIN
            SalesSetup.GET;
            SalesHeader.VALIDATE("Posting No.", NoSeriesMgt.GetNextNo(SalesSetup."Posted Invoice Nos.", SalesHeader."Posting Date", TRUE));
            SalesHeader.MODIFY;
            Commit();
        END;

        SalesHeader.Validate(Ship, Ship);
        SalesHeader.Validate(Invoice, Invoice);
        SalesHeader.MODIFY(false);

        PostingNo := SalesHeader."Posting No.";

        SalesPost.RUN(SalesHeader);

        exit(PostingNo);
    end;

    var
        SingleInstanceCodeunit: Codeunit "Single Instance Codeunit";
}