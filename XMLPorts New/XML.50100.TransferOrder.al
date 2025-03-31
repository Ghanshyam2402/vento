xmlport 50100 "Transfer Order WS XML"
{
    UseDefaultNamespace = true;
    Direction = Import;
    schema
    {
        textelement(NodeName1)
        {
            tableelement("TransferHeader"; "Transfer Header")
            {
                MinOccurs = Once;
                UseTemporary = true;
                fieldattribute(TransferfromCode; TransferHeader."Transfer-from Code") { Occurrence = Optional; }
                fieldattribute(TransferToCode; TransferHeader."Transfer-to Code") { Occurrence = Optional; }
                fieldattribute(PostingDate; TransferHeader."Posting Date") { }
                textelement(TransferID) { MinOccurs = Zero; }
                textelement(DocumentNo) { MinOccurs = Zero; }
                textelement(Create) { MinOccurs = Zero; }
                textelement(Ship) { MinOccurs = Zero; }
                textelement(Receive) { MinOccurs = Zero; }

                tableelement(TransferLine; "Transfer Line")
                {
                    LinkTable = TransferHeader;
                    UseTemporary = true;
                    MinOccurs = Zero;
                    fieldattribute(LineNo; TransferLine."Line No.") { Occurrence = Optional; }
                    fieldattribute(ItemNo; TransferLine."Item No.") { Occurrence = Optional; }
                    fieldattribute(UnitofMeasureCode; TransferLine."Unit of Measure Code") { Occurrence = Optional; }
                    fieldattribute(Quantity; TransferLine.Quantity) { Occurrence = Optional; }
                    fieldattribute(TransferfromBinCode; TransferLine."Transfer-from Bin Code") { Occurrence = Optional; }
                    fieldattribute(TransferToBinCode; TransferLine."Transfer-To Bin Code") { Occurrence = Optional; }


                    //Transfer Line
                    trigger OnAfterInsertRecord()
                    begin

                        if Create = '1' then begin
                            TransferLineRec.INIT;
                            TransferLineRec."Line No." := TransferLine."Line No.";
                            TransferLineRec.VALIDATE("Document No.", TrasnferHeaderRec."No.");
                            TransferLineRec.INSERT(TRUE);

                            TransferLineRec.VALIDATE("Item No.", TransferLine."Item No.");
                            TransferLineRec.VALIDATE("Unit of Measure Code", TransferLine."Unit of Measure Code");
                            TransferLineRec.VALIDATE("Transfer-from Code", TrasnferHeaderRec."Transfer-from Code");
                            TransferLineRec.VALIDATE("Transfer-to Code", TrasnferHeaderRec."Transfer-to Code");

                            TransferLineRec.VALIDATE(TransferLineRec.Quantity, TransferLine.Quantity);
                            IF TransferLine."Transfer-from Bin Code" <> '' then
                                TransferLineRec.VALIDATE("Transfer-from Bin Code", TransferLine."Transfer-from Bin Code");
                            IF TransferLine."Transfer-To Bin Code" <> '' then
                                TransferLineRec.VALIDATE("Transfer-To Bin Code", TransferLine."Transfer-To Bin Code");
                            TransferLineRec.Modify();
                        end;
                    end;

                }

                // Transfer Header
                trigger OnAfterInsertRecord()
                begin

                    if Create = '1' then begin
                        InventorySetup.GET;
                        DocumentNo := NoSeriesMgt.GetNextNo(InventorySetup."Transfer Order Nos.", TransferHeader."Posting Date", TRUE);

                        TrasnferHeaderRec.INIT;
                        TrasnferHeaderRec."No." := DocumentNo;
                        TrasnferHeaderRec.INSERT;

                        TransferRoute.GET(TransferHeader."Transfer-from Code", TransferHeader."Transfer-to Code");
                        TrasnferHeaderRec.VALIDATE("Transfer-from Code", TransferHeader."Transfer-from Code");
                        TrasnferHeaderRec.VALIDATE("Transfer-to Code", TransferHeader."Transfer-to Code");
                        TrasnferHeaderRec.VALIDATE("In-Transit Code", TransferRoute."In-Transit Code");

                        TrasnferHeaderRec.VALIDATE("Posting Date", TransferHeader."Posting Date");
                        TrasnferHeaderRec.VALIDATE("Shipment Date", TransferHeader."Posting Date");
                        TrasnferHeaderRec."External Document No." := TransferID;
                        TrasnferHeaderRec.MODIFY(TRUE);

                        SingleInstanceCodeunit.SetPONumber(DocumentNo);

                    end else begin
                        TrasnferHeaderRec.Get(DocumentNo);
                        TrasnferHeaderRec."Posting Date" := TransferHeader."Posting Date";
                    end;

                    if Ship = '1' then
                        ShipOrder := true
                    else
                        ShipOrder := false;


                    if Receive = '1' then
                        ReceiveOrder := true
                    else
                        ReceiveOrder := false;



                    if Create = '1' then
                        CreateOrder := true
                    else
                        CreateOrder := false;
                end;


            }
        }
    }

    trigger OnPostXmlPort()
    begin


        if ShipOrder then
            TransferPostShipment.RUN(TrasnferHeaderRec);

        if ReceiveOrder then
            TransferPostReceipt.RUN(TrasnferHeaderRec);


        if not CreateOrder then
            SingleInstanceCodeunit.SetPONumber('success');

    end;

    var
        TrasnferHeaderRec: Record "Transfer Header";
        TransferLineRec: Record "Transfer Line";
        NoSeriesMgt: Codeunit "No. Series";
        InventorySetup: Record "Inventory Setup";
        TransferRoute: Record "Transfer Route";
        ShipOrder: Boolean;
        ReceiveOrder: Boolean;
        CreateOrder: Boolean;
        TransferPostShipment: Codeunit "TransferOrder-Post Shipment";
        TransferPostReceipt: Codeunit "TransferOrder-Post Receipt";
        SingleInstanceCodeunit: Codeunit "Single Instance Codeunit";

}