xmlport 50103 "GRN Posting WS XML"
{
    UseDefaultNamespace = true;
    Direction = Import;

    schema
    {
        textelement(NodeName1)
        {
            tableelement(PurchaseHeader; "Purchase Header")
            {
                MinOccurs = Once;
                UseTemporary = true;
                fieldattribute(DocumentType; PurchaseHeader."Document Type") { }
                fieldattribute(DocumentNo; PurchaseHeader."No.") { }
                fieldattribute(PostingDate; PurchaseHeader."Posting Date") { }
                textelement(Narration) { MinOccurs = Zero; }

                tableelement(PurchaseLine; "Purchase Line")
                {
                    LinkTable = PurchaseHeader;
                    MinOccurs = Zero;
                    UseTemporary = true;


                    fieldattribute(LineNo; PurchaseLine."Line No.") { Occurrence = Optional; }
                    fieldattribute(QtytoRcv; PurchaseLine."Qty. to Receive") { Occurrence = Optional; }
                    fieldattribute(BinCode; PurchaseLine."Bin Code") { Occurrence = Optional; }

                    //Purchase Line
                    trigger OnAfterInsertRecord()
                    BEGIN

                        PurchaseLineRec.GET(PurchaseLineRec."Document Type"::Order, PurchaseHeader."No.", PurchaseLine."Line No.");
                        PurchaseLineRec.Validate("Qty. to Receive", PurchaseLine."Qty. to Receive");
                        IF PurchaseLine."Bin Code" <> '' then
                            PurchaseLineRec.Validate("Bin Code", PurchaseLine."Bin Code");
                        PurchaseLineRec.Modify();
                    END;
                }
                //Purchase Header
                trigger OnAfterInsertRecord()
                BEGIN
                    PurchaseHeaderRec.Reset();
                    PurchaseHeaderRec.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");

                    PurchaseHeaderRec.Validate("Posting Date", PurchaseHeader."Posting Date");
                    PurchaseHeaderRec.Validate(Receive, true);
                    PurchaseHeaderRec.Validate(Invoice, false);
                    PurchaseHeaderRec.Modify();

                END;
            }
        }
    }


    trigger OnPostXmlPort()
    BEGIN

        IF PurchaseHeaderRec."Receiving No." = '' THEN BEGIN
            PurchasesPayablesSetup.GET;
            PurchaseHeaderRec.VALIDATE("Receiving No.", NoSeriesMgt.GetNextNo(PurchasesPayablesSetup."Posted Receipt Nos.", Today, TRUE));
            PurchaseHeaderRec.MODIFY;
            Commit();
        END;
        SingleInstanceCodeunit.SetPONumber(PurchaseHeaderRec."Receiving No.");
        PurchasePostRecipt.Run(PurchaseHeaderRec);

    END;



    var
        PurchaseHeaderRec: Record "Purchase Header";
        PurchaseLineRec: Record "Purchase Line";
        PurchasePostRecipt: Codeunit "Purch.-Post";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        NoSeriesMgt: Codeunit "No. Series";
        SingleInstanceCodeunit: Codeunit "Single Instance Codeunit";

}