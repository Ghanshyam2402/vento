xmlport 50109 "Sales Invoice Posting"
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
                fieldattribute(DocumentNo; SalesHeader."No.") { }
                fieldattribute(ExternalDocumentNo; SalesHeader."External Document No.") { Occurrence = Optional; }
                fieldattribute(PostingDate; SalesHeader."Posting Date") { Occurrence = Optional; }
                fieldattribute(PaymentTermsCode; SalesHeader."Payment Terms Code") { Occurrence = Optional; }
                fieldattribute(PaymentMethodCode; SalesHeader."Payment Method Code") { Occurrence = Optional; }

                trigger OnAfterInsertRecord()
                var
                    SalesDocWS: Codeunit "Sales Doc WS";
                    SalesHeaderRec: Record "Sales Header";
                    PostingNo: Code[20];
                begin
                    SalesHeaderRec.Reset();
                    SalesHeaderRec.SetRange("Document Type", SalesHeader."Document Type");
                    SalesHeaderRec.SetRange("No.", SalesHeader."No.");

                    if not SalesHeaderRec.FindFirst() then
                        Error('Sales Document %1 not found.', SalesHeader."No.");

                    // Update invoice information if provided
                    if SalesHeader."External Document No." <> '' then begin
                        SalesHeaderRec.Validate("External Document No.", SalesHeader."External Document No.");
                        SalesHeaderRec.Modify(true);
                    end;

                    if SalesHeader."Posting Date" <> 0D then begin
                        SalesHeaderRec.Validate("Posting Date", SalesHeader."Posting Date");
                        SalesHeaderRec.Modify(true);
                    end;

                    if SalesHeader."Payment Terms Code" <> '' then begin
                        SalesHeaderRec.Validate("Payment Terms Code", SalesHeader."Payment Terms Code");
                        SalesHeaderRec.Modify(true);
                    end;

                    if SalesHeader."Payment Method Code" <> '' then begin
                        SalesHeaderRec.Validate("Payment Method Code", SalesHeader."Payment Method Code");
                        SalesHeaderRec.Modify(true);
                    end;

                    // Post the invoice
                    if SalesHeader."Document Type" = SalesHeader."Document Type"::Order then
                        PostingNo := SalesDocWS.PostSalesDoc(SalesHeaderRec."Document Type", SalesHeaderRec."No.", false, true)
                    else if SalesHeader."Document Type" = SalesHeader."Document Type"::Invoice then
                        PostingNo := SalesDocWS.PostSalesDoc(SalesHeaderRec."Document Type", SalesHeaderRec."No.", false, true);

                    SingleInstanceCodeunit.SetSalesDocNumber(PostingNo);
                end;
            }
        }
    }

    var
        SingleInstanceCodeunit: Codeunit "Single Instance Codeunit";
}