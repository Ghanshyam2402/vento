xmlport 50108 "Sales Shipment Creation"
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
                fieldattribute(ShippingAgentCode; SalesHeader."Shipping Agent Code") { Occurrence = Optional; }
                fieldattribute(PackageTrackingNo; SalesHeader."Package Tracking No.") { Occurrence = Optional; }

                trigger OnAfterInsertRecord()
                var
                    SalesDocWS: Codeunit "Sales Doc WS";
                    SalesHeaderRec: Record "Sales Header";
                    PostingNo: Code[20];
                begin
                    SalesHeaderRec.Reset();
                    SalesHeaderRec.SetRange("Document Type", SalesHeader."Document Type"::Order);
                    SalesHeaderRec.SetRange("No.", SalesHeader."No.");

                    if not SalesHeaderRec.FindFirst() then
                        Error('Sales Order %1 not found.', SalesHeader."No.");

                    // Update shipping information if provided
                    if SalesHeader."External Document No." <> '' then begin
                        SalesHeaderRec.Validate("External Document No.", SalesHeader."External Document No.");
                        SalesHeaderRec.Modify(true);
                    end;

                    if SalesHeader."Posting Date" <> 0D then begin
                        SalesHeaderRec.Validate("Posting Date", SalesHeader."Posting Date");
                        SalesHeaderRec.Modify(true);
                    end;

                    if SalesHeader."Shipping Agent Code" <> '' then begin
                        SalesHeaderRec.Validate("Shipping Agent Code", SalesHeader."Shipping Agent Code");
                        SalesHeaderRec.Modify(true);
                    end;

                    if SalesHeader."Package Tracking No." <> '' then begin
                        SalesHeaderRec.Validate("Package Tracking No.", SalesHeader."Package Tracking No.");
                        SalesHeaderRec.Modify(true);
                    end;

                    // Post the shipment
                    PostingNo := SalesDocWS.PostSalesDoc(SalesHeaderRec."Document Type", SalesHeaderRec."No.", true, false);
                    SingleInstanceCodeunit.SetSalesDocNumber(PostingNo);
                end;
            }
        }
    }

    var
        SingleInstanceCodeunit: Codeunit "Single Instance Codeunit";
}