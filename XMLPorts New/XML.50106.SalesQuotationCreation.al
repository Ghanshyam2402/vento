xmlport 50106 "Sales Quotation Creation"
{
    UseDefaultNamespace = true;
    Direction = Import;

    schema
    {
        textelement(Root)
        {
            tableelement(SalesHeader; "Sales Header")
            {
                MinOccurs = Once;
                UseTemporary = true;
                fieldattribute(DocumentType; SalesHeader."Document Type") { }
                fieldattribute(CustomerNo; SalesHeader."Sell-to Customer No.") { }
                fieldattribute(ExternalDocumentNo; SalesHeader."External Document No.") { Occurrence = Optional; }
                fieldattribute(PostingDate; SalesHeader."Posting Date") { Occurrence = Optional; }
                fieldattribute(DocumentDate; SalesHeader."Document Date") { Occurrence = Optional; }
                fieldattribute(OrderDate; SalesHeader."Order Date") { Occurrence = Optional; }
                fieldattribute(Location; SalesHeader."Location Code") { Occurrence = Optional; }
                fieldattribute(QuoteValidUntilDate; SalesHeader."Quote Valid Until Date") { Occurrence = Optional; }
                fieldattribute(RequestedDeliveryDate; SalesHeader."Requested Delivery Date") { Occurrence = Optional; }
                fieldattribute(SalespersonCode; SalesHeader."Salesperson Code") { Occurrence = Optional; }
                textelement(Comment) { MinOccurs = Zero; }

                tableelement(SalesLine; "Sales Line")
                {
                    LinkTable = SalesHeader;
                    LinkFields = "Document Type" = field("Document Type"), "Document No." = field("No.");
                    UseTemporary = true;
                    fieldelement(LineNo; SalesLine."Line No.") { }
                    fieldelement(Type; SalesLine.Type) { }
                    fieldelement(No; SalesLine."No.") { }
                    fieldelement(Description; SalesLine.Description) { MinOccurs = Zero; }
                    fieldelement(Quantity; SalesLine.Quantity) { }
                    fieldelement(UnitOfMeasure; SalesLine."Unit of Measure Code") { MinOccurs = Zero; }
                    fieldelement(UnitPrice; SalesLine."Unit Price") { MinOccurs = Zero; }
                    fieldelement(LineDiscount; SalesLine."Line Discount %") { MinOccurs = Zero; }

                    trigger OnAfterInsertRecord()
                    begin
                        SalesLineRec.Init();
                        SalesLineRec.Validate("Document Type", SalesHeaderRec."Document Type");
                        SalesLineRec.Validate("Document No.", SalesHeaderRec."No.");
                        SalesLineRec.Validate("Line No.", SalesLine."Line No.");
                        SalesLineRec.Validate(Type, SalesLine.Type);
                        SalesLineRec.Validate("No.", SalesLine."No.");

                        if SalesLine.Description <> '' then
                            SalesLineRec.Validate(Description, SalesLine.Description);

                        SalesLineRec.Validate(Quantity, SalesLine.Quantity);

                        if SalesLine."Unit of Measure Code" <> '' then
                            SalesLineRec.Validate("Unit of Measure Code", SalesLine."Unit of Measure Code");

                        if SalesLine."Unit Price" <> 0 then
                            SalesLineRec.Validate("Unit Price", SalesLine."Unit Price");

                        if SalesLine."Line Discount %" <> 0 then
                            SalesLineRec.Validate("Line Discount %", SalesLine."Line Discount %");

                        SalesLineRec.Insert(true);
                    end;
                }

                trigger OnAfterInsertRecord()
                var
                    SalesReceivablesSetup: Record "Sales & Receivables Setup";
                    NoSeriesMgt: Codeunit "No. Series";
                    DocNo: Code[20];
                begin
                    SalesReceivablesSetup.Get();
                    DocNo := NoSeriesMgt.GetNextNo(SalesReceivablesSetup."Quote Nos.", WorkDate(), true);

                    SalesHeaderRec.Init();
                    SalesHeaderRec.Validate("Document Type", SalesHeader."Document Type"::Quote);
                    SalesHeaderRec.Validate("No.", DocNo);
                    SalesHeaderRec.Insert(true);

                    SalesHeaderRec.Validate("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");

                    if SalesHeader."External Document No." <> '' then
                        SalesHeaderRec.Validate("External Document No.", SalesHeader."External Document No.");

                    if SalesHeader."Posting Date" <> 0D then
                        SalesHeaderRec.Validate("Posting Date", SalesHeader."Posting Date")
                    else
                        SalesHeaderRec.Validate("Posting Date", WorkDate());

                    if SalesHeader."Document Date" <> 0D then
                        SalesHeaderRec.Validate("Document Date", SalesHeader."Document Date")
                    else
                        SalesHeaderRec.Validate("Document Date", WorkDate());

                    if SalesHeader."Order Date" <> 0D then
                        SalesHeaderRec.Validate("Order Date", SalesHeader."Order Date");

                    if SalesHeader."Location Code" <> '' then
                        SalesHeaderRec.Validate("Location Code", SalesHeader."Location Code");

                    if SalesHeader."Quote Valid Until Date" <> 0D then
                        SalesHeaderRec.Validate("Quote Valid Until Date", SalesHeader."Quote Valid Until Date");

                    if SalesHeader."Requested Delivery Date" <> 0D then
                        SalesHeaderRec.Validate("Requested Delivery Date", SalesHeader."Requested Delivery Date");

                    if SalesHeader."Salesperson Code" <> '' then
                        SalesHeaderRec.Validate("Salesperson Code", SalesHeader."Salesperson Code");

                    SalesHeaderRec.Modify(true);

                    if Comment <> '' then
                        InsertSalesComment(SalesHeaderRec, Comment);

                    SingleInstanceCodeunit.SetSalesDocNumber(SalesHeaderRec."No.");
                end;
            }
        }
    }

    var
        SalesHeaderRec: Record "Sales Header";
        SalesLineRec: Record "Sales Line";
        SingleInstanceCodeunit: Codeunit "Single Instance Codeunit";


    local procedure InsertSalesComment(SalesHeader: Record "Sales Header"; CommentText: Text)
    var
        SalesCommentLine: Record "Sales Comment Line";
        LineNo: Integer;
    begin
        if CommentText = '' then
            exit;

        SalesCommentLine.Reset();
        SalesCommentLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesCommentLine.SetRange("No.", SalesHeader."No.");
        SalesCommentLine.SetRange("Document Line No.", 0);

        if SalesCommentLine.FindLast() then
            LineNo := SalesCommentLine."Line No." + 10000
        else
            LineNo := 10000;

        SalesCommentLine.Init();
        SalesCommentLine."Document Type" := SalesHeader."Document Type";
        SalesCommentLine."No." := SalesHeader."No.";
        SalesCommentLine."Line No." := LineNo;
        SalesCommentLine.Date := SalesHeader."Posting Date";
        SalesCommentLine.Comment := CopyStr(CommentText, 1, 80);
        SalesCommentLine."Document Line No." := 0;
        SalesCommentLine.Insert(true);

        // If comment is longer than 80 characters, add additional lines
        if StrLen(CommentText) > 80 then begin
            SalesCommentLine."Line No." := LineNo + 10000;
            SalesCommentLine.Comment := CopyStr(CommentText, 81, 80);
            SalesCommentLine.Insert(true);
        end;
    end;
}