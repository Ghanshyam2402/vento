xmlport 50101 "Supply Purchase Order Creation"
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
                fieldattribute(VendorNo; PurchaseHeader."Buy-from Vendor No.") { }
                fieldattribute(DocumentType; PurchaseHeader."Document Type") { }
                fieldattribute(VendorInvoiceNo; PurchaseHeader."Vendor Invoice No.") { Occurrence = Optional; }
                fieldattribute(PostingDate; PurchaseHeader."Posting Date") { Occurrence = Optional; }
                fieldattribute(DocumentDate; PurchaseHeader."Document Date") { Occurrence = Optional; }
                fieldattribute(OrderDate; PurchaseHeader."Order Date") { Occurrence = Optional; }
                fieldattribute(OrderAddressCode; PurchaseHeader."Order Address Code") { Occurrence = Optional; }
                fieldattribute(Location; PurchaseHeader."Location Code") { }
                fieldattribute(YourReferene; PurchaseHeader."Quote No.") { Occurrence = Optional; }
                textelement(Comment) { MinOccurs = Zero; }
                textelement(Release) { }
                textelement(SendForApproval) { }
                tableelement(DimensionSetEntry; "Dimension Set Entry")
                {
                    LinkTable = PurchaseHeader;
                    UseTemporary = true;
                    fieldelement(DimensionCode; DimensionSetEntry."Dimension Code") { }
                    fieldelement(DimensionValueCode; DimensionSetEntry."Dimension Value Code") { }

                    //DIMENSION INSERT
                    trigger OnAfterInsertRecord()
                    VAR
                        NewDimSetID: Integer;

                    BEGIN
                        TempDimSetEntry.Reset();
                        TempDimSetEntry.SetRange("Dimension Code", DimensionSetEntry."Dimension Code");
                        TempDimSetEntry.SetRange("Dimension Value Code", DimensionSetEntry."Dimension Value Code");
                        IF NOT TempDimSetEntry.FindFirst() then begin
                            GeneralBBQFunctions.UpdateDimension(TempDimSetEntry, DimensionSetEntry."Dimension Code", DimensionSetEntry."Dimension Value Code");

                            NewDimSetID := DimMngt.GetDimensionSetID(TempDimSetEntry);

                            IF NewDimSetID <> PurchaseHeaderRec."Dimension Set ID" then begin
                                PurchaseHeaderRec."Dimension Set ID" := NewDimSetID;

                                GLSetup.Get();
                                IF DimensionSetEntry."Dimension Code" = GLSetup."Global Dimension 1 Code" THEN BEGIN
                                    PurchaseHeaderRec."Shortcut Dimension 1 Code" := DimensionSetEntry."Dimension Value Code";
                                END;
                                IF DimensionSetEntry."Dimension Code" = GLSetup."Global Dimension 2 Code" THEN
                                    PurchaseHeaderRec."Shortcut Dimension 2 Code" := DimensionSetEntry."Dimension Value Code";

                                PurchaseHeaderRec.Modify();
                            end;


                        end;
                    END;
                }

                tableelement(PurchaseLine; "Purchase Line")
                {
                    LinkTable = PurchaseHeader;
                    MinOccurs = Zero;
                    UseTemporary = true;
                    fieldattribute(Type; PurchaseLine.Type) { Occurrence = Optional; }
                    fieldattribute(No; PurchaseLine."No.") { Occurrence = Optional; }
                    fieldattribute(LineNo; PurchaseLine."Line No.") { Occurrence = Optional; }
                    fieldattribute(UnitOfMeasureCode; PurchaseLine."Unit of Measure Code") { Occurrence = Optional; }
                    fieldattribute(Location; PurchaseLine."Location Code") { Occurrence = Optional; }
                    fieldattribute(Qty; PurchaseLine.Quantity) { Occurrence = Optional; }
                    fieldattribute(DirectUnitCost; PurchaseLine."Direct Unit Cost") { Occurrence = Optional; }
                    fieldattribute(BinCode; PurchaseLine."Bin Code") { Occurrence = Optional; }
                    //PURCHASE LINES
                    trigger OnAfterInsertRecord()
                    var
                    BEGIN
                        PurchaseLineRec.Init();
                        PurchaseLineRec."Document Type" := PurchaseHeaderRec."Document Type";
                        PurchaseLineRec."Document No." := PurchaseHeaderRec."No.";
                        PurchaseLineRec."Line No." := PurchaseLine."Line No.";
                        PurchaseLineRec.Insert();


                        PurchaseLineRec.VALIDATE(PurchaseLineRec.Type, PurchaseLine.Type);
                        PurchaseLineRec.VALIDATE(PurchaseLineRec."No.", PurchaseLine."No.");
                        PurchaseLineRec.VALIDATE(PurchaseLineRec."Unit of Measure Code", PurchaseLine."Unit of Measure Code");
                        PurchaseLineRec.VALIDATE(PurchaseLineRec.Quantity, PurchaseLine.Quantity);
                        PurchaseLineRec.VALIDATE(PurchaseLineRec."Direct Unit Cost", PurchaseLine."Direct Unit Cost");
                        PurchaseLineRec.VALIDATE(PurchaseLineRec."Location Code", PurchaseLine."Location Code");
                        PurchaseLineRec.VALIDATE(PurchaseLineRec."Bin Code", PurchaseLine."Bin Code");
                        PurchaseLineRec."Dimension Set ID" := PurchaseHeaderRec."Dimension Set ID";

                        PurchaseLineRec.Modify();

                    END;
                }


                //Purchase Header
                trigger OnAfterInsertRecord()
                begin
                    PurchaseNPayable.Get();
                    DocNo := NoSeriesMgt.GetNextNo(PurchaseNPayable."Order Nos.", Today, TRUE);
                    SingleInstanceCodeunit.SetPONumber(DocNo);

                    PurchaseHeaderRec.INIT;
                    PurchaseHeaderRec."Document Type" := PurchaseHeader."Document Type";
                    PurchaseHeaderRec."No." := DocNo;
                    PurchaseHeaderRec.Validate(PurchaseHeaderRec."Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
                    PurchaseHeaderRec."Vendor Invoice No." := PurchaseHeader."Vendor Invoice No.";
                    PurchaseHeaderRec."Order Date" := PurchaseHeader."Order Date";
                    PurchaseHeaderRec."Quote No." := PurchaseHeader."Quote No.";
                    PurchaseHeaderRec.Validate("Posting Date", PurchaseHeader."Posting Date");
                    PurchaseHeaderRec.Validate("Document Date", PurchaseHeader."Document Date");
                    PurchaseHeaderRec.Insert(true);


                    PurchaseHeaderRec.Validate("Location Code", PurchaseHeader."Location Code");
                    PurchaseHeaderRec.Validate("Order Address Code", PurchaseHeader."Order Address Code");
                    PurchaseHeaderRec."Order Date" := PurchaseHeader."Order Date";
                    PurchaseHeaderRec.Modify(true);
                    IF Comment <> '' THEN BEGIN

                        InsertNarrationPurch(PurchaseHeaderRec, 0, COPYSTR(Comment, 1, 50));
                        InsertNarrationPurch(PurchaseHeaderRec, 0, COPYSTR(Comment, 51, 50));
                        InsertNarrationPurch(PurchaseHeaderRec, 0, COPYSTR(Comment, 101, 50));
                        InsertNarrationPurch(PurchaseHeaderRec, 0, COPYSTR(Comment, 151, 50));
                        InsertNarrationPurch(PurchaseHeaderRec, 0, COPYSTR(Comment, 251, 50));
                    END;
                end;
            }
        }
    }

    trigger OnPostXmlPort()
    begin

        IF SendForApproval = '1' then begin
            CLEAR(ApprovalsMgmt);
            IF ApprovalsMgmt.CheckPurchaseApprovalPossible(PurchaseHeaderRec) THEN
                ApprovalsMgmt.OnSendPurchaseDocForApproval(PurchaseHeaderRec);

        END ELSE
            IF Release = '1' THEN begin
                CLEAR(ReleasePurchDoc);
                CLEAR(ArchiveManagement);
                ReleasePurchDoc.PerformManualRelease(PurchaseHeaderRec);
                PurchaseHeaderRec.Modify(false);
            end;


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
        PurchaseHeaderRec: Record "Purchase Header";
        PurchaseNPayable: Record "Purchases & Payables Setup";
        DocNo: Code[50];
        NoSeriesMgt: Codeunit "No. Series";
        SingleInstanceCodeunit: Codeunit "Single Instance Codeunit";
        TempDimSetEntry: Record 480 temporary;
        GeneralBBQFunctions: Codeunit "General BBQ Functions";
        DimMngt: Codeunit 408;
        GLSetup: Record "General Ledger Setup";
        ApprovalsMgmt: Codeunit 1535;
        ReleasePurchDoc: Codeunit 415;
        ArchiveManagement: Codeunit 5063;
        PurchaseLineRec: Record "Purchase Line";


}