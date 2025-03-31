xmlport 50110 "Bin Change WS XML"
{
    UseDefaultNamespace = true;
    Direction = Import;

    schema
    {
        textelement(Root)
        {
            tableelement(ItemReclassJournalLine; "Item Journal Line")
            {
                MinOccurs = Once;
                UseTemporary = true;
                fieldattribute(PostingDate; ItemReclassJournalLine."Posting Date") { }
                fieldattribute(ExternalDocumentNo; ItemReclassJournalLine."External Document No.") { Occurrence = Optional; }
                fieldattribute(LocationCode; ItemReclassJournalLine."Location Code") { }
                fieldattribute(LineNo; ItemReclassJournalLine."Line No.") { }
                fieldattribute(ItemNo; ItemReclassJournalLine."Item No.") { }
                fieldattribute(UnitofMeasureCode; ItemReclassJournalLine."Unit of Measure Code") { Occurrence = Optional; }
                fieldattribute(Quantity; ItemReclassJournalLine.Quantity) { }
                fieldattribute(FromBinCode; ItemReclassJournalLine."Bin Code") { }
                fieldattribute(ToBinCode; ItemReclassJournalLine."New Bin Code") { }
                fieldattribute(JournalTemplateName; ItemReclassJournalLine."Journal Template Name") { }
                fieldattribute(JournalBatchName; ItemReclassJournalLine."Journal Batch Name") { }

                trigger OnBeforeInsertRecord()
                begin
                    if not IsFirstRecord then
                        exit;
                    IsFirstRecord := false;

                    // Delete existing records for the same journal template and batch
                    ItemJnlLine.Reset();
                    ItemJnlLine.SetRange("Journal Template Name", ItemReclassJournalLine."Journal Template Name");
                    ItemJnlLine.SetRange("Journal Batch Name", ItemReclassJournalLine."Journal Batch Name");
                    if ItemJnlLine.FindSet() then
                        ItemJnlLine.DeleteAll();

                end;

                trigger OnAfterInsertRecord()
                var
                    ItemJournalTemplate: Record "Item Journal Template";
                    ItemJournalBatch: Record "Item Journal Batch";
                    NoSeriesMgt: Codeunit "No. Series";
                begin
                    ItemJournalTemplate.Get(ItemReclassJournalLine."Journal Template Name");
                    ItemJournalBatch.Get(ItemReclassJournalLine."Journal Template Name", ItemReclassJournalLine."Journal Batch Name");

                    ItemReclassJournalLineRec.Init();
                    ItemReclassJournalLineRec.Validate("Journal Template Name", ItemReclassJournalLine."Journal Template Name");
                    ItemReclassJournalLineRec.Validate("Journal Batch Name", ItemReclassJournalLine."Journal Batch Name");
                    ItemReclassJournalLineRec.Validate("Line No.", ItemReclassJournalLine."Line No.");
                    ItemReclassJournalLineRec.Validate("Entry Type", ItemReclassJournalLine."Entry Type"::Transfer);
                    ItemReclassJournalLineRec.Insert(true);

                    ItemReclassJournalLineRec.Validate("Item No.", ItemReclassJournalLine."Item No.");
                    ItemReclassJournalLineRec.Validate("Posting Date", ItemReclassJournalLine."Posting Date");
                    ItemReclassJournalLineRec.Validate("Location Code", ItemReclassJournalLine."Location Code");
                    ItemReclassJournalLineRec.Validate("New Location Code", ItemReclassJournalLine."Location Code");
                    ItemReclassJournalLineRec.Validate("Item No.", ItemReclassJournalLine."Item No.");
                    ItemReclassJournalLineRec.Validate("Unit of Measure Code", ItemReclassJournalLine."Unit of Measure Code");
                    ItemReclassJournalLineRec.Validate(Quantity, ItemReclassJournalLine.Quantity);
                    ItemReclassJournalLineRec.Validate("Bin Code", ItemReclassJournalLine."Bin Code");
                    ItemReclassJournalLineRec.Validate("New Bin Code", ItemReclassJournalLine."New Bin Code");

                    if DocumentNo = '' then begin
                        DocumentNo := NoSeriesMgt.PeekNextNo(ItemJournalBatch."No. Series");
                    end;
                    ItemReclassJournalLineRec.Validate("Document No.", DocumentNo);
                    ItemReclassJournalLineRec.Modify(true);
                end;
            }
        }
    }

    trigger OnInitXmlPort()
    begin
        IsFirstRecord := true;
    end;

    trigger OnPostXmlPort()
    begin

        ItemJnlLine.Reset();
        ItemJnlLine.SetRange("Journal Template Name", ItemReclassJournalLineRec."Journal Template Name");
        ItemJnlLine.SetRange("Journal Batch Name", ItemReclassJournalLineRec."Journal Batch Name");
        ItemJnlLine.SetRange("Document No.", DocumentNo);

        if ItemJnlLine.FindSet() then
            ItemJnlPostBatch.Run(ItemJnlLine);

        SingleInstanceCodeunit.SetPONumber(DocumentNo);
    end;

    var
        ItemReclassJournalLineRec: Record "Item Journal Line";
        SingleInstanceCodeunit: Codeunit "Single Instance Codeunit";
        DocumentNo: Code[20];
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
        ItemJnlLine: Record "Item Journal Line";
        IsFirstRecord: Boolean;
}