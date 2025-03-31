xmlport 50104 "Create Customer WS XML"
{

    UseDefaultNamespace = true;
    Direction = Import;

    schema
    {
        textelement(NodeName1)
        {
            tableelement(RecCustomer; Customer)
            {
                MinOccurs = Once;
                UseTemporary = true;
                fieldattribute(CustomerName; RecCustomer.Name) { }
                fieldattribute(Address; RecCustomer.Address) { }
                fieldattribute(Address2; RecCustomer."Address 2") { }
                fieldattribute(City; RecCustomer.City) { }
                fieldattribute(PhoneNo; RecCustomer."Phone No.") { }
                fieldattribute(MobilePhoneNo; RecCustomer."Mobile Phone No.") { }
                fieldattribute(EMail; RecCustomer."E-Mail") { }
                fieldattribute(GenBusPostingGroup; RecCustomer."Gen. Bus. Posting Group") { }
                fieldattribute(CustomerPostingGroup; RecCustomer."Customer Posting Group") { }
                fieldattribute(PaymentTermsCode; RecCustomer."Payment Terms Code") { }

                trigger OnAfterInsertRecord()
                BEGIN

                    SalesReceivablesSetup.Get();
                    DocNo := NoSeriesMgt.GetNextNo(SalesReceivablesSetup."Customer Nos.", Today, TRUE);

                    NewCustomer.Init();
                    NewCustomer.Validate("No.", DocNo);
                    NewCustomer.Insert();
                    SingleInstanceCodeunit.SetPONumber(NewCustomer."No.");

                    NewCustomer.Validate(Name, RecCustomer.Name);
                    NewCustomer.Validate(Address, RecCustomer.Address);
                    NewCustomer.Validate("Address 2", RecCustomer."Address 2");
                    NewCustomer.Validate(City, RecCustomer.City);
                    NewCustomer.Validate("Phone No.", RecCustomer."Phone No.");
                    NewCustomer.Validate("Mobile Phone No.", RecCustomer."Mobile Phone No.");
                    NewCustomer.Validate("E-Mail", RecCustomer."E-Mail");
                    NewCustomer.Validate("Gen. Bus. Posting Group", RecCustomer."Gen. Bus. Posting Group");
                    NewCustomer.Validate("Customer Posting Group", RecCustomer."Customer Posting Group");
                    NewCustomer.Validate("Payment Terms Code", RecCustomer."Payment Terms Code");
                    NewCustomer.Modify();

                    UpdateContFromCust.InsertNewContact(NewCustomer, false);

                END;

            }
        }
    }

    var
        NewCustomer: Record Customer;
        SingleInstanceCodeunit: Codeunit "Single Instance Codeunit";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        DocNo: Code[50];
        NoSeriesMgt: Codeunit "No. Series";
        UpdateContFromCust: Codeunit "CustCont-Update";
}