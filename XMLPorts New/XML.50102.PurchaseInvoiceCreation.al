xmlport 50102 "Purchase Invoice Creation"
{
    UseDefaultNamespace = true;
    Direction = Import;

    schema
    {
        textelement(PurchaseInvoice)
        {
            textelement(purchRcptNo) { }
            textelement(VendorInvoiceNo) { MinOccurs = Zero; }
            textelement(narration) { MinOccurs = Zero; }
            trigger OnAfterAssignVariable()
            begin

                PurchReceiptHeader.Get(purchRcptNo);
                PurchaseHeaderOrder.Get(PurchaseHeaderOrder."Document Type"::Order, PurchReceiptHeader."Order No.");

                //Purchase Header Insert
                PurchasesPayablesSetup.GET;

                PurchaseHeaderInovice.INIT;
                PurchaseHeaderInovice."Document Type" := PurchaseHeaderInovice."Document Type"::Invoice;
                PurchaseHeaderInovice."No." := NoSeriesMgt.GetNextNo(PurchasesPayablesSetup."Invoice Nos.", Today, TRUE);
                PurchaseHeaderInovice.INSERT(TRUE);
                SingleInstanceCodeunit.SetPONumber(PurchaseHeaderInovice."No.");


                PurchaseHeaderInovice.VALIDATE("Buy-from Vendor No.", PurchaseHeaderOrder."Buy-from Vendor No.");
                PurchaseHeaderInovice.VALIDATE("No. Series", PurchasesPayablesSetup."Invoice Nos.");
                PurchaseHeaderInovice.VALIDATE("Order Address Code", PurchaseHeaderOrder."Order Address Code");
                PurchaseHeaderInovice.VALIDATE("Posting Date", Today);
                PurchaseHeaderInovice.VALIDATE("Document Date", PurchaseHeaderOrder."Document Date");
                PurchaseHeaderInovice.VALIDATE("Location Code", PurchReceiptHeader."Location Code");
                PurchaseHeaderInovice.VALIDATE("Vendor Invoice No.", VendorInvoiceNo);
                PurchaseHeaderInovice.MODIFY(TRUE);

                PurchaseHeaderInovice.VALIDATE("Dimension Set ID", PurchReceiptHeader."Dimension Set ID");
                PurchaseHeaderInovice."Shortcut Dimension 1 Code" := PurchReceiptHeader."Shortcut Dimension 1 Code";
                PurchaseHeaderInovice."Shortcut Dimension 2 Code" := PurchReceiptHeader."Shortcut Dimension 2 Code";
                PurchaseHeaderInovice.VALIDATE("Posting No. Series", PurchasesPayablesSetup."Posted Invoice Nos.");
                PurchaseHeaderInovice.VALIDATE("Posting No.", NoSeriesMgt.GetNextNo(PurchasesPayablesSetup."Posted Invoice Nos.", Today, TRUE));
                PurchaseHeaderInovice.MODIFY(TRUE);


                //Purchase Line Insert
                PurchRcptLine.RESET;
                PurchRcptLine.SETRANGE(PurchRcptLine."Document No.", PurchReceiptHeader."No.");
                PurchRcptLine.SETFILTER("Qty. Rcd. Not Invoiced", '<>0');
                IF PurchRcptLine.FINDSET THEN
                    REPEAT
                        PurchaseLineOrder.Reset();
                        PurchaseLineOrder.GET(PurchaseHeaderOrder."Document Type"::Order, PurchaseHeaderOrder."No.", PurchRcptLine."Order Line No.");

                        PurchaseLineInovice.Init();
                        PurchaseLineInovice."Document Type" := PurchaseHeaderInovice."Document Type";
                        PurchaseLineInovice."Document No." := PurchaseHeaderInovice."No.";
                        PurchaseLineInovice."Line No." := PurchRcptLine."Line No.";
                        PurchaseLineInovice.Insert();

                        PurchaseLineInovice.Validate(PurchaseLineInovice.Type, PurchaseLineOrder.Type);
                        PurchaseLineInovice.Validate(PurchaseLineInovice."No.", PurchaseLineOrder."No.");
                        PurchaseLineInovice.Validate(PurchaseLineInovice."Unit of Measure Code", PurchRcptLine."Unit of Measure Code");
                        PurchaseLineInovice.Validate(Quantity, PurchRcptLine.Quantity);
                        PurchaseLineInovice.Validate(PurchaseLineInovice."Direct Unit Cost", PurchaseLineOrder."Direct Unit Cost");
                        PurchaseLineInovice."Location Code" := PurchReceiptHeader."Location Code";
                        PurchaseLineInovice.Validate(PurchaseLineInovice."Dimension Set ID", PurchReceiptHeader."Dimension Set ID");


                        PurchaseLineInovice."Order No." := PurchaseLineOrder."Document No.";
                        PurchaseLineInovice."Order Line No." := PurchaseLineOrder."Line No.";
                        PurchaseLineInovice."Receipt No." := PurchRcptLine."Document No.";
                        PurchaseLineInovice."Receipt Line No." := PurchRcptLine."Line No.";
                        PurchaseLineInovice.Modify(true);

                        PurchaseLineInovice.Modify(true);
                    UNTIL PurchRcptLine.NEXT = 0;

                IF narration <> '' THEN BEGIN

                    InsertNarrationPurch(PurchaseHeaderInovice, 0, COPYSTR(narration, 1, 50));
                    InsertNarrationPurch(PurchaseHeaderInovice, 0, COPYSTR(narration, 51, 50));
                    InsertNarrationPurch(PurchaseHeaderInovice, 0, COPYSTR(narration, 101, 50));
                    InsertNarrationPurch(PurchaseHeaderInovice, 0, COPYSTR(narration, 151, 50));
                    InsertNarrationPurch(PurchaseHeaderInovice, 0, COPYSTR(narration, 251, 50));
                END;

            end;
        }
    }

    trigger OnPostXmlPort()
    begin

    end;

    local procedure InsertNarrationPurch(PurchaseHeader: Record 38; DocumentLineNo: Integer; LineNarration: Text[50])
    var
        PurchCommentLine: Record 43;
        LineNo: Integer;

    begin
        IF LineNarration <> '' THEN BEGIN

            PurchCommentLine.RESET;
            PurchCommentLine.SETRANGE(PurchCommentLine."Document Type", PurchaseHeader."Document Type");
            PurchCommentLine.SETRANGE(PurchCommentLine."No.", PurchaseHeader."No.");
            PurchCommentLine.SETRANGE(PurchCommentLine."Document Line No.", DocumentLineNo);
            IF PurchCommentLine.FINDLAST THEN
                LineNo := PurchCommentLine."Line No." + 10000
            else
                LineNo := 10000;


            PurchCommentLine.INIT;
            PurchCommentLine."Document Type" := PurchaseHeader."Document Type";
            PurchCommentLine."No." := PurchaseHeader."No.";
            PurchCommentLine."Line No." := LineNo;
            PurchCommentLine.Date := PurchaseHeader."Posting Date";
            PurchCommentLine.Comment := LineNarration;
            PurchCommentLine."Document Line No." := DocumentLineNo;
            PurchCommentLine.INSERT(TRUE);
        END;
    end;

    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLineOrder: Record "Purchase Line";
        PurchaseHeaderInovice: Record "Purchase Header";
        PurchaseLineInovice: Record "Purchase Line";
        PurchReceiptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        SingleInstanceCodeunit: Codeunit "Single Instance Codeunit";
        NoSeriesMgt: Codeunit "No. Series";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        LineNo: Integer;

}